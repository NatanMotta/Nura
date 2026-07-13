-- Tabella per gestire i Follow tra utenti
CREATE TABLE IF NOT EXISTS public.follows (
    follower_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    following_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    PRIMARY KEY (follower_id, following_id)
);

-- Indici per query veloci
CREATE INDEX IF NOT EXISTS idx_follows_follower ON public.follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_following ON public.follows(following_id);

-- RLS (Row Level Security)
ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Tutti possono vedere chi segue chi" ON public.follows FOR SELECT USING (true);
CREATE POLICY "Un utente puo seguire altri" ON public.follows FOR INSERT WITH CHECK (auth.uid() = follower_id);
CREATE POLICY "Un utente puo smettere di seguire" ON public.follows FOR DELETE USING (auth.uid() = follower_id);
