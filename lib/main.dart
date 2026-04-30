// Nura — Flutter port
//
// Single-file Dart entrypoint that mirrors the HTML/React prototype 1:1:
//   • palette + 3 vibe variants (Premium · Glass / Vibrant · Bloom / Editorial · Tech)
//   • original jellyfish mark drawn with CustomPainter (no assets)
//   • Home Swipe Feed (drag + Skip/Like/Save buttons, animated card-out)
//   • Cerca (search field + Trend list + Genres grid)
//   • Profilo (Scout level + XP bar + saved tracks + battle history)
//   • Bottom nav flush to bottom edge with active-tab underline below
//   • Animated waveform (bars · wave · pulse) via CustomPainter
//
// Drop into a fresh Flutter project as lib/main.dart, then `flutter run`.
// The prototype targets a phone-sized viewport; on web/desktop it scales.

import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const NuraApp());
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. DESIGN TOKENS — port of app/tokens.jsx
// ─────────────────────────────────────────────────────────────────────────────

class NuraBrand {
  static const Color deep    = Color(0xFF005D6D); // Misicura — primary background
  static const Color mint    = Color(0xFFACE7D5); // Bianco Nura — text & icons
  static const Color pink    = Color(0xFFFF0A75); // Nura Pink — primary CTA
  static const Color deepest = Color(0xFF00343C);
  static const Color deepMid = Color(0xFF004956);

  static Color mintAlpha(double a)  => mint.withOpacity(a);
  static Color pinkAlpha(double a)  => pink.withOpacity(a);
  static Color tealAlpha(double a)  => deep.withOpacity(a);
  static Color deepMidAlpha(double a) => deepMid.withOpacity(a);
}

enum VibeId { premium, maximalist, techy }

class NuraVibe {
  final String label;
  final Gradient bgGradient;
  final Color cardBg;
  final Color cardBorder;
  final double cardBlurSigma;     // 0 == no blur (techy)
  final bool grain;
  final bool bloom;
  final double radius;

  const NuraVibe({
    required this.label,
    required this.bgGradient,
    required this.cardBg,
    required this.cardBorder,
    required this.cardBlurSigma,
    required this.grain,
    required this.bloom,
    required this.radius,
  });

  static const NuraVibe premium = NuraVibe(
    label: 'Premium · Glass',
    bgGradient: RadialGradient(
      center: Alignment(-0.4, -1.0), radius: 1.4,
      colors: [Color(0xFF00768A), Color(0xFF005D6D), Color(0xFF004956)],
      stops: [0.0, 0.55, 1.0],
    ),
    cardBg: Color(0x1AACE7D5),         // rgba(172,231,213,0.10)
    cardBorder: Color(0x47ACE7D5),     // rgba(172,231,213,0.28)
    cardBlurSigma: 24,
    grain: false, bloom: false, radius: 24,
  );

  static const NuraVibe maximalist = NuraVibe(
    label: 'Vibrant · Bloom',
    bgGradient: LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Color(0xFF00768A), Color(0xFF005D6D)],
    ),
    cardBg: Color(0x24ACE7D5),         // rgba(172,231,213,0.14)
    cardBorder: Color(0x5CFF0A75),     // rgba(255,10,117,0.36)
    cardBlurSigma: 28,
    grain: false, bloom: true, radius: 28,
  );

  static const NuraVibe techy = NuraVibe(
    label: 'Editorial · Tech',
    bgGradient: LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Color(0xFF005D6D), Color(0xFF004956)],
    ),
    cardBg: Color(0x8C005D6D),         // rgba(0,93,109,0.55)
    cardBorder: Color(0x66ACE7D5),     // rgba(172,231,213,0.40)
    cardBlurSigma: 0,
    grain: true, bloom: false, radius: 8,
  );

  static NuraVibe of(VibeId id) => switch (id) {
    VibeId.premium    => premium,
    VibeId.maximalist => maximalist,
    VibeId.techy      => techy,
  };
}

class Track {
  final String id, artist, track, genre, dur;
  final int bpm, hue;
  final Color swatch;
  const Track(this.id, this.artist, this.track, this.genre, this.bpm, this.hue, this.swatch, this.dur);
}

const List<Track> kTracks = [
  Track('t1','Mira Solène','Velvet Static','dream pop',     92, 332, Color(0xFFFF0A75),'2:48'),
  Track('t2','Kaspar Vogel','Notturno 03','neo-classical', 64, 188, Color(0xFFACE7D5),'3:31'),
  Track('t3','Rōnin Avila','Sub Fathom','deep house',      124,260, Color(0xFF7C5BFF),'5:12'),
  Track('t4','Iva Krause','Tempera','art folk',             76, 28, Color(0xFFFF8A3D),'3:04'),
  Track('t5','Polara','Soft Machine','electro-pop',        108,332, Color(0xFFFF0A75),'3:22'),
  Track('t6','Nube Pequeña','Madrugada','latin alt',        88, 12, Color(0xFFFF5A5F),'2:55'),
  Track('t7','Theo Halberg','Iron Lung','post-rock',       112,200, Color(0xFF54B6CC),'4:48'),
];

