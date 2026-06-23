-- Security Hardening: Aggiunta Policy DELETE e restrizioni Storage

-- 1. DELETE su profiles
CREATE POLICY "Utenti possono cancellare il proprio profilo" 
  ON public.profiles 
  FOR DELETE 
  USING (auth.uid() = id);

-- 2. DELETE su tracks
CREATE POLICY "Artisti possono cancellare le proprie tracce" 
  ON public.tracks 
  FOR DELETE 
  USING (auth.uid() = artist_id);

-- 3. DELETE su curator_pitches
CREATE POLICY "Utenti possono cancellare i propri pitch" 
  ON public.curator_pitches 
  FOR DELETE 
  USING (auth.uid() = artist_id OR auth.uid() = curator_id);

-- 4. DELETE su follows
CREATE POLICY "Utenti possono rimuovere i propri follow" 
  ON public.follows 
  FOR DELETE 
  USING (auth.uid() = follower_id);

-- 5. Storage DELETE policies
CREATE POLICY "Utenti possono cancellare i propri file avatar" 
  ON storage.objects 
  FOR DELETE 
  USING (bucket_id = 'avatars' AND auth.uid() = owner);

CREATE POLICY "Artisti possono cancellare le proprie cover" 
  ON storage.objects 
  FOR DELETE 
  USING (bucket_id = 'tracks_covers' AND auth.uid() = owner);

-- 6. Trigger per impedire escalation del ruolo
-- Impedisce a un utente di cambiarsi il ruolo in "admin" o modificarselo se non ha permessi,
-- ma per ora la policy UPDATE su profiles permette all'utente di modificare la propria riga.
-- Creiamo una semplice funzione che impedisce il cambio di ruolo (il ruolo viene settato alla registrazione).

CREATE OR REPLACE FUNCTION public.prevent_role_escalation()
RETURNS TRIGGER AS $$
BEGIN
  -- Se l'utente tenta di cambiare il suo ruolo, lo rimettiamo a quello vecchio
  -- a meno che non sia l'admin (qui semplificato: nessuno può cambiare ruolo da solo post-registrazione)
  IF NEW.role IS DISTINCT FROM OLD.role THEN
    NEW.role = OLD.role;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS tr_prevent_role_escalation ON public.profiles;
CREATE TRIGGER tr_prevent_role_escalation
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.prevent_role_escalation();
