import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../services/audio_preview_service.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';

class GlobalMiniPlayer extends StatelessWidget {
  final NuraVibe vibe;
  const GlobalMiniPlayer({super.key, required this.vibe});

  @override
  Widget build(BuildContext context) {
    final audio = AudioPreviewService.instance;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ValueListenableBuilder<String?>(
        valueListenable: audio.playingTrackId,
        builder: (context, trackId, _) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                height: 76,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // 1. INTERACTIVE PROGRESS BAR (TOP)
                    const Positioned(
                      top: 0, left: 0, right: 0,
                      child: _InteractiveProgressBar(),
                    ),

                    // 2. PLAYER CONTENT
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                      child: Row(
                        children: [
                          // Artwork
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 46,
                              height: 46,
                              color: Colors.black12,
                              child: const Icon(Icons.music_note, color: Colors.white, size: 20),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Info
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Sunset Drive',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 13, fontWeight: FontWeight.w800),
                                ),
                                Text(
                                  'Aria Nova',
                                  style: TextStyle(color: Colors.black.withValues(alpha: 0.4), fontSize: 11, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          // Heart / Like
                          IconButton(
                            icon: const Icon(Icons.favorite_border, color: Colors.black45, size: 22),
                            onPressed: () {},
                          ),
                          // Play/Pause Circle
                          ValueListenableBuilder<bool>(
                            valueListenable: audio.isPlaying,
                            builder: (context, isPlaying, _) {
                              return GestureDetector(
                                onTap: () => isPlaying ? audio.pause() : audio.resume(),
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF1A1A1A),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isPlaying ? Icons.pause : Icons.play_arrow,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 4),
                          // CLOSE BUTTON (X)
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.black26, size: 18),
                            onPressed: () => audio.stop(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InteractiveProgressBar extends StatelessWidget {
  const _InteractiveProgressBar();

  @override
  Widget build(BuildContext context) {
    final audio = AudioPreviewService.instance;

    return ValueListenableBuilder<Duration?>(
      valueListenable: audio.duration,
      builder: (context, totalDuration, _) {
        return ValueListenableBuilder<Duration>(
          valueListenable: audio.position,
          builder: (context, pos, _) {
            final totalMs = totalDuration?.inMilliseconds.toDouble() ?? 0.0;
            final posMs = pos.inMilliseconds.toDouble().clamp(0.0, totalMs > 0 ? totalMs : 0.0);

            return SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0), // Hidden until active? Or keep very small
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                activeTrackColor: NuraBrand.pink,
                inactiveTrackColor: Colors.black.withValues(alpha: 0.05),
                trackShape: const _FullWidthTrackShape(),
              ),
              child: Slider(
                value: posMs,
                max: totalMs > 0 ? totalMs : 1.0,
                onChanged: (value) {
                  audio.seek(Duration(milliseconds: value.toInt()));
                },
              ),
            );
          },
        );
      },
    );
  }
}

// Custom track shape to remove side padding from the slider
class _FullWidthTrackShape extends RoundedRectSliderTrackShape {
  const _FullWidthTrackShape();
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 3.0;
    final double trackLeft = offset.dx;
    final double trackTop = offset.dy;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}