class Genre { final String id, name; final int count, hue;
  const Genre(this.id, this.name, this.count, this.hue); }

const List<Genre> kGenres = [
  Genre('g1','Dream Pop',1284,332), Genre('g2','Neo-Classical',412,188),
  Genre('g3','Deep House',2104,260),Genre('g4','Art Folk',286,28),
  Genre('g5','Latin Alt',822,12),   Genre('g6','Post-Rock',514,200),
  Genre('g7','Electro-Pop',1670,332),Genre('g8','Ambient',942,168),
];

class Trending { final int rank; final String artist, track, delta; final Color swatch;
  const Trending(this.rank, this.artist, this.track, this.delta, this.swatch); }

const List<Trending> kTrending = [
  Trending(1,'Polara','Soft Machine','+18',Color(0xFFFF0A75)),
  Trending(2,'Mira Solène','Velvet Static','+12',Color(0xFFFF0A75)),
  Trending(3,'Rōnin Avila','Sub Fathom','+7', Color(0xFF7C5BFF)),
  Trending(4,'Iva Krause','Tempera','+4',     Color(0xFFFF8A3D)),
  Trending(5,'Theo Halberg','Iron Lung','−1', Color(0xFF54B6CC)),
];

// HSL approximation of `oklch(L C h)` → hue-anchored color blend used for
// genre tiles and saved-track swatches in the original. Close enough at small
// sizes, no extra package needed.
Color hueColor(double l, double c, double h) {
  final hsl = HSLColor.fromAHSL(1.0, h, c.clamp(0.0, 1.0), l.clamp(0.0, 1.0));
  return hsl.toColor();
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. APP ROOT + STATE — port of app/nura-app.jsx
// ─────────────────────────────────────────────────────────────────────────────

class NuraApp extends StatefulWidget {
  const NuraApp({super.key});
  @override
  State<NuraApp> createState() => _NuraAppState();
}

class _NuraAppState extends State<NuraApp> {
  VibeId vibeId = VibeId.premium;
  String screen = 'home';
  Color accent = NuraBrand.pink;
  String waveform = 'bars'; // bars · wave · pulse

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nura',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: NuraBrand.deepest,
        fontFamily: 'InterTight',
        textTheme: const TextTheme().apply(bodyColor: NuraBrand.mint, displayColor: NuraBrand.mint),
      ),
      home: NuraShell(
        vibe: NuraVibe.of(vibeId),
        accent: accent,
        screen: screen,
        waveform: waveform,
        onNav: (s) => setState(() => screen = s),
        onVibe: (v) => setState(() => vibeId = v),
        onAccent: (c) => setState(() => accent = c),
        onWaveform: (w) => setState(() => waveform = w),
      ),
    );
  }
}

class NuraShell extends StatelessWidget {
  final NuraVibe vibe;
  final Color accent;
  final String screen, waveform;
  final ValueChanged<String> onNav, onWaveform;
  final ValueChanged<VibeId> onVibe;
  final ValueChanged<Color> onAccent;

  const NuraShell({
    super.key,
    required this.vibe, required this.accent,
    required this.screen, required this.waveform,
    required this.onNav, required this.onVibe,
    required this.onAccent, required this.onWaveform,
  });

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).padding;
    final safeTop = inset.top > 0 ? inset.top : 16.0;
    final safeBottom = inset.bottom > 0 ? inset.bottom : 16.0;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: vibe.bgGradient),
        child: Stack(children: [
          if (vibe.bloom)
            Positioned(
              top: -120, right: -80,
              child: Container(width: 320, height: 320, decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [accent.withOpacity(0.33), Colors.transparent]),
              )),
            ),

          // Active screen
          Positioned.fill(child: switch (screen) {
            'search'  => HomeSearch(vibe: vibe, accent: accent, waveform: waveform, safeTop: safeTop, safeBottom: safeBottom),
            'profile' => HomeProfile(vibe: vibe, accent: accent, safeTop: safeTop, safeBottom: safeBottom),
            _         => HomeFeed(vibe: vibe, accent: accent, waveform: waveform, safeTop: safeTop, safeBottom: safeBottom),
          }),

          // Bottom nav — flush
          Positioned(left: 0, right: 0, bottom: 0,
            child: BottomNav(active: screen, onChange: onNav, vibe: vibe, accent: accent, safeBottom: safeBottom),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. PRIMITIVES — port of app/primitives.jsx + app/icons.jsx
// ─────────────────────────────────────────────────────────────────────────────

/// Original Nura jellyfish glyph — same geometry as the SVG `NuraMark`.
class NuraMark extends StatelessWidget {
  final double size;
  final Color? color;
  final bool dropShadow;
  const NuraMark({super.key, this.size = 28, this.color, this.dropShadow = false});
  @override
  Widget build(BuildContext context) {
    final c = color ?? NuraBrand.pink;
    final w = SizedBox(width: size, height: size, child: CustomPaint(painter: _NuraMarkPainter(c)));
    if (!dropShadow) return w;
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [BoxShadow(color: c.withOpacity(0.33), blurRadius: 16)],
      ),
      child: w,
    );
  }
}

