import 'package:flutter/material.dart';


import '../../../../../app/theme/app_theme.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../discovery/swipe/presentation/screens/artist_public_profile_screen.dart' show ParallaxOrganicMeshPainter;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/curator_pitch_providers.dart';
import '../../../data/curator_pitch_service.dart';
import '../../../../../core/services/audio_preview_service.dart';

class CuratorPitchReviewScreen extends ConsumerStatefulWidget {
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
  ConsumerState<CuratorPitchReviewScreen> createState() => _CuratorPitchReviewScreenState();
}

class _CuratorPitchReviewScreenState extends ConsumerState<CuratorPitchReviewScreen> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _scrollNotifier = ValueNotifier(0.0);
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _tabController = TabController(length: 2, vsync: this);
  }

  void _onScroll() {
    _scrollNotifier.value = _scrollController.offset;
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _scrollNotifier.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _openReviewSheet(Map<String, dynamic> pitch) {
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
    final pendingAsync = ref.watch(pendingPitchesProvider);
    final evaluatedAsync = ref.watch(evaluatedPitchesProvider);
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
          
          // 2. CONTENUTO SCORREVOLE
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: SizedBox(height: widget.safeTop + 20),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'A&R Dashboard',
                        style: TextStyle(
                          color: NuraBrand.pink,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Le tue scoperte',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TabBar(
                        controller: _tabController,
                        labelColor: Colors.black87,
                        unselectedLabelColor: Colors.black45,
                        indicatorColor: NuraBrand.pink,
                        indicatorSize: TabBarIndicatorSize.label,
                        indicatorWeight: 3,
                        splashFactory: NoSplash.splashFactory,
                        overlayColor: WidgetStateProperty.all(Colors.transparent),
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        tabs: const [
                          Tab(text: 'Da Valutare'),
                          Tab(text: 'Valutati'),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Contenuto Tab
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPitchesList(pendingAsync, true),
                    _buildPitchesList(evaluatedAsync, false),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPitchesList(AsyncValue<List<Map<String, dynamic>>> asyncValue, bool isPending) {
    return asyncValue.when(
      data: (pitches) {
        if (pitches.isEmpty) {
          return const Center(
            child: Text(
              'Nessun pitch presente.',
              style: TextStyle(color: Colors.black54),
            ),
          );
        }
        return ListView.separated(
          padding: EdgeInsets.only(bottom: widget.safeBottom + 100, left: 20, right: 20),
          itemCount: pitches.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) => _buildPitchCard(pitches[index], isPending),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: NuraBrand.pink)),
      error: (e, st) => Center(child: Text('Errore: $e')),
    );
  }

  Widget _buildPitchCard(Map<String, dynamic> pitch, bool isPending) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isPending ? () => _openReviewSheet(pitch) : null,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: pitch['track_cover_url'] != null
                        ? DecorationImage(
                            image: NetworkImage(pitch['track_cover_url']),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: Colors.black12,
                  ),
                  child: pitch['track_cover_url'] == null
                      ? const Icon(Icons.music_note, color: Colors.white54)
                      : null,
                ),
                const SizedBox(width: 16),
                // Info Traccia
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pitch['track_title'] ?? 'Brano Sconosciuto',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pitch['artist_name'] ?? 'Artista',
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.6),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Action Icon
                if (isPending)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: NuraBrand.pink.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: NuraBrand.pink),
                  ),
                if (!isPending)
                  const Icon(Icons.check_circle, color: Colors.green),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CuratorPitchReviewDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> pitch;
  final NuraVibe vibe;
  final Color accent;

  const CuratorPitchReviewDetailScreen({
    super.key,
    required this.pitch,
    required this.vibe,
    required this.accent,
  });

  @override
  ConsumerState<CuratorPitchReviewDetailScreen> createState() => _CuratorPitchReviewDetailScreenState();
}

class _CuratorPitchReviewDetailScreenState extends ConsumerState<CuratorPitchReviewDetailScreen> {
  final _feedbackController = TextEditingController();
  double _lyrics = 50.0;
  double _vibe = 50.0;
  double _production = 50.0;
  double _market = 50.0;
  bool _isSubmitting = false;

  int get _nuraScore => ((_lyrics + _vibe + _production + _market) / 4).round();

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
            child: Stack(
              children: [
                // Scrollable Content
                Positioned.fill(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(
                      top: 80, // Space for the close button
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
                  child: Image.network(
                    widget.pitch['track_cover_url'] ?? '',
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
                        widget.pitch['track_title'] ?? 'Brano',
                        style: const TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.pitch['artist_name'] ?? 'Artista',
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
            _buildSlider('Lyrics', _lyrics, (v) => setState(() => _lyrics = v)),
            _buildSlider('Vibe', _vibe, (v) => setState(() => _vibe = v)),
            _buildSlider('Production', _production, (v) => setState(() => _production = v)),
            _buildSlider('Market Potential', _market, (v) => setState(() => _market = v)),
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
              onPressed: _isSubmitting ? null : () async {
                setState(() => _isSubmitting = true);
                try {
                  final service = ref.read(curatorPitchServiceProvider);
                  await service.submitScore(
                    pitchId: widget.pitch['pitch_id'],
                    lyricsScore: _lyrics.round(),
                    vibeScore: _vibe.round(),
                    productionScore: _production.round(),
                    marketScore: _market.round(),
                    feedback: _feedbackController.text.isNotEmpty ? _feedbackController.text : null,
                  );
                  
                  // Invalidate providers to refresh tabs
                  ref.invalidate(pendingPitchesProvider);
                  ref.invalidate(evaluatedPitchesProvider);

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Feedback inviato con successo'),
                        backgroundColor: widget.accent,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  setState(() => _isSubmitting = false);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Errore: $e'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
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
              child: _isSubmitting 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text(
                      'Invia Valutazione',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
                      ],
                    ),
                  ),
                ),

                // Floating Close Button
                Positioned(
                  top: 16,
                  right: 24,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF1A1A1A), size: 28),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A1A).withValues(alpha: 0.1),
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
