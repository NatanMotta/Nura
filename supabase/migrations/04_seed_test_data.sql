-- 2. Creazione Profili associati
INSERT INTO public.profiles (id, username, display_name, role, bio)
VALUES
  ('11111111-1111-1111-1111-111111111111', 'artist1', 'Artist Test One', 'artist', 'Sono un artista emergente con tanta voglia di far ascoltare i miei brani su Nura!'),
  ('22222222-2222-2222-2222-222222222222', 'curator1', 'Curator Test Uno', 'curator', 'Esperto musicale, cerco nuovi talenti per la mia etichetta.')
ON CONFLICT (id) DO NOTHING;

-- 3. Inserimento di due tracce test per l'artista
INSERT INTO public.tracks (id, artist_id, title, audio_url, duration_seconds, bpm, genre, status)
VALUES
  ('33333333-3333-3333-3333-333333333333', '11111111-1111-1111-1111-111111111111', 'Neon Lights', 'test_audio_1.mp3', 15, 120, 'Electronic', 'ready'),
  ('44444444-4444-4444-4444-444444444444', '11111111-1111-1111-1111-111111111111', 'Sunset Groove', 'test_audio_2.mp3', 15, 95, 'Lo-Fi', 'ready')
ON CONFLICT (id) DO NOTHING;

-- 4. Creazione di una Pitch Request per una traccia al curatore
INSERT INTO public.curator_pitches (track_id, artist_id, curator_id, status, pitch_message)
VALUES
  ('33333333-3333-3333-3333-333333333333', '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', 'pending', 'Ehi! Ascolta la mia ultima traccia elettronica, penso sia perfetta per voi!')
ON CONFLICT (track_id, curator_id) DO NOTHING;