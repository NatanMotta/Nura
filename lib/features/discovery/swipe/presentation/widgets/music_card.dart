import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../../../../../core/models/track.dart';

ui.FragmentProgram? _globalShaderProgram;

/// Bare-Metal AOT Shader Pre-loader. 
/// Invocare nel main() prima di runApp per vincolare lo shader 
/// nella memoria VRAM ed eliminare lo Shader Compilation Jank.
Future<void> preloadLiquidGlassShader() async {
  if (_globalShaderProgram == null) {
    _globalShaderProgram = await ui.FragmentProgram.fromAsset('shaders/liquid_glass.frag');
  }
}

class MusicCard extends StatefulWidget {
  final Track track;
  final bool isTopCard;
  final bool isDragging;
  final Color ambientGlow;
  final VoidCallback? onArtistTap;

  const MusicCard({
    super.key,
    required this.track,
    this.isTopCard = true,
    this.isDragging = false,
    required this.ambientGlow,
    this.onArtistTap,
  });

  @override
  State<MusicCard> createState() => _MusicCardState();
}

class _MusicCardState extends State<MusicCard>
    with SingleTickerProviderStateMixin {
  ui.FragmentShader? _cardShader;
  late Ticker _ticker;
  final ValueNotifier<double> _timeNotifier = ValueNotifier<double>(0.0);
  int? _targetCacheWidth;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_targetCacheWidth == null) {
      final mq = MediaQuery.of(context);
      _targetCacheWidth = (mq.size.width * mq.devicePixelRatio).toInt();
    }
  }

  @override
  void initState() {
    super.initState();
    if (_globalShaderProgram != null) {
      _cardShader = _globalShaderProgram!.fragmentShader();
    } else {
      ui.FragmentProgram.fromAsset('shaders/liquid_glass.frag').then((shader) {
        _globalShaderProgram = shader;
        if (mounted) {
          setState(() {
            _cardShader = shader.fragmentShader();
          });
        }
      });
    }

    _ticker = createTicker((elapsed) {
      _timeNotifier.value = (elapsed.inMilliseconds % 10000) / 1000.0;
    });
    
    if (widget.isTopCard) {
      _ticker.start();
    }
  }

  @override
  void didUpdateWidget(MusicCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTopCard != oldWidget.isTopCard) {
      if (widget.isTopCard) {
        _timeNotifier.value = 0.0;
        if (!_ticker.isActive) _ticker.start();
      } else {
        if (_ticker.isActive) _ticker.stop();
      }
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _timeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget cardContent = RepaintBoundary(
        child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(38),
        color: widget.track.swatch.withValues(alpha: 1.0),
        image: widget.track.coverAsset != null
            ? DecorationImage(
                image: ResizeImage(
                  AssetImage(widget.track.coverAsset!), 
                  width: _targetCacheWidth
                ),
                fit: BoxFit.cover,
              )
            : null,
        boxShadow: (widget.isTopCard && !widget.isDragging)
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 40,
                  spreadRadius: 2,
                  offset: const Offset(0, 10),
                )
              ]
            : null,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Glassmorphism 2.0: Border ottico che riflette la luce ambientale
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(38),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1.2,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.3),
                  Colors.white.withValues(alpha: 0.0),
                  widget.ambientGlow.withValues(alpha: 0.2),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),

          // Pannello inferiore in Liquid Glass (Shader custom)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ValueListenableBuilder<double>(
              valueListenable: _timeNotifier,
              builder: (context, timeValue, child) {
                if (_cardShader == null) return child!; // Renderizza istantaneamente in modo sincrono

                return RepaintBoundary(
                  child: CustomPaint(
                    painter: LiquidGlassPainter(
                      shader: _cardShader!,
                      time: timeValue,
                      glowColor: widget.ambientGlow,
                    ),
                    child: child,
                  ),
                );
              },
              child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28.0, vertical: 36.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Editorial Typography (Cliccabile per profilo Artista)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: widget.onArtistTap,
                          splashColor: Colors.white.withValues(alpha: 0.1),
                          highlightColor: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4.0, horizontal: 4.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      widget.track.artist.toUpperCase(),
                                      style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.95),
                                        fontSize: 42,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -1.5,
                                        height: 0.9,
                                        decoration: widget.onArtistTap != null
                                            ? TextDecoration.underline
                                            : TextDecoration.none,
                                        decorationColor:
                                            Colors.white.withValues(alpha: 0.4),
                                      ),
                                    ),
                                  ),
                                ),
                                if (widget.onArtistTap != null)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Icon(Icons.arrow_forward_ios_rounded,
                                        color:
                                            Colors.white.withValues(alpha: 0.7),
                                        size: 16),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          widget.track.track,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: 24,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 2.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildPill(widget.track.genre),
                          const SizedBox(width: 8),
                          _buildPill('${widget.track.bpm} BPM'),
                        ],
                      )
                    ],
                ),
              ),
            ),
          ),
        ],
      ),
    ));

    return cardContent;
  }

  Widget _buildPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: widget.ambientGlow.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.ambientGlow.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class LiquidGlassPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final double time;
  final Color glowColor;

  LiquidGlassPainter(
      {required this.shader, required this.time, required this.glowColor});

  @override
  void paint(Canvas canvas, Size size) {
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, time);
    shader.setFloat(
        3,
        glowColor
            .r); // usando le nuove API r g b invece delle deprecate red green blue
    shader.setFloat(4, glowColor.g);
    shader.setFloat(5, glowColor.b);

    final paint = Paint()..shader = shader;
    final rrect = RRect.fromRectAndCorners(
      Offset.zero & size,
      bottomLeft: const Radius.circular(38),
      bottomRight: const Radius.circular(38),
    );
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant LiquidGlassPainter oldDelegate) =>
      oldDelegate.time != time;
}
