import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../../../core/models/track.dart';
import '../../../../../core/widgets/mono.dart';
import '../../../../../core/widgets/nura_mark.dart';
import '../../../../../core/widgets/striped_panel.dart';
import '../../../../../core/widgets/waveform.dart';
import '../../../../shared/data/mock_nura_data.dart';

class HomeFeed extends StatefulWidget {
  final NuraVibe vibe;
  final Color accent;
  final String waveform;
  final double safeTop, safeBottom;
  const HomeFeed(
      {super.key,
      required this.vibe,
      required this.accent,
      required this.waveform,
      required this.safeTop,
      required this.safeBottom});
  @override
  State<HomeFeed> createState() => _HomeFeedState();
}

class _HomeFeedState extends State<HomeFeed> {
  late List<Track> deck;
  String? impulse;
  int likes = 12, skips = 38;
  @override
  void initState() {
    super.initState();
    deck = List.of(kTracks);
  }

  void _decide(String action) {
    setState(() {
      if (action == 'like') {
        likes++;
      } else {
        skips++;
      }
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
          const Text('nura',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: NuraBrand.mint,
                  letterSpacing: 0.4)),
          const Spacer(),
          Mono('♥ $likes', color: NuraBrand.mint),
          const SizedBox(width: 8),
          Mono('↳ $skips', color: NuraBrand.mintAlpha(0.45)),
        ]),
      ),
      // Card stack
      Positioned(
        top: widget.safeTop + 50,
        left: 16,
        right: 16,
        bottom: nav + 100,
        child: Stack(children: [
          for (int i = math.min(2, deck.length - 1); i >= 0; i--)
            SwipeCard(
              key: ValueKey('${deck[i].id}-${deck.length}-$i'),
              track: deck[i],
              vibe: widget.vibe,
              accent: widget.accent,
              waveStyle: widget.waveform,
              depth: i,
              isTop: i == 0,
              manualImpulse: i == 0 ? impulse : null,
              onDecide: _decide,
            ),
        ]),
      ),
      // Action buttons
      Positioned(
        left: 0,
        right: 0,
        bottom: nav + 16,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _RoundBtn(
              size: 54,
              border: widget.vibe.cardBorder,
              onTap: () => setState(() => impulse = 'skip'),
              child: const Icon(Icons.close, size: 22, color: NuraBrand.mint)),
          const SizedBox(width: 22),
          GestureDetector(
            onTap: () => setState(() => impulse = 'like'),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.accent,
                boxShadow: [
                  BoxShadow(
                      color: widget.accent.withOpacity(0.4),
                      blurRadius: 36,
                      offset: const Offset(0, 12))
                ],
                border: Border.all(color: Colors.white.withOpacity(0.18)),
              ),
              child: const Icon(Icons.favorite, size: 26, color: Colors.white),
            ),
          ),
          const SizedBox(width: 22),
          _RoundBtn(
              size: 54,
              border: widget.vibe.cardBorder,
              onTap: () {},
              child: const Icon(Icons.bookmark_outline,
                  size: 20, color: NuraBrand.mint)),
        ]),
      ),
    ]);
  }
}

class _RoundBtn extends StatelessWidget {
  final double size;
  final Widget child;
  final Color border;
  final VoidCallback onTap;
  const _RoundBtn(
      {required this.size,
      required this.child,
      required this.border,
      required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: ClipOval(
            child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: NuraBrand.deepMidAlpha(0.7),
                border: Border.all(color: border)),
            child: child,
          ),
        )),
      );
}

