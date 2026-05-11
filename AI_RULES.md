# AI RULES - Nura App

## Obiettivo

Questo progetto deve essere sviluppato in modo collaborativo con più persone e più AI.  
La priorità è evitare conflitti, refactor inutili e modifiche non controllate ai file comuni.

## Regole generali

- Non modificare ios/ o android/ salvo richiesta esplicita.

- Non modificare pubspec.yaml salvo richiesta esplicita o reale necessità.

- Non eliminare codice esistente senza spiegare il motivo.

- Non cambiare la grafica attuale se il task è solo strutturale.

- Non cambiare il comportamento dell’app senza richiesta.

- Non fare refactor globali non richiesti.

- Ogni nuova funzionalità deve stare nella rispettiva cartella dentro lib/features/.

- Mantieni sempre il progetto compilabile.

## File protetti

Questi file/cartelle vanno modificati solo se necessario:

- lib/main.dart

- lib/app/

- lib/core/

- pubspec.yaml

- ios/

- android/

## Prima di modificare file protetti

Se una modifica richiede file protetti, l’AI deve:

1. spiegare quale file vuole modificare

2. spiegare perché serve

3. fare la modifica più piccola possibile

## Struttura feature

Ogni feature deve seguire, quando possibile:

presentation/

  screens/

  widgets/

data/

domain/

## Tre visualizzazioni principali

L’app avrà tre esperienze:

- User

- Artist

- Label / Curatore

Le feature devono essere organizzate tenendo conto di queste tre aree.

## Regola sui file comuni

Non inserire logica specifica di User, Artist o Label dentro file comuni se può stare nella relativa feature.

## Regola sugli import

Dopo ogni spostamento di file, aggiorna tutti gli import necessari.

## Regola finale

Se non sei sicuro se una modifica sia sicura, fermati e segnala il dubbio invece di procedere.

## Regole log e roadmap (obbligatorie)

Documenti ufficiali:

- `ROADMAP.md` = stato operativo e task.
- `SESSION_LOG.md` = diario cronologico completo.

Regole:

1. A fine sessione, aggiornare sempre `SESSION_LOG.md`.
2. Ogni entry deve avere il nome autore prima del timestamp.
3. Formato titolo entry:

`### <Nome> — Sessione YYYY-MM-DD (<LetteraProgressiva>)`

Esempio:

`### Natan — Sessione 2026-05-11 (S)`

4. Dentro ogni entry inserire solo:
- modifiche fatte
- file toccati (se rilevante)
- stato verifiche (`flutter analyze`, build, test)
- eventuali blocchi o TODO.
5. Non usare `SESSION_RECAP.md` (deprecato/rimosso).
6. Se viene aggiornata la pianificazione, aggiornare `ROADMAP.md` nella stessa sessione.

Template da copiare:

```md
### <Nome> — Sessione YYYY-MM-DD (<LetteraProgressiva>)
- Obiettivo sessione: ...
- Modifiche principali:
  - ...
  - ...
- File coinvolti:
  - `path/file_1`
  - `path/file_2`
- Verifiche:
  - `flutter analyze`: OK/KO
  - build/test: ...
- Note/TODO:
  - ...
```
