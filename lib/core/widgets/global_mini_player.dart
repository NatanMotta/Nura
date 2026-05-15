import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../services/audio_preview_service.dart';

/// Mini player globale che appare sopra la nav bar in tutto lo shell.
/// Si mostra automaticamente quando c'è un brano in riproduzione.
class GlobalMiniPlayer extends StatelessWidget {
  final NuraVibe vibe;
  const GlobalMiniPlayer({super.key, required this.vibe});

  String _durationLabel(int? seconds) {
    if (seconds == null) return '--:--';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final audio = AudioPreviewService.instance;

    return AnimatedBuilder(
      animation: Listenable.merge(
        [audio.playingTrackId, audio.isPlaying, audio.position, audio.duration],
      ),
      builder: (context, _) {
        final activeTrackId = audio.playingTrackId.value;
        if (activeTrackId == null || activeTrackId.isEmpty) {
          return const SizedBox.shrink();
        }

        final duration = audio.duration.value ?? const Duration(seconds: 15);
        final position = audio.position.value;
        final currentPosition = position > duration ? duration : position;

        return LayoutBuilder(
          builder: (context, constraints) {
            final progress = duration.inMilliseconds > 0
                ? currentPosition.inMilliseconds / duration.inMilliseconds
                : 0.0;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: (details) {
                final pct = (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
                audio.seek(Duration(milliseconds: (pct * duration.inMilliseconds).floor()));
              },
              onTapDown: (details) {
                final pct = (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
                audio.seek(Duration(milliseconds: (pct * duration.inMilliseconds).floor()));
              },
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: NuraBrand.deepMid,
                  border: Border(
                    top: BorderSide(color: NuraBrand.mintAlpha(0.12)),
                  ),
                ),
                child: Stack(
                  children: [
                    // Background progress fill
                    Container(
                      width: constraints.maxWidth * progress,
                      height: double.infinity,
                      color: NuraBrand.pink.withValues(alpha: 0.08),
                    ),
                    // Top progress line
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        height: 2,
                        width: constraints.maxWidth * progress,
                        color: NuraBrand.pink,
                      ),
                    ),
                    // Content row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: LinearGradient(
                                colors: [NuraBrand.mintAlpha(0.2), NuraBrand.deep],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Icon(Icons.music_note, color: NuraBrand.mint, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'In riproduzione',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: NuraBrand.mint,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  '${_durationLabel(currentPosition.inSeconds)} / ${_durationLabel(duration.inSeconds)}',
                                  style: TextStyle(
                                    color: NuraBrand.mintAlpha(0.5),
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ValueListenableBuilder<bool>(
                            valueListenable: audio.isPlaying,
                            builder: (_, isPlaying, __) => IconButton(
                              onPressed: () {
                                if (isPlaying) {
                                  audio.pause();
                                } else {
                                  audio.resume();
                                }
                              },
                              icon: Icon(
                                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: NuraBrand.mint,
                                size: 28,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
