import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class VinylTrackCover extends StatefulWidget {
  final bool isPlaying;
  final String? coverAsset;
  final Color swatch;
  final double size;

  const VinylTrackCover({
    super.key,
    required this.isPlaying,
    this.coverAsset,
    this.swatch = NuraBrand.pink,
    this.size = 60,
  });

  @override
  State<VinylTrackCover> createState() => _VinylTrackCoverState();
}

class _VinylTrackCoverState extends State<VinylTrackCover> with SingleTickerProviderStateMixin {
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    if (widget.isPlaying) {
      _spinController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant VinylTrackCover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _spinController.repeat();
      } else {
        _spinController.stop();
      }
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  Widget _buildVinylGroove({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
          width: 0.8,
        ),
      ),
    );
  }

  Widget _buildVinylRecord() {
    final vinylSize = widget.size * 0.92;
    return Container(
      width: vinylSize,
      height: vinylSize,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Color(0xFF2C2C2C),
            Color(0xFF151515),
            Color(0xFF0F0F0F),
          ],
          stops: [0.0, 0.7, 1.0],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Groove concentric lines
          _buildVinylGroove(size: vinylSize * 0.85),
          _buildVinylGroove(size: vinylSize * 0.7),
          _buildVinylGroove(size: vinylSize * 0.55),

          // Shiny physical glare overlay that rotates
          Container(
            width: vinylSize,
            height: vinylSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.0),
                  Colors.white.withValues(alpha: 0.12),
                  Colors.white.withValues(alpha: 0.03),
                  Colors.white.withValues(alpha: 0.12),
                  Colors.white.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.45, 0.5, 0.55, 1.0],
              ),
            ),
          ),

          // Center Sticker
          Container(
            width: vinylSize * 0.32,
            height: vinylSize * 0.32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Two-toned sticker gradient
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        widget.swatch,
                        widget.swatch.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                ),
                // Center hole
                Center(
                  child: Container(
                    width: vinylSize * 0.07,
                    height: vinylSize * 0.07,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
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

  Widget _buildPlaceholderCover() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [widget.swatch, widget.swatch.withValues(alpha: 0.5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.music_note_outlined,
          color: Colors.white38,
          size: widget.size * 0.3,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Total width must accommodate the sleeve + vinyl sliding out
    final totalWidth = widget.size * 1.5;

    return SizedBox(
      height: widget.size + 10,
      width: totalWidth,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Vinyl Record (Slides out from behind cover)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 550),
            curve: widget.isPlaying ? Curves.easeOutBack : Curves.easeOut,
            left: widget.isPlaying ? (widget.size * 0.6) : (widget.size * 0.1),
            top: 5 + (widget.size * 0.04), // slightly centered
            child: AnimatedBuilder(
              animation: _spinController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _spinController.value * 2 * 3.1415926535,
                  child: child,
                );
              },
              child: _buildVinylRecord(),
            ),
          ),

          // 2. Sleeve Cover
          Positioned(
            left: 0,
            top: 5,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: widget.isPlaying 
                        ? NuraBrand.pink.withValues(alpha: 0.25) 
                        : Colors.black.withValues(alpha: 0.12),
                    blurRadius: widget.isPlaying ? 12 : 6,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    // Album cover or gradient
                    widget.coverAsset != null
                        ? Image.asset(
                            widget.coverAsset!,
                            width: widget.size,
                            height: widget.size,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                            cacheWidth: 300,
                            errorBuilder: (_, __, ___) => _buildPlaceholderCover(),
                          )
                        : _buildPlaceholderCover(),
                    
                    // Glassmorphic overlay border
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.isPlaying 
                              ? NuraBrand.pink.withValues(alpha: 0.45) 
                              : Colors.white.withValues(alpha: 0.15),
                          width: widget.isPlaying ? 2.0 : 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
