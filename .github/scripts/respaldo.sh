#!/usr/bin/env bash
# Guarda una copia de todas tus finanzas en Supabase Storage (bucket privado "respaldos")
# y conserva solo los últimos 12 respaldos.
source "$(dirname "$0")/supabase.sh"
GUARDAR="${GUARDAR:-12}"

aplicar_migraciones   # asegura que exista el bucket "respaldos"

uid=$(consulta "select id from auth.users order by created_at limit 1" | jq -r '.[0].id // empty')
if [ -z "$uid" ]; then echo "::error::No hay ningún usuario en Authentication → Users"; exit 1; fi

archivo=$(mktemp)
consulta "select json_build_object(
  'app', 'Mis Finanzas', 'creado', now(),
  'registros',   (select coalesce(json_agg(t order by t.id), '[]'::json) from public.registros t),
  'categorias',  (select coalesce(json_agg(t), '[]'::json) from public.categorias t),
  'capital',     (select coalesce(json_agg(t), '[]'::json) from public.capital t),
  'compromisos', (select coalesce(json_agg(t), '[]'::json) from public.compromisos t),
  'ajustes',     (select coalesce(json_agg(t), '[]'::json) from public.ajustes t)
) as respaldo" | jq '.[0].respaldo' > "$archivo"
jq -e '.registros | type == "array"' "$archivo" >/dev/null || { echo "::error::El respaldo salió vacío o mal formado"; exit 1; }
echo "Respaldo: $(jq '.registros|length' "$archivo") registros, $(jq '.compromisos|length' "$archivo") compromisos, $(jq '.categorias|length' "$archivo") categorías"

# Llave de servicio del proyecto (solo para guardar en Storage; nunca se muestra en el registro)
llaves=$(curl -sS -f "$SB_API/v1/projects/$SB_REF/api-keys?reveal=true" -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN")
srv=$(jq -r '[.[] | select(.name == "service_role" and .api_key != null)][0].api_key // empty' <<<"$llaves")
[ -z "$srv" ] && srv=$(jq -r '[.[] | select(.type == "secret" and .api_key != null)][0].api_key // empty' <<<"$llaves")
if [ -z "$srv" ]; then echo "::error::No se encontró la llave de servicio del proyecto"; exit 1; fi
echo "::add-mask::$srv"
cab=(-H "apikey: $srv")
[[ "$srv" == eyJ* ]] && cab+=(-H "Authorization: Bearer $srv")

nombre="finanzas_$(date -u +%Y-%m-%d).json"
curl -sS -f -X POST "$SB_URL/storage/v1/object/respaldos/$uid/$nombre" "${cab[@]}" \
  -H 'Content-Type: application/json' -H 'x-upsert: true' --data-binary @"$archivo" >/dev/null
echo "✓ Guardado respaldos/$nombre"

# Se conservan los últimos $GUARDAR
lista=$(curl -sS -f -X POST "$SB_URL/storage/v1/object/list/respaldos" "${cab[@]}" -H 'Content-Type: application/json' \
  -d "{\"prefix\":\"$uid\",\"limit\":1000,\"sortBy\":{\"column\":\"name\",\"order\":\"desc\"}}")
viejos=$(jq -c --arg u "$uid" --argjson g "$GUARDAR" \
  '[.[] | select(.name | test("^finanzas_.*\\.json$")) | .name] | sort | reverse | .[$g:] | map($u + "/" + .)' <<<"$lista")
if [ "$(jq length <<<"$viejos")" -gt 0 ]; then
  curl -sS -f -X DELETE "$SB_URL/storage/v1/object/respaldos" "${cab[@]}" -H 'Content-Type: application/json' \
    -d "{\"prefixes\":$viejos}" >/dev/null
  echo "Borrados $(jq length <<<"$viejos") respaldos viejos"
fi
rm -f "$archivo"
