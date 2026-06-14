import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// 하단 탭 네비게이션
class BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const BottomNav({required this.index, required this.onChanged});

  static const _items = [
    (icon: Icons.home_outlined, active: Icons.home, label: '홈'),
    (icon: Icons.explore_outlined, active: Icons.explore, label: '탐색'),
    (icon: Icons.auto_awesome_outlined, active: Icons.auto_awesome, label: '추천'),
    (icon: Icons.person_outline, active: Icons.person, label: '마이'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cream,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      padding: EdgeInsets.fromLTRB(
          12, 8, 12, 10 + MediaQuery.of(context).padding.bottom * 0.4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_items.length, (i) {
          final it = _items[i];
          final on = i == index;
          final isRecommend = i == 2;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(i),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                  decoration: BoxDecoration(
                    color: on ? AppColors.ink : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Icon(
                    on ? it.active : it.icon,
                    size: 22,
                    color: on
                        ? (isRecommend ? AppColors.yellow : AppColors.cream)
                        : AppColors.inkSoft,
                  ),
                ),
                const SizedBox(height: 3),
                Text(it.label,
                    style: AppType.body(
                      size: 10,
                      weight: FontWeight.w700,
                      color: on ? AppColors.ink : AppColors.muted,
                    )),
              ],
            ),
          );
        }),
      ),
    );
  }
}
