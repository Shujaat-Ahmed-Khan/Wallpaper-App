import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../core/theme/dark_neon_theme.dart';

class GyroPreviewWidget extends StatefulWidget {
  final String backgroundUrl;
  final String foregroundUrl;
  final double maxBgShift;
  final double maxFgShift;

  const GyroPreviewWidget({
    super.key,
    required this.backgroundUrl,
    required this.foregroundUrl,
    this.maxBgShift = 30.0,
    this.maxFgShift = 60.0,
  });

  @override
  State<GyroPreviewWidget> createState() => _GyroPreviewWidgetState();
}

class _GyroPreviewWidgetState extends State<GyroPreviewWidget> {
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  double _pitch = 0.0;
  double _roll = 0.0;
  double _smoothPitch = 0.0;
  double _smoothRoll = 0.0;

  Timer? _animTimer;

  @override
  void initState() {
    super.initState();
    _startGyroStream();
    _startSmoothLoop();
  }

  void _startGyroStream() {
    try {
      _gyroSub = gyroscopeEventStream().listen(
        (GyroscopeEvent event) {
          // Accumulate tilt and clamp
          setState(() {
            _roll = (_roll + event.y * 0.05).clamp(-1.0, 1.0);
            _pitch = (_pitch + event.x * 0.05).clamp(-1.0, 1.0);
          });
        },
        onError: (_) {},
        cancelOnError: false,
      );
    } catch (_) {}
  }

  void _startSmoothLoop() {
    _animTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      const alpha = 0.15;
      if (mounted) {
        setState(() {
          _smoothPitch += alpha * (_pitch - _smoothPitch);
          _smoothRoll += alpha * (_roll - _smoothRoll);
        });
      }
    });
  }

  @override
  void dispose() {
    _gyroSub?.cancel();
    _animTimer?.cancel();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    // Touch parallax fallback for emulators & testing
    setState(() {
      _roll = (_roll + details.delta.dx * 0.01).clamp(-1.0, 1.0);
      _pitch = (_pitch + details.delta.dy * 0.01).clamp(-1.0, 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bgShiftX = -_smoothRoll * widget.maxBgShift;
    final bgShiftY = -_smoothPitch * widget.maxBgShift;

    final fgShiftX = _smoothRoll * widget.maxFgShift;
    final fgShiftY = _smoothPitch * widget.maxFgShift;

    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      child: ClipRRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Deep background color
            Container(color: DarkNeonTheme.scaffoldBackground),

            // Background Layer (Shifted in reverse)
            Transform.translate(
              offset: Offset(bgShiftX, bgShiftY),
              child: Transform.scale(
                scale: 1.25,
                child: CachedNetworkImage(
                  imageUrl: widget.backgroundUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const Center(
                    child: CircularProgressIndicator(color: DarkNeonTheme.primaryNeon),
                  ),
                  errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white30),
                ),
              ),
            ),

            // Foreground Layer (Shifted forward with glowing pop-out)
            Transform.translate(
              offset: Offset(fgShiftX, fgShiftY),
              child: Transform.scale(
                scale: 1.08,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: widget.foregroundUrl,
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const SizedBox.shrink(),
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),

            // 3D Gyro HUD Indicator
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: DarkNeonTheme.cardSurface.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: DarkNeonTheme.primaryNeon.withOpacity(0.7)),
                  boxShadow: DarkNeonTheme.neonGlow(DarkNeonTheme.primaryNeon, blur: 8, opacity: 0.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.screen_rotation, color: DarkNeonTheme.primaryNeon, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'TILT DEVICE OR DRAG',
                      style: TextStyle(
                        color: DarkNeonTheme.primaryNeon,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
