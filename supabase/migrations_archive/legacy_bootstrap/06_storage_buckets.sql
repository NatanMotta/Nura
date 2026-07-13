-- Crea i bucket Storage se non esistono
INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('tracks_covers', 'tracks_covers', true) ON CONFLICT (id) DO NOTHING;

-- RLS per avatars
CREATE POLICY "Tutti possono vedere gli avatar" ON storage.objects FOR SELECT USING (bucket_id = 'avatars');
CREATE POLICY "Utenti autenticati possono caricare il proprio avatar" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'avatars' AND auth.role() = 'authenticated');
CREATE POLICY "Utenti possono modificare il proprio avatar" ON storage.objects FOR UPDATE USING (bucket_id = 'avatars' AND auth.role() = 'authenticated');

-- RLS per tracks_covers
CREATE POLICY "Tutti possono vedere le cover" ON storage.objects FOR SELECT USING (bucket_id = 'tracks_covers');
CREATE POLICY "Artisti possono caricare cover" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'tracks_covers' AND auth.role() = 'authenticated');
CREATE POLICY "Artisti possono modificare le proprie cover" ON storage.objects FOR UPDATE USING (bucket_id = 'tracks_covers' AND auth.role() = 'authenticated');
