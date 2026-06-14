import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onDone;
  const SplashScreen({required this.onDone});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.vermilion,
      body: Stack(
        children: [
          // 배경 유등 패턴
          Positioned.fill(
            child: CustomPaint(painter: _LanternPainter()),
          ),
          Center(
            child: FadeTransition(
              opacity: _c,
              child: ScaleTransition(
                scale: Tween(begin: 0.95, end: 1.0).animate(
                  CurvedAnimation(parent: _c, curve: Curves.easeOutCubic),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('길\n동무',
                        textAlign: TextAlign.center,
                        style: AppType.display(size: 88, color: Colors.white)
                            .copyWith(height: 1.0)),
                    const SizedBox(height: 24),
                    Text('GilDongMu · 路東舞',
                        style: AppType.body(
                                size: 13,
                                weight: FontWeight.w600,
                                color: Colors.white)
                            .copyWith(letterSpacing: 3)),
                    const SizedBox(height: 8),
                    Text('지방축제 통합 내비게이션',
                        style: AppType.serif(size: 14, color: Colors.white70)),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Text('POWERED BY KOREA TOURISM OPENAPI',
                textAlign: TextAlign.center,
                style: AppType.body(
                        size: 10,
                        weight: FontWeight.w600,
                        color: Colors.white70)
                    .copyWith(letterSpacing: 2.5)),
          ),
        ],
      ),
    );
  }
}

class _LanternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()..color = AppColors.yellow.withValues(alpha: 0.18);
    final dot = Paint()..color = Colors.white.withValues(alpha: 0.18);
    var seed = 7;
    double rnd() {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      return (seed % 1000) / 1000;
    }

    for (var i = 0; i < 30; i++) {
      final x = rnd() * size.width;
      final y = rnd() * size.height;
      final r = 18 + rnd() * 22;
      canvas.drawCircle(Offset(x, y), r, glow);
      canvas.drawCircle(Offset(x, y - r / 3), r * 0.3, dot);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
