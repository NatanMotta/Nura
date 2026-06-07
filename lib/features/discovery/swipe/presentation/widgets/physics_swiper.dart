import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

enum SwipeDirection { left, right }

// ─── KineticSimdEngine ─────────────────────────────────────────────────────
/// Motore fisico SIMD a zero allocazioni.
/// Calcola posizione e velocità su 4 componenti (x, y, vx, vy) in parallelo
/// utilizzando Float32x4 che mappa direttamente sui registri NEON (ARM).
/// L'integrazione usa il metodo Semi-Implicito di Eulero per stabilità.
class KineticSimdEngine {
  Float32x4 _state = Float32x4.zero(); // x, y, vx, vy

  void reset(double x, double y, double vx, double vy) {
    _state = Float32x4(x, y, vx, vy);
  }

  /// Ritorna true quando la molla si è assestata (settled).
  /// dt viene sub-stepped internamente per evitare esplosioni numeriche.
  bool tick(double dt) {
    const double k = 420.0; // Stiffness
    const double c = 45.0; // Damping
    const double mass = 1.8;

    // Sub-stepping: se dt è grande, spezziamo in passi da max 4ms
    // per evitare l'esplosione numerica SENZA falsificare la simulazione.
    const double maxStep = 0.004;
    double remaining = dt;

    while (remaining > 0.0) {
      final step = remaining > maxStep ? maxStep : remaining;
      remaining -= step;

      final x = _state.x;
      final y = _state.y;
      final vx = _state.z;
      final vy = _state.w;

      // Semi-Implicit Euler: aggiorna velocità prima, poi posizione
      final ax = (-k * x - c * vx) / mass;
      final ay = (-k * y - c * vy) / mass;

      final nvx = vx + ax * step;
      final nvy = vy + ay * step;

      final nx = x + nvx * step;
      final ny = y + nvy * step;

      _state = Float32x4(nx, ny, nvx, nvy);
    }

    return _state.x.abs() < 0.0005 &&
        _state.y.abs() < 0.0005 &&
        _state.z.abs() < 0.5 &&
        _state.w.abs() < 0.5;
  }

  double get x => _state.x;
  double get y => _state.y;
}

// ─── PhysicsSwiper ─────────────────────────────────────────────────────────

class PhysicsSwiper extends StatefulWidget {
  final Widget child;
  final void Function(SwipeDirection direction) onSwipe;
  final void Function(double dx) onDragUpdate;
  final String? impulse;
  final double swipeThreshold;

  const PhysicsSwiper({
    super.key,
    required this.child,
    required this.onSwipe,
    required this.onDragUpdate,
    this.impulse,
    this.swipeThreshold = 0.65,
  });

  @override
  State<PhysicsSwiper> createState() => _PhysicsSwiperState();
}