class _NuraMarkPainter extends CustomPainter {
  final Color c;
  _NuraMarkPainter(this.c);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = c;
    final s = size.width / 32.0;
    // Dome: M6 13.5 a10 7 0 0 1 20 0 V15 H6 Z
    final dome = Path()
      ..moveTo(6*s, 13.5*s)
      ..arcToPoint(Offset(26*s, 13.5*s), radius: Radius.elliptical(10*s, 7*s), clockwise: true)
      ..lineTo(26*s, 15*s) ..lineTo(6*s, 15*s) ..close();
    canvas.drawPath(dome, p);
    // Three trailing pills
    final pills = [Rect.fromLTWH(9.5*s,17*s,3*s,7*s),
                   Rect.fromLTWH(14.5*s,17*s,3*s,11*s),
                   Rect.fromLTWH(19.5*s,17*s,3*s,6*s)];
    for (final r in pills) {
      canvas.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(1.5*s)), p);
    }
  }
  @override bool shouldRepaint(_NuraMarkPainter o) => o.c != c;
}

/// Vibe-aware glass surface — backdrop blur + tinted bg + 1px border.
class Glass extends StatelessWidget {
  final NuraVibe vibe;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? radius;
  const Glass({super.key, required this.vibe, required this.child, this.padding, this.radius});
  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius ?? vibe.radius);
    final inner = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: vibe.cardBg,
        border: Border.all(color: vibe.cardBorder),
        borderRadius: r,
      ),
      child: child,
    );
    if (vibe.cardBlurSigma == 0) return ClipRRect(borderRadius: r, child: inner);
    return ClipRRect(
      borderRadius: r,
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: vibe.cardBlurSigma, sigmaY: vibe.cardBlurSigma), child: inner),
    );
  }
}

/// Mono caption — JetBrains-Mono-style label, uppercase, 0.14em tracking.
class Mono extends StatelessWidget {
  final String text; final Color? color; final double size;
  const Mono(this.text, {super.key, this.color, this.size = 10});
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(
      fontFamily: 'JetBrainsMono',
      fontFamilyFallback: const ['Menlo','Consolas','monospace'],
      fontSize: size, letterSpacing: 1.4,
      color: color ?? NuraBrand.mintAlpha(0.72),
    ),
  );
}

/// Striped placeholder panel — stands in for an artist photo. Teal-anchored.
class StripedPanel extends StatelessWidget {
  final int hue; final NuraVibe vibe;
  const StripedPanel({super.key, required this.hue, required this.vibe});
  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      // Gradient base — teal-anchored, hue is a small accent
      DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
        begin: const Alignment(-0.6, -1.0), end: const Alignment(0.6, 1.0),
        colors: [hueColor(0.46, 0.10, hue.toDouble()), hueColor(0.32, 0.07, 195)],
      ))),
      // Diagonal stripe overlay
      CustomPaint(painter: _StripesPainter(NuraBrand.mintAlpha(0.10))),
      // Bottom vignette
      DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [NuraBrand.deepMidAlpha(0), NuraBrand.deepMidAlpha(0.72)],
        stops: const [0.5, 1.0],
      ))),
      // Corner crosshairs
      _Corner(top: 12, left: 12),  _Corner(top: 12, right: 12),
      _Corner(bottom: 12, left: 12), _Corner(bottom: 12, right: 12),
    ]);
  }
}

class _StripesPainter extends CustomPainter {
  final Color color;
  _StripesPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color..strokeWidth = 14;
    const step = 28.0;
    final diag = size.width + size.height;
    for (double d = -diag; d < diag; d += step) {
      canvas.drawLine(Offset(d, 0), Offset(d + size.height, size.height), p);
    }
  }
  @override bool shouldRepaint(_StripesPainter o) => o.color != color;
}

