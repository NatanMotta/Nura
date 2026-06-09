import 'package:flutter/material.dart';


import '../../../../../app/theme/app_theme.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../discovery/swipe/presentation/screens/artist_public_profile_screen.dart' show ParallaxOrganicMeshPainter;

class CuratorPitchReviewScreen extends StatefulWidget {
  final NuraVibe vibe;
  final Color accent;
  final double safeTop;
  final double safeBottom;

  const CuratorPitchReviewScreen({
    super.key,
    required this.vibe,
    required this.accent,
    required this.safeTop,
    required this.safeBottom,
  });

  @override
  State<CuratorPitchReviewScreen> createState() => _CuratorPitchReviewScreenState();
}

class _CuratorPitchReviewScreenState extends State<CuratorPitchReviewScreen> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _scrollNotifier = ValueNotifier(0.0);

  final List<Map<String, String>> _mockPitches = [
    {
      'id': '1',
      'title': 'Neon Dreams',
      'artist': 'SynthWave Duo',
      'cover': 'assets/images/artists/aiony-haust-3TLl_97HNJo-unsplash.jpg',
    },
    {
      'id': '2',
      'title': 'Acoustic Sunrise',
      'artist': 'Emma Woods',
      'cover': 'assets/images/artists/christopher-campbell-rDEOVtE7vOs-unsplash.jpg',
    },
    {
      'id': '3',
      'title': 'Urban Flow',
      'artist': 'MC Matrix',
      'cover': 'assets/images/artists/elevate-nYgy58eb9aw-unsplash.jpg',
    },
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    _scrollNotifier.value = _scrollController.offset;
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _scrollNotifier.dispose();
    super.dispose();
  }

  void _openReviewSheet(Map<String, String> pitch) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CuratorPitchReviewDetailScreen(
          pitch: pitch,
          vibe: widget.vibe,
          accent: widget.accent,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          // 1. HIGH-END PARALLAX ORGANIC MESH BACKGROUND (Coerente col Profilo Artista)
          Positioned.fill(
            child: ValueListenableBuilder<double>(
              valueListenable: _scrollNotifier,
              builder: (context, scrollOffset, _) {
                return RepaintBoundary(
                  child: CustomPaint(
                    painter: ParallaxOrganicMeshPainter(
                      scrollOffset: scrollOffset,
                      musicuraBlu: NuraBrand.deep,
                      nuraPink: NuraBrand.pink,
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Scrollable Content
          Positioned.fill(
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: widget.safeTop + 32,
                      left: 24,
                      right: 24,
                      bottom: 32,
                    ),
                    child: const Text(
                      'Discovery Curator',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.only(
                    bottom: widget.safeBottom + 120, // Account for miniplayer & nav
                    left: 20,
                    right: 20,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                final pitch = _mockPitches[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3), // Dark glass effect
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _openReviewSheet(pitch),
                        borderRadius: BorderRadius.circular(24),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.asset(
                                  pitch['cover']!,
                                  width: 72,
                                  height: 72,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    width: 72,
                                    height: 72,
                                    color: Colors.grey.withValues(alpha: 0.2),
                                    child: const Icon(Icons.music_note, color: Colors.grey),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pitch['title']!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      pitch['artist']!,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.6),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: widget.accent.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: widget.accent.withValues(alpha: 0.3)),
                                ),
                                child: Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
              childCount: _mockPitches.length,
            ),
          ),
        ),
      ],
    ),
  ),
        ],
      ),
    );
  }
}

class CuratorPitchReviewDetailScreen extends StatefulWidget {
  final Map<String, String> pitch;
  final NuraVibe vibe;
  final Color accent;

  const CuratorPitchReviewDetailScreen({
    super.key,
    required this.pitch,
    required this.vibe,
    required this.accent,
  });

  @override
  State<CuratorPitchReviewDetailScreen> createState() => _CuratorPitchReviewDetailScreenState();
}

class _CuratorPitchReviewDetailScreenState extends State<CuratorPitchReviewDetailScreen> {
  final _feedbackController = TextEditingController();
  double _par1 = 50.0;
  double _par2 = 50.0;
  double _par3 = 50.0;
  double _par4 = 50.0;
  double _par5 = 50.0;

  int get _nuraScore => ((_par1 + _par2 + _par3 + _par4 + _par5) / 5).round();

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: ParallaxOrganicMeshPainter(
                  scrollOffset: 0,
                  musicuraBlu: NuraBrand.deep,
                  nuraPink: NuraBrand.pink,
                ),
              ),
            ),
          ),
          
          // Content
          SafeArea(
            child: Column(
              children: [
                // Top Handle and Close Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF1A1A1A), size: 28),
                        onPressed: () => Navigator.pop(context),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF1A1A1A).withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(
                      left: 24,
                      right: 24,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    widget.pitch['cover']!,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 64,
                      height: 64,
                      color: Colors.grey.withValues(alpha: 0.2),
                      child: const Icon(Icons.music_note, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.pitch['title']!,
                        style: const TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.pitch['artist']!,
                        style: TextStyle(
                          color: const Color(0xFF1A1A1A).withValues(alpha: 0.6),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  Text(
                    'NURA SCORE',
                    style: TextStyle(
                      color: const Color(0xFF1A1A1A).withValues(alpha: 0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_nuraScore',
                    style: TextStyle(
                      color: widget.accent,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildSlider('Parametro 1', _par1, (v) => setState(() => _par1 = v)),
            _buildSlider('Parametro 2', _par2, (v) => setState(() => _par2 = v)),
            _buildSlider('Parametro 3', _par3, (v) => setState(() => _par3 = v)),
            _buildSlider('Parametro 4', _par4, (v) => setState(() => _par4 = v)),
            _buildSlider('Parametro 5', _par5, (v) => setState(() => _par5 = v)),
            const SizedBox(height: 32),
            TextField(
              controller: _feedbackController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Scrivi un feedback dettagliato...',
                hintStyle: TextStyle(color: const Color(0xFF1A1A1A).withValues(alpha: 0.4)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: const Color(0xFF1A1A1A).withValues(alpha: 0.1), width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: const Color(0xFF1A1A1A).withValues(alpha: 0.1), width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: widget.accent, width: 2),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              style: const TextStyle(color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Invia feedback
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Feedback inviato con successo'),
                    backgroundColor: widget.accent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Invia Feedback',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(String label, double value, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value.round().toString(),
                style: TextStyle(
                  color: widget.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: widget.accent,
              inactiveTrackColor: const Color(0xFF1A1A1A).withValues(alpha: 0.1),
              thumbColor: const Color(0xFF1A1A1A),
              overlayColor: widget.accent.withValues(alpha: 0.15),
              trackHeight: 6,
            ),
            child: Slider(
              value: value,
              min: 0,
              max: 100,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
