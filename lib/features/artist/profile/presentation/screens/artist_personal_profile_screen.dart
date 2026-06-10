
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../../../core/services/supabase_bootstrap.dart';
import '../../../../auth/presentation/auth_providers.dart';
import '../../data/artist_stats_service.dart';

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
  ConsumerState<ArtistPersonalProfileScreen> createState() => _ArtistPersonalProfileScreenState();
}

class _ArtistPersonalProfileScreenState extends ConsumerState<ArtistPersonalProfileScreen> {
  List<Map<String, dynamic>> _realTracks = [];
  bool _isLoadingTracks = true;
  NuuraScore? _nuuraScore;
  String _artistName = 'Caricamento...';
  String _artistBio = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final authUser = await ref.read(authRepositoryProvider).getCurrentUser();
      if (authUser == null || !SupabaseBootstrap.isInitialized) {
        if (mounted) setState(() => _isLoadingTracks = false);
        return;
      }

      // 1. Fetch Profile Data
      final profileResponse = await Supabase.instance.client
          .from('profiles')
          .select('display_name, bio')
          .eq('id', authUser.id)
          .maybeSingle();

      if (profileResponse != null) {
        _artistName = profileResponse['display_name'] ?? 'Artista';
        _artistBio = profileResponse['bio'] ?? 'Produttore & Cantautore';
      }

      // 2. Fetch Nuura Score from Service
      final scoreService = ref.read(artistStatsServiceProvider);
      final score = await scoreService.getArtistNuuraScore(authUser.id);

      // 3. Fetch Tracks
      final rows = await Supabase.instance.client
          .from('tracks')
          .select('id,title,duration_seconds')
          .eq('artist_id', authUser.id)
          .not('storage_path', 'is', null)
          .order('created_at', ascending: false)
          .limit(20);

      if (mounted) {
        setState(() {
          _artistName = _artistName;
          _artistBio = _artistBio;
          _nuuraScore = score;
          _realTracks = List<Map<String, dynamic>>.from(rows);
          _isLoadingTracks = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingTracks = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NuraBrand.deepest,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // 1. SliverAppBar (Parallax Cover Nativa)
          SliverAppBar(
            expandedHeight: 340.0,
            pinned: true,
            stretch: true,
            backgroundColor: NuraBrand.deepest,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 28),
                  onPressed: () {},
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/artists/michael-dam-mEZ3PoFGs_k-unsplash.jpg',
                    fit: BoxFit.cover,
                    cacheHeight: 1200,
                  ),
                  // Dark Glassmorphism Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          NuraBrand.deepest.withValues(alpha: 0.6),
                          NuraBrand.deepest,
                        ],
                        stops: const [0.4, 0.8, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Profile Info & Nuura Score
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _buildIdentityGlassCard(),
                  const SizedBox(height: 24),
                  if (_nuuraScore != null) _buildNuuraBentoGrid(_nuuraScore!),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // 3. Sticky Header
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickySectionHeaderDelegate(
              title: 'BRANI',
              safeTop: 0,
            ),
          ),

          // 4. Tracks List
          if (_isLoadingTracks)
            const SliverToBoxAdapter(
              child: SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator(color: NuraBrand.mint)),
              ),
            )
          else if (_realTracks.isEmpty)
            const SliverToBoxAdapter(
              child: SizedBox(
                height: 150,
                child: Center(
                  child: Text('Nessuna traccia caricata.', style: TextStyle(color: Colors.white54)),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 16.0, bottom: 0.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return _buildTrackTile(_realTracks[index], index);
                  },
                  childCount: _realTracks.length,
                ),
              ),
            ),

          SliverToBoxAdapter(
            child: SizedBox(height: widget.safeBottom + 140),
          ),
        ],
      ),
    );
  }

  // --- IDENTITY CARD (Gamification Ring) ---
  Widget _buildIdentityGlassCard() {
    final score = _nuuraScore?.totalScore ?? 0;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildGamifiedAvatar('assets/images/artists/michael-dam-mEZ3PoFGs_k-unsplash.jpg', score),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _artistName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _artistBio,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGamifiedAvatar(String imageUrl, int score) {
    Color ringColor = score >= 90 ? const Color(0xFF39FF14) : 
                      score >= 80 ? NuraBrand.mint : 
                      score >= 70 ? Colors.yellow : NuraBrand.pink;
                      
    return SizedBox(
      width: 104,
      height: 104,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Glow
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ringColor.withValues(alpha: 0.3),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          // Avatar
          ClipRRect(
            borderRadius: BorderRadius.circular(52),
            child: Image.asset(
              imageUrl,
              width: 88,
              height: 88,
              fit: BoxFit.cover,
              cacheWidth: 300,
            ),
          ),
          // Progress Ring
          SizedBox(
            width: 104,
            height: 104,
            child: CircularProgressIndicator(
              value: score / 100.0,
              strokeWidth: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(ringColor),
              strokeCap: StrokeCap.round,
            ),
          ),
          // Score Badge
          Positioned(
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: NuraBrand.deepest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ringColor, width: 1.5),
              ),
              child: Text(
                score.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- NUURA BENTO GRID ---
  Widget _buildNuuraBentoGrid(NuuraScore score) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nuura Analytics',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildBentoStat('TESTO', score.lyricsScore, NuraBrand.pink)),
            const SizedBox(width: 12),
            Expanded(child: _buildBentoStat('VIBE', score.vibeScore, const Color(0xFF9D00FF))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildBentoStat('PROD.', score.productionScore, NuraBrand.mint)),
            const SizedBox(width: 12),
            Expanded(child: _buildBentoStat('MERCATO', score.marketPotentialScore, const Color(0xFF39FF14))),
          ],
        ),
      ],
    );
  }

  Widget _buildBentoStat(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value.toString(),
                style: TextStyle(
                  color: color,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.0,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  '/100',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100.0,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  // --- TRACK TILE ---
  Widget _buildTrackTile(Map<String, dynamic> track, int index) {
    final title = track['title'] as String? ?? 'Senza titolo';
    final durSecs = track['duration_seconds'] as int? ?? 0;
    final min = durSecs ~/ 60;
    final sec = (durSecs % 60).toString().padLeft(2, '0');
    final durationStr = '$min:$sec';
    final mockPlays = 1200 + (index * 432); 
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.music_note, color: Colors.white54, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$mockPlays ascolti • $durationStr',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.more_vert, color: Colors.white.withValues(alpha: 0.3), size: 24),
        ],
      ),
    );
  }
}

class _StickySectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final double safeTop;

  _StickySectionHeaderDelegate({required this.title, required this.safeTop});

  @override
  double get minExtent => 64.0 + safeTop; 
  @override
  double get maxExtent => 64.0 + safeTop; 

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double opacity = (shrinkOffset / maxExtent).clamp(0.0, 1.0);
    
    return Container(
      color: Color.lerp(Colors.transparent, NuraBrand.deepest.withValues(alpha: 0.98), opacity),
      padding: EdgeInsets.only(top: safeTop, left: 20, right: 20),
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickySectionHeaderDelegate oldDelegate) {
    return title != oldDelegate.title || safeTop != oldDelegate.safeTop;
  }
}
