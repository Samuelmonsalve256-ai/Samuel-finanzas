-- Compromisos con categoría: al pagarlo, el gasto se registra en la categoría elegida
-- (antes siempre caía en la primera categoría de la lista). No cambia datos existentes;
-- los compromisos sin categoría usan una sugerida por su nombre.
alter table public.compromisos add column if not exists categoria text;
