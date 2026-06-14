import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// 길동무 타이포그래피
/// - display: 임팩트 헤드라인 (Noto Sans KR 900 — 한글 지원, 축제다운 굵기)
/// - serif: 인용/태그라인 (Hahmlet, 이탤릭 느낌)
/// - body: 본문 (Noto Sans KR)
///
/// 참고: Bagel Fat One은 한글 글리프가 없어 헤드라인은 NotoSansKR w900으로 통일.
/// 라틴 전용 헤드라인이 필요하면 GoogleFonts.bagelFatOne() 사용.
class AppType {
  AppType._();

  static TextStyle display({
    double size = 24,
    Color color = AppColors.ink,
    double height = 1.1,
    double letterSpacing = -0.5,
  }) {
    return GoogleFonts.notoSansKr(
      fontSize: size,
      fontWeight: FontWeight.w900,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle serif({
    double size = 13,
    Color color = AppColors.inkSoft,
    FontStyle style = FontStyle.italic,
    double height = 1.5,
  }) {
    return GoogleFonts.hahmlet(
      fontSize: size,
      fontStyle: style,
      color: color,
      height: height,
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle body({
    double size = 14,
    Color color = AppColors.ink,
    FontWeight weight = FontWeight.w500,
    double height = 1.5,
    double letterSpacing = 0,
  }) {
    return GoogleFonts.notoSansKr(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// 작은 라벨용 — 자간 넓힌 대문자 키커
  static TextStyle kicker({
    double size = 10,
    Color color = AppColors.muted,
  }) {
    return GoogleFonts.notoSansKr(
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: 1.6,
    );
  }
}
