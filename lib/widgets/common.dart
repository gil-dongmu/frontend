import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// 필터/온보딩용 칩
class GdmChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final String? leading; // 이모지/심볼
  const GdmChip({
    required this.label,
    required this.active,
    required this.onTap,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? AppColors.ink : AppColors.line,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              Text(leading!,
                  style: TextStyle(
                      fontSize: 13,
                      color: active ? AppColors.yellow : AppColors.vermilion)),
              const SizedBox(width: 4),
            ],
            Text(label,
                style: AppType.body(
                  size: 13,
                  weight: FontWeight.w600,
                  color: active ? AppColors.cream : AppColors.inkSoft,
                )),
          ],
        ),
      ),
    );
  }
}

/// 작은 뱃지
class GdmBadge extends StatelessWidget {
  final String text;
  final Color color;
  final bool dark;
  const GdmBadge(this.text, {this.color = AppColors.vermilion, this.dark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: dark ? Colors.black : color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: AppType.body(size: 10, weight: FontWeight.w700, color: Colors.white)
            .copyWith(letterSpacing: 0.4),
      ),
    );
  }
}

/// 단청 스탬프 (도장 느낌의 날짜 마크)
class GdmStamp extends StatelessWidget {
  final String text;
  final Color color;
  final double size;
  final double rotate; // degrees
  const GdmStamp(this.text,
      {this.color = AppColors.vermilion, this.size = 56, this.rotate = 8});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotate * 3.1415926 / 180,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white.withValues(alpha: 0.0)),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppType.serif(
            size: size * 0.22,
            color: Colors.white,
            style: FontStyle.normal,
          ).copyWith(fontWeight: FontWeight.w700, height: 1.1),
        ),
      ),
    );
  }
}

/// 섹션 헤더 (키커 + 제목 + 액션)
class SectionHeader extends StatelessWidget {
  final String? kicker;
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionHeader({
    this.kicker,
    required this.title,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (kicker != null) ...[
                  Text(kicker!.toUpperCase(), style: AppType.kicker()),
                  const SizedBox(height: 4),
                ],
                Text(title, style: AppType.display(size: 22)),
              ],
            ),
          ),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Row(
                children: [
                  Text(action!,
                      style: AppType.body(
                          size: 12,
                          weight: FontWeight.w600,
                          color: AppColors.inkSoft)),
                  const Icon(Icons.chevron_right,
                      size: 16, color: AppColors.inkSoft),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// 메타 라인 (· 구분)
class MetaLine extends StatelessWidget {
  final List<String> items;
  final Color color;
  const MetaLine(this.items, {this.color = AppColors.inkSoft});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) {
        children.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text('·', style: TextStyle(color: color.withValues(alpha: 0.4))),
        ));
      }
      children.add(Text(items[i],
          style: AppType.body(size: 12, weight: FontWeight.w500, color: color)));
    }
    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }
}

/// 빈 상태 — 단청 연화문 일러스트 + 안내 문구
class GdmEmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double size;
  const GdmEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.size = 96,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomPaint(
              size: Size.square(size),
              painter: _DancheongEmptyPainter(),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: AppType.body(
                    size: 14,
                    weight: FontWeight.w700,
                    color: AppColors.inkSoft)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!,
                  textAlign: TextAlign.center,
                  style: AppType.body(size: 12, color: AppColors.muted)),
            ],
          ],
        ),
      ),
    );
  }
}

/// 연꽃잎 8장 + 중심 원 + 점 테두리 (단청 연화문 모티프)
class _DancheongEmptyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;

    final petal = Paint()..color = AppColors.vermilion.withValues(alpha: 0.18);
    for (var i = 0; i < 8; i++) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(i * math.pi / 4);
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(0, -r * 0.55), width: r * 0.42, height: r * 0.8),
        petal,
      );
      canvas.restore();
    }

    canvas.drawCircle(
        c, r * 0.34, Paint()..color = AppColors.yellow.withValues(alpha: 0.35));
    canvas.drawCircle(
        c,
        r * 0.34,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = AppColors.vermilion.withValues(alpha: 0.5));
    canvas.drawCircle(c, r * 0.12,
        Paint()..color = AppColors.vermilion.withValues(alpha: 0.55));

    final dot = Paint()..color = AppColors.teal.withValues(alpha: 0.4);
    for (var i = 0; i < 16; i++) {
      final a = i * math.pi / 8;
      canvas.drawCircle(
        Offset(c.dx + r * 0.88 * math.cos(a), c.dy + r * 0.88 * math.sin(a)),
        2.2,
        dot,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 기본 버튼
class GdmButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool primary;
  final bool dark;
  final bool full;
  final IconData? icon;
  const GdmButton(
    this.label, {
    this.onTap,
    this.primary = false,
    this.dark = false,
    this.full = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bg = primary
        ? AppColors.vermilion
        : dark
            ? AppColors.ink
            : AppColors.paper;
    final fg = (primary || dark) ? Colors.white : AppColors.ink;
    return SizedBox(
      width: full ? double.infinity : null,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: full ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: fg),
                  const SizedBox(width: 8),
                ],
                Text(label,
                    style: AppType.body(
                        size: 15, weight: FontWeight.w700, color: fg)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
