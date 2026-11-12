# Funciones comunes para las tareas de Supabase. Se carga con: source .github/scripts/supabase.sh
# Usa la API de administración de Supabase con el secreto SUPABASE_ACCESS_TOKEN.
set -euo pipefail

SB_REF="${SB_REF:-hcwgtyjgscgdnxkrcjqf}"
SB_API="${SB_API:-https://api.supabase.com}"
SB_URL="${SB_URL:-https://$SB_REF.supabase.co}"

if [ -z "${SUPABASE_ACCESS_TOKEN:-}" ]; then
  # Sin la llave no se hace nada (aviso, sin marcar error): ver supabase/LEEME.md
  echo "::warning::Falta el secreto SUPABASE_ACCESS_TOKEN. Agrégalo en GitHub: Settings → Secrets and variables → Actions (ver supabase/LEEME.md)."
  exit 0
fi

# Ejecuta SQL en la base del proyecto e imprime las filas en JSON. Falla si Supabase da error.
consulta() {
  local resp code
  resp=$(mktemp)
  code=$(jq -Rs '{query: .}' <<<"$1" | curl -sS -o "$resp" -w '%{http_code}' -X POST \
    "$SB_API/v1/projects/$SB_REF/database/query" \
    -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN" -H 'Content-Type: application/json' --data-binary @-)
  if [[ "$code" != 2* ]]; then
    echo "::error::Supabase respondió $code: $(head -c 500 "$resp")" >&2
    rm -f "$resp"; return 1
  fi
  cat "$resp"; rm -f "$resp"
}

# Aplica, en orden, los archivos de supabase/migraciones que aún no se han aplicado.
# Cada uno va en una transacción: si falla, no queda a medias y la tarea avisa.
aplicar_migraciones() {
  consulta "create table if not exists public._migraciones (nombre text primary key, aplicada timestamptz not null default now());
            alter table public._migraciones enable row level security;" >/dev/null
  local aplicadas n=0 f nombre
  aplicadas=$(consulta "select nombre from public._migraciones" | jq -r '.[].nombre')
  for f in $(ls supabase/migraciones/*.sql 2>/dev/null | sort); do
    nombre=$(basename "$f" .sql)
    if grep -qxF "$nombre" <<<"$aplicadas"; then echo "✓ $nombre (ya estaba aplicada)"; continue; fi
    echo "→ Aplicando $nombre"
    consulta "begin;
$(cat "$f")
;
insert into public._migraciones (nombre) values ('$nombre');
commit;" >/dev/null
    echo "✓ $nombre aplicada"
    n=$((n+1))
  done
  echo "Cambios aplicados en esta ejecución: $n"
}
