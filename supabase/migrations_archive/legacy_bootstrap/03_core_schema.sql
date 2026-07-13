-- Migrazione per la Fase 2: Core Schema (Profili, Tracce, Pitches)
-- Ottimizzato per scalabilità e sicurezza (Row Level Security)

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Tipo Enumerativo per il ruolo utente
DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('artist', 'curator', 'admin');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 2. Tabella Profiles
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username VARCHAR(50) UNIQUE NOT NULL,
    display_name VARCHAR(100),
    bio TEXT,
    avatar_url TEXT,
    role user_role DEFAULT 'artist'::user_role NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Indici per ricerche rapide sui profili
CREATE INDEX IF NOT EXISTS idx_profiles_username ON public.profiles(username);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);

-- 3. Tipo Enumerativo per lo status della traccia
DO $$ BEGIN
    CREATE TYPE track_status AS ENUM ('processing', 'ready', 'archived');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 4. Tabella Tracks (Le canzoni caricate dagli artisti)
CREATE TABLE IF NOT EXISTS public.tracks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    artist_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    audio_url TEXT NOT NULL, -- URL Cloudflare R2
    cover_url TEXT, -- URL Supabase Storage
    duration_seconds INTEGER NOT NULL,
    bpm INTEGER,
    genre VARCHAR(100),
    status track_status DEFAULT 'processing'::track_status NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Indici per feed swipe
CREATE INDEX IF NOT EXISTS idx_tracks_artist_id ON public.tracks(artist_id);
CREATE INDEX IF NOT EXISTS idx_tracks_status_created ON public.tracks(status, created_at DESC);

-- 5. Tipo Enumerativo per lo stato del pitch
DO $$ BEGIN
    CREATE TYPE pitch_status AS ENUM ('pending', 'accepted', 'rejected', 'feedback_given');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 6. Tabella Curator Pitches
CREATE TABLE IF NOT EXISTS public.curator_pitches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    track_id UUID NOT NULL REFERENCES public.tracks(id) ON DELETE CASCADE,
    artist_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    curator_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    status pitch_status DEFAULT 'pending'::pitch_status NOT NULL,
    pitch_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    -- Un artista non può pitchare la stessa traccia allo stesso curatore due volte
    UNIQUE(track_id, curator_id)
);

CREATE INDEX IF NOT EXISTS idx_pitches_curator ON public.curator_pitches(curator_id, status);
CREATE INDEX IF NOT EXISTS idx_pitches_artist ON public.curator_pitches(artist_id);

--------------------------------------------------------------------------------
-- SICUREZZA: ROW LEVEL SECURITY (RLS)
--------------------------------------------------------------------------------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tracks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.curator_pitches ENABLE ROW LEVEL SECURITY;

-- POLICY: Profiles
CREATE POLICY "Profili pubblici" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Utenti possono aggiornare il proprio profilo" ON public.profiles FOR UPDATE USING (auth.uid() = id);
-- L'inserimento iniziale (signup) avverrà tramite Trigger o chiamata Supabase sicura.
CREATE POLICY "Utenti possono inserire il proprio profilo" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- POLICY: Tracks
CREATE POLICY "Chiunque può vedere le tracce pronte o dell'autore" ON public.tracks FOR SELECT 
USING (status = 'ready'::track_status OR auth.uid() = artist_id);
CREATE POLICY "Artisti possono inserire tracce" ON public.tracks FOR INSERT WITH CHECK (auth.uid() = artist_id);
CREATE POLICY "Artisti possono aggiornare le proprie tracce" ON public.tracks FOR UPDATE USING (auth.uid() = artist_id);

-- POLICY: Curator Pitches
CREATE POLICY "Artisti e Curatori coinvolti possono leggere il pitch" ON public.curator_pitches FOR SELECT USING (auth.uid() = artist_id OR auth.uid() = curator_id);

CREATE POLICY "Artisti possono inviare pitch" ON public.curator_pitches FOR INSERT 
WITH CHECK (auth.uid() = artist_id);

CREATE POLICY "Curatori possono aggiornare lo stato del pitch" ON public.curator_pitches FOR UPDATE 
USING (auth.uid() = curator_id);