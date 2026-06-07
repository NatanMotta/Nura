import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../../../core/utils/color_utils.dart';
import '../../../../../core/widgets/glass.dart';
import '../../../../../core/widgets/mono.dart';
import '../../../../../core/widgets/striped_panel.dart';
import '../../../../../core/widgets/waveform.dart';
import '../../../../shared/data/mock_nura_data.dart';
import '../../../../discovery/swipe/presentation/screens/artist_public_profile_screen.dart';

class HomeSearch extends StatefulWidget {
  final NuraVibe vibe;
  final Color accent;
  final String waveform;
  final double safeTop, safeBottom;
  const HomeSearch(
      {super.key,
      required this.vibe,
      required this.accent,
      required this.waveform,
      required this.safeTop,
      required this.safeBottom});
  @override
  State<HomeSearch> createState() => _HomeSearchState();
}

class _HomeSearchState extends State<HomeSearch> with AutomaticKeepAliveClientMixin {
  final _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _scrollNotifier = ValueNotifier<double>(0.0);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _scrollNotifier.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    _scrollNotifier.value = _scrollController.offset;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Stack(children: [
      ValueListenableBuilder<double>(
        valueListenable: _scrollNotifier,
        builder: (context, scrollOffset, _) {
          return Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: ParallaxOrganicMeshPainter(
                  scrollOffset: scrollOffset,
                  musicuraBlu: NuraBrand.deep,
                  nuraPink: NuraBrand.pink,
                ),
              ),
            ),
          );
        },
      ),
      SingleChildScrollView(
        controller: _scrollController,
        padding:
            EdgeInsets.fromLTRB(0, widget.safeTop, 0, 100 + widget.safeBottom),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Cerca',
                style: TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0)),
            Mono('scopri · suoni · scene', color: Colors.black45),
          ]),
        ),
        // Search field
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Glass(
            vibe: widget.vibe,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: SizedBox(
                height: 46,
                child: Row(children: [
                  const Icon(Icons.search, size: 18, color: Colors.black45),
                  const SizedBox(width: 10),
                  Expanded(
                      child: TextField(
                          controller: _controller,
                          style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 14),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'artisti, brani, mood…',
                            hintStyle: const TextStyle(color: Colors.black45),
                            isDense: true,
                          ))),
                  Mono('⌘ K', color: Colors.black38),
                ])),
          ),
        ),
        // Trending
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Mono('↗ trend · oggi', color: Color(0xFF1A1A1A)),
                    Mono('04·29', color: Colors.black38),
                  ]),
            ),
            Glass(
              vibe: widget.vibe,
              padding: const EdgeInsets.all(4),
              child: Column(children: [
                for (int i = 0; i < kTrending.length; i++)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                        border: Border(
                      top: i == 0
                          ? BorderSide.none
                          : BorderSide(color: widget.vibe.cardBorder),
                    )),
                    child: Row(children: [
                      SizedBox(
                          width: 28,
                          child: Text(
                              kTrending[i].rank.toString().padLeft(2, '0'),
                              style: TextStyle(
                                  fontFamily: 'JetBrainsMono',
                                  fontFamilyFallback: const ['monospace'],
                                  fontSize: 13,
                                  color: Colors.black45))),
                      Container(
                          width: 32,
                          height: 32,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    kTrending[i].swatch,
                                    NuraBrand.deep
                                  ]))),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(kTrending[i].track,
                                style: const TextStyle(
                                    color: Color(0xFF1A1A1A),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                            Text(kTrending[i].artist,
                                style: TextStyle(
                                    color: Colors.black45,
                                    fontSize: 11)),
                          ])),
                      SizedBox(
                          width: 56,
                          child: Waveform(
                              style: widget.waveform,
                              color: NuraBrand.mint,
                              height: 18,
                              count: 20,
                              seed: kTrending[i].rank)),
                      const SizedBox(width: 8),
                      SizedBox(
                          width: 30,
                          child: Text(kTrending[i].delta,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  fontFamily: 'JetBrainsMono',
                                  fontFamilyFallback: const ['monospace'],
                                  fontSize: 12,
                                  color: kTrending[i].delta.startsWith('−')
                                      ? Colors.black45
                                      : widget.accent))),
                    ]),
                  ),
              ]),
            ),
          ]),
        ),
        // Genres
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Padding(
                padding: EdgeInsets.only(bottom: 10), child: Mono('◎ generi', color: Color(0xFF1A1A1A))),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.6,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: kGenres
                  .map((g) => Container(
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(widget.vibe.radius - 4),
                          border: Border.all(color: widget.vibe.cardBorder),
                          gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                hueColor(0.50, 0.10, g.hue.toDouble()),
                                hueColor(0.36, 0.07, 195)
                              ]),
                        ),
                        child: Stack(children: [
                          Positioned.fill(
                              child: CustomPaint(
                                  painter: StripesPainter(
                                      Colors.white.withValues(alpha: 0.05)))),
                          Positioned(
                            left: 12,
                            right: 12,
                            bottom: 10,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(g.name,
                                      style: const TextStyle(
                                          color: Color(0xFF1A1A1A),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14)),
                                  Mono('${g.count} brani', color: Colors.black45),
                                ]),
                          ),
                        ]),
                      ))
                  .toList(),
            ),
          ]),
        ),
      ]),
    )]);
  }
}
