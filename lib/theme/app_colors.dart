import 'package:flutter/material.dart';

/// 길동무 컬러 토큰 — 단청(丹靑) 팔레트 기반
/// 크림 베이스 + 잉크 블랙 + 단청 주홍/노랑/청록/자주
class AppColors {
  AppColors._();

  // 베이스
  static const cream = Color(0xFFF5F0E8);
  static const paper = Color(0xFFFBF7F0);
  static const ink = Color(0xFF1A1A1A);
  static const inkSoft = Color(0xFF3D3833);
  static const muted = Color(0xFF8A8278);
  static const line = Color(0xFFE5DDD0);

  // 단청 액센트
  static const vermilion = Color(0xFFE03A1A); // 주홍
  static const yellow = Color(0xFFFFC233); // 노랑
  static const teal = Color(0xFF1B6E70); // 청록
  static const plum = Color(0xFF6B1F4A); // 자주
  static const ultramarine = Color(0xFF1763B5); // 청

  /// 축제별 대표 색 (TourAPI에는 색 정보가 없어 테마→색 매핑으로 보강)
  static Color forTheme(String? theme) {
    switch (theme) {
      case '전통':
        return vermilion;
      case '자연':
      case '자연·꽃':
        return teal;
      case '먹거리':
        return const Color(0xFFD84315);
      case '체험':
        return const Color(0xFF7B4A2F);
      case '문화예술':
        return plum;
      case '농경':
        return const Color(0xFFC68A2E);
      case '겨울':
        return ultramarine;
      default:
        return vermilion;
    }
  }
}
