import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../models/festival.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/common.dart';
import '../widgets/festival_image.dart';

class RecommendScreen extends StatelessWidget {
  final void Function(Festival) onOpenFest;
  const RecommendScreen({required this.onOpenFest});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final recs = app.recommended();
    if (recs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final top = recs.first;
    final others = recs.skip(1).take(5).toList();

    final reasons = [
      ('☀️', app.hasRealLocation ? '현재 날씨 맑음 22°' : '오늘 ${top.city} 날씨 맑음 22°'),
      ('🎭', "당신이 좋아하는 '${top.theme}' 테마"),
      ('📍', '현재 위치에서 ${top.distanceKm?.toStringAsFixed(1) ?? '?'}km'),
      ('🌙', '야간 관람 추천 시간대'),
    ];

    // AnimatedSwitcher — 가중치 토글 시 순위 재배열을 크로스페이드로 시각화
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: ListView(
      key: ValueKey(app.declineBoost),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('FOR YOU', style: AppType.kicker(color: AppColors.vermilion)),
              const SizedBox(height: 4),
              Text('맞춤 추천', style: AppType.display(size: 32)),
              const SizedBox(height: 8),
              Text('위치 · 시간 · 날씨 · 선호도를 함께 봤어요',
                  style: AppType.serif(size: 13)),
            ],
          ),
        ),
        // 최상위 추천
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: GestureDetector(
            onTap: () => onOpenFest(top),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 200,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    FestivalImage(festival: top),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black45, Colors.transparent, Colors.black54],
                          stops: [0, 0.4, 1],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: AppColors.yellow,
                            borderRadius: BorderRadius.circular(999)),
                        child: Text(
                            '매치율 ${app.matchPercent(top, 0)}%',
                            style: AppType.body(
                                size: 11, weight: FontWeight.w700)),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('오늘 가장 추천',
                              style: AppType.kicker(color: Colors.white)
                                  .copyWith(letterSpacing: 1.8)),
                          const SizedBox(height: 4),
                          Text(top.name,
                              style: AppType.display(
                                  size: 28, color: Colors.white)),
                          if (top.tagline.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text('"${top.tagline}"',
                                style: AppType.serif(
                                    size: 13, color: Colors.white)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // 추천 이유
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            margin: const EdgeInsets.only(top: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('이런 이유로 추천해요', style: AppType.kicker()),
                const SizedBox(height: 10),
                ...reasons.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Text(r.$1, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(r.$2,
                                  style: AppType.body(size: 13))),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ),
        // 가중치 토글
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
                color: AppColors.teal, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.public, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('지역 활성화 가중치',
                          style: AppType.body(
                              size: 11,
                              weight: FontWeight.w700,
                              color: Colors.white)),
                      Text('비수도권 · 인구감소지역 우선 노출',
                          style: AppType.body(size: 10, color: Colors.white70)),
                    ],
                  ),
                ),
                Switch(
                  value: app.declineBoost,
                  activeColor: AppColors.yellow,
                  onChanged: app.setDeclineBoost,
                ),
              ],
            ),
          ),
        ),
        SectionHeader(kicker: '비슷한 취향', title: '당신이 좋아할 만한'),
        ...others.asMap().entries.map((e) {
          final f = e.value;
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: GestureDetector(
              onTap: () => onOpenFest(f),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                          width: 72,
                          height: 72,
                          child: FestivalImage(festival: f)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                  child: Text(f.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppType.display(size: 15))),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 가중치로 순위가 오른 축제에 ↑N 배지
                                  if ((app.rankDelta[f.contentId] ?? 0) >
                                      0) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                          color: AppColors.teal,
                                          borderRadius:
                                              BorderRadius.circular(999)),
                                      child: Text(
                                          '↑${app.rankDelta[f.contentId]}',
                                          style: AppType.body(
                                              size: 10,
                                              weight: FontWeight.w800,
                                              color: Colors.white)),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Text('${app.matchPercent(f, e.key + 1)}%',
                                      style: AppType.display(
                                          size: 16,
                                          color: AppColors.vermilion)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          MetaLine(['${f.region} ${f.city}', f.theme]),
                          if (f.isDeclineRegion) ...[
                            const SizedBox(height: 4),
                            const GdmBadge('지역활성화', color: AppColors.teal),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 20),
      ],
      ),
    );
  }
}
