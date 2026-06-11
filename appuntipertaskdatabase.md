# Appunti per Task Database (Supabase)

Questi appunti servono solo come promemoria concettuale per quando andremo a collegare il backend. Non definiscono strutture fisse, che dipenderanno dallo stato del database e dai dati reali.

## Nura Score e Origine dei Dati
- **Dipendenza dai Curator**: Il Nura Score (sia globale dell'artista che specifico per canzone) non è un numero a sé stante, ma va calcolato dinamicamente partendo dai **Feedback lasciati dai Curator**.
- Abbiamo già sviluppato in passato la task/schermata relativa ai Curator (dove ascoltano e valutano i brani). Quei dati lì sono la fonte di verità.
- **Flusso logico futuro**: Quando faremo l'integrazione, per mostrare i dettagli del Nura Score di un artista o di una canzone in questa schermata, dovremo interrogare la tabella/struttura che contiene i feedback dei curator per i brani di quell'artista, e da lì calcolare le medie (Vibe, Testo, Produzione, Potenziale di Mercato).

## Bio Artista
- **Bio/Descrizione**: La descrizione e l'eventuale link attualmente hardcoded ('KOcco...', 'https...') dovranno essere recuperati dinamicamente dai campi del profilo artista nel database.

## Sistema di Following
- **Azione Segui/Non Segui**: Quando un utente clicca 'Segui' su un profilo pubblico, dovr� essere aggiornata la tabella delle relazioni (es. 'follows' o 'user_followers').
- **Conteggio Follower**: Il numero totale di follower dovr� aggiornarsi dinamicamente in tempo reale o al ricaricamento, pescando il dato aggiornato dal database.
