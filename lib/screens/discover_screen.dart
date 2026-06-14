import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../providers/app_state.dart';
import '../models/festival.dart';
import '../data/mock_festivals.dart';
import '../services/api_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/common.dart';
import '../widgets/festival_cards.dart';
import '../widgets/festival_image.dart';

enum DiscoverView { list, map, calendar }

class DiscoverScreen extends StatefulWidget {
  final void Function(Festival) onOpenFest;
  const DiscoverScreen({required this.onOpenFest});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  DiscoverView view = DiscoverView.list;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final list = app.filtered;

    return Column(
      children: [
        // 헤더
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: Text('탐색', style: AppType.display(size: 32))),
              RichText(
                text: TextSpan(children: [
                  TextSpan(
                      text: '${list.length}',
                      style: AppType.display(size: 16, color: AppColors.vermilion)),
                  TextSpan(
                      text: '개 축제',
                      style: AppType.body(
                          size: 11,
                          weight: FontWeight.w600,
                          color: AppColors.muted)),
                ]),
              ),
            ],
          ),
        ),
        // 뷰 토글 + 필터
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    _viewBtn(DiscoverView.list, Icons.view_agenda_outlined, '리스트'),
                    _viewBtn(DiscoverView.map, Icons.map_outlined, '지도'),
                    _viewBtn(DiscoverView.calendar, Icons.calendar_today_outlined, '캘린더'),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _openFilter(context, app),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.tune, size: 14, color: AppColors.cream),
                      const SizedBox(width: 6),
                      Text('필터',
                          style: AppType.body(
                              size: 12,
                              weight: FontWeight.w700,
                              color: AppColors.cream)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // 테마 칩
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: kThemes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => GdmChip(
              label: kThemes[i].name,
              leading: kThemes[i].icon,
              active: app.themeFilter == kThemes[i].id,
              onTap: () => app.setTheme(kThemes[i].id),
            ),
          ),
        ),
        // 가중치 토글 후 효과를 한 줄로 보여주는 배너
        if (app.declineBoost && app.boostedCount > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(children: [
              const Icon(Icons.trending_up, size: 13, color: AppColors.teal),
              const SizedBox(width: 5),
              Text(
                  '지역 가중치 적용 중 — 인구감소지역 축제 ${app.boostedCount}개 순위 상승',
                  style: AppType.body(
                      size: 11,
                      weight: FontWeight.w600,
                      color: AppColors.teal)),
            ]),
          ),
        const SizedBox(height: 8),
        Expanded(child: _content(list, app)),
      ],
    );
  }

  Widget _viewBtn(DiscoverView v, IconData icon, String label) {
    final on = view == v;
    return GestureDetector(
      onTap: () => setState(() => view = v),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: on ? AppColors.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: on ? AppColors.cream : AppColors.inkSoft),
            const SizedBox(width: 4),
            Text(label,
                style: AppType.body(
                    size: 12,
                    weight: FontWeight.w700,
                    color: on ? AppColors.cream : AppColors.inkSoft)),
          ],
        ),
      ),
    );
  }

  Widget _content(List<Festival> list, AppState app) {
    switch (view) {
      case DiscoverView.list:
        if (list.isEmpty) {
          return const GdmEmptyState(
              title: '조건에 맞는 축제가 없어요',
              subtitle: '테마·지역 필터를 조정해 보세요');
        }
        // 당겨서 새로고침 + 가중치 토글 시 크로스페이드
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: RefreshIndicator(
            key: ValueKey(app.declineBoost),
            color: AppColors.vermilion,
            onRefresh: app.bootstrap,
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (_, i) => FestivalRow(
                festival: list[i],
                rank: i + 1,
                onTap: () => widget.onOpenFest(list[i]),
              ),
            ),
          ),
        );
      case DiscoverView.map:
        return _MapView(list: list, onOpenFest: widget.onOpenFest);
      case DiscoverView.calendar:
        return _CalendarView(list: list, onOpenFest: widget.onOpenFest);
    }
  }

  void _openFilter(BuildContext context, AppState app) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cream,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _FilterSheet(app: app),
    );
  }
}

// ── 지도 뷰 ───────────────────────────────────────────────
class _MapView extends StatefulWidget {
  final List<Festival> list;
  final void Function(Festival) onOpenFest;
  const _MapView({required this.list, required this.onOpenFest});

  @override
  State<_MapView> createState() => _MapViewState();
}

class _MapViewState extends State<_MapView> {
  Festival? selected;

