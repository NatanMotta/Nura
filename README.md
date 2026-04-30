# Nura — Flutter port

1:1 port of the React/HTML user prototype. Mirrors palette, screens, swipe
mechanics, vibe variants, and bottom-nav exactly.

## Getting started

```bash
cd flutter
flutter create .       # generates ios/android/web/macos folders
flutter pub get
flutter run            # pick a simulator/emulator
```

`lib/main.dart` is intentionally a single file so it's easy to scan and
diff against the HTML version — split into sections by big banner comments:

1. **Design tokens** — `NuraBrand`, `NuraVibe`, demo data
2. **App root** — `NuraApp` + `NuraShell` (state + routing)
3. **Primitives** — `NuraMark`, `Glass`, `Mono`, `StripedPanel`, `Waveform`, `BottomNav`
4. **Screens** — `HomeFeed`, `HomeSearch`, `HomeProfile`

## Switching vibes / accent / waveform / screen

For now these are state on `_NuraAppState`. Wire them to a settings sheet,
shared-preferences, or a Riverpod provider when you bring it into a real
build — the data flow is already top-down.

## Fonts

The app references `InterTight` and `JetBrainsMono` but falls back to
system sans + monospace if you don't add the files. Drop the TTFs into
`flutter/fonts/` and uncomment the block in `pubspec.yaml` to swap them in.

## Behavior parity with the HTML prototype

- Drag swipe cards left/right with rotation, LIKE/SKIP badges, fly-out animation
- Skip / Like / Save buttons in their own zone below the card
- Animated bars/wave/pulse waveform via `CustomPainter` on a `Ticker`
- Bottom nav flush to the device edge with active-tab underline below the label
- Identical Italian copy and brand palette (#005D6D / #ACE7D5 / #FF0A75)
