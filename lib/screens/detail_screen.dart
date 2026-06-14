import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/app_state.dart';
import '../models/festival.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/common.dart';
import '../widgets/festival_image.dart';
import 'navigation_screen.dart';
import 'course_screen.dart';

class DetailScreen extends StatefulWidget {
  final Festival festival;
  const DetailScreen({required this.festival});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  late Festival fest;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    fest = widget.festival;
    // 상세 보강 (API 키 있을 때만 실제 호출)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final enriched = await context.read<AppState>().detail(fest);
      if (mounted) setState(() => fest = enriched);
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final saved = app.isSaved(fest);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          // 히어로
          SizedBox(
            height: 300,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: 'fest-hero-${fest.contentId}',
                  child: FestivalImage(festival: fest),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black38, Colors.transparent, Colors.black54],
                      stops: [0, 0.35, 1],
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _circleBtn(Icons.arrow_back, () => Navigator.pop(context)),
                        Row(
                          children: [
                            _circleBtn(
                                saved ? Icons.bookmark : Icons.bookmark_border,
                                () => app.toggleSave(fest),
                                color: saved ? AppColors.vermilion : AppColors.ink),
                            const SizedBox(width: 8),
                            _circleBtn(Icons.share_outlined, _share),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (fest.isDeclineRegion) ...[
                        const GdmBadge('지역활성화 추천', color: AppColors.teal),
                        const SizedBox(height: 8),
                      ],
                      Text(fest.name,
                          style: AppType.display(size: 30, color: Colors.white)),
                      if (fest.tagline.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text('"${fest.tagline}"',
                            style: AppType.serif(size: 13, color: Colors.white)),
                      ],
                    ],
                  ),
                ),
                if (fest.start != null)
                  Positioned(
                    top: 70,
                    right: 20,
                    child: GdmStamp(
                        '${fest.start!.month}/\n${fest.start!.day}',
                        size: 56),
                  ),
              ],
            ),
          ),
          // 메타 카드
          Transform.translate(
            offset: const Offset(0, -20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  children: [
                    Row(children: [
                      _stat(Icons.calendar_today, '기간', fest.periodLabel),
                      _stat(Icons.access_time, '운영',
                          fest.hours.isEmpty ? '10:00–22:00' : fest.hours),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      _stat(Icons.location_on, '위치', '${fest.region} ${fest.city}'),
                      _stat(Icons.confirmation_num, '입장',
                          fest.fee.isEmpty ? '정보 없음' : fest.fee.split('/').first),
                    ]),
                  ],
                ),
              ),
            ),
          ),
          // CTA
          Transform.translate(
            offset: const Offset(0, -8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: GdmButton('길 안내',
                        primary: true,
                        icon: Icons.route,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => NavigationScreen(festival: fest)))),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GdmButton('코스 만들기',
                        dark: true,
                        icon: Icons.auto_fix_high,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => CourseScreen(festival: fest)))),
                  ),
                ],
              ),
            ),
          ),
          // 탭
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: TabBar(
              controller: _tab,
              labelColor: AppColors.ink,
              unselectedLabelColor: AppColors.muted,
              indicatorColor: AppColors.vermilion,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: AppType.body(size: 13, weight: FontWeight.w700),
              tabs: const [
                Tab(text: '소개'),
                Tab(text: '프로그램'),
                Tab(text: '갤러리'),
                Tab(text: '주변'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _OverviewTab(fest: fest),
                _ProgramsTab(fest: fest),
                _GalleryTab(fest: fest),
                _AroundTab(
                    fest: fest,
                    onCourse: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => CourseScreen(festival: fest)))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 축제 정보 공유 — 네이티브 공유 시트, 실패 시 클립보드 복사 폴백
  Future<void> _share() async {
    final text = '🏮 ${fest.name}\n'
        '${fest.periodLabel} · ${fest.region} ${fest.city}\n'
        '${fest.address}\n\n'
        '#길동무 #지방축제';
    try {
      await Share.share(text, subject: fest.name);
    } catch (_) {
      try {
        await Clipboard.setData(ClipboardData(text: text));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AppColors.ink,
          content: Text('축제 정보가 클립보드에 복사됐어요',
              style: AppType.body(size: 12, color: Colors.white)),
        ));
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AppColors.vermilion,
          content: Text('이 환경에서는 공유를 지원하지 않아요',
              style: AppType.body(size: 12, color: Colors.white)),
        ));
      }
    }
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap, {Color color = AppColors.ink}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Widget _stat(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 11, color: AppColors.vermilion),
            const SizedBox(width: 4),
            Text(label, style: AppType.kicker().copyWith(letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 4),
          Text(value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppType.body(size: 13, weight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final Festival fest;
  const _OverviewTab({required this.fest});

  @override
  Widget build(BuildContext context) {
    final ov = fest.overview.isEmpty ? '축제 상세 정보를 불러오는 중입니다.' : fest.overview;
    final days = (fest.start != null && fest.end != null)
        ? fest.end!.difference(fest.start!).inDays + 1
        : 0;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(ov, style: AppType.body(size: 14, height: 1.65)),
        const SizedBox(height: 24),
        // 통계 카드
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: AppColors.ink, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('축제 한눈에 보기',
                  style: AppType.kicker(color: AppColors.yellow)
                      .copyWith(letterSpacing: 1.8)),
              const SizedBox(height: 14),
              Row(children: [
                _bigStat(fest.visitors.replaceAll('약 ', ''), '지난해 방문객'),
                _bigStat(
                    fest.distanceKm != null
                        ? '${fest.distanceKm!.toStringAsFixed(0)}km'
                        : '—',
                    '내 위치에서'),
              ]),
              const SizedBox(height: 18),
              Row(children: [
                _bigStat('${fest.programs.length}개', '주요 프로그램'),
                _bigStat(days > 0 ? '$days일' : '상시', '총 기간'),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('테마', style: AppType.kicker()),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: (fest.themes.isEmpty ? [fest.theme] : fest.themes)
              .map((t) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Text('# $t',
                        style: AppType.body(
                            size: 11,
                            weight: FontWeight.w600,
                            color: AppColors.inkSoft)),
                  ))
              .toList(),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: AppColors.vermilion),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(fest.address,
                      style: AppType.body(size: 13, weight: FontWeight.w600))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bigStat(String n, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(n,
              style: AppType.display(size: 30, color: AppColors.yellow)
                  .copyWith(height: 1)),
          const SizedBox(height: 4),
          Text(label, style: AppType.body(size: 11, color: Colors.white70)),
        ],
      ),
    );
  }
}

