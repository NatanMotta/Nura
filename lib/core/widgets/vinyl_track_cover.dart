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
    return SizedBox(
      height: widget.size,
      width: widget.size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 1. Vinyl Record (Always centered, scales up when playing)
          AnimatedScale(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            scale: widget.isPlaying ? 1.0 : 0.6,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: widget.isPlaying ? 1.0 : 0.0,
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
          ),

          // 2. Sleeve Cover -> Center Sticker
          AnimatedBuilder(
            animation: _spinController,
            builder: (context, child) {
              return Transform.rotate(
                angle: widget.isPlaying ? _spinController.value * 2 * 3.1415926535 : 0,
                child: child,
              );
            },
            child: AnimatedScale(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              scale: widget.isPlaying ? 0.33 : 1.0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutBack,
                clipBehavior: Clip.antiAlias,
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.isPlaying ? widget.size / 2 : 12),
                  boxShadow: [
                    BoxShadow(
                      color: widget.isPlaying 
                          ? Colors.black.withValues(alpha: 0.4) 
                          : Colors.black.withValues(alpha: 0.12),
                      blurRadius: widget.isPlaying ? 8 : 6,
                      offset: Offset(0, widget.isPlaying ? 2 : 4),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                  image: widget.coverAsset != null
                      ? DecorationImage(
                          image: AssetImage(widget.coverAsset!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (widget.coverAsset == null)
                      _buildPlaceholderCover(),
                    
                    // Center hole
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: widget.isPlaying ? 1.0 : 0.0,
                      child: Container(
                        width: widget.size * 0.12, // slightly bigger hole
                        height: widget.size * 0.12,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8F9FA),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black45,
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
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
