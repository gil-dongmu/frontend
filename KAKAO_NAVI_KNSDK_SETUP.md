# 카카오내비 인앱 주행(KNSDK) 연동 — 설정 가이드

외부 카카오내비 앱을 띄우지 않고, 앱 내부(KNNaviActivity)에서 카카오내비
주행 화면(KNNaviView)을 표시하는 스캐폴드입니다. **빌드 전 아래 설정이 필요합니다.**

## 1. SDK 이용 신청 / 키
- 카카오디벨로퍼스(developers.kakao.com)에서 앱 생성 → **네이티브 앱 키** 발급
- 카카오모빌리티 디벨로퍼스에서 **카카오내비 길찾기 SDK(with UI)** 이용(상용은 가격/문의 확인)
- 플랫폼 > Android: 패키지명 `com.gildongmu.gildongmu` + **키 해시** 등록

## 2. local.properties (커밋 금지)
```
knsdk.app.key=발급받은_네이티브_앱_키
```
없으면 BuildConfig.KNSDK_APP_KEY 가 빈 값 → 초기화 실패(토스트 후 자체 안내 화면 폴백).

## 3. 요구사항
- minSdk 26 (이미 build.gradle.kts 에서 26으로 상향)
- Java 11+/Kotlin (충족)
- settings.gradle.kts 에 KNSDK maven 레포 추가됨

## 4. 동작
- 길안내 화면의 "주행 안내" 버튼 → Android 면 `KakaoNaviSdkService.startGuidance()` →
  네이티브 `KNNaviActivity`(KNNaviView)로 인앱 주행. 실패 시 기존 `GuidanceScreen` 폴백.

## ⚠️ 스캐폴드 검증 필요 항목
- KNSDK Kotlin **import 경로 / enum 값(KNRoutePriority, KNRouteAvoidOption 등)** 은
  버전에 따라 다를 수 있음 → API 레퍼런스/공식 샘플로 빌드 시 조정.
- 좌표 변환 `KNSDK.WGS84ToKATEC(lng, lat)` 반환 타입(.x/.y)도 레퍼런스로 확인.
- iOS는 별도 작업(ios-ui SDK) 미포함.
- 이 환경에서는 네이티브 빌드 검증을 못 했으므로, 실제 기기 빌드로 확인 필요.

참고:
- https://developers.kakaomobility.com/guide/android-ui/start.html
- https://developers.kakaomobility.com/guide/android-ui/driving.html
- https://developers.kakaomobility.com/reference/android-ui-ref-kotlin/
