# 길동무 (GilDongMu) · Flutter

> 지방축제 통합 내비게이션. 한국관광공사 TourAPI(KorService2) 기반.

크림 베이스 + 단청(丹靑) 팔레트의 비비드 에디토리얼 디자인. 비수도권·인구감소지역
축제를 우선 노출하는 가중치 추천이 핵심 컨셉입니다.

---

## 1. 빠른 시작

```bash
# 1) 의존성 설치
flutter pub get

# 2) 실행 (API 키 없이 → 데모 데이터로 동작)
flutter run

# 3) 실제 데이터로 실행 (한국관광공사 + 구글맵 키 주입)
flutter run \
  --dart-define=TOUR_API_KEY=발급받은_TourAPI_디코딩키 \
  --dart-define=GOOGLE_MAPS_KEY=구글맵_API_키
```

> 키를 넣지 않아도 앱은 **데모 데이터(MockData)** 로 모든 화면이 동작합니다.
> 키를 넣으면 자동으로 실데이터/실지도로 전환됩니다.

요구 환경: **Flutter 3.27+ / Dart 3.3+** (Material 3, records, `Color.withValues` 사용)

---

## 2. 한국관광공사 TourAPI 키 발급

1. [공공데이터포털 data.go.kr](https://www.data.go.kr) 회원가입
2. **"한국관광공사_국문 관광정보 서비스 GW (KorService2)"** 활용신청
3. 승인 후 마이페이지 → 활용신청 상세에서 **일반 인증키(Decoding)** 복사
4. `--dart-define=TOUR_API_KEY=...` 또는 `lib/services/api_config.dart` 의
   `tourApiKey` 기본값에 직접 입력 (개발용)

사용 중인 오퍼레이션:

| 기능 | 오퍼레이션 |
|------|-----------|
| 기간별 축제 | `searchFestival2` |
| 지역 기반 목록 | `areaBasedList2` |
| 내 주변 (GPS) | `locationBasedList2` |
| 키워드 검색 | `searchKeyword2` |
| 공통 상세(개요) | `detailCommon2` |
| 소개 상세(요금/시간) | `detailIntro2` |

축제 contentTypeId = `15`. 자세한 매핑은 `lib/models/festival.dart`,
`lib/services/tour_api_service.dart` 참고.

---

## 3. 지도 설정 (선택)

`google_maps_flutter` 사용. 키가 없으면 **스타일라이즈된 핀 폴백 지도**가 표시됩니다.

### Android
`android/app/src/main/AndroidManifest.xml` 의 `<application>` 안에:
```xml
<meta-data android:name="com.google.android.geo.API_KEY"
           android:value="구글맵_API_키"/>
```

### iOS
`ios/Runner/AppDelegate.swift`:
```swift
import GoogleMaps
// application(_:didFinishLaunchingWithOptions:) 안에서
GMSServices.provideAPIKey("구글맵_API_키")
```

> 🇰🇷 국내 서비스라면 **카카오맵/네이버맵**이 더 적합합니다.
> `_MapView`(lib/screens/discover_screen.dart)의 `GoogleMap` 위젯을
> `kakao_map_plugin` 또는 `flutter_naver_map` 의 지도 위젯으로 교체하고,
> 마커 좌표는 그대로 `festival.lat/lng` 를 쓰면 됩니다.

---

## 4. 위치 권한

`geolocator` 사용. 권한 미설정/거부 시 기본 좌표(진주시)로 폴백합니다.

### Android — `android/app/src/main/AndroidManifest.xml`
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

### iOS — `ios/Runner/Info.plist`
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>주변 축제 추천과 길 안내를 위해 위치를 사용합니다.</string>
```

---

## 5. 프로젝트 구조

```
lib/
├── main.dart                  앱 진입점
├── app.dart                   라우터: 스플래시 → 온보딩 → 메인(탭) + 상세/검색 push
├── theme/
│   ├── app_colors.dart        단청 팔레트 + 테마→색 매핑
│   ├── app_typography.dart    display / serif / body / kicker
│   └── app_theme.dart         ThemeData (Material 3)
├── models/
│   ├── festival.dart          Festival + TourAPI 매핑 + 지역코드/인구감소 판별
│   └── course.dart            Course / CourseItem / RouteStop
├── data/
│   └── mock_festivals.dart    데모 데이터 + 테마/지역 목록
├── services/
│   ├── api_config.dart        키/엔드포인트 설정
│   ├── tour_api_service.dart  TourAPI(KorService2) 클라이언트
│   └── location_service.dart  위치 권한 + 하버사인 거리
├── providers/
│   └── app_state.dart         전역 상태(Provider): 로딩/필터/추천/찜
├── widgets/
│   ├── common.dart            칩/뱃지/스탬프/섹션헤더/버튼/메타
│   ├── festival_image.dart    원격 이미지 + 테마 그라데이션 폴백
│   ├── festival_cards.dart    포스터 카드 / 리스트 행
│   └── bottom_nav.dart        하단 탭
└── screens/
    ├── splash_screen.dart     스플래시 (유등 패턴 애니메이션)
    ├── onboarding_screen.dart 3스텝 (테마·동행·권한)
    ├── home_screen.dart       오늘의 헤드라인 · 주말 추천 · 지역 보석
    ├── discover_screen.dart   리스트/지도/캘린더 + 필터 시트
    ├── detail_screen.dart     히어로 + 소개/프로그램/갤러리/주변 4탭
    ├── navigation_screen.dart 다중 경유지 + 동선 최적화 + 차/버스/도보
    ├── course_screen.dart     1박2일 코스(타임라인 + 예산)
    ├── recommend_screen.dart  매치율 + 추천 이유 + 가중치 토글
    ├── search_screen.dart     자연어/음성 + 실시간 인기 + 테마별
    └── mypage_screen.dart     레벨 카드 + 방문/찜/리뷰
```

---

## 6. 핵심 컨셉: 인구감소지역 가중치

- `AreaCodes.isDecline()` 으로 비수도권(서울/인천/경기 제외) 축제를 가산 대상으로 표시
  (데모 단순화 — 실제 서비스는 행정안전부 89개 시군구 코드 테이블로 교체).
- `AppState._sort()` / `recommended()` 에서 가산점 반영.
- 탐색 필터 시트 · 추천 화면에서 토글 가능.

---

## 7. 다음 작업 (TODO)

- [ ] TourAPI 실키 검증 + 페이지네이션(무한 스크롤)
- [ ] 89개 인구감소지역 시군구 코드 테이블 적용
- [ ] 카카오맵/카카오내비 연동 (`url_launcher` 로 `kakaonavi://` 딥링크)
- [ ] 찜/방문기록 영속화 (`shared_preferences` — 의존성은 이미 포함)
- [ ] 다국어(en/zh/ja) — `intl` ARB 도입
- [ ] 오프라인 캐시 (cached_network_image + 로컬 DB)

---

### 라이선스 / 데이터 출처
관광 데이터: 한국관광공사 TourAPI. 데모 이미지·일러스트는 앱 내 CustomPaint로 생성됩니다.