class _Corner extends StatelessWidget {
  final double? top, left, right, bottom;
  const _Corner({this.top, this.left, this.right, this.bottom});
  @override
  Widget build(BuildContext context) {
    final c = NuraBrand.mintAlpha(0.42);
    return Positioned(top: top, left: left, right: right, bottom: bottom,
      child: Container(width: 10, height: 10, decoration: BoxDecoration(
        border: Border(
          top:    top    != null ? BorderSide(color: c) : BorderSide.none,
          bottom: bottom != null ? BorderSide(color: c) : BorderSide.none,
          left:   left   != null ? BorderSide(color: c) : BorderSide.none,
          right:  right  != null ? BorderSide(color: c) : BorderSide.none,
        ),
      )),
    );
  }
}

/// Animated waveform — bars · wave · pulse. Repaints on a Ticker.
class Waveform extends StatefulWidget {
  final String style; final Color color; final double height; final int count; final int seed;
  const Waveform({super.key, this.style='bars', this.color=NuraBrand.mint, this.height=28, this.count=32, this.seed=0});
  @override State<Waveform> createState() => _WaveformState();
}
class _WaveformState extends State<Waveform> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 60))..repeat();
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.lastElapsedDuration?.inMilliseconds ?? 0;
        final time = t / 1000.0;
        return CustomPaint(
          size: Size.fromHeight(widget.height),
          painter: _WavePainter(widget.style, widget.color, widget.count, widget.seed, time),
          child: SizedBox(height: widget.height, width: double.infinity),
        );
      },
    );
  }
}
class _WavePainter extends CustomPainter {
  final String style; final Color color; final int count, seed; final double t;
  _WavePainter(this.style, this.color, this.count, this.seed, this.t);
  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height, w = size.width;
    if (style == 'wave') {
      final paths = [(0.0, 0.35, 1.2), (1.4, 1.0, 1.6)];
      for (final tup in paths) {
        final phase = tup.$1, alpha = tup.$2, sw = tup.$3;
        final p = Path()..moveTo(0, h/2);
        for (int i = 1; i <= 40; i++) {
          final x = (i/40) * w;
          final y = h/2 + math.sin((i/40) * math.pi * 4 + t * 2.4 + phase)
            * (h * 0.36) * (0.6 + math.sin(i*0.7 + t)*0.4);
          p.lineTo(x, y);
        }
        canvas.drawPath(p, Paint()..color = color.withOpacity(alpha)..style = PaintingStyle.stroke..strokeWidth = sw);
      }
      return;
    }
    if (style == 'pulse') {
      final n = 18; final gap = 6.0;
      final totalW = n * 10 + (n - 1) * gap;
      var x = (w - totalW) / 2;
      for (int i = 0; i < n; i++) {
        final v = math.sin(i * 0.6 + t * 2 + seed).abs();
        final sz = 4 + v * 6;
        canvas.drawCircle(Offset(x + sz/2, h/2), sz/2, Paint()..color = color.withOpacity(0.4 + v * 0.6));
        x += sz + gap;
      }
      return;
    }
    // bars
    final n = count; const barW = 3.0; const gap = 3.0;
    final totalW = n * barW + (n - 1) * gap;
    var x = (w - totalW) / 2;
    for (int i = 0; i < n; i++) {
      final v = math.sin(i * 0.5 + t * 4 + seed).abs() * math.cos(i * 0.21 + t * 1.3).abs();
      final bh = math.max(2.0, v * h);
      final r = Rect.fromLTWH(x, (h - bh) / 2, barW, bh);
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)),
        Paint()..color = color.withOpacity(0.55 + v * 0.45));
      x += barW + gap;
    }
  }
  @override bool shouldRepaint(_WavePainter o) => true;
}