  @override
  Widget build(BuildContext context) {
    // 구글맵 키가 없으면 안내 + 핀 일러스트로 폴백
    if (ApiConfig.googleMapsKey.isEmpty) {
      return _MapFallback(list: widget.list, onOpenFest: widget.onOpenFest);
    }
    final markers = widget.list
        .where((f) => f.lat != 0)
        .map((f) => Marker(
              markerId: MarkerId(f.contentId),
              position: LatLng(f.lat, f.lng),
              onTap: () => setState(() => selected = f),
            ))
        .toSet();

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: LatLng(36.0, 127.8),
            zoom: 6.4,
          ),
          markers: markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
        ),
        if (selected != null)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: _MapCard(
                festival: selected!,
                onTap: () => widget.onOpenFest(selected!),
                onClose: () => setState(() => selected = null)),
          ),
      ],
    );
  }
}

/// 구글맵 키 미설정 시 — 스타일라이즈된 지도 핀 폴백
class _MapFallback extends StatefulWidget {
  final List<Festival> list;
  final void Function(Festival) onOpenFest;
  const _MapFallback({required this.list, required this.onOpenFest});

  @override
  State<_MapFallback> createState() => _MapFallbackState();
}

class _MapFallbackState extends State<_MapFallback> {
  Festival? selected;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CustomPaint(
                painter: _KoreaPinPainter(widget.list),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
        Positioned(
          top: 28,
          left: 28,
          right: 28,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.yellow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '구글맵 키(GOOGLE_MAPS_KEY) 설정 시 실제 지도가 표시됩니다',
              style: AppType.body(size: 11, weight: FontWeight.w600),
            ),
          ),
        ),
        // 리스트로 핀 탭 대체
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.list.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => SizedBox(
                width: 280,
                child: _MapCard(
                  festival: widget.list[i],
                  onTap: () => widget.onOpenFest(widget.list[i]),
                  onClose: null,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _KoreaPinPainter extends CustomPainter {
  final List<Festival> list;
  _KoreaPinPainter(this.list);
  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint()..color = AppColors.line.withValues(alpha: 0.6);
    for (double y = 16; y < size.height; y += 18) {
      for (double x = 16; x < size.width; x += 18) {
        canvas.drawCircle(Offset(x, y), 0.8, dot);
      }
    }
    // 위경도 → 화면 좌표
    for (final f in list) {
      if (f.lat == 0) continue;
      final x = ((f.lng - 124.5) / (131 - 124.5)) * size.width;
      final y = ((38.7 - f.lat) / (38.7 - 33)) * size.height;
      final c = AppColors.forTheme(f.theme);
      canvas.drawCircle(Offset(x, y), 11, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(x, y), 8, Paint()..color = c);
      canvas.drawCircle(Offset(x, y), 3, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapCard extends StatelessWidget {
  final Festival festival;
  final VoidCallback onTap;
  final VoidCallback? onClose;
  const _MapCard({required this.festival, required this.onTap, this.onClose});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 6)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            SizedBox(
                width: 88, height: 88, child: FestivalImage(festival: festival)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(festival.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.display(size: 15)),
                    const SizedBox(height: 2),
                    MetaLine([
                      '${festival.region} ${festival.city}',
                      if (festival.distanceKm != null)
                        '${festival.distanceKm!.toStringAsFixed(1)}km',
                    ]),
                    const SizedBox(height: 4),
                    Text(festival.periodLabel,
                        style: AppType.body(
                            size: 11,
                            weight: FontWeight.w600,
                            color: AppColors.muted)),
                  ],
                ),
              ),
            ),
            if (onClose != null)
              IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close,
                      size: 16, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

// ── 캘린더 뷰 ─────────────────────────────────────────────
class _CalendarView extends StatefulWidget {
  final List<Festival> list;
  final void Function(Festival) onOpenFest;
  const _CalendarView({required this.list, required this.onOpenFest});

  @override
  State<_CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<_CalendarView> {
  late int year;
  late int month;
  late int selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    year = now.year;
    month = now.month;
    selectedDay = now.day;
  }

  /// 월 이동 — 연도 경계를 넘어가며, 선택일은 말일로 클램프
  void _moveMonth(int delta) {
    setState(() {
      final m = DateTime(year, month + delta);
      year = m.year;
      month = m.month;
      final last = DateTime(year, month + 1, 0).day;
      if (selectedDay > last) selectedDay = last;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 해당 연·월에 진행되는 축제 → 날짜별 매핑 (연도까지 비교)
    final monthStart = DateTime(year, month, 1);
    final monthEnd = DateTime(year, month + 1, 0);
    final byDay = <int, List<Festival>>{};
    for (final f in widget.list) {
      if (f.start == null || f.end == null) continue;
      if (f.end!.isBefore(monthStart) || f.start!.isAfter(monthEnd)) continue;
      final s = f.start!.isBefore(monthStart) ? 1 : f.start!.day;
      final e = f.end!.isAfter(monthEnd) ? monthEnd.day : f.end!.day;
      for (var d = s; d <= e; d++) {
        byDay.putIfAbsent(d, () => []).add(f);
      }
    }

    const monthNames = ['', '1월', '2월', '3월', '4월', '5월', '6월', '7월', '8월', '9월', '10월', '11월', '12월'];
    final firstDow = monthStart.weekday % 7; // 0=일
    final daysInMonth = monthEnd.day;
    final selFests = byDay[selectedDay] ?? [];

    return ListView(
      children: [
        // 월 이동
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                  onPressed: () => _moveMonth(-1),
                  icon: const Icon(Icons.chevron_left, color: AppColors.ink)),
              Text('$year · ${monthNames[month]}',
                  style: AppType.display(size: 22)),
              IconButton(
                  onPressed: () => _moveMonth(1),
                  icon: const Icon(Icons.chevron_right, color: AppColors.ink)),
            ],
          ),
        ),
        // 요일
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: ['일', '월', '화', '수', '목', '금', '토']
                .asMap()
                .entries
                .map((e) => Expanded(
                      child: Center(
                        child: Text(e.value,
                            style: AppType.body(
                                size: 11,
                                weight: FontWeight.w700,
                                color: e.key == 0
                                    ? AppColors.vermilion
                                    : AppColors.muted)),
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 4),
        // 날짜 그리드
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 0.92,
            ),
            itemCount: firstDow + daysInMonth,
            itemBuilder: (_, i) {
              if (i < firstDow) return const SizedBox();
              final d = i - firstDow + 1;
              final has = byDay[d];
              final sel = selectedDay == d;
              final dow = i % 7;
              return GestureDetector(
                onTap: has != null ? () => setState(() => selectedDay = d) : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: sel
                        ? AppColors.ink
                        : (has != null ? AppColors.paper : Colors.transparent),
                    borderRadius: BorderRadius.circular(8),
                    border: has != null && !sel
                        ? Border.all(color: AppColors.line)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$d',
                          style: AppType.display(
                              size: 15,
                              color: sel
                                  ? AppColors.cream
                                  : (dow == 0
                                      ? AppColors.vermilion
                                      : AppColors.ink))),
                      if (has != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: has.take(3).map((f) {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: sel
                                    ? AppColors.yellow
                                    : AppColors.forTheme(f.theme),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SectionHeader(
            kicker: '${monthNames[month]} $selectedDay일',
            title: '이 날 ${selFests.length}개 축제'),
        ...selFests.map((f) =>
            FestivalRow(festival: f, onTap: () => widget.onOpenFest(f))),
        if (selFests.isEmpty)
          const GdmEmptyState(
              title: '이 날 진행되는 축제가 없어요',
              subtitle: '점이 표시된 날짜를 선택해 보세요',
              size: 72),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ── 필터 시트 ─────────────────────────────────────────────
class _FilterSheet extends StatefulWidget {
  final AppState app;
  const _FilterSheet({required this.app});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: AppColors.line, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('필터', style: AppType.display(size: 24)),
                TextButton(
                  onPressed: () {
                    app.resetFilters();
                    setState(() {});
                  },
                  child: Text('초기화',
                      style: AppType.body(
                          size: 12,
                          weight: FontWeight.w700,
                          color: AppColors.vermilion)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('테마', style: AppType.kicker()),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: kThemes
                      .map((t) => GdmChip(
                            label: t.name,
                            leading: t.icon,
                            active: app.themeFilter == t.id,
                            onTap: () {
                              app.setTheme(t.id);
                              setState(() {});
                            },
                          ))
                      .toList(),
                ),
                const SizedBox(height: 24),
                Text('지역', style: AppType.kicker()),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: kRegions
                      .map((r) => GdmChip(
                            label: r,
                            active: app.regionFilter == r,
                            onTap: () {
                              app.setRegion(r);
                              setState(() {});
                            },
                          ))
                      .toList(),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('인구감소지역 가산점',
                                style: AppType.display(size: 14)),
                            const SizedBox(height: 2),
                            Text('89개 시군구 축제 우선 노출',
                                style: AppType.body(
                                    size: 11, color: AppColors.muted)),
                          ],
                        ),
                      ),
                      Switch(
                        value: app.declineBoost,
                        activeColor: AppColors.vermilion,
                        onChanged: (v) {
                          app.setDeclineBoost(v);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                GdmButton('적용하기',
                    primary: true,
                    full: true,
                    onTap: () => Navigator.pop(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
