import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../models/festival.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/common.dart';
import '../widgets/festival_cards.dart';
import '../widgets/festival_image.dart';

class HomeScreen extends StatelessWidget {
  final void Function(Festival) onOpenFest;
  final VoidCallback onOpenSearch;
  final void Function(int tab) onGoTab;
  const HomeScreen({
    required this.onOpenFest,
    required this.onOpenSearch,
    required this.onGoTab,
  });

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final all = app.all;
    final weekend = all.take(4).toList();
    final decline = app.declineFestivals.take(3).toList();

    final now = DateTime.now();
    const seasons = ['겨울', '봄', '여름', '가을'];
    final season = seasons[(now.month % 12) ~/ 3];
    // 오늘 진행 중인 축제 수 — 없으면 다가오는 축제 수로 표기
    final activeToday = all
        .where((f) =>
            f.start != null &&
            f.end != null &&
            !now.isBefore(f.start!) &&
            !now.isAfter(f.end!.add(const Duration(days: 1))))
        .length;

    // 당겨서 새로고침 — 위치/축제 데이터 재로드
    return RefreshIndicator(
      color: AppColors.vermilion,
      onRefresh: app.bootstrap,
      child: ListView(
      padding: EdgeInsets.zero,
      children: [
        // 헤더
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('길동무', style: AppType.display(size: 28)),
                    const SizedBox(height: 4),
                    Text('${now.year} · $season호',
                        style: AppType.kicker().copyWith(letterSpacing: 1.8)),
                  ],
                ),
              ),
              IconButton(
                onPressed: onOpenSearch,
                icon: const Icon(Icons.search, color: AppColors.ink),
              ),
              const Icon(Icons.notifications_none, color: AppColors.ink),
            ],
          ),
        ),
        // 위치 + 날씨
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: Row(
            children: [
              const Icon(Icons.location_on, size: 14, color: AppColors.vermilion),
              const SizedBox(width: 6),
              Text(
                app.hasRealLocation ? '현재 위치 · 맑음 22°' : '진주시 본성동 · 맑음 22°',
                style: AppType.body(size: 13, weight: FontWeight.w600),
              ),
              const Spacer(),
              // 데이터 출처 배지 — 실데이터/데모 여부 투명하게 표시
              _SourceBadge(usingMock: app.state == LoadState.usingMock),
            ],
          ),
        ),
        // 빅 헤드라인 카드
        _HeadlineCard(
          count: activeToday > 0 ? activeToday : all.length,
          label: activeToday > 0 ? '오늘 열리는' : '다가오는',
          onTap: () => onGoTab(1),
        ),
        // 이번 주말
        SectionHeader(
          kicker: 'TODAY',
          title: '이번 주말 가볼 만한',
          action: '더보기',
          onAction: () => onGoTab(1),
        ),
        SizedBox(
          height: 240,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: weekend.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => FestivalPosterCard(
              festival: weekend[i],
              rank: i + 1,
              onTap: () => onOpenFest(weekend[i]),
            ),
          ),
        ),
        // 지역활성화 배너
        const SizedBox(height: 8),
        SectionHeader(
          kicker: 'LOCAL GEMS',
          title: '잘 알려지지 않은 보석',
          action: '더 알아보기',
          onAction: () => onGoTab(2),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _DeclineBanner(count: app.declineFestivals.length),
        ),
        const SizedBox(height: 14),
        ...decline.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: FestivalRow(
                festival: e.value,
                rank: e.key + 1,
                onTap: () => onOpenFest(e.value),
              ),
            )),
        // 푸터 인용
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            children: [
              Text(
                '"여행은 목적지가 아니라\n길 위의 동무를 찾는 일이다."',
                textAlign: TextAlign.center,
                style: AppType.serif(size: 13, color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              Text('— 한국관광공사 OPENAPI 기반',
                  style: AppType.kicker().copyWith(letterSpacing: 1.6)),
            ],
          ),
        ),
      ],
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  final bool usingMock;
  const _SourceBadge({required this.usingMock});

  @override
  Widget build(BuildContext context) {
    final color = usingMock ? AppColors.muted : AppColors.teal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(usingMock ? '데모 데이터' : 'TourAPI 실데이터',
            style: AppType.body(size: 9, weight: FontWeight.w700, color: color)
                .copyWith(letterSpacing: 0.3)),
      ]),
    );
  }
}

class _HeadlineCard extends StatelessWidget {
  final int count;
  final String label;
  final VoidCallback onTap;
  const _HeadlineCard({
    required this.count,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('오늘의 길동무',
                  style: AppType.kicker(color: AppColors.yellow)
                      .copyWith(letterSpacing: 2)),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: AppType.display(size: 44, color: AppColors.cream)
                      .copyWith(height: 0.95),
                  children: [
                    TextSpan(text: '$label\n'),
                    TextSpan(
                        text: '축제 ',
                        style: AppType.display(size: 44, color: AppColors.yellow)),
                    TextSpan(
                        text: '$count',
                        style: AppType.display(size: 60, color: AppColors.yellow)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text('비수도권 우선 · 인구감소지역 가산',
                  style: AppType.serif(size: 12, color: Colors.white70)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: onTap,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('전체 보기',
                          style: AppType.body(
                              size: 12, weight: FontWeight.w700)),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward,
                          size: 14, color: AppColors.ink),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: GdmStamp(
              '${now.month}/\n${now.day.toString().padLeft(2, '0')}',
              size: 48,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeclineBanner extends StatelessWidget {
  final int count;
  const _DeclineBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.teal,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('인구감소지역 89개 시군구',
                    style: AppType.kicker(color: const Color(0xFF7FE0DC))
                        .copyWith(letterSpacing: 1.8)),
                const SizedBox(height: 6),
                Text('작은 마을의\n큰 잔치',
                    style: AppType.display(size: 22, color: Colors.white)),
                const SizedBox(height: 8),
                Text('여행 한 번이 지역 경제에 도움이 됩니다',
                    style: AppType.serif(size: 12, color: Colors.white70)),
              ],
            ),
          ),
          Text('$count',
              style: AppType.display(size: 64, color: AppColors.yellow)
                  .copyWith(height: 1)),
        ],
      ),
    );
  }
}
