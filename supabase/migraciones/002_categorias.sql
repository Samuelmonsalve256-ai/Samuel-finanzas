-- Categorías con ícono (emoji) y tipo: de gasto o de ingreso.
-- Las categorías que ya existen quedan como "gasto". Se agrega "Ingreso" como categoría de
-- ingreso (es la que ya tienen tus ingresos registrados). No borra ni cambia movimientos.

alter table public.categorias add column if not exists icono text;
alter table public.categorias add column if not exists tipo text not null default 'gasto';

alter table public.categorias drop constraint if exists categorias_tipo_check;
alter table public.categorias add constraint categorias_tipo_check check (tipo in ('gasto', 'ingreso'));

insert into public.categorias (name, color, icono, tipo)
select 'Ingreso', '#059669', '💵', 'ingreso'
where not exists (select 1 from public.categorias where name = 'Ingreso');
