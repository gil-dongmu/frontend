import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/festival.dart';
import '../models/user_profile.dart';
import '../services/tour_api_service.dart';
import '../services/location_service.dart';
import '../services/auth_service.dart';
import '../services/api_config.dart';
import '../data/mock_festivals.dart';

enum LoadState { idle, loading, ready, error, usingMock }

/// 앱 전역 상태 — 축제 목록 로딩, 위치, 필터, 선호도, 찜.
///
/// API 키가 있으면 TourAPI에서 실데이터를, 없거나 실패하면 MockData를 사용.
class AppState extends ChangeNotifier {
  final TourApiService _api;
  final LocationService _loc;
  final AuthService _auth;

  AppState({TourApiService? api, LocationService? loc, AuthService? auth})
      : _api = api ?? TourApiService(),
        _loc = loc ?? LocationService(),
        _auth = auth ?? AuthService();

  // ── 로딩 상태 ──────────────────────────────────────────
  LoadState state = LoadState.idle;
  String? errorMessage;

  // ── 인증 ──────────────────────────────────────────────
  UserProfile? currentUser;
  bool authChecked = false;
  bool isSigningIn = false;
  AuthProvider? signingInProvider;
  bool get isAuthenticated => currentUser != null;

  Future<void> restoreAuth() async {
    currentUser = await _auth.restore();
    authChecked = true;
    notifyListeners();
  }