class SwipeCard extends StatefulWidget {
  final Track track;
  final NuraVibe vibe;
  final Color accent;
  final String waveStyle;
  final int depth;
  final bool isTop;
  final String? manualImpulse;
  final ValueChanged<String> onDecide;
  const SwipeCard(
      {super.key,
      required this.track,
      required this.vibe,
      required this.accent,
      required this.waveStyle,
      required this.depth,
      required this.isTop,
      required this.manualImpulse,
      required this.onDecide});
  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard>
    with SingleTickerProviderStateMixin {
  Offset drag = Offset.zero;
  String? exit;

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
      Future.delayed(const Duration(milliseconds: 280), () {
        if (mounted) widget.onDecide('like');
      });
    } else if (drag.dx < -threshold) {
      setState(() => exit = 'skip');
      Future.delayed(const Duration(milliseconds: 280), () {
        if (mounted) widget.onDecide('skip');
      });
    } else {
      setState(() => drag = Offset.zero);
    }
  }

  @override
  Widget build(BuildContext context) {
    double tx = drag.dx, ty = drag.dy, rotation = drag.dx / 18 * math.pi / 180;
    if (exit == 'like') {
      tx = 600;
      rotation = 24 * math.pi / 180;
    }
    if (exit == 'skip') {
      tx = -600;
      rotation = -24 * math.pi / 180;
    }

    final stackOffset = widget.depth * 12.0;
    final stackScale = 1 - widget.depth * 0.04;
    final likeOpacity = (drag.dx / 110).clamp(0.0, 1.0);
    final skipOpacity = (-drag.dx / 110).clamp(0.0, 1.0);

    return AnimatedPositioned(
      duration:
          Duration(milliseconds: exit != null || drag == Offset.zero ? 280 : 0),
      curve: Curves.easeOut,
      left: tx,
      right: -tx,
      top: ty + stackOffset,
      bottom: -ty - stackOffset,
      child: Transform.rotate(
        angle: rotation,
        child: Transform.scale(
          scale: stackScale,
          child: GestureDetector(
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.vibe.radius),
              child: Stack(children: [
                Positioned.fill(
                    child:
                        StripedPanel(hue: widget.track.hue, vibe: widget.vibe)),
                // Top meta
                Positioned(
                  top: 14,
                  left: 16,
                  right: 16,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Mono(widget.track.genre,
                            color: NuraBrand.mintAlpha(0.85)),
                        Mono('${widget.track.bpm} BPM',
                            color: NuraBrand.mintAlpha(0.85)),
                      ]),
                ),
                // LIKE / SKIP badges
                Positioned(
                    top: 28,
                    left: 22,
                    child: Opacity(
                        opacity: likeOpacity,
                        child: Transform.rotate(
                            angle: -12 * math.pi / 180,
                            child:
                                _Badge(text: 'LIKE', color: widget.accent)))),
                Positioned(
                    top: 28,
                    right: 22,
                    child: Opacity(
                        opacity: skipOpacity,
                        child: Transform.rotate(
                            angle: 12 * math.pi / 180,
                            child: const _Badge(
                                text: 'SKIP', color: NuraBrand.mint)))),
                // Bottom overlay
                Positioned(
                  bottom: 16,
                  left: 12,
                  right: 12,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(widget.vibe.radius - 4),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: NuraBrand.deepMidAlpha(0.55),
                          border: Border.all(color: widget.vibe.cardBorder),
                          borderRadius:
                              BorderRadius.circular(widget.vibe.radius - 4),
                        ),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(children: [
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(widget.track.artist,
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: NuraBrand.mintAlpha(0.65),
                                              letterSpacing: 0.4)),
                                      const SizedBox(height: 2),
                                      Text(widget.track.track,
                                          style: const TextStyle(
                                              fontSize: 19,
                                              fontWeight: FontWeight.w600,
                                              color: NuraBrand.mint)),
                                    ])),
                                Container(
                                    width: 38,
                                    height: 38,
                                    decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: NuraBrand.mint),
                                    child: const Icon(Icons.play_arrow,
                                        color: NuraBrand.deep, size: 18)),
                              ]),
                              const SizedBox(height: 8),
                              Row(children: [
                                Expanded(
                                    child: Waveform(
                                        style: widget.waveStyle,
                                        color: NuraBrand.mint,
                                        height: 22,
                                        count: 36,
                                        seed: widget.track.id.codeUnitAt(1))),
                                const SizedBox(width: 10),
                                Mono(widget.track.dur,
                                    color: NuraBrand.mintAlpha(0.55)),
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
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(8)),
        child: Text(text,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 2.5,
                fontFamily: 'JetBrainsMono',
                fontFamilyFallback: const ['monospace'])),
      );
}
