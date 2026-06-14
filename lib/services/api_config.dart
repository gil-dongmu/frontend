/// 한국관광공사 TourAPI 설정.
///
/// [data.go.kr](https://www.data.go.kr) 에서 "한국관광공사_국문 관광정보 서비스 GW"
/// (KorService2) 활용신청 후 발급받은 **일반 인증키(Decoding)** 를 넣으세요.
///
/// 보안: 실제 배포 시 이 값을 소스에 두지 말고 --dart-define 또는
/// 별도 api_keys.dart(.gitignore 처리)로 분리하세요.
///
/// 실행 예:
///   flutter run --dart-define=TOUR_API_KEY=발급받은키
class ApiConfig {
  ApiConfig._();

  /// --dart-define=TOUR_API_KEY=... 우선, 없으면 아래 기본값(빈 값) 사용
  static const tourApiKey = String.fromEnvironment(
    'TOUR_API_KEY',
    defaultValue: '', // ← 여기에 직접 키를 넣어도 됩니다 (개발용)
  );

  /// KorService2 베이스 URL (국문)
  static const tourApiBase = 'https://apis.data.go.kr/B551011/KorService2';

  /// 축제/공연/행사 contentTypeId
  static const contentTypeFestival = '15';

  /// 공통 파라미터
  static const mobileOS = 'ETC'; // IOS / AND / WIN / ETC
  static const mobileApp = 'GilDongMu';

  /// 구글맵 API 키 (지도 화면) — android/app/src/main/AndroidManifest.xml,
  /// ios/Runner/AppDelegate.swift 에도 등록 필요. README 참고.
  static const googleMapsKey = String.fromEnvironment(
    'GOOGLE_MAPS_KEY',
    defaultValue: '',
  );

  /// 카카오 JavaScript 키 — developers.kakao.com 에서 발급.
  /// 웹: Kakao JS SDK 초기화 + `Kakao.Navi.start()` 호출에 사용.
  /// 모바일: 카카오내비 deeplink는 키 없이도 동작.
  ///
  ///   flutter run --dart-define=KAKAO_JS_KEY=발급받은JS키
  static const kakaoJsKey = String.fromEnvironment(
    'KAKAO_JS_KEY',
    defaultValue: '',
  );

  static bool get hasTourKey => tourApiKey.isNotEmpty;
  static bool get hasKakaoJsKey => kakaoJsKey.isNotEmpty;
}
