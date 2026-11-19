-- Historial de cambios del capital inicial.
-- Cada vez que se modifica el capital inicial queda un registro con la fecha, el valor
-- anterior, el nuevo y el motivo. Desde la app solo se puede LEER y AGREGAR: no hay
-- regla para modificar ni borrar, así que el historial no se puede alterar.

create table if not exists public.capital_historial (
  id          bigint generated always as identity primary key,
  creado      timestamptz not null default now(),
  anterior    jsonb,
  nuevo       jsonb not null,
  motivo      text not null,
  dispositivo text
);

alter table public.capital_historial enable row level security;

do $$
declare v_uid uuid;
begin
  select id into v_uid from auth.users order by created_at limit 1;
  if v_uid is null then raise exception 'No hay usuario en Authentication → Users'; end if;
  drop policy if exists cap_hist_ver on public.capital_historial;
  drop policy if exists cap_hist_agregar on public.capital_historial;
  execute format('create policy cap_hist_ver on public.capital_historial for select to authenticated using (auth.uid() = %L::uuid)', v_uid);
  execute format('create policy cap_hist_agregar on public.capital_historial for insert to authenticated with check (auth.uid() = %L::uuid)', v_uid);
end $$;

grant select, insert on public.capital_historial to authenticated;
revoke update, delete on public.capital_historial from authenticated, anon;
