import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/festival.dart';
import '../theme/app_colors.dart';

/// 축제 대표 이미지.
/// - TourAPI firstimage가 있으면 네트워크 이미지(캐싱)
/// - 없으면 테마 색 그라데이션 + 단청 문양 플레이스홀더
class FestivalImage extends StatelessWidget {
  final Festival festival;
  final BoxFit fit;
  const FestivalImage({required this.festival, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forTheme(festival.theme);
    final placeholder = _Placeholder(color: color, theme: festival.theme);

    if (festival.firstImage != null && festival.firstImage!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: festival.firstImage!,
        fit: fit,
        placeholder: (_, __) => placeholder,
        errorWidget: (_, __, ___) => placeholder,
      );
    }
    return placeholder;
  }
}

class _Placeholder extends StatelessWidget {
  final Color color;
  final String theme;
  const _Placeholder({required this.color, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            Color.lerp(color, Colors.black, 0.35)!,
          ],
        ),
      ),
      child: CustomPaint(
        painter: _MunPainter(color),
        child: Center(
          child: Text(
            _symbol(theme),
            style: TextStyle(
              fontSize: 64,
              color: Colors.white.withValues(alpha: 0.25),
            ),
          ),
        ),
      ),
    );
  }

  String _symbol(String t) {
    switch (t) {
      case '전통':
        return '⛩';
      case '자연':
        return '✿';
      case '먹거리':
        return '◐';
      case '체험':
        return '✦';
      case '문화예술':
        return '♪';
      case '농경':
        return '✤';
      case '겨울':
        return '❅';
      default:
        return '◉';
    }
  }
}

/// 은은한 점 패턴(한지 느낌)
class _MunPainter extends CustomPainter {
  final Color color;
  _MunPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withValues(alpha: 0.06);
    const gap = 16.0;
    for (double y = gap; y < size.height; y += gap) {
      for (double x = gap; x < size.width; x += gap) {
        canvas.drawCircle(Offset(x, y), 1.2, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
