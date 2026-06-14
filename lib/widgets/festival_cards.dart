import 'package:flutter/material.dart';

import '../models/festival.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'festival_image.dart';
import 'common.dart';

/// 큰 세로 카드 (홈 가로 스크롤 / 추천)
class FestivalPosterCard extends StatelessWidget {
  final Festival festival;
  final int? rank;
  final VoidCallback onTap;
  final double width;
  final double height;
  const FestivalPosterCard({
    required this.festival,
    required this.onTap,
    this.rank,
    this.width = 220,
    this.height = 240,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Hero — 상세 화면 히어로 이미지로 자연스럽게 확대 전환
                Hero(
                  tag: 'fest-hero-${festival.contentId}',
                  child: FestivalImage(festival: festival),
                ),
                // 그라데이션
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black54],
                      stops: [0.5, 1],
                    ),
                  ),
                ),
                if (rank != null)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Text(
                      rank!.toString().padLeft(2, '0'),
                      style: AppType.display(size: 36, color: Colors.white),
                    ),
                  ),
                if (festival.isDeclineRegion)
                  const Positioned(
                    top: 14,
                    right: 14,
                    child: GdmBadge('지역활성화', color: AppColors.teal),
                  ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(festival.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.display(size: 18, color: Colors.white)),
                      const SizedBox(height: 4),
                      MetaLine(
                        [
                          '${festival.region} ${festival.city}',
                          if (festival.distanceKm != null)
                            '${festival.distanceKm!.toStringAsFixed(1)}km',
                        ],
                        color: Colors.white70,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 가로 리스트 행
class FestivalRow extends StatelessWidget {
  final Festival festival;
  final int? rank;
  final VoidCallback onTap;
  final Widget? trailing;
  const FestivalRow({
    required this.festival,
    required this.onTap,
    this.rank,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.line)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (rank != null) ...[
              SizedBox(
                width: 26,
                child: Text(rank!.toString().padLeft(2, '0'),
                    style: AppType.display(size: 22, color: AppColors.vermilion)),
              ),
              const SizedBox(width: 6),
            ],
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 64,
                height: 64,
                child: FestivalImage(festival: festival),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(festival.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.display(size: 15)),
                  const SizedBox(height: 2),
                  MetaLine(['${festival.region} ${festival.city}', festival.theme]),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(festival.periodLabel,
                          style: AppType.body(
                              size: 11,
                              weight: FontWeight.w600,
                              color: AppColors.muted)),
                      if (festival.isDeclineRegion) ...[
                        const SizedBox(width: 8),
                        const GdmBadge('지역활성화', color: AppColors.teal),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            trailing ??
                const Icon(Icons.chevron_right, size: 16, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
