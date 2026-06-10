import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../data/artist_stats_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// COLORI SEMANTIC PER I 4 SOTTO-PARAMETRI
// ─────────────────────────────────────────────────────────────────────────────
const _kColorLyrics     = Color(0xFFFF0A75); // NuraBrand.pink
const _kColorVibe       = Color(0xFF9D00FF); // Viola
const _kColorProduction = Color(0xFF00D4AA); // NuraBrand.mint-ish
const _kColorMarket     = Color(0xFF39FF14); // Neon Green

// ─────────────────────────────────────────────────────────────────────────────
// MAIN WIDGET
// ─────────────────────────────────────────────────────────────────────────────
class ArtistPersonalProfileScreen extends ConsumerStatefulWidget {
  final NuraVibe vibe;
  final Color accent;
  final double safeTop;
  final double safeBottom;

  const ArtistPersonalProfileScreen({
    super.key,
    required this.vibe,
    required this.accent,
    required this.safeTop,
    required this.safeBottom,
  });

  @override
  ConsumerState<ArtistPersonalProfileScreen> createState() =>
      _ArtistPersonalProfileScreenState();
}

class _ArtistPersonalProfileScreenState
    extends ConsumerState<ArtistPersonalProfileScreen>
    with TickerProviderStateMixin {
  // ── Dati ──────────────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _mockTracks = [
    {'title': 'Midnight Neon', 'duration_seconds': 184, 'plays': 12400},
    {'title': 'Synthwave Dreams', 'duration_seconds': 212, 'plays': 8900},
    {'title': 'Retro Future', 'duration_seconds': 195, 'plays': 15600},
    {'title': 'Cybernetic Heart', 'duration_seconds': 208, 'plays': 7200},
    {'title': 'Phantom Signal', 'duration_seconds': 176, 'plays': 5300},
    {'title': 'Digital Bloom', 'duration_seconds': 231, 'plays': 9800},
  ];

  late NuuraScore _nuuraScore;
  final String _artistName    = 'Michael Dam';
  final String _artistGenre   = 'Electronic / Synthwave';
  final String _imageAsset    =
      'assets/images/artists/michael-dam-mEZ3PoFGs_k-unsplash.jpg';

  // ── Scroll ────────────────────────────────────────────────────────────────
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _scrollOffsetNotifier = ValueNotifier(0.0);

  // ── Animazioni Entry ──────────────────────────────────────────────────────
  late AnimationController _entryController;
  late Animation<double>    _heroFade;
  late Animation<Offset>    _heroSlide;
  late Animation<double>    _scoreFade;
  late Animation<double>    _scoreScale;

  // ── Animazione Archi (staggered reveal) ───────────────────────────────────
  late AnimationController _arcController;
  late Animation<double>    _arcProgress; // 0→1

  // ── Stato Track ───────────────────────────────────────────────────────────
  int? _playingIndex;

  @override
  void initState() {
    super.initState();
    _nuuraScore = const NuuraScore(
      totalScore: 88,
      lyricsScore: 85,
      vibeScore: 92,
      productionScore: 89,
      marketPotentialScore: 86,
      totalFeedbacks: 14,
    );

    // Scroll
    _scrollController.addListener(() {
      _scrollOffsetNotifier.value = _scrollController.offset;
    });

    // Entry animation (hero + score sequenziale)
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _heroFade = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _heroSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    ));

    _scoreFade = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.35, 0.75, curve: Curves.easeOut),
    );
    _scoreScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.35, 0.85, curve: Curves.elasticOut),
      ),
    );

    // Arc reveal (parte subito dopo l'entry)
    _arcController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _arcProgress = CurvedAnimation(
      parent: _arcController,
      curve: Curves.easeInOutCubic,
    );

    _entryController.forward().then((_) {
      _arcController.forward();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollOffsetNotifier.dispose();
    _entryController.dispose();
    _arcController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: NuraBrand.deepest,
      body: Stack(
        children: [
          // ── 1. SFONDO ORGANIC MESH PARALLAX (DARK VERSION) ────────────────
          Positioned.fill(
            child: ValueListenableBuilder<double>(
              valueListenable: _scrollOffsetNotifier,
              builder: (context, offset, _) => CustomPaint(
                painter: _DarkOrganicMeshPainter(
                  scrollOffset: offset,
                  primaryColor: NuraBrand.deepMid,
                  accentColor: NuraBrand.pink,
                ),
              ),
            ),
          ),

          // ── 2. CONTENUTO PRINCIPALE ───────────────────────────────────────
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // Spazio sicuro top
              SliverToBoxAdapter(
                child: SizedBox(height: widget.safeTop + 16),
              ),

              // ZONA 1: HERO IDENTITY
              SliverToBoxAdapter(
                child: _buildHeroIdentity(screenWidth),
              ),

              // ZONA 2: NUURA NEXUS SCORE
              SliverToBoxAdapter(
                child: _buildNexusScoreSection(),
              ),

              // ZONA 3: STICKY HEADER BRANI
              SliverPersistentHeader(
                pinned: true,
                delegate: _BraniStickyHeader(
                  artistName: _artistName,
                  totalScore: _nuuraScore.totalScore,
                  onAddTap: () {},
                ),
              ),

              // ZONA 4: LISTA BRANI
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _buildTrackTile(_mockTracks[i], i),
                    childCount: _mockTracks.length,
                  ),
                ),
              ),

              // Footer spazio miniPlayer
              SliverToBoxAdapter(
                child: SizedBox(height: widget.safeBottom + 140),
              ),
            ],
          ),

          // ── 3. TOP BAR FLOATING (Settings + Title) ────────────────────────
          _buildFloatingTopBar(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ZONA 1: HERO IDENTITY
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHeroIdentity(double screenWidth) {
    // L'immagine occupa il 58% destro dello schermo
    const double heroHeight = 300.0;
    final double photoWidth = screenWidth * 0.58;

    return FadeTransition(
      opacity: _heroFade,
      child: SlideTransition(
        position: _heroSlide,
        child: SizedBox(
          height: heroHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ── Foto Hero (lato destro, sfuma verso sinistra) ──────────────
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: photoWidth,
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Colors.transparent, Colors.white, Colors.white],
                    stops: [0.0, 0.32, 1.0],
                  ).createShader(bounds),
                  child: ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: (bounds) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white, Colors.white, Colors.transparent],
                      stops: [0.0, 0.65, 1.0],
                    ).createShader(bounds),
                    child: Image.asset(
                      _imageAsset,
                      width: photoWidth,
                      height: heroHeight,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      cacheWidth: 600,
                    ),
                  ),
                ),
              ),

              // ── Glow Ambientale sotto la foto ─────────────────────────────
              Positioned(
                right: 0,
                bottom: -20,
                width: photoWidth * 0.7,
                height: 80,
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: NuraBrand.pink.withValues(alpha: 0.18),
                        blurRadius: 60,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Testo Editorial (lato sinistro) ───────────────────────────
              Positioned(
                left: 20,
                top: 0,
                bottom: 0,
                width: screenWidth * 0.52,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Badge "Il tuo profilo"
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: NuraBrand.pink.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: NuraBrand.pink.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        '✦  ARTISTA',
                        style: TextStyle(
                          color: NuraBrand.pink,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Nome Artista (Multi-line per nomi lunghi)
                    Text(
                      _artistName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.8,
                        height: 0.95,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Genere
                    Text(
                      _artistGenre,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Separator line decorativa
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 1.5,
                          color: NuraBrand.pink,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_nuuraScore.totalFeedbacks} FEEDBACK CURATORI',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ZONA 2: NUURA NEXUS SCORE
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildNexusScoreSection() {
    return FadeTransition(
      opacity: _scoreFade,
      child: ScaleTransition(
        scale: _scoreScale,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header sezione
              Row(
                children: [
                  Text(
                    'NUURA SCORE',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.5,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Text(
                      'Basato su ${_nuuraScore.totalFeedbacks} review',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Nexus Chart Centrale
              Center(
                child: AnimatedBuilder(
                  animation: _arcProgress,
                  builder: (context, _) => _NexusScoreChart(
                    score: _nuuraScore,
                    animationProgress: _arcProgress.value,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Insight Card Contestuale
              _buildInsightCard(),
            ],
          ),
        ),
      ),
    );
  }

  /// Card di testo "motivazionale" che legge il punto debole
  Widget _buildInsightCard() {
    // Trova il parametro più basso
    final params = {
      'Testo': _nuuraScore.lyricsScore,
      'Vibe': _nuuraScore.vibeScore,
      'Produzione': _nuuraScore.productionScore,
      'Mercato': _nuuraScore.marketPotentialScore,
    };
    final weakest =
        params.entries.reduce((a, b) => a.value < b.value ? a : b);
    final strongest =
        params.entries.reduce((a, b) => a.value > b.value ? a : b);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
          ),
          child: Row(
            children: [
              // Icona lucchetto/tendenza
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: NuraBrand.pink.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_graph_rounded,
                  color: NuraBrand.pink,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '✦ ${strongest.key} è il tuo punto di forza',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lavora su ${weakest.key} per sbloccare il livello successivo',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ZONA 3: TRACK TILE
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTrackTile(Map<String, dynamic> track, int index) {
    final title    = track['title'] as String;
    final durSecs  = track['duration_seconds'] as int;
    final plays    = track['plays'] as int;
    final isPlaying = _playingIndex == index;

    final min = durSecs ~/ 60;
    final sec = (durSecs % 60).toString().padLeft(2, '0');
    final durationStr = '$min:$sec';

    // Formato plays umano
    final playsStr = plays >= 1000
        ? '${(plays / 1000).toStringAsFixed(1)}K'
        : plays.toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GestureDetector(
        onTap: () => setState(() {
          _playingIndex = isPlaying ? null : index;
        }),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isPlaying
                    ? NuraBrand.pink.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isPlaying
                      ? NuraBrand.pink.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.08),
                  width: isPlaying ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  // ── Play Button / Numero ───────────────────────────────────
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isPlaying
                          ? NuraBrand.pink
                          : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: isPlaying
                          ? const Icon(Icons.pause_rounded,
                              color: Colors.white, size: 20)
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // ── Info ──────────────────────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: isPlaying
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.9),
                            fontSize: 15,
                            fontWeight: isPlaying
                                ? FontWeight.w800
                                : FontWeight.w600,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.play_arrow_rounded,
                              size: 12,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '$playsStr ascolti',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // ── Durata + Waveform ─────────────────────────────────────
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        durationStr,
                        style: TextStyle(
                          color: isPlaying
                              ? NuraBrand.pink.withValues(alpha: 0.9)
                              : Colors.white.withValues(alpha: 0.3),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Mini waveform procedurale
                      _MiniWaveform(
                        isActive: isPlaying,
                        seed: index * 7 + 3,
                        activeColor: NuraBrand.pink,
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.more_vert,
                    color: Colors.white.withValues(alpha: 0.2),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TOP BAR FLOATING
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFloatingTopBar() {
    return Positioned(
      top: widget.safeTop + 8,
      right: 16,
      child: GestureDetector(
        onTap: () {},
        child: ClipOval(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              child: const Icon(
                Icons.settings_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NEXUS SCORE CHART (CustomPainter)
// ─────────────────────────────────────────────────────────────────────────────
class _NexusScoreChart extends StatelessWidget {
  final NuuraScore score;
  final double animationProgress; // 0.0 → 1.0

  const _NexusScoreChart({
    required this.score,
    required this.animationProgress,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 280,
      child: CustomPaint(
        painter: _NexusChartPainter(
          score: score,
          progress: animationProgress,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Punteggio totale
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Color(0xFFCCCCCC)],
                ).createShader(bounds),
                child: Text(
                  '${score.totalScore}',
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -4,
                    height: 1.0,
                  ),
                ),
              ),
              Text(
                '/ 100',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: _scoreColor(score.totalScore).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _scoreColor(score.totalScore).withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  _scoreLabel(score.totalScore),
                  style: TextStyle(
                    color: _scoreColor(score.totalScore),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _scoreColor(int s) {
    if (s >= 90) return const Color(0xFF39FF14);
    if (s >= 80) return const Color(0xFF00D4AA);
    if (s >= 70) return const Color(0xFFFFD60A);
    return _kColorLyrics;
  }

  String _scoreLabel(int s) {
    if (s >= 90) return 'ELITE';
    if (s >= 80) return 'AVANZATO';
    if (s >= 70) return 'INTERMEDIO';
    return 'EMERGENTE';
  }
}

class _NexusChartPainter extends CustomPainter {
  final NuuraScore score;
  final double progress;

  _NexusChartPainter({required this.score, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2 - 20;
    const strokeW = 12.0;
    const gapDeg = 8.0; // gap in gradi tra archi adiacenti
    const arcSpanDeg = 90.0 - gapDeg; // ogni arco copre ~82°

    // ── Cerchio di background glassmorphico ───────────────────────────────
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, maxRadius + 14, bgPaint);

    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, maxRadius + 14, borderPaint);

    // ── Track di sfondo (4 archi grigi) ───────────────────────────────────
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.05);

    final params = [
      (score.lyricsScore,      _kColorLyrics,     'TESTO',    -135.0), // Q alto-sx
      (score.vibeScore,        _kColorVibe,        'VIBE',     -45.0),  // Q alto-dx
      (score.productionScore,  _kColorProduction,  'PROD.',    45.0),   // Q basso-dx
      (score.marketPotentialScore, _kColorMarket,  'MERCATO',  135.0),  // Q basso-sx
    ];

    for (final param in params) {
      final (_, _, _, startAngle) = param;
      final startRad = (startAngle - arcSpanDeg / 2) * math.pi / 180;
      final sweepRad = arcSpanDeg * math.pi / 180;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: maxRadius),
        startRad,
        sweepRad,
        false,
        trackPaint,
      );
    }

    // ── Archi colorati (animati) ───────────────────────────────────────────
    for (final param in params) {
      final (value, color, label, startAngle) = param;

      // Sweep proporzionale al valore (progress anima da 0 a valore/100)
      final arcFraction = (value / 100.0) * progress;
      final startRad = (startAngle - arcSpanDeg / 2) * math.pi / 180;
      final sweepRad = arcSpanDeg * arcFraction * math.pi / 180;

      // Glow
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW + 6
        ..strokeCap = StrokeCap.round
        ..imageFilter = ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4)
        ..color = color.withValues(alpha: 0.2 * progress);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: maxRadius),
        startRad,
        sweepRad,
        false,
        glowPaint,
      );

      // Arco principale con gradient
      final gradient = SweepGradient(
        center: Alignment.center,
        startAngle: startRad,
        endAngle: startRad + sweepRad + 0.001,
        colors: [
          color.withValues(alpha: 0.7),
          color,
        ],
      );

      final rect = Rect.fromCircle(center: center, radius: maxRadius);
      final arcPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round
        ..shader = gradient.createShader(rect);

      if (sweepRad > 0.001) {
        canvas.drawArc(rect, startRad, sweepRad, false, arcPaint);
      }

      // ── Labels ai capi degli archi ─────────────────────────────────────
      if (progress > 0.4) {
        final labelOpacity = ((progress - 0.4) / 0.6).clamp(0.0, 1.0);
        final midAngle = startAngle * math.pi / 180;
        final labelRadius = maxRadius + 32;

        final labelPos = Offset(
          center.dx + labelRadius * math.cos(midAngle),
          center.dy + labelRadius * math.sin(midAngle),
        );

        // Label nome parametro
        final tpLabel = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              color: color.withValues(alpha: labelOpacity * 0.7),
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        )..layout();

        // Valore numerico
        final tpValue = TextPainter(
          text: TextSpan(
            text: value.toString(),
            style: TextStyle(
              color: color.withValues(alpha: labelOpacity),
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        )..layout();

        // Offset per centrare il testo
        final totalH = tpValue.height + 2 + tpLabel.height;
        final topY = labelPos.dy - totalH / 2;

        tpValue.paint(canvas,
            Offset(labelPos.dx - tpValue.width / 2, topY));
        tpLabel.paint(canvas,
            Offset(labelPos.dx - tpLabel.width / 2, topY + tpValue.height + 2));
      }
    }

    // ── Cerchio inner glow (decorativo) ────────────────────────────────────
    final innerGlowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, maxRadius - strokeW - 10, innerGlowPaint);
  }

  @override
  bool shouldRepaint(covariant _NexusChartPainter old) =>
      old.progress != progress || old.score != score;
}

// ─────────────────────────────────────────────────────────────────────────────
// MINI WAVEFORM (Procedurale, statica)
// ─────────────────────────────────────────────────────────────────────────────
class _MiniWaveform extends StatelessWidget {
  final bool isActive;
  final int seed;
  final Color activeColor;

  const _MiniWaveform({
    required this.isActive,
    required this.seed,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(32, 16),
      painter: _WaveformPainter(
        isActive: isActive,
        seed: seed,
        activeColor: activeColor,
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final bool isActive;
  final int seed;
  final Color activeColor;

  _WaveformPainter(
      {required this.isActive, required this.seed, required this.activeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    const barCount = 8;
    final barWidth = size.width / (barCount * 2 - 1);

    final paint = Paint()
      ..color = isActive
          ? activeColor.withValues(alpha: 0.8)
          : Colors.white.withValues(alpha: 0.2)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barWidth * 0.85;

    for (int i = 0; i < barCount; i++) {
      final barH = (0.2 + rng.nextDouble() * 0.8) * size.height;
      final x = i * barWidth * 2 + barWidth / 2;
      final top = (size.height - barH) / 2;

      canvas.drawLine(
        Offset(x, top),
        Offset(x, top + barH),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter old) =>
      old.isActive != isActive;
}

// ─────────────────────────────────────────────────────────────────────────────
// STICKY HEADER BRANI (con collasso intelligente)
// ─────────────────────────────────────────────────────────────────────────────
class _BraniStickyHeader extends SliverPersistentHeaderDelegate {
  final String artistName;
  final int totalScore;
  final VoidCallback onAddTap;

  static const double _minH = 60.0;
  static const double _maxH = 68.0;

  const _BraniStickyHeader({
    required this.artistName,
    required this.totalScore,
    required this.onAddTap,
  });

  @override
  double get minExtent => _minH;

  @override
  double get maxExtent => _maxH;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final t = (shrinkOffset / (_maxH - _minH)).clamp(0.0, 1.0);

    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20 * t, sigmaY: 20 * t),
        child: Container(
          color: Color.lerp(
            Colors.transparent,
            NuraBrand.deepest.withValues(alpha: 0.92),
            t,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Titolo sezione / Collapsed Info
                Expanded(
                  child: Stack(
                    children: [
                      // Testo originale (fade out)
                      Opacity(
                        opacity: 1 - t,
                        child: const Text(
                          'I TUOI BRANI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      // Info collassate (fade in)
                      Opacity(
                        opacity: t,
                        child: Row(
                          children: [
                            Text(
                              artistName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: NuraBrand.pink.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                totalScore.toString(),
                                style: const TextStyle(
                                  color: NuraBrand.pink,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Pulsante Aggiungi
                GestureDetector(
                  onTap: onAddTap,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _BraniStickyHeader oldDelegate) {
    return artistName != oldDelegate.artistName ||
           totalScore != oldDelegate.totalScore;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DARK ORGANIC MESH PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _DarkOrganicMeshPainter extends CustomPainter {
  final double scrollOffset;
  final Color primaryColor;
  final Color accentColor;

  _DarkOrganicMeshPainter({
    required this.scrollOffset,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Sfondo di base scuro
    final paint = Paint()..style = PaintingStyle.fill;
    paint.color = NuraBrand.deepest;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    void drawReflection(Offset center, double radius, Color color, double opacity) {
      final glowPaint = Paint()
        ..imageFilter = ui.ImageFilter.blur(sigmaX: 70, sigmaY: 70)
        ..color = color.withValues(alpha: opacity);
      
      // Movimento di parallasse per ogni macchia
      final parallaxCenter = Offset(center.dx, center.dy - (scrollOffset * 0.15));
      canvas.drawCircle(parallaxCenter, radius, glowPaint);
    }

    // Macchie sfocate
    drawReflection(Offset(size.width * 0.1, size.height * 0.15), size.width * 0.6, primaryColor, 0.4);
    drawReflection(Offset(size.width * 0.8, size.height * 0.45), size.width * 0.5, accentColor, 0.25);
    drawReflection(Offset(size.width * 0.2, size.height * 0.8), size.width * 0.45, primaryColor, 0.35);
  }

  @override
  bool shouldRepaint(covariant _DarkOrganicMeshPainter oldDelegate) => 
      oldDelegate.scrollOffset != scrollOffset;
}
