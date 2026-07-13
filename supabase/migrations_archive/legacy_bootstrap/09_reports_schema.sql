-- Tabella per i blocchi utente
CREATE TABLE IF NOT EXISTS public.user_blocks (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  blocker_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  blocked_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  created_at timestamptz DEFAULT now(),
  UNIQUE(blocker_id, blocked_id)
);

ALTER TABLE public.user_blocks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Utenti possono vedere chi hanno bloccato" 
  ON public.user_blocks 
  FOR SELECT 
  USING (auth.uid() = blocker_id);

CREATE POLICY "Utenti possono bloccare altre persone" 
  ON public.user_blocks 
  FOR INSERT 
  WITH CHECK (auth.uid() = blocker_id);

CREATE POLICY "Utenti possono sbloccare persone" 
  ON public.user_blocks 
  FOR DELETE 
  USING (auth.uid() = blocker_id);


-- Tabella per le segnalazioni (Report)
CREATE TABLE IF NOT EXISTS public.content_reports (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  reporter_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  track_id uuid REFERENCES public.tracks(id) ON DELETE CASCADE,
  profile_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  reason text NOT NULL,
  status text DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'resolved')),
  created_at timestamptz DEFAULT now()
);

-- Assicura che la segnalazione sia per una traccia O un profilo, non entrambi e non nessuno.
ALTER TABLE public.content_reports
  ADD CONSTRAINT chk_report_target CHECK (
    (track_id IS NOT NULL AND profile_id IS NULL) OR
    (track_id IS NULL AND profile_id IS NOT NULL)
  );

ALTER TABLE public.content_reports ENABLE ROW LEVEL SECURITY;

-- Gli utenti possono solo inserire report, solo gli admin possono vederli (o il creatore se vogliamo, ma di solito i report sono ciechi)
CREATE POLICY "Utenti possono inviare report" 
  ON public.content_reports 
  FOR INSERT 
  WITH CHECK (auth.uid() = reporter_id);
