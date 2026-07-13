-- Tabella per registrare i dispositivi e i loro token FCM
CREATE TABLE IF NOT EXISTS public.user_devices (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  profile_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  fcm_token text NOT NULL,
  platform text NOT NULL, -- 'ios', 'android', 'web'
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(profile_id, fcm_token)
);

ALTER TABLE public.user_devices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Utenti possono vedere i propri devices" 
  ON public.user_devices 
  FOR SELECT 
  USING (auth.uid() = profile_id);

CREATE POLICY "Utenti possono aggiungere i propri devices" 
  ON public.user_devices 
  FOR INSERT 
  WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "Utenti possono modificare i propri devices" 
  ON public.user_devices 
  FOR UPDATE 
  USING (auth.uid() = profile_id);

CREATE POLICY "Utenti possono eliminare i propri devices" 
  ON public.user_devices 
  FOR DELETE 
  USING (auth.uid() = profile_id);

-- Tabella per le notifiche in-app
CREATE TABLE IF NOT EXISTS public.in_app_notifications (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  profile_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  type text NOT NULL, -- 'match', 'review_ready', 'system', 'new_follower'
  title text NOT NULL,
  body text NOT NULL,
  data jsonb DEFAULT '{}'::jsonb, -- Dati aggiuntivi (es. track_id, matcher_id)
  is_read boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE public.in_app_notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Utenti possono vedere le proprie notifiche" 
  ON public.in_app_notifications 
  FOR SELECT 
  USING (auth.uid() = profile_id);

CREATE POLICY "Utenti possono aggiornare lo stato di lettura delle notifiche" 
  ON public.in_app_notifications 
  FOR UPDATE 
  USING (auth.uid() = profile_id);

CREATE POLICY "Utenti possono eliminare le proprie notifiche" 
  ON public.in_app_notifications 
  FOR DELETE 
  USING (auth.uid() = profile_id);

-- Policy per inserimento: le notifiche possono essere inserite da altri utenti (es. ti metto un follow) 
-- o dal backend (Service Role)
CREATE POLICY "Tutti gli utenti possono inserire notifiche" 
  ON public.in_app_notifications 
  FOR INSERT 
  WITH CHECK (true);

-- Funzione per aggiornare updated_at
CREATE OR REPLACE FUNCTION update_user_devices_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_user_devices_updated_at_trigger
BEFORE UPDATE ON public.user_devices
FOR EACH ROW
EXECUTE FUNCTION update_user_devices_updated_at();

-- Abilita l'estensione pg_net
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Trigger per invocare l'Edge Function in background quando viene inserita una notifica
CREATE OR REPLACE FUNCTION trigger_push_notification()
RETURNS TRIGGER AS $$
DECLARE
  edge_function_url text := 'https://acmnybvdfytwxchpalgo.supabase.co/functions/v1/send-push-notification';
  payload jsonb;
BEGIN
  payload := json_build_object(
    'record', row_to_json(NEW)
  )::jsonb;

  -- Usiamo pg_net per inviare una richiesta POST asincrona
  PERFORM net.http_post(
    url := edge_function_url,
    body := payload,
    headers := jsonb_build_object(
      'Content-Type', 'application/json'
    )
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_notification_insert
AFTER INSERT ON public.in_app_notifications
FOR EACH ROW
EXECUTE FUNCTION trigger_push_notification();
