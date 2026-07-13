-- ==========================================
-- TRIGGER 1: NUOVO FOLLOWER
-- ==========================================
CREATE OR REPLACE FUNCTION notify_new_follower()
RETURNS TRIGGER AS $$
BEGIN
  -- Recupera il nome di chi ti sta seguendo per fare una notifica più carina (opzionale)
  -- Per ora restiamo generici, o potremmo usare una subquery:
  -- DECLARE follower_name text;
  -- SELECT username INTO follower_name FROM public.profiles WHERE id = NEW.follower_id;
  
  INSERT INTO public.in_app_notifications (
    profile_id, 
    type, 
    title, 
    body, 
    data
  ) VALUES (
    NEW.following_id, 
    'new_follower', 
    'Nuovo Follower!', 
    'Un utente ha appena iniziato a seguirti.',
    jsonb_build_object('follower_id', NEW.follower_id)
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_new_follower
AFTER INSERT ON public.follows
FOR EACH ROW
EXECUTE FUNCTION notify_new_follower();


-- ==========================================
-- TRIGGER 2: PITCH REVIEWED (All'artista)
-- ==========================================
CREATE OR REPLACE FUNCTION notify_pitch_reviewed()
RETURNS TRIGGER AS $$
BEGIN
  -- Vogliamo triggerare solo quando lo status cambia ed è uno di quelli finali
  IF NEW.status IS DISTINCT FROM OLD.status AND NEW.status IN ('reviewed', 'accepted', 'rejected') THEN
    INSERT INTO public.in_app_notifications (
      profile_id, 
      type, 
      title, 
      body, 
      data
    ) VALUES (
      NEW.artist_id, 
      'review_ready', 
      'Esito del Pitch', 
      'Il curatore ha appena recensito il tuo brano!',
      jsonb_build_object('pitch_id', NEW.id, 'status', NEW.status)
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_pitch_reviewed
AFTER UPDATE ON public.curator_pitches
FOR EACH ROW
EXECUTE FUNCTION notify_pitch_reviewed();


-- ==========================================
-- TRIGGER 3: NUOVO PITCH RICEVUTO (Al Curatore)
-- ==========================================
CREATE OR REPLACE FUNCTION notify_new_pitch()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.in_app_notifications (
    profile_id, 
    type, 
    title, 
    body, 
    data
  ) VALUES (
    NEW.curator_id, 
    'system', 
    'Nuovo Pitch Ricevuto', 
    'Un artista ti ha appena inviato un brano da recensire.',
    jsonb_build_object('pitch_id', NEW.id, 'artist_id', NEW.artist_id)
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_new_pitch
AFTER INSERT ON public.curator_pitches
FOR EACH ROW
EXECUTE FUNCTION notify_new_pitch();
