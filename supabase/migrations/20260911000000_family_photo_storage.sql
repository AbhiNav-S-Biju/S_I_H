-- Private storage for patient-scoped family photos.
-- Object paths must begin with the patient UUID: <patient_id>/<photo_id>.<ext>

insert into storage.buckets (id, name, public)
values ('family-photos', 'family-photos', false)
on conflict (id) do update set public = false;

create policy "family photos storage select linked"
on storage.objects for select
to authenticated
using (
  bucket_id = 'family-photos'
  and public.is_caregiver_for_patient((storage.foldername(name))[1]::uuid)
);

create policy "family photos storage insert linked"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'family-photos'
  and public.is_caregiver_for_patient((storage.foldername(name))[1]::uuid)
);

create policy "family photos storage update linked"
on storage.objects for update
to authenticated
using (
  bucket_id = 'family-photos'
  and public.is_caregiver_for_patient((storage.foldername(name))[1]::uuid)
)
with check (
  bucket_id = 'family-photos'
  and public.is_caregiver_for_patient((storage.foldername(name))[1]::uuid)
);

create policy "family photos storage delete linked"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'family-photos'
  and public.is_caregiver_for_patient((storage.foldername(name))[1]::uuid)
);
