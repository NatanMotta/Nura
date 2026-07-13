-- Aggiunge le colonne per i punteggi (Nura Score) alla tabella curator_pitches
ALTER TABLE public.curator_pitches
ADD COLUMN IF NOT EXISTS lyrics_score INTEGER CHECK (lyrics_score >= 0 AND lyrics_score <= 100),
ADD COLUMN IF NOT EXISTS vibe_score INTEGER CHECK (vibe_score >= 0 AND vibe_score <= 100),
ADD COLUMN IF NOT EXISTS production_score INTEGER CHECK (production_score >= 0 AND production_score <= 100),
ADD COLUMN IF NOT EXISTS market_potential_score INTEGER CHECK (market_potential_score >= 0 AND market_potential_score <= 100),
ADD COLUMN IF NOT EXISTS feedback_message TEXT;

-- Vista per facilitare il recupero dei dati del track e dell'artista insieme al pitch
CREATE OR REPLACE VIEW public.curator_pitches_view AS
SELECT 
    cp.id as pitch_id,
    cp.track_id,
    cp.artist_id,
    cp.curator_id,
    cp.status,
    cp.pitch_message,
    cp.lyrics_score,
    cp.vibe_score,
    cp.production_score,
    cp.market_potential_score,
    cp.feedback_message,
    cp.created_at,
    -- Info Traccia
    t.title as track_title,
    t.genre as track_genre,
    t.audio_url as track_audio_url,
    t.cover_url as track_cover_url,
    -- Info Artista
    p.display_name as artist_name,
    p.avatar_url as artist_avatar_url
FROM public.curator_pitches cp
JOIN public.tracks t ON cp.track_id = t.id
JOIN public.profiles p ON cp.artist_id = p.id;
