import 'package:flutter/material.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../data/artist_stats_service.dart';

class NuraScoreAnalyticsScreen extends StatelessWidget {
  final NuraVibe vibe;
  final NuuraScore globalScore;
  final List<Map<String, dynamic>> tracks;

  const NuraScoreAnalyticsScreen({
    super.key,
    required this.vibe,
    required this.globalScore,
    required this.tracks,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NuraBrand.deepest,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Analisi Nura Score',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _buildGlobalScoreHero(),
          ),
          SliverToBoxAdapter(
            child: _buildGlobalBreakdown(),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: const Text(
                'Punteggi per Canzone',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildTrackScoreDetail(tracks[index]),
                childCount: tracks.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalScoreHero() {
    return Column(
      children: [
        const SizedBox(height: 24),
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: NuraBrand.pink.withValues(alpha: 0.2),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
            gradient: SweepGradient(
              colors: const [NuraBrand.pink, Color(0xFF9D00FF), NuraBrand.mint, NuraBrand.pink],
              stops: const [0.0, 0.33, 0.66, 1.0],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Container(
              decoration: const BoxDecoration(
                color: NuraBrand.deepest,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '${globalScore.totalScore}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 54,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'NURA SCORE GLOBALE',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Calcolato elaborando ${globalScore.totalFeedbacks} feedback ufficiali lasciati dai Curator di Nura sui tuoi brani.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildGlobalBreakdown() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: NuraBrand.deep.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MEDIA DEI PARAMETRI',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          _buildProgressBar('Vibe / Emozione', globalScore.vibeScore, NuraBrand.pink),
          const SizedBox(height: 16),
          _buildProgressBar('Produzione', globalScore.productionScore, const Color(0xFF9D00FF)),
          const SizedBox(height: 16),
          _buildProgressBar('Testo (Lyrics)', globalScore.lyricsScore, NuraBrand.mint),
          const SizedBox(height: 16),
          _buildProgressBar('Potenziale di Mercato', globalScore.marketPotentialScore, const Color(0xFF00BFA5)),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, int value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$value/100',
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 8,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: value / 100,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrackScoreDetail(Map<String, dynamic> track) {
    // Generate some mock individual metrics for the track based on its main score
    final baseScore = track['score'] as int;
    final int vibe = (baseScore + 4).clamp(0, 100);
    final int prod = (baseScore + 1).clamp(0, 100);
    final int lyrics = (baseScore - 3).clamp(0, 100);
    final int market = (baseScore + 2).clamp(0, 100);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Theme(
        data: ThemeData.dark().copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          iconColor: Colors.white54,
          collapsedIconColor: Colors.white54,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          title: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/labels/milad-fakurian-PGdW_bHDbpI-unsplash.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track['title'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${track['feedback']} Feedback',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: NuraBrand.pink.withValues(alpha: 0.5), width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$baseScore',
                  style: const TextStyle(
                    color: NuraBrand.pink,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildProgressBar('Vibe / Emozione', vibe, NuraBrand.pink),
                  const SizedBox(height: 12),
                  _buildProgressBar('Produzione', prod, const Color(0xFF9D00FF)),
                  const SizedBox(height: 12),
                  _buildProgressBar('Testo (Lyrics)', lyrics, NuraBrand.mint),
                  const SizedBox(height: 12),
                  _buildProgressBar('Potenziale di Mercato', market, const Color(0xFF00BFA5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
