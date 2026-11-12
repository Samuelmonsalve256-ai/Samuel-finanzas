-- ════════════════════════════════════════════════════════════════════════════
-- Mis Finanzas: seguridad de la base de datos
-- Ejecútalo en Supabase → SQL Editor DESPUÉS de crear tu usuario y de entrar una vez
-- a la app con él (ver supabase/LEEME.md). Se puede ejecutar varias veces sin problema.
--
-- Qué hace:
--   1. Crea la tabla "ajustes" (presupuestos y PIN compartidos entre tus dispositivos)
--   2. Activa la seguridad por filas (RLS) en todas las tablas y deja una sola regla:
--      solo TU usuario puede leer y escribir. Sin sesión, la base no muestra nada.
--   3. Crea la función mantener_activo(), que usa la tarea automática de GitHub para
--      que el proyecto no se pause por falta de uso. No lee ni cambia tus datos.
-- No borra ningún dato.
-- ════════════════════════════════════════════════════════════════════════════

-- 1. Tabla de ajustes
create table if not exists public.ajustes (
  clave       text primary key,
  valor       jsonb not null,
  actualizado timestamptz not null default now()
);

-- 2. Reglas de seguridad
do $$
declare
  -- ✏️ Cambia esto por el correo con el que entras a Mis Finanzas (déjalo entre comillas)
  v_email text := 'TU_CORREO@ejemplo.com';
  v_uid   uuid;
  t       text;
  p       record;
begin
  select id into v_uid from auth.users where lower(email) = lower(v_email);
  if v_uid is null then
    raise exception 'No existe un usuario con el correo %. Créalo en Authentication → Users y cambia el correo en la línea v_email.', v_email;
  end if;

  foreach t in array array['registros','categorias','capital','compromisos','ajustes'] loop
    execute format('alter table public.%I enable row level security', t);
    -- Se quitan las reglas anteriores (por ejemplo, las que dejaban entrar a cualquiera)
    for p in select policyname from pg_policies where schemaname = 'public' and tablename = t loop
      execute format('drop policy %I on public.%I', p.policyname, t);
    end loop;
    execute format(
      'create policy solo_mi_cuenta on public.%I for all to authenticated using (auth.uid() = %L::uuid) with check (auth.uid() = %L::uuid)',
      t, v_uid, v_uid);
    execute format('grant select, insert, update, delete on public.%I to authenticated', t);
  end loop;
  raise notice 'Listo: solo % puede ver y cambiar los datos.', v_email;
end $$;

-- 3. Función para mantener el proyecto activo
create or replace function public.mantener_activo()
returns timestamptz language sql stable as $$ select now() $$;
grant execute on function public.mantener_activo() to anon, authenticated;

-- Comprobación: debe mostrar las 5 tablas con rls_activo = true y una regla cada una
select c.relname as tabla, c.relrowsecurity as rls_activo,
       (select count(*) from pg_policies p where p.schemaname = 'public' and p.tablename = c.relname) as reglas
from pg_class c join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public' and c.relname in ('registros','categorias','capital','compromisos','ajustes')
order by 1;
