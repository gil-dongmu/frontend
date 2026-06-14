import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/course.dart';
import '../models/festival.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/common.dart';

/// 인앱 주행 내비게이션 — 외부 앱 없이 앱 안에서 길안내가 진행된다.
///
/// 실제 도로 데이터 없이 경유지 단위로 안내하는 데모 주행:
/// 경로 애니메이션 + 남은 거리/시간 + 다음 목적지 안내 + 도착 연출.
class GuidanceScreen extends StatefulWidget {
  final Festival festival;
  final List<RouteStop> stops;
  final double distKm;
  final int durMin;
  final String mode; // car / bus / walk

  const GuidanceScreen({
    super.key,
    required this.festival,
    required this.stops,
    required this.distKm,
    required this.durMin,
    required this.mode,
  });

  @override
  State<GuidanceScreen> createState() => _GuidanceScreenState();
}

class _GuidanceScreenState extends State<GuidanceScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 30),
  )
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        setState(() => arrived = true);
      }
    })
    ..forward();

  bool arrived = false;

  int get _segCount => math.max(1, widget.stops.length - 1);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  IconData get _modeIcon => switch (widget.mode) {
        'car' => Icons.directions_car,
        'bus' => Icons.directions_bus,
        _ => Icons.directions_walk,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;
            final remainKm = widget.distKm * (1 - t);
            final remainMin = (widget.durMin * (1 - t)).ceil();
            final eta = DateTime.now().add(Duration(minutes: remainMin));
            final segF = (t * _segCount).clamp(0.0, _segCount - 0.0001);
            final segIdx = segF.floor();
            final nextStop =
                widget.stops[math.min(segIdx + 1, widget.stops.length - 1)];
            final segLen = widget.distKm / _segCount;
            final segRemainKm = ((segIdx + 1) - segF) * segLen;

            return Stack(
              children: [
                Column(
                  children: [
                    // ── 상단: 남은 시간/거리/도착 예정 ─────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Icon(_modeIcon,
                                      size: 14, color: AppColors.yellow),
                                  const SizedBox(width: 6),
                                  Text('길동무 내비 · 데모 주행',
                                      style:
                                          AppType.kicker(color: AppColors.yellow)
                                              .copyWith(letterSpacing: 1.6)),
                                ]),
                                const SizedBox(height: 8),
                                RichText(
                                  text: TextSpan(children: [
                                    TextSpan(
                                        text: '$remainMin',
                                        style: AppType.display(
                                            size: 52, color: AppColors.cream)),
                                    TextSpan(
                                        text: ' 분',
                                        style: AppType.display(
                                            size: 22, color: AppColors.cream)),
                                    TextSpan(
                                        text:
                                            '   ${remainKm.toStringAsFixed(1)}km',
                                        style: AppType.body(
                                            size: 15,
                                            weight: FontWeight.w600,
                                            color: Colors.white70)),
                                  ]),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                    '도착 예정 ${eta.hour.toString().padLeft(2, '0')}:${eta.minute.toString().padLeft(2, '0')}',
                                    style: AppType.body(
                                        size: 12, color: Colors.white54)),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: '안내 종료',
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close,
                                color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    // ── 중앙: 경로 지도 ────────────────────────────
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: CustomPaint(
                            painter: _GuidePainter(
                              stops: widget.stops,
                              t: t,
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                    ),
                    // ── 하단: 다음 안내 + 진행 바 + 컨트롤 ─────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      child: Column(
                        children: [
                          // 다음 목적지 카드
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.vermilion,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(12)),
                                  child: const Icon(Icons.turn_right,
                                      color: Colors.white, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          segIdx == _segCount - 1
                                              ? '목적지'
                                              : '다음 경유지',
                                          style: AppType.kicker(
                                                  color: Colors.white70)
                                              .copyWith(letterSpacing: 1.2)),
                                      const SizedBox(height: 2),
                                      Text(nextStop.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppType.display(
                                              size: 18, color: Colors.white)),
                                    ],
                                  ),
                                ),
                                Text(
                                    segRemainKm < 1
                                        ? '${(segRemainKm * 1000).round()}m'
                                        : '${segRemainKm.toStringAsFixed(1)}km',
                                    style: AppType.display(
                                        size: 20, color: AppColors.yellow)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // 전체 진행 바
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: t,
                              minHeight: 5,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.12),
                              valueColor: const AlwaysStoppedAnimation(
                                  AppColors.yellow),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // 컨트롤
                          Row(
                            children: [
                              Expanded(
                                child: _ctrlBtn(
                                  _c.isAnimating ? Icons.pause : Icons.play_arrow,
                                  _c.isAnimating ? '일시정지' : '재생',
                                  () => setState(() => _c.isAnimating
                                      ? _c.stop()
                                      : _c.forward()),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _ctrlBtn(
                                  Icons.fast_forward,
                                  '바로 도착',
                                  () => _c.animateTo(1,
                                      duration:
                                          const Duration(milliseconds: 600)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // ── 도착 오버레이 ─────────────────────────────────
                if (arrived) _arrivedOverlay(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _ctrlBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(label,
                style: AppType.body(
                    size: 13, weight: FontWeight.w700, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _arrivedOverlay() {
    return Positioned.fill(
      child: Container(
        color: AppColors.ink.withValues(alpha: 0.88),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const GdmStamp('도착', size: 84, rotate: -6),
              const SizedBox(height: 24),
              Text(widget.festival.name,
                  textAlign: TextAlign.center,
                  style: AppType.display(size: 26, color: AppColors.cream)),
              const SizedBox(height: 8),
              Text('축제장에 도착했어요! 즐거운 시간 보내세요 🏮',
                  style: AppType.serif(size: 13, color: Colors.white70)),
              const SizedBox(height: 28),
              SizedBox(
                width: 200,
                child: GdmButton('안내 종료',
                    primary: true,
                    full: true,
                    onTap: () => Navigator.pop(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 주행 경로 캔버스 — 경유지 지점 + 진행된 경로(주홍) + 이동 마커
class _GuidePainter extends CustomPainter {
  final List<RouteStop> stops;
  final double t;
  _GuidePainter({required this.stops, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    // 배경 격자 점
    final dotBg = Paint()..color = Colors.white.withValues(alpha: 0.06);
    for (double y = 14; y < size.height; y += 22) {
      for (double x = 14; x < size.width; x += 22) {
        canvas.drawCircle(Offset(x, y), 1, dotBg);
      }
    }

    // 경유지 좌표 (아래 → 위, 좌우로 굽이치는 경로)
    final n = math.max(2, stops.length);
    final pts = List.generate(n, (i) {
      final f = i / (n - 1);
      final x = size.width * (0.5 + 0.26 * math.sin(i * 2.1 + 0.7));
      final y = size.height * (0.88 - 0.76 * f);
      return Offset(x, y);
    });

    // 부드러운 경로 path
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final prev = pts[i - 1];
      final cur = pts[i];
      final mid = Offset((prev.dx + cur.dx) / 2, (prev.dy + cur.dy) / 2);
      path.quadraticBezierTo(prev.dx, prev.dy, mid.dx, mid.dy);
    }
    path.lineTo(pts.last.dx, pts.last.dy);

    // 전체 도로 (희미하게)
    canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.14)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round);

    // 진행된 경로 (주홍) + 마커 위치
    final metrics = path.computeMetrics().toList();
    if (metrics.isNotEmpty) {
      final m = metrics.first;
      final traveled = m.extractPath(0, m.length * t);
      canvas.drawPath(
          traveled,
          Paint()
            ..color = AppColors.vermilion
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5
            ..strokeCap = StrokeCap.round);

      // 경유지 점
      for (var i = 0; i < pts.length; i++) {
        final isOrigin = i == 0;
        final isDest = i == pts.length - 1;
        final c = isOrigin
            ? Colors.white
            : isDest
                ? AppColors.vermilion
                : AppColors.teal;
        if (isDest) {
          // 목적지 글로우
          canvas.drawCircle(pts[i], 16,
              Paint()..color = AppColors.vermilion.withValues(alpha: 0.25));
        }
        canvas.drawCircle(pts[i], 8, Paint()..color = AppColors.ink);
        canvas.drawCircle(pts[i], 6, Paint()..color = c);
      }

      // 이동 마커 (방향 화살표)
      final tangent = m.getTangentForOffset(m.length * t);
      if (tangent != null) {
        final p = tangent.position;
        canvas.drawCircle(p, 13, Paint()..color = Colors.white);
        canvas.drawCircle(p, 10, Paint()..color = AppColors.vermilion);
        canvas.save();
        canvas.translate(p.dx, p.dy);
        canvas.rotate(tangent.angle * -1 + math.pi / 2);
        final arrow = Path()
          ..moveTo(0, -5)
          ..lineTo(4, 3)
          ..lineTo(-4, 3)
          ..close();
        canvas.drawPath(arrow, Paint()..color = Colors.white);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GuidePainter old) =>
      old.t != t || old.stops.length != stops.length;
}
