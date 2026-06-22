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

  // ── 길동무 백엔드 (소셜 로그인 / 인증) ───────────────────
  //
  // 백엔드는 소셜 access token을 받아 자체 JWT를 발급한다.
  //   POST /api/v1/auth/login/{provider}   provider = kakao | naver
  //   POST /api/v1/auth/reissue
  //   POST /api/v1/auth/logout
  //   PATCH /api/v1/users/me               (닉네임 설정)
  //
  // 기본값은 Android 에뮬레이터에서 호스트(localhost:8080)에 접근하는 주소.
  // iOS 시뮬레이터/실기기/배포 시에는 --dart-define 로 덮어쓴다.
  //   flutter run --dart-define=API_BASE_URL=https://api.gildongmu.app
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  /// 카카오 네이티브 앱 키 — KakaoSdk.init(nativeAppKey: ...) 에 사용.
  /// 안전을 위해 소스에 직접 두지 말고 env.json(.gitignore) 으로 주입하세요.
  ///   flutter run --dart-define-from-file=env.json
  static const kakaoNativeAppKey = String.fromEnvironment(
    'KAKAO_NATIVE_APP_KEY',
    defaultValue: '',
  );

  // ── 네이버 로그인 (flutter_naver_login 2.x) ─────────────
  // 2.x 부터 Dart initSdk 가 없어졌다. Client ID / Secret / 앱 이름은
  // android/app/src/main/res/values/strings.xml + AndroidManifest.xml,
  // iOS Info.plist 에서 네이티브 SDK 가 직접 읽어가므로 여기서 다루지 않는다.

  static bool get hasTourKey => tourApiKey.isNotEmpty;
  static bool get hasKakaoJsKey => kakaoJsKey.isNotEmpty;
  static bool get hasKakaoNativeKey => kakaoNativeAppKey.isNotEmpty;
}
