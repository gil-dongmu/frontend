import 'package:url_launcher/url_launcher.dart';

import '../models/festival.dart';
import 'api_config.dart';
import 'kakao_navi_platform_stub.dart'
    if (dart.library.js_interop) 'kakao_navi_platform_web.dart';

/// 카카오내비 호출 결과 — 어떤 경로로 처리됐는지 추적.
enum KakaoNaviResult {
  /// 카카오 JS SDK (`Kakao.Navi.start`) 호출 성공.
  jsSdk,

  /// 카카오내비 앱 deeplink (kakaonavi://) 호출 성공 — 모바일 전용.
  appDeeplink,

  /// 폴백: 카카오맵 길찾기 페이지(브라우저 새 창).
  webFallback,

  /// 좌표 유효 안 함 (lat=0 / lng=0).
  invalidCoord,

  /// 어떤 경로도 실패.
  failed,
}

class KakaoNaviService {
  KakaoNaviService();

  /// 축제로 길안내 시작.
  ///
  /// 우선순위:
  ///   1. (웹 + JS 키 있음) Kakao.Navi.start()
  ///   2. (모바일) kakaonavi:// 앱 deeplink
  ///   3. 폴백: 카카오맵 길찾기 페이지 (https://map.kakao.com/link/to/...)
  Future<KakaoNaviResult> startToFestival(Festival f) async {
    if (f.lat == 0 || f.lng == 0) return KakaoNaviResult.invalidCoord;

    // 1) 웹 + JS SDK 시도
    if (ApiConfig.hasKakaoJsKey) {
      final ok = await KakaoNaviPlatform.tryStartJsSdk(
        key: ApiConfig.kakaoJsKey,
        name: f.name,
        lng: f.lng,
        lat: f.lat,
      );
      if (ok) return KakaoNaviResult.jsSdk;
    }

    // 2) 모바일 앱 deeplink
    final deeplink = Uri(
      scheme: 'kakaonavi',
      host: 'navigate',
      queryParameters: {
        'name': f.name,
        'x': f.lng.toString(),
        'y': f.lat.toString(),
        'coord_type': 'wgs84',
      },
    );
    try {
      if (await canLaunchUrl(deeplink)) {
        final launched = await launchUrl(
          deeplink,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return KakaoNaviResult.appDeeplink;
      }
    } catch (_) {
      // 다음 폴백으로 진행
    }

    // 3) 카카오맵 길찾기 웹 폴백
    final fallback = Uri.parse(
      'https://map.kakao.com/link/to/${Uri.encodeComponent(f.name)},${f.lat},${f.lng}',
    );
    try {
      final launched = await launchUrl(
        fallback,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return KakaoNaviResult.webFallback;
    } catch (_) {}

    return KakaoNaviResult.failed;
  }
}
