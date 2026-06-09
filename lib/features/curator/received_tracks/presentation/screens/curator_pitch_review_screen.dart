import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/nura_brand.dart';
import '../../../discovery/swipe/presentation/screens/artist_public_profile_screen.dart' show ParallaxOrganicMeshPainter;

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

  // Mock data for pitches
  final List<Map<String, String>> _mockPitches = [
    {
      'id': '1',
      'title': 'Neon Dreams',
      'artist': 'SynthWave Duo',
      'cover': 'https://images.unsplash.com/photo-1614113489855-66422ad300a4?w=500&q=80',
    },
    {
      'id': '2',
      'title': 'Acoustic Sunrise',
      'artist': 'Emma Woods',
      'cover': 'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=500&q=80',
    },
    {
      'id': '3',
      'title': 'Urban Flow',
      'artist': 'MC Matrix',
      'cover': 'https://images.unsplash.com/photo-1516280440508-10756bb01777?w=500&q=80',
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReviewBottomSheet(
        pitch: pitch,
        vibe: widget.vibe,
        accent: widget.accent,
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
          
          // Header Overlay
          Positioned(
            top: widget.safeTop + 16,
            left: 24,
            right: 24,
            child: Text(
              'Discovery Curator',
              style: TextStyle(
                color: const Color(0xFF1A1A1A),
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ),

          // Content List
          Positioned.fill(
            child: ListView.builder(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(
                top: widget.safeTop + 80,
                bottom: widget.safeBottom + 120, // Account for miniplayer & nav
                left: 20,
                right: 20,
              ),
              itemCount: _mockPitches.length,
              itemBuilder: (context, index) {
                final pitch = _mockPitches[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8), // Semi-transparent for glass effect
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
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
                                child: Image.network(
                                  pitch['cover']!,
                                  width: 72,
                                  height: 72,
                                  fit: BoxFit.cover,
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
                                        color: Color(0xFF1A1A1A),
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      pitch['artist']!,
                                      style: TextStyle(
                                        color: const Color(0xFF1A1A1A).withValues(alpha: 0.6),
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
                                  color: widget.accent.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.play_arrow_rounded,
                                  color: widget.accent,
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
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewBottomSheet extends StatefulWidget {
  final Map<String, String> pitch;
  final NuraVibe vibe;
  final Color accent;

  const _ReviewBottomSheet({
    required this.pitch,
    required this.vibe,
    required this.accent,
  });

  @override
  State<_ReviewBottomSheet> createState() => _ReviewBottomSheetState();
}

class _ReviewBottomSheetState extends State<_ReviewBottomSheet> {
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
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    widget.pitch['cover']!,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
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
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.pitch['artist']!,
                        style: TextStyle(
                          color: const Color(0xFF1A1A1A).withValues(alpha: 0.6),
                          fontSize: 16,
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
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
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
              inactiveTrackColor: widget.accent.withValues(alpha: 0.1),
              thumbColor: widget.accent,
              overlayColor: widget.accent.withValues(alpha: 0.1),
              trackHeight: 4,
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
