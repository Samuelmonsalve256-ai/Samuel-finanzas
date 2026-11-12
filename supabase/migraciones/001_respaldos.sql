-- Respaldos semanales en Supabase Storage (bucket privado "respaldos").
-- La tarea de GitHub "Respaldo semanal" guarda ahí una copia de tus finanzas cada domingo.
-- Desde la app (Ajustes → Respaldos) solo tu cuenta puede verlos y descargarlos:
-- cada respaldo va en una carpeta con el id de tu usuario.
-- No toca ninguna tabla ni dato.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('respaldos', 'respaldos', false, 52428800, array['application/json'])
on conflict (id) do update
  set public = false,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists mf_respaldos_ver on storage.objects;
create policy mf_respaldos_ver on storage.objects
  for select to authenticated
  using (bucket_id = 'respaldos' and (storage.foldername(name))[1] = auth.uid()::text);
