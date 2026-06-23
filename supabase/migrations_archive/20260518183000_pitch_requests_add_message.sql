-- Aggiunta della colonna message alla tabella pitch_requests per ospitare la presentazione dell'artista
alter table public.pitch_requests add column if not exists message text;