  Future<UserProfile?> signIn(AuthProvider provider) async {
    isSigningIn = true;
    signingInProvider = provider;
    notifyListeners();
    try {
      currentUser = await _auth.signIn(provider);
      return currentUser;
    } finally {
      isSigningIn = false;
      signingInProvider = null;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    currentUser = null;
    notifyListeners();
  }

  // ── 데이터 ────────────────────────────────────────────
  List<Festival> _all = [];
  List<Festival> get all => _all;

  // ── 위치 ──────────────────────────────────────────────
  double myLat = LocationService.defaultLat;
  double myLng = LocationService.defaultLng;
  bool hasRealLocation = false;

  // ── 필터 ──────────────────────────────────────────────
  String themeFilter = 'all';
  String regionFilter = '전체';
  bool declineBoost = true; // 인구감소지역 가산점

  // ── 선호도(온보딩) / 찜 ────────────────────────────────
  static const _kSavedKey = 'gildongmu.saved';
  static const _kThemesKey = 'gildongmu.preferredThemes';
  static const _kPartnerKey = 'gildongmu.partner';
  SharedPreferences? _prefs;

  Set<String> preferredThemes = {};
  String? partner; // solo/couple/family/friends
  final Set<String> _saved = {};
  bool isSaved(Festival f) => _saved.contains(f.contentId);
  void toggleSave(Festival f) {
    if (!_saved.add(f.contentId)) _saved.remove(f.contentId);
    _prefs?.setStringList(_kSavedKey, _saved.toList());
    notifyListeners();
  }

  /// 온보딩에서 고른 테마/동행 저장 (재시작 후에도 유지)
  void setPreferences({required Set<String> themes, String? partner}) {
    preferredThemes = themes;
    this.partner = partner;
    _prefs?.setStringList(_kThemesKey, themes.toList());
    if (partner != null) _prefs?.setString(_kPartnerKey, partner);
    notifyListeners();
  }

  List<Festival> get saved =>
      _all.where((f) => _saved.contains(f.contentId)).toList();

  // ── 초기 로드 ─────────────────────────────────────────
  Future<void> bootstrap() async {
    state = LoadState.loading;
    notifyListeners();

    // 0) 로컬 저장 복원 — 찜 / 온보딩 선호
    try {
      _prefs = await SharedPreferences.getInstance();
      _saved.addAll(_prefs!.getStringList(_kSavedKey) ?? const []);
      if (preferredThemes.isEmpty) {
        preferredThemes =
            (_prefs!.getStringList(_kThemesKey) ?? const []).toSet();
      }
      partner ??= _prefs!.getString(_kPartnerKey);
    } catch (_) {
      // prefs 사용 불가 환경(테스트 등) — 메모리로만 동작
    }

    // 1) 위치
    final pos = await _loc.current();
    if (pos != null) {
      myLat = pos.latitude;
      myLng = pos.longitude;
      hasRealLocation = true;
    }

    // 2) 축제 데이터
    try {
      if (ApiConfig.hasTourKey) {
        // 위치 기반 우선, 부족하면 기간 검색으로 보강
        List<Festival> list = [];
        if (hasRealLocation) {
          list = await _api.nearbyFestivals(lat: myLat, lng: myLng);
        }
        if (list.length < 5) {
          final more = await _api.searchFestivals();
          final ids = list.map((e) => e.contentId).toSet();
          list.addAll(more.where((e) => !ids.contains(e.contentId)));
        }
        if (list.isEmpty) {
          // 키는 있지만 결과가 비면 데모 데이터로 폴백 (빈 화면 방지)
          _all = _withDistance(MockData.festivals);
          state = LoadState.usingMock;
        } else {
          _all = _withDistance(list);
          state = LoadState.ready;
        }
      } else {
        _all = _withDistance(MockData.festivals);
        state = LoadState.usingMock;
      }
    } catch (e) {
      errorMessage = '$e';
      _all = _withDistance(MockData.festivals);
      state = LoadState.usingMock;
    }
    _sort();
    notifyListeners();
  }

  List<Festival> _withDistance(List<Festival> list) {
    return list
        .map((f) => f.copyWith(
              distanceKm: f.lat == 0
                  ? null
                  : LocationService.distanceKm(myLat, myLng, f.lat, f.lng),
            ))
        .toList();
  }

  void _sort() {
    _all.sort((a, b) {
      // 인구감소지역 가산점 적용 후 거리순
      double score(Festival f) {
        final d = f.distanceKm ?? 9999;
        return d - (declineBoost && f.isDeclineRegion ? 15 : 0);
      }

      return score(a).compareTo(score(b));
    });
  }

  // ── 필터링된 목록 ─────────────────────────────────────
  List<Festival> get filtered {
    return _all.where((f) {
      final themeOk = themeFilter == 'all' ||
          f.theme == themeFilter ||
          f.themes.contains(themeFilter);
      final regionOk = regionFilter == '전체' || f.region == regionFilter;
      return themeOk && regionOk;
    }).toList();
  }

  List<Festival> get declineFestivals =>
      _all.where((f) => f.isDeclineRegion).toList();

  /// 맞춤 추천 점수 (위치+선호테마+인구감소 가중치)
  List<Festival> recommended() {
    final scored = _all.map((f) {
      double s = 100;
      s -= (f.distanceKm ?? 50) * 0.3;
      if (preferredThemes.contains(f.theme)) s += 20;
      for (final t in f.themes) {
        if (preferredThemes.contains(t)) s += 6;
      }
      if (declineBoost && f.isDeclineRegion) s += 12;
      return MapEntry(f, s);
    }).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return scored.map((e) => e.key).toList();
  }

  int matchPercent(Festival f, int index) =>
      (96 - index * 4).clamp(60, 99);

  // ── 필터 setter ───────────────────────────────────────
  void setTheme(String t) {
    themeFilter = t;
    notifyListeners();
  }

  void setRegion(String r) {
    regionFilter = r;
    notifyListeners();
  }

  /// declineBoost 토글 직후 추천 순위 변화 (contentId → 상승 칸 수, 양수 = 상승)
  Map<String, int> rankDelta = {};

  /// 가중치로 순위가 오른 축제 수
  int get boostedCount => rankDelta.values.where((d) => d > 0).length;

  void setDeclineBoost(bool v) {
    final before = recommended().map((f) => f.contentId).toList();
    declineBoost = v;
    _sort();
    final after = recommended().map((f) => f.contentId).toList();
    rankDelta = {
      for (var i = 0; i < after.length; i++)
        after[i]: before.indexOf(after[i]) - i,
    };
    notifyListeners();
  }

  void resetFilters() {
    themeFilter = 'all';
    regionFilter = '전체';
    notifyListeners();
  }

  // ── 검색 ──────────────────────────────────────────────
  Future<List<Festival>> search(String q) async {
    if (q.trim().isEmpty) return [];
    if (ApiConfig.hasTourKey) {
      try {
        return _withDistance(await _api.searchKeyword(q));
      } catch (_) {}
    }
    // 로컬 검색 — 공백으로 나눈 토큰이 모두 포함되면 매치
    // (예: "안동 탈춤" → 이름에 붙어있지 않아도 검색됨)
    final tokens = q.trim().toLowerCase().split(RegExp(r'\s+'));
    return _all.where((f) {
      final hay = '${f.name} ${f.nameEn ?? ''} ${f.region} ${f.city} '
              '${f.theme} ${f.themes.join(' ')}'
          .toLowerCase();
      return tokens.every(hay.contains);
    }).toList();
  }

  // ── 상세 보강 ─────────────────────────────────────────
  Future<Festival> detail(Festival f) async {
    if (ApiConfig.hasTourKey && f.contentId.isNotEmpty) {
      try {
        return await _api.enrichDetail(f);
      } catch (_) {}
    }
    return f;
  }
}