class _ProgramsTab extends StatelessWidget {
  final Festival fest;
  const _ProgramsTab({required this.fest});

  @override
  Widget build(BuildContext context) {
    if (fest.programs.isEmpty) {
      return Center(
          child: Text('프로그램 정보가 없습니다',
              style: AppType.body(size: 13, color: AppColors.muted)));
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('주요 프로그램', style: AppType.kicker()),
        const SizedBox(height: 16),
        ...fest.programs.asMap().entries.map((e) {
          final i = e.key;
          final p = e.value;
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: i == 0 ? AppColors.vermilion : AppColors.cream,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.ink, width: 2.5),
                      ),
                    ),
                    if (i < fest.programs.length - 1)
                      Expanded(
                          child: Container(
                              width: 2, color: AppColors.line)),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(p.time,
                              style: AppType.display(
                                  size: 18, color: AppColors.vermilion)),
                          if (i == 0) ...[
                            const SizedBox(width: 10),
                            const GdmBadge('NOW', color: AppColors.ink),
                          ],
                        ]),
                        const SizedBox(height: 4),
                        Text(p.name, style: AppType.display(size: 15)),
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.location_on,
                              size: 11, color: AppColors.muted),
                          const SizedBox(width: 4),
                          Text(p.location,
                              style: AppType.body(
                                  size: 11, color: AppColors.muted)),
                        ]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _GalleryTab extends StatelessWidget {
  final Festival fest;
  const _GalleryTab({required this.fest});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: const EdgeInsets.all(20),
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: List.generate(6, (i) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: FestivalImage(festival: fest),
        );
      }),
    );
  }
}

class _AroundTab extends StatelessWidget {
  final Festival fest;
  final VoidCallback onCourse;
  const _AroundTab({required this.fest, required this.onCourse});

  @override
  Widget build(BuildContext context) {
    final cats = [
      (icon: Icons.restaurant, label: '맛집', color: AppColors.vermilion,
          items: fest.nearby.where((_) => true).take(2).toList()),
      (icon: Icons.location_on, label: '관광지', color: AppColors.plum,
          items: fest.nearby.take(3).toList()),
    ];
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        GestureDetector(
          onTap: onCourse,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: AppColors.vermilion,
                borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI 자동 코스',
                    style: AppType.kicker(color: AppColors.yellow)
                        .copyWith(letterSpacing: 1.8)),
                const SizedBox(height: 6),
                Text('이 축제 + 주변\n1박 2일 코스 만들기',
                    style: AppType.display(size: 20, color: Colors.white)),
                const SizedBox(height: 8),
                Text('맛집·숙박·관광지를 자동으로 묶어드려요',
                    style: AppType.serif(size: 12, color: Colors.white70)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        ...cats.expand((cat) => [
              Row(children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: cat.color,
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(cat.icon, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Text(cat.label, style: AppType.display(size: 18)),
              ]),
              const SizedBox(height: 10),
              ...cat.items.map((name) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                            child: Text(name,
                                style: AppType.body(
                                    size: 13, weight: FontWeight.w600))),
                        const Icon(Icons.add,
                            size: 16, color: AppColors.vermilion),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),
            ]),
      ],
    );
  }
}
