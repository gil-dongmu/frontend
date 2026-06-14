import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../models/festival.dart';
import 'guidance_screen.dart';
import 'in_app_map_screen.dart';
import '../models/course.dart';
import '../services/kakao_navi_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/common.dart';
import '../widgets/festival_image.dart';

class NavigationScreen extends StatefulWidget {
  final Festival festival;
  const NavigationScreen({required this.festival});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  String mode = 'car'; // car/bus/walk
  bool optimized = false;
  bool launching = false;
  late List<RouteStop> stops;
  final _navi = KakaoNaviService();

  static const candidates = [
    (id: 'h1', name: '하연옥 본점', sub: '진주냉면 0.4km', type: RouteStopType.food),
    (id: 'h2', name: '진주성', sub: '관광지 0.6km', type: RouteStopType.spot),
    (id: 'h3', name: '국립진주박물관', sub: '관광지 0.5km', type: RouteStopType.spot),
    (id: 'h4', name: '동방호텔 진주', sub: '숙박 0.3km · ₩89,000', type: RouteStopType.stay),
  ];

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    stops = [
      RouteStop(
          id: 'origin',
          name: '현재 위치',
          sub: app.hasRealLocation ? '내 GPS 위치' : '진주시 본성동 (기본 위치)',
          type: RouteStopType.origin),
      RouteStop(
          id: widget.festival.contentId,
          name: widget.festival.name,
          sub: widget.festival.address,
          type: RouteStopType.festival,
          festival: widget.festival),
    ];
  }

  Color _color(RouteStopType t) => switch (t) {
        RouteStopType.origin => AppColors.ink,
        RouteStopType.festival => AppColors.vermilion,
        RouteStopType.food => AppColors.vermilion,
        RouteStopType.spot => AppColors.plum,
        RouteStopType.stay => AppColors.teal,
      };

  IconData _icon(RouteStopType t) => switch (t) {
        RouteStopType.origin => Icons.my_location,
        RouteStopType.festival => Icons.celebration,
        RouteStopType.food => Icons.restaurant,
        RouteStopType.spot => Icons.location_on,
        RouteStopType.stay => Icons.hotel,
      };

  @override
  Widget build(BuildContext context) {
    final dist = _dist;
    final dur = _dur;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: AppColors.ink)),
                  Expanded(child: Text('길 안내', style: AppType.display(size: 22))),
                  GestureDetector(
                    onTap: () => setState(() => optimized = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: optimized ? AppColors.teal : AppColors.ink,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(children: [
                        const Icon(Icons.auto_awesome,
                            size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(optimized ? '최적화됨' : '동선 최적화',
                            style: AppType.body(
                                size: 11,
                                weight: FontWeight.w700,
                                color: Colors.white)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
            // 지도
            Container(
              height: 200,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Positioned.fill(
                      child: CustomPaint(
                          painter: _RoutePainter(stops.length, _color))),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999)),
                      child: Row(children: [
                        _modeBtn('car', Icons.directions_car),
                        _modeBtn('bus', Icons.directions_bus),
                        _modeBtn('walk', Icons.directions_walk),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
            // 통계
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(children: [
                _navStat(dist.toStringAsFixed(1), 'km', '총 거리'),
                const SizedBox(width: 8),
                _navStat('$dur', '분', mode == 'car' ? '예상 소요' : '이동시간'),
                const SizedBox(width: 8),
                _navStat('${stops.length}', '곳', '경유지'),
              ]),
            ),
            // 경로 리스트
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                children: [
                  Row(children: [
                    Text('이동 경로', style: AppType.kicker()),
                    const Spacer(),
                    if (optimized) const GdmBadge('최적 순서', color: AppColors.teal),
                  ]),
                  const SizedBox(height: 10),
                  ...stops.asMap().entries.map((e) => _stopTile(e.key, e.value)),
                  _addTile(),
                ],
              ),
            ),
            // CTA
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: Column(
                children: [
                  // 메인: 인앱 내비게이션
                  GdmButton(
                    '길 안내 시작 · $dur분',
                    onTap: _startGuidance,
                    primary: true,
                    full: true,
                    icon: Icons.navigation,
                  ),
                  const SizedBox(height: 4),
                  // 보조: 실제 도로 경로가 필요할 때
                  TextButton(
                    onPressed: launching ? null : _openExternal,
                    child: Text(
                      launching ? '카카오맵 여는 중…' : '카카오맵에서 실제 경로 보기',
                      style: AppType.body(
                              size: 12,
                              weight: FontWeight.w600,
                              color: AppColors.muted)
                          .copyWith(decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeBtn(String m, IconData icon) {
    final on = mode == m;
    return GestureDetector(
      onTap: () => setState(() => mode = m),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
            color: on ? AppColors.ink : Colors.transparent,
            shape: BoxShape.circle),
        child: Icon(icon, size: 16, color: on ? Colors.white : AppColors.ink),
      ),
    );
  }

  Widget _navStat(String n, String unit, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic, children: [
              Text(n, style: AppType.display(size: 22)),
              const SizedBox(width: 2),
              Text(unit,
                  style: AppType.body(size: 11, weight: FontWeight.w600)),
            ]),
            const SizedBox(height: 4),
            Text(label, style: AppType.kicker().copyWith(letterSpacing: 0.8)),
          ],
        ),
      ),
    );
  }

  Widget _stopTile(int i, RouteStop s) {
    final isLast = i == stops.length - 1;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 16,
                height: 16,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: _color(s.type),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.cream, width: 2.5),
                ),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: AppColors.line)),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: s.festival != null
                          ? FestivalImage(festival: s.festival!)
                          : Container(
                              color: _color(s.type),
                              child: Icon(_icon(s.type),
                                  color: Colors.white, size: 20)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            s.type == RouteStopType.origin
                                ? '출발'
                                : '$i번째 경유지',
                            style: AppType.kicker().copyWith(letterSpacing: 1)),
                        const SizedBox(height: 2),
                        Text(s.name, style: AppType.display(size: 15)),
                        const SizedBox(height: 2),
                        Text(s.sub,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.body(
                                size: 11, color: AppColors.muted)),
                      ],
                    ),
                  ),
                  if (s.type != RouteStopType.origin &&
                      s.type != RouteStopType.festival)
                    IconButton(
                      onPressed: () =>
                          setState(() => stops.removeWhere((x) => x.id == s.id)),
                      icon: const Icon(Icons.close,
                          size: 14, color: AppColors.muted),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addTile() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 16,
          height: 16,
          margin: const EdgeInsets.only(top: 16, left: 0),
          decoration: BoxDecoration(
            color: AppColors.cream,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.muted, width: 1.5),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: GestureDetector(
            onTap: _openAddSheet,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.line,
                    width: 1.5,
                    style: BorderStyle.solid),
              ),
              child: Row(children: [
                const Icon(Icons.add, size: 16, color: AppColors.muted),
                const SizedBox(width: 8),
                Text('경유지 추가 (맛집 · 관광지 · 숙박)',
                    style: AppType.body(
                        size: 13,
                        weight: FontWeight.w600,
                        color: AppColors.muted)),
              ]),
            ),
          ),
        ),
      ],
    );
  }

  /// WebView를 쓸 수 있는 플랫폼(Android/iOS)인지
  static bool get _canInAppMap =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// 총 거리: 내 위치→축제 실거리 + 경유지당 가산
  double get _dist =>
      (widget.festival.distanceKm ?? 4.2) + (stops.length - 2) * 1.8;

  double get _speedKmh =>
      switch (mode) { 'car' => 70.0, 'bus' => 45.0, _ => 4.5 };

  int get _dur => (_dist / _speedKmh * 60).round().clamp(1, 5999);

  /// 인앱 내비 시작 — 외부 앱 없이 앱 안에서 주행 안내가 진행된다
  void _startGuidance() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GuidanceScreen(
          festival: widget.festival,
          stops: List.of(stops),
          distKm: _dist,
          durMin: _dur,
          mode: mode,
        ),
      ),
    );
  }

  /// 보조: 실제 지도 — 모바일은 인앱 카카오맵(WebView), 웹은 외부 호출
  Future<void> _openExternal() async {
    if (_canInAppMap) {
      if (widget.festival.lat == 0 || widget.festival.lng == 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AppColors.vermilion,
          content: Text('이 축제 좌표가 없어 안내가 불가합니다',
              style: AppType.body(size: 12, color: Colors.white)),
        ));
        return;
      }
      final app = context.read<AppState>();
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InAppMapScreen(
            festival: widget.festival,
            originLat: app.myLat,
            originLng: app.myLng,
            hasRealLocation: app.hasRealLocation,
          ),
        ),
      );
      return;
    }

    // 웹/데스크톱: 기존 외부 호출 흐름 (JS SDK → 딥링크 → 웹 폴백)
    setState(() => launching = true);
    KakaoNaviResult? result;
    try {
      result = await _navi.startToFestival(widget.festival);
    } finally {
      if (mounted) setState(() => launching = false);
    }
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(SnackBar(
      backgroundColor: switch (result) {
        KakaoNaviResult.jsSdk || KakaoNaviResult.appDeeplink => AppColors.teal,
        KakaoNaviResult.webFallback => AppColors.ink,
        _ => AppColors.vermilion,
      },
      content: Text(
        switch (result) {
          KakaoNaviResult.jsSdk => '카카오내비 SDK 호출됨 — 모바일 브라우저면 앱이 열려요',
          KakaoNaviResult.appDeeplink => '카카오내비 앱 실행',
          KakaoNaviResult.webFallback => '카카오맵 길찾기 페이지로 이동',
          KakaoNaviResult.invalidCoord => '이 축제 좌표가 없어 안내가 불가합니다',
          KakaoNaviResult.failed => '안내 시작 실패 — 카카오 키/네트워크 확인',
          null => '안내 시작 실패',
        },
        style: AppType.body(size: 12, color: Colors.white),
      ),
      duration: const Duration(seconds: 3),
    ));
  }

  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('주변 추천', style: AppType.display(size: 22)),
            const SizedBox(height: 4),
            Text('축제장 반경 1km 내',
                style: AppType.body(size: 12, color: AppColors.muted)),
            const SizedBox(height: 16),
            ...candidates.map((c) => GestureDetector(
                  onTap: () {
                    setState(() {
                      stops.insert(
                          stops.length - 1,
                          RouteStop(
                              id: c.id,
                              name: c.name,
                              sub: c.sub,
                              type: c.type));
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Row(children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                            color: _color(c.type),
                            borderRadius: BorderRadius.circular(10)),
                        child: Icon(_icon(c.type),
                            size: 18, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.name,
                                style: AppType.body(
                                    size: 14, weight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(c.sub,
                                style: AppType.body(
                                    size: 11, color: AppColors.muted)),
                          ],
                        ),
                      ),
                      const Icon(Icons.add, color: AppColors.vermilion),
                    ]),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  final int n;
  final Color Function(RouteStopType) colorOf;
  _RoutePainter(this.n, this.colorOf);

  @override
  void paint(Canvas canvas, Size size) {
    // 격자
    final grid = Paint()..color = AppColors.line.withValues(alpha: 0.5);
    for (double y = 0; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid..strokeWidth = 0.5);
    }
    for (double x = 0; x < size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid..strokeWidth = 0.5);
    }
    // 도로
    final road = Paint()
      ..color = const Color(0xFFE0D5C0)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke;
    final p = Path()
      ..moveTo(-20, size.height * 0.4)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.3,
          size.width * 0.55, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.8, size.height * 0.65,
          size.width + 20, size.height * 0.5);
    canvas.drawPath(p, road);

    // 경로 점
    final pts = List.generate(n, (i) {
      final x = 40 + (i / (n - 1).clamp(1, 99)) * (size.width - 80);
      final y = size.height * 0.5 + (i.isEven ? -18 : 18);
      return Offset(x, y);
    });
    final line = Paint()
      ..color = AppColors.vermilion
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    if (pts.length > 1) {
      final lp = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final pt in pts.skip(1)) {
        lp.lineTo(pt.dx, pt.dy);
      }
      canvas.drawPath(lp, line);
    }
    for (var i = 0; i < pts.length; i++) {
      final c = i == 0
          ? AppColors.ink
          : (i == pts.length - 1 ? AppColors.vermilion : AppColors.teal);
      canvas.drawCircle(pts[i], 9, Paint()..color = Colors.white);
      canvas.drawCircle(pts[i], 6, Paint()..color = c);
    }
  }

  @override
  bool shouldRepaint(covariant _RoutePainter old) => old.n != n;
}