/// Bottom nav — flush, 3 items, underline indicator BELOW the icon+label.
class BottomNav extends StatelessWidget {
  final String active; final ValueChanged<String> onChange;
  final NuraVibe vibe; final Color accent; final double safeBottom;
  const BottomNav({super.key, required this.active, required this.onChange,
    required this.vibe, required this.accent, required this.safeBottom});
  @override
  Widget build(BuildContext context) {
    final items = const [
      ('home',    'Home',    Icons.home_outlined),
      ('search',  'Cerca',   Icons.search),
      ('profile', 'Profilo', Icons.person_outline),
    ];
    final bg = vibe == NuraVibe.techy
        ? const Color(0xEB005D6D) : const Color(0xC7005D6D);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          padding: EdgeInsets.fromLTRB(0, 6, 0, safeBottom),
          decoration: BoxDecoration(
            color: bg,
            border: Border(top: BorderSide(color: vibe.cardBorder)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.map((it) {
              final isActive = active == it.$1;
              final color = isActive ? NuraBrand.mint : NuraBrand.mintAlpha(0.55);
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChange(it.$1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(it.$3, size: 22, color: color),
                    const SizedBox(height: 4),
                    Text(it.$2, style: TextStyle(
                      fontSize: 10, color: color, letterSpacing: 0.4,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    )),
                    const SizedBox(height: 2),
                    Container(width: 22, height: 3,
                      decoration: BoxDecoration(
                        color: isActive ? accent : Colors.transparent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ]),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. SCREENS — port of app/screens.jsx
// ─────────────────────────────────────────────────────────────────────────────

// ── Home Swipe Feed ─────────────────────────────────────────────────────────
class HomeFeed extends StatefulWidget {
  final NuraVibe vibe; final Color accent; final String waveform;
  final double safeTop, safeBottom;
  const HomeFeed({super.key, required this.vibe, required this.accent, required this.waveform,
    required this.safeTop, required this.safeBottom});
  @override State<HomeFeed> createState() => _HomeFeedState();
}
class _HomeFeedState extends State<HomeFeed> {
  late List<Track> deck;
  String? impulse;
  int likes = 12, skips = 38;
  @override void initState() { super.initState(); deck = List.of(kTracks); }
  void _decide(String action) {
    setState(() {
      if (action == 'like') likes++; else skips++;
      deck.removeAt(0);
      if (deck.isEmpty) deck = List.of(kTracks);
      impulse = null;
    });
  }
  @override
  Widget build(BuildContext context) {
    final nav = 86 + widget.safeBottom; // bottom nav height incl. safe area
    return Stack(children: [
      // Header
      Padding(
        padding: EdgeInsets.fromLTRB(18, widget.safeTop, 18, 8),
        child: Row(children: [
          NuraMark(size: 26, color: widget.accent, dropShadow: true),
          const SizedBox(width: 8),
          const Text('nura', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
            color: NuraBrand.mint, letterSpacing: 0.4)),
          const Spacer(),
          Mono('♥ $likes', color: NuraBrand.mint),
          const SizedBox(width: 8),
          Mono('↳ $skips', color: NuraBrand.mintAlpha(0.45)),
        ]),
      ),
      // Card stack
      Positioned(
        top: widget.safeTop + 50, left: 16, right: 16,
        bottom: nav + 100,
        child: Stack(children: [
          for (int i = math.min(2, deck.length - 1); i >= 0; i--)
            SwipeCard(
              key: ValueKey('${deck[i].id}-${deck.length}-$i'),
              track: deck[i], vibe: widget.vibe, accent: widget.accent,
              waveStyle: widget.waveform,
              depth: i, isTop: i == 0,
              manualImpulse: i == 0 ? impulse : null,
              onDecide: _decide,
            ),
        ]),
      ),
      // Action buttons
      Positioned(
        left: 0, right: 0, bottom: nav + 16,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _RoundBtn(size: 54, child: const Icon(Icons.close, size: 22, color: NuraBrand.mint),
            border: widget.vibe.cardBorder,
            onTap: () => setState(() => impulse = 'skip')),
          const SizedBox(width: 22),
          GestureDetector(
            onTap: () => setState(() => impulse = 'like'),
            child: Container(width: 64, height: 64, decoration: BoxDecoration(
              shape: BoxShape.circle, color: widget.accent,
              boxShadow: [BoxShadow(color: widget.accent.withOpacity(0.4), blurRadius: 36, offset: const Offset(0, 12))],
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
              child: const Icon(Icons.favorite, size: 26, color: Colors.white),
            ),
          ),
          const SizedBox(width: 22),
          _RoundBtn(size: 54, child: const Icon(Icons.bookmark_outline, size: 20, color: NuraBrand.mint),
            border: widget.vibe.cardBorder, onTap: () {}),
        ]),
      ),
    ]);
  }
}

class _RoundBtn extends StatelessWidget {
  final double size; final Widget child; final Color border; final VoidCallback onTap;
  const _RoundBtn({required this.size, required this.child, required this.border, required this.onTap});
  @override Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: ClipOval(child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(width: size, height: size, alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle,
          color: NuraBrand.deepMidAlpha(0.7), border: Border.all(color: border)),
        child: child,
      ),
    )),
  );
}

class SwipeCard extends StatefulWidget {
  final Track track; final NuraVibe vibe; final Color accent; final String waveStyle;
  final int depth; final bool isTop; final String? manualImpulse;
  final ValueChanged<String> onDecide;
  const SwipeCard({super.key, required this.track, required this.vibe, required this.accent,
    required this.waveStyle, required this.depth, required this.isTop,
    required this.manualImpulse, required this.onDecide});
  @override State<SwipeCard> createState() => _SwipeCardState();
}
class _SwipeCardState extends State<SwipeCard> with SingleTickerProviderStateMixin {
  Offset drag = Offset.zero; String? exit;

  @override
  void didUpdateWidget(SwipeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTop && widget.manualImpulse != null && exit == null) {
      exit = widget.manualImpulse;
      Future.delayed(const Duration(milliseconds: 280), () {
        if (mounted) widget.onDecide(widget.manualImpulse!);
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (!widget.isTop || exit != null) return;
    setState(() => drag += d.delta);
  }
  void _onPanEnd(DragEndDetails _) {
    if (!widget.isTop || exit != null) return;
    const threshold = 90.0;
    if (drag.dx > threshold) {
      setState(() => exit = 'like');
      Future.delayed(const Duration(milliseconds: 280), () { if (mounted) widget.onDecide('like'); });
    } else if (drag.dx < -threshold) {
      setState(() => exit = 'skip');
      Future.delayed(const Duration(milliseconds: 280), () { if (mounted) widget.onDecide('skip'); });
    } else {
      setState(() => drag = Offset.zero);
    }
  }

  @override
  Widget build(BuildContext context) {
    double tx = drag.dx, ty = drag.dy, rotation = drag.dx / 18 * math.pi / 180;
    if (exit == 'like') { tx = 600;  rotation =  24 * math.pi / 180; }
    if (exit == 'skip') { tx = -600; rotation = -24 * math.pi / 180; }

    final stackOffset = widget.depth * 12.0;
    final stackScale = 1 - widget.depth * 0.04;
    final likeOpacity = (drag.dx / 110).clamp(0.0, 1.0);
    final skipOpacity = (-drag.dx / 110).clamp(0.0, 1.0);

    return AnimatedPositioned(
      duration: Duration(milliseconds: exit != null || drag == Offset.zero ? 280 : 0),
      curve: Curves.easeOut,
      left: tx, right: -tx, top: ty + stackOffset, bottom: -ty - stackOffset,
      child: Transform.rotate(
        angle: rotation,
        child: Transform.scale(scale: stackScale,
          child: GestureDetector(
            onPanUpdate: _onPanUpdate, onPanEnd: _onPanEnd,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.vibe.radius),
              child: Stack(children: [
                Positioned.fill(child: StripedPanel(hue: widget.track.hue, vibe: widget.vibe)),
                // Top meta
                Positioned(top: 14, left: 16, right: 16,
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Mono(widget.track.genre, color: NuraBrand.mintAlpha(0.85)),
                    Mono('${widget.track.bpm} BPM', color: NuraBrand.mintAlpha(0.85)),
                  ]),
                ),
                // LIKE / SKIP badges
                Positioned(top: 28, left: 22, child: Opacity(opacity: likeOpacity,
                  child: Transform.rotate(angle: -12 * math.pi / 180, child: _Badge(text: 'LIKE', color: widget.accent)))),
                Positioned(top: 28, right: 22, child: Opacity(opacity: skipOpacity,
                  child: Transform.rotate(angle: 12 * math.pi / 180, child: const _Badge(text: 'SKIP', color: NuraBrand.mint)))),
                // Bottom overlay
                Positioned(bottom: 16, left: 12, right: 12,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(widget.vibe.radius - 4),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: NuraBrand.deepMidAlpha(0.55),
                          border: Border.all(color: widget.vibe.cardBorder),
                          borderRadius: BorderRadius.circular(widget.vibe.radius - 4),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
                          Row(children: [
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(widget.track.artist, style: TextStyle(fontSize: 11, color: NuraBrand.mintAlpha(0.65), letterSpacing: 0.4)),
                              const SizedBox(height: 2),
                              Text(widget.track.track, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: NuraBrand.mint)),
                            ])),
                            Container(width: 38, height: 38, decoration: const BoxDecoration(shape: BoxShape.circle, color: NuraBrand.mint),
                              child: const Icon(Icons.play_arrow, color: NuraBrand.deep, size: 18)),
                          ]),
                          const SizedBox(height: 8),
                          Row(children: [
                            Expanded(child: Waveform(style: widget.waveStyle, color: NuraBrand.mint, height: 22, count: 36, seed: widget.track.id.codeUnitAt(1))),
                            const SizedBox(width: 10),
                            Mono(widget.track.dur, color: NuraBrand.mintAlpha(0.55)),
                          ]),
                        ]),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
class _Badge extends StatelessWidget {
  final String text; final Color color;
  const _Badge({required this.text, required this.color});
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(border: Border.all(color: color, width: 2), borderRadius: BorderRadius.circular(8)),
    child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 2.5, fontFamily: 'JetBrainsMono', fontFamilyFallback: const ['monospace'])),
  );
}

// ── Cerca ───────────────────────────────────────────────────────────────────
class HomeSearch extends StatefulWidget {
  final NuraVibe vibe; final Color accent; final String waveform;
  final double safeTop, safeBottom;
  const HomeSearch({super.key, required this.vibe, required this.accent, required this.waveform,
    required this.safeTop, required this.safeBottom});
  @override State<HomeSearch> createState() => _HomeSearchState();
}
class _HomeSearchState extends State<HomeSearch> {
  final _controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(0, widget.safeTop, 0, 100 + widget.safeBottom),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Cerca', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: NuraBrand.mint, letterSpacing: -0.5)),
            Mono('scopri · suoni · scene', color: NuraBrand.mintAlpha(0.5)),
          ]),
        ),
        // Search field
        Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Glass(vibe: widget.vibe, padding: const EdgeInsets.symmetric(horizontal: 14),
            child: SizedBox(height: 46, child: Row(children: [
              Icon(Icons.search, size: 18, color: NuraBrand.mintAlpha(0.7)),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _controller,
                style: const TextStyle(color: NuraBrand.mint, fontSize: 14),
                decoration: InputDecoration(border: InputBorder.none,
                  hintText: 'artisti, brani, mood…',
                  hintStyle: TextStyle(color: NuraBrand.mintAlpha(0.5)),
                  isDense: true,
                ))),
              Mono('⌘ K', color: NuraBrand.mintAlpha(0.45)),
            ])),
          ),
        ),
        // Trending
        Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.only(bottom: 10),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Mono('↗ trend · oggi', color: NuraBrand.mint),
                Mono('04·29', color: NuraBrand.mintAlpha(0.4)),
              ]),
            ),
            Glass(vibe: widget.vibe, padding: const EdgeInsets.all(4),
              child: Column(children: [
                for (int i = 0; i < kTrending.length; i++)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(border: Border(
                      top: i == 0 ? BorderSide.none : BorderSide(color: widget.vibe.cardBorder),
                    )),
                    child: Row(children: [
                      SizedBox(width: 28, child: Text(kTrending[i].rank.toString().padLeft(2,'0'),
                        style: TextStyle(fontFamily: 'JetBrainsMono', fontFamilyFallback: const ['monospace'],
                          fontSize: 13, color: NuraBrand.mintAlpha(0.6)))),
                      Container(width: 32, height: 32, margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(6),
                          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                            colors: [kTrending[i].swatch, NuraBrand.deep]))),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(kTrending[i].track, style: const TextStyle(color: NuraBrand.mint, fontWeight: FontWeight.w600, fontSize: 13)),
                        Text(kTrending[i].artist, style: TextStyle(color: NuraBrand.mintAlpha(0.55), fontSize: 11)),
                      ])),
                      SizedBox(width: 56, child: Waveform(style: widget.waveform, color: NuraBrand.mint, height: 18, count: 20, seed: kTrending[i].rank)),
                      const SizedBox(width: 8),
                      SizedBox(width: 30, child: Text(kTrending[i].delta, textAlign: TextAlign.right,
                        style: TextStyle(fontFamily: 'JetBrainsMono', fontFamilyFallback: const ['monospace'], fontSize: 12,
                          color: kTrending[i].delta.startsWith('−') ? NuraBrand.mintAlpha(0.5) : widget.accent))),
                    ]),
                  ),
              ]),
            ),
          ]),
        ),
        // Genres
        Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.only(bottom: 10), child: Mono('◎ generi', color: NuraBrand.mint)),
            GridView.count(
              crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10,
              childAspectRatio: 1.6, shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: kGenres.map((g) => Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.vibe.radius - 4),
                  border: Border.all(color: widget.vibe.cardBorder),
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [hueColor(0.50, 0.10, g.hue.toDouble()), hueColor(0.36, 0.07, 195)]),
                ),
                child: Stack(children: [
                  Positioned.fill(child: CustomPaint(painter: _StripesPainter(Colors.white.withOpacity(0.05)))),
                  Positioned(left: 12, right: 12, bottom: 10,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Text(g.name, style: const TextStyle(color: NuraBrand.mint, fontWeight: FontWeight.w700, fontSize: 14)),
                      Mono('${g.count} brani', color: NuraBrand.mintAlpha(0.6)),
                    ]),
                  ),
                ]),
              )).toList(),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ── Profilo ─────────────────────────────────────────────────────────────────