class _PhysicsSwiperState extends State<PhysicsSwiper>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _controller;
  late Ticker _simdTicker;
  final KineticSimdEngine _simdEngine = KineticSimdEngine();
  double _timeAccumulator = 0.0;
  static const double _fixedTimeStep = 0.0166667; // 60Hz fissi
  Duration _lastSimdTick = Duration.zero;

  final ValueNotifier<Alignment> _dragAlignment =
      ValueNotifier<Alignment>(Alignment.center);
  Animation<Alignment>? _animation;

  bool _tensionHapticTriggered = false;
  bool _isDragging =
      false; // Lock: impedisce al Ticker di sovrascrivere durante il drag
  bool _isDisposed = false; // Guard: impedisce scritture post-dispose
  Offset _touchOrigin = Offset.zero;

  final DoubleBufferZeroAllocTransform _zeroAlloc =
      DoubleBufferZeroAllocTransform();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(vsync: this);
    _controller.addListener(() {
      if (_animation != null) {
        _dragAlignment.value = _animation!.value;
        widget.onDragUpdate(
            _dragAlignment.value.x * MediaQuery.of(context).size.width / 2);
      }
    });

    _simdTicker = createTicker(_onSimdTick);
  }

  @override
  void didUpdateWidget(PhysicsSwiper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.impulse != oldWidget.impulse && widget.impulse != null) {
      _isDragging = false;
      final direction = widget.impulse!.startsWith('like')
          ? SwipeDirection.right
          : SwipeDirection.left;
      _animateOffScreen(
        Offset(direction == SwipeDirection.right ? 2000.0 : -2000.0, 0),
        forcedDirection: direction,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isDisposed = true;
    _simdTicker.dispose();
    _controller.dispose();
    _dragAlignment.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      // PATCH: Se un alert di sistema o una chiamata rubano il focus,
      // sblocca forzatamente la pipeline per prevenire il soft brick.
      _isDragging = false;
      if (_simdTicker.isActive) _simdTicker.stop();
    } else if (state == AppLifecycleState.resumed && !_isDragging && _touchOrigin != Offset.zero) {
      // PATCH: Riavvia la simulazione fisica se l'app torna attiva e c'era un trascinamento in sospeso
      _runSpringSimulation(Offset.zero);
    }
  }

  void _onSimdTick(Duration elapsed) {
    // LOCK: Se l'utente sta trascinando, il Ticker NON deve toccare _dragAlignment.
    // Questo previene la race condition Ticker vs GestureDetector.
    if (_isDragging) {
      _simdTicker.stop();
      return;
    }

    if (_lastSimdTick == Duration.zero) {
      _lastSimdTick = elapsed;
      return;
    }
    double frameDelta = (elapsed - _lastSimdTick).inMicroseconds / 1000000.0;
    _lastSimdTick = elapsed;

    // Cappello massimo di sicurezza (spiral of death prevention)
    if (frameDelta > 0.25) {
      frameDelta = 0.25;
    }

    _timeAccumulator += frameDelta;
    bool settled = false;

    // Integrazione a passo fisso (Fix Your Timestep)
    while (_timeAccumulator >= _fixedTimeStep) {
      settled = _simdEngine.tick(_fixedTimeStep);
      _timeAccumulator -= _fixedTimeStep;
    }

    _dragAlignment.value = Alignment(_simdEngine.x, _simdEngine.y);
    widget.onDragUpdate(_simdEngine.x * MediaQuery.of(context).size.width / 2);

    if (settled) {
      _simdTicker.stop();
      _dragAlignment.value = Alignment.center;
      widget.onDragUpdate(0);
    }
  }

  void _onPanDown(DragDownDetails details) {
    _isDragging = true;
    if (_controller.isAnimating) _controller.stop();
    if (_simdTicker.isActive) _simdTicker.stop();

    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPos = box.globalToLocal(details.globalPosition);
    _touchOrigin = Offset(
        localPos.dx - box.size.width / 2, localPos.dy - box.size.height / 2);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final size = MediaQuery.of(context).size;
    _dragAlignment.value += Alignment(
      details.delta.dx / (size.width / 2),
      details.delta.dy / (size.height / 2),
    );
    widget.onDragUpdate(_dragAlignment.value.x * size.width / 2);

    if (_dragAlignment.value.x.abs() > widget.swipeThreshold &&
        !_tensionHapticTriggered) {
      HapticFeedback.heavyImpact();
      _tensionHapticTriggered = true;
    }
  }

  void _onPanEnd(DragEndDetails details) {
    _isDragging = false;
    _tensionHapticTriggered = false;
    final currentAlign = _dragAlignment.value;
    final velocityX = details.velocity.pixelsPerSecond.dx;
    final isEscaping = velocityX.abs() > 1000.0 ||
        currentAlign.x.abs() > widget.swipeThreshold;

    if (isEscaping) {
      HapticFeedback.mediumImpact();
      _animateOffScreen(details.velocity.pixelsPerSecond);
    } else {
      _runSpringSimulation(details.velocity.pixelsPerSecond);
    }
  }

  void _runSpringSimulation(Offset pixelsPerSecond) {
    final size = MediaQuery.of(context).size;
    final unitsPerSecondX = pixelsPerSecond.dx / size.width;
    final unitsPerSecondY = pixelsPerSecond.dy / size.height;

    _simdEngine.reset(
      _dragAlignment.value.x,
      _dragAlignment.value.y,
      unitsPerSecondX,
      unitsPerSecondY,
    );

    _lastSimdTick = Duration.zero;
    _timeAccumulator = 0.0;
    if (!_simdTicker.isActive) {
      _simdTicker.start();
    }
  }

  void _animateOffScreen(Offset pixelsPerSecond,
      {SwipeDirection? forcedDirection}) {
    if (_simdTicker.isActive) _simdTicker.stop();

    final currentAlign = _dragAlignment.value;
    double signX = currentAlign.x.sign;
    if (signX == 0) {
      if (forcedDirection != null) {
        signX = forcedDirection == SwipeDirection.right ? 1.0 : -1.0;
      } else {
        signX = pixelsPerSecond.dx.sign >= 0 ? 1.0 : -1.0;
      }
    }

    final endAlign = Alignment(
      signX * 2.5,
      currentAlign.y.sign * 2.5 + (pixelsPerSecond.dy.sign * 0.5),
    );

    _animation = _controller.drive(
      AlignmentTween(begin: currentAlign, end: endAlign),
    );

    final velocityX = pixelsPerSecond.dx.abs().clamp(100.0, 5000.0);
    final distance = (endAlign.x - currentAlign.x).abs() *
        MediaQuery.of(context).size.width /
        2;
    final durationSeconds = distance / velocityX;

    // Reset obbligatorio: se il controller era a 1.0 da un ciclo precedente,
    // forward() non farebbe nulla (è già al massimo).
    _controller.reset();
    _controller.duration =
        Duration(milliseconds: (durationSeconds * 1000).clamp(80, 200).toInt());
    _controller.forward().then((_) {
      // GUARD: il widget potrebbe essere stato smontato durante l'animazione
      // (nuova ValueKey dopo _decide). Senza questo check, scriveremmo
      // su un ValueNotifier già disposed → crash silenzioso o freeze.
      if (_isDisposed) return;
      final direction =
          endAlign.x > 0 ? SwipeDirection.right : SwipeDirection.left;
      widget.onSwipe(direction);
      if (!_isDisposed) {
        _dragAlignment.value = Alignment.center;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanDown: _onPanDown,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: ValueListenableBuilder<Alignment>(
        valueListenable: _dragAlignment,
        builder: (context, alignment, child) {
          final size = MediaQuery.of(context).size;
          final dx = alignment.x * (size.width / 2);
          final dy = alignment.y * (size.height / 2);
          final angle = alignment.x * 0.12;

          return Transform(
            transform:
                _zeroAlloc.computeKineticTransform(dx, dy, angle, _touchOrigin),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

// ─── LUT trigonometrica O(1) ───────────────────────────────────────────────

final Float64List _sinLUT = Float64List(4096);
final Float64List _cosLUT = Float64List(4096);
final double _radToIndex = 4096.0 / (2.0 * math.pi);
bool _lutInitialized = false;

void _initializeTrigLUT() {
  if (_lutInitialized) return;
  for (int i = 0; i < 4096; i++) {
    final angle = (i * 2.0 * math.pi) / 4096.0;
    _sinLUT[i] = math.sin(angle);
    _cosLUT[i] = math.cos(angle);
  }
  _lutInitialized = true;
}

double _fastSin(double radians) =>
    _sinLUT[(radians * _radToIndex).toInt() & 4095];

double _fastCos(double radians) =>
    _cosLUT[(radians * _radToIndex).toInt() & 4095];

// ─── DoubleBufferZeroAllocTransform ────────────────────────────────────────
/// FIX CHIRURGICO: Double Buffering per eludere il controllo identical()
/// di Flutter. Due buffer alternati costringono il framework a ridisegnare
/// ogni frame, eliminando lo "stuttering fantasma" causato dalla
/// riconciliazione referenziale.

class DoubleBufferZeroAllocTransform {
  final Float64List _storageA = Float64List(16);
  final Float64List _storageB = Float64List(16);
  late final Matrix4 matrixA;
  late final Matrix4 matrixB;
  bool _useA = true;

  DoubleBufferZeroAllocTransform() {
    _initializeTrigLUT();
    matrixA = Matrix4.fromFloat64List(_storageA);
    matrixB = Matrix4.fromFloat64List(_storageB);
    _resetToIdentity(_storageA);
    _resetToIdentity(_storageB);
  }

  void _resetToIdentity(Float64List s) {
    s[0] = 1;
    s[4] = 0;
    s[8] = 0;
    s[12] = 0;
    s[1] = 0;
    s[5] = 1;
    s[9] = 0;
    s[13] = 0;
    s[2] = 0;
    s[6] = 0;
    s[10] = 1;
    s[14] = 0;
    s[3] = 0;
    s[7] = 0;
    s[11] = 0;
    s[15] = 1;
  }

  Matrix4 computeKineticTransform(
      double dx, double dy, double angle, Offset origin) {
    // Alterna il buffer ad ogni frame → oggetto Matrix4 diverso → Flutter ridisegna
    _useA = !_useA;
    final s = _useA ? _storageA : _storageB;
    final m = _useA ? matrixA : matrixB;

    _resetToIdentity(s);
    final c = _fastCos(angle);
    final sin = _fastSin(angle);

    s[0] = c;
    s[1] = sin;
    s[4] = -sin;
    s[5] = c;

    final ox = origin.dx;
    final oy = origin.dy;
    s[12] = dx + ox - (c * ox - sin * oy);
    s[13] = dy + oy - (sin * ox + c * oy);

    return m;
  }
}
