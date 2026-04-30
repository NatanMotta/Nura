import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../../../core/utils/color_utils.dart';
import '../../../../../core/widgets/glass.dart';
import '../../../../../core/widgets/mono.dart';
import '../../../../../core/widgets/striped_panel.dart';
import '../../../../../core/widgets/waveform.dart';
import '../../../../shared/data/mock_nura_data.dart';

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

class _HomeSearchState extends State<HomeSearch> {
  final _controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding:
          EdgeInsets.fromLTRB(0, widget.safeTop, 0, 100 + widget.safeBottom),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Cerca',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: NuraBrand.mint,
                    letterSpacing: -0.5)),
            Mono('scopri · suoni · scene', color: NuraBrand.mintAlpha(0.5)),
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
                  Icon(Icons.search, size: 18, color: NuraBrand.mintAlpha(0.7)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: TextField(
                          controller: _controller,
                          style: const TextStyle(
                              color: NuraBrand.mint, fontSize: 14),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'artisti, brani, mood…',
                            hintStyle:
                                TextStyle(color: NuraBrand.mintAlpha(0.5)),
                            isDense: true,
                          ))),
                  Mono('⌘ K', color: NuraBrand.mintAlpha(0.45)),
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
                    const Mono('↗ trend · oggi', color: NuraBrand.mint),
                    Mono('04·29', color: NuraBrand.mintAlpha(0.4)),
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
                                  color: NuraBrand.mintAlpha(0.6)))),
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
                                    color: NuraBrand.mint,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                            Text(kTrending[i].artist,
                                style: TextStyle(
                                    color: NuraBrand.mintAlpha(0.55),
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
                                      ? NuraBrand.mintAlpha(0.5)
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
                padding: EdgeInsets.only(bottom: 10),
                child: Mono('◎ generi', color: NuraBrand.mint)),
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
                                      Colors.white.withOpacity(0.05)))),
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
                                          color: NuraBrand.mint,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14)),
                                  Mono('${g.count} brani',
                                      color: NuraBrand.mintAlpha(0.6)),
                                ]),
                          ),
                        ]),
                      ))
                  .toList(),
            ),
          ]),
        ),
      ]),
    );
  }
}