class HomeProfile extends StatelessWidget {
  final NuraVibe vibe; final Color accent;
  final double safeTop, safeBottom;
  const HomeProfile({super.key, required this.vibe, required this.accent, required this.safeTop, required this.safeBottom});
  @override
  Widget build(BuildContext context) {
    final battles = const [
      (true,  'Polara · Soft Machine',  'Mira S. · Velvet Static', '64% · 36%'),
      (false, 'Iva K. · Tempera',       'Theo H. · Iron Lung',     '41% · 59%'),
      (true,  'Rōnin · Sub Fathom',     'Nube P. · Madrugada',     '58% · 42%'),
    ];
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(0, safeTop, 0, 100 + safeBottom),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Profilo', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: NuraBrand.mint, letterSpacing: -0.5)),
            Icon(Icons.settings_outlined, size: 20, color: NuraBrand.mintAlpha(0.6)),
          ]),
        ),
        // Identity card
        Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: Glass(vibe: vibe, padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 64, height: 64,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [accent, NuraBrand.deep])),
                  alignment: Alignment.center,
                  child: const Text('EM', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Elena Marchetti', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: NuraBrand.mint)),
                  const SizedBox(height: 2),
                  Text('@elenam · iscritta dal 2026', style: TextStyle(fontSize: 12, color: NuraBrand.mintAlpha(0.6))),
                  const SizedBox(height: 8),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(999),
                      color: NuraBrand.mintAlpha(0.10), border: Border.all(color: vibe.cardBorder)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.bolt, size: 12, color: accent),
                      const SizedBox(width: 6),
                      Mono('SCOUT · LIV. 04', color: NuraBrand.mint, size: 9.5),
                    ]),
                  ),
                ])),
              ]),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Mono('xp verso liv. 05', color: NuraBrand.mintAlpha(0.55)),
                Mono('740 / 1000', color: NuraBrand.mint),
              ]),
              const SizedBox(height: 6),
              ClipRRect(borderRadius: BorderRadius.circular(3),
                child: Container(height: 6, color: NuraBrand.mintAlpha(0.12),
                  child: FractionallySizedBox(widthFactor: 0.74, alignment: Alignment.centerLeft,
                    child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [accent, NuraBrand.mint])))))),
              const SizedBox(height: 14),
              Container(padding: const EdgeInsets.only(top: 14),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: vibe.cardBorder))),
                child: Row(children: [
                  for (final s in const [('BRANI · LIKE', '128'), ('BATTLE','37'), ('SCOUTING','12')])
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s.$2, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: NuraBrand.mint, letterSpacing: -0.5)),
                      Mono(s.$1, color: NuraBrand.mintAlpha(0.5)),
                    ])),
                ]),
              ),
            ]),
          ),
        ),
        // Saved tracks
        Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.only(bottom: 10),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Mono('♥ brani salvati', color: NuraBrand.mint),
                Mono('vedi tutti →', color: NuraBrand.mintAlpha(0.45)),
              ])),
            Glass(vibe: vibe, padding: const EdgeInsets.all(4),
              child: Column(children: [
                for (int i = 0; i < 4; i++)
                  Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(border: Border(
                      top: i == 0 ? BorderSide.none : BorderSide(color: vibe.cardBorder))),
                    child: Row(children: [
                      Container(width: 36, height: 36, decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                          colors: [hueColor(0.55, 0.10, kTracks[i].hue.toDouble()), hueColor(0.38, 0.07, 195)]),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(kTracks[i].track, style: const TextStyle(color: NuraBrand.mint, fontWeight: FontWeight.w600, fontSize: 13)),
                        Text('${kTracks[i].artist} · ${kTracks[i].genre}', style: TextStyle(color: NuraBrand.mintAlpha(0.55), fontSize: 11)),
                      ])),
                      Mono(kTracks[i].dur, color: NuraBrand.mintAlpha(0.45)),
                      const SizedBox(width: 8),
                      Icon(Icons.play_arrow, size: 16, color: accent),
                    ]),
                  ),
              ]),
            ),
          ]),
        ),
        // Battle history
        Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.only(bottom: 10), child: Mono('⚔ storico battle', color: NuraBrand.mint)),
            Glass(vibe: vibe, padding: const EdgeInsets.all(14),
              child: Column(children: [
                for (int i = 0; i < battles.length; i++) Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(border: Border(
                    top: i == 0 ? BorderSide.none : BorderSide(color: vibe.cardBorder))),
                  child: IntrinsicHeight(child: Row(children: [
                    Container(width: 6, decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: battles[i].$1 ? accent : NuraBrand.mintAlpha(0.25))),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(battles[i].$2, style: const TextStyle(fontSize: 12, color: NuraBrand.mint, fontWeight: FontWeight.w500)),
                      Text('vs', style: TextStyle(fontSize: 11, color: NuraBrand.mintAlpha(0.5))),
                      Text(battles[i].$3, style: TextStyle(fontSize: 12, color: NuraBrand.mintAlpha(0.7))),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Mono(battles[i].$1 ? 'VINTA' : 'PERSA',
                        color: battles[i].$1 ? accent : NuraBrand.mintAlpha(0.45), size: 10),
                      const SizedBox(height: 2),
                      Text(battles[i].$4, style: TextStyle(fontFamily: 'JetBrainsMono', fontFamilyFallback: const ['monospace'], fontSize: 11, color: NuraBrand.mintAlpha(0.6))),
                    ]),
                  ])),
                ),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}
