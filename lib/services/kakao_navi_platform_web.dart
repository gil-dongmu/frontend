import 'dart:js_interop';

/// web/index.html 에서 정의된 글로벌 헬퍼.
@JS('gdmKakaoInit')
external JSString _gdmKakaoInit(JSString key);

@JS('gdmKakaoNaviStart')
external JSString _gdmKakaoNaviStart(JSString name, JSNumber x, JSNumber y);

/// Web 빌드 전용 — Kakao JS SDK 호출 어댑터.
///
/// 글로벌 함수가 'OK' 외 다른 문자열을 반환하면 SDK 미로드/초기화 실패로 판단하고
/// false 를 반환해 호출자가 폴백 경로를 타도록 한다.
class KakaoNaviPlatform {
  KakaoNaviPlatform._();

  static bool _initialized = false;

  static Future<bool> tryStartJsSdk({
    required String key,
    required String name,
    required double lng,
    required double lat,
  }) async {
    try {
      if (!_initialized) {
        final r = _gdmKakaoInit(key.toJS).toDart;
        _initialized = r == 'OK';
        if (!_initialized) return false;
      }
      final r =
          _gdmKakaoNaviStart(name.toJS, lng.toJS, lat.toJS).toDart;
      return r == 'OK';
    } catch (_) {
      return false;
    }
  }
}
