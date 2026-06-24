import 'dart:async';
import 'dart:convert';

import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:flutter_naver_login/interface/types/naver_login_result.dart';
import 'package:flutter_naver_login/interface/types/naver_login_status.dart';
import 'package:flutter_naver_login/interface/types/naver_token.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';
import 'api_client.dart';
import 'token_store.dart';

/// 소셜 로그인 도중(SDK 단계 또는 사용자 취소) 발생한 오류.
class SocialLoginException implements Exception {
  const SocialLoginException(this.message, {this.cancelled = false});

  final String message;

  /// 사용자가 직접 로그인 창을 닫은 경우 — UI에서 조용히 무시할 수 있다.
  final bool cancelled;

  @override
  String toString() => 'SocialLoginException: $message';
}

/// 소셜 로그인 + 백엔드 JWT 인증.
///
/// 흐름:
///   1) 카카오/네이버 SDK 로 로그인 → 소셜 access token 획득
///   2) 백엔드 `POST /api/v1/auth/login/{provider}` 에 전달 → JWT 발급
///   3) JWT 를 안전 저장소(TokenStore)에 보관, 표시용 프로필은 prefs 에 저장
///
/// guest(둘러보기)는 서버를 호출하지 않는 로컬 전용 모드다.
class AuthService {
  AuthService({
    SharedPreferences? prefs,
    ApiClient? apiClient,
    TokenStore? tokenStore,
  })  : _prefsOverride = prefs,
        _tokens = tokenStore ?? TokenStore(),
        _api = apiClient ?? ApiClient(tokenStore: tokenStore);

  final SharedPreferences? _prefsOverride;
  final ApiClient _api;
  final TokenStore _tokens;

  static const _kStorageKey = 'gildongmu.auth.user';

  Future<SharedPreferences> _prefs() async =>
      _prefsOverride ?? await SharedPreferences.getInstance();

  /// 저장된 세션 복원 (앱 시작 시).
  ///
  /// 소셜 사용자는 JWT 가 있어야 유효하다. 게스트는 토큰 없이 프로필만으로 유효.
  Future<UserProfile?> restore() async {
    final profile = await _readProfile();
    if (profile == null) return null;

    if (profile.isGuest) return profile;

    // 소셜 사용자 — 토큰이 사라졌다면 세션 무효화
    if (!await _tokens.hasTokens) {
      await _clearProfile();
      return null;
    }
    return profile;
  }

  /// 제공자별 로그인.
  Future<AuthResult> signIn(AuthProvider provider) async {
    return switch (provider) {
      AuthProvider.kakao => _signInKakao(),
      AuthProvider.naver => _signInNaver(),
      AuthProvider.guest => _signInGuest(),
    };
  }

  // ── 카카오 ─────────────────────────────────────────────
  Future<AuthResult> _signInKakao() async {
    final String socialAccessToken;
    var name = '카카오 사용자';
    String? email;
    var providerId = '';

    try {
      final OAuthToken token = await isKakaoTalkInstalled()
          ? await UserApi.instance.loginWithKakaoTalk()
          : await UserApi.instance.loginWithKakaoAccount();
      socialAccessToken = token.accessToken;

      final kakaoUser = await UserApi.instance.me();
      providerId = '${kakaoUser.id}';
      final account = kakaoUser.kakaoAccount;
      name = account?.profile?.nickname ?? name;
      email = account?.email;
    } on KakaoAuthException catch (e) {
      throw SocialLoginException(
        e.error.toString(),
        cancelled: e.error == AuthErrorCause.accessDenied,
      );
    } on KakaoClientException catch (e) {
      throw SocialLoginException(
        e.msg.isNotEmpty ? e.msg : '카카오 로그인을 취소했습니다.',
        cancelled: e.reason == ClientErrorCause.cancelled,
      );
    } on Exception catch (e) {
      throw SocialLoginException('카카오 로그인에 실패했습니다. ($e)');
    }

    return _loginToBackend(
      provider: AuthProvider.kakao,
      socialAccessToken: socialAccessToken,
      providerId: providerId,
      name: name,
      email: email,
    );
  }

  // ── 네이버 ─────────────────────────────────────────────
  Future<AuthResult> _signInNaver() async {
    final String socialAccessToken;
    var name = '네이버 사용자';
    String? email;
    var providerId = '';

    try {
      final NaverLoginResult result = await FlutterNaverLogin.logIn();
      if (result.status == NaverLoginStatus.error) {
        // 설정/등록 오류 등은 '취소'가 아니므로 화면에 그대로 노출한다.
        throw SocialLoginException('네이버 로그인 설정 오류입니다. ($result)');
      }
      if (result.status != NaverLoginStatus.loggedIn) {
        throw const SocialLoginException('네이버 로그인을 취소했습니다.',
            cancelled: true);
      }

      // logIn() 내부는 getCurrentAccount() 를 호출해 계정 정보만 반환하고
      // accessToken 은 null 로 내려온다 — 토큰은 별도로 조회해야 한다.
      final NaverToken naverToken = await FlutterNaverLogin.getCurrentAccessToken();
      if (naverToken.accessToken.isEmpty) {
        throw const SocialLoginException('네이버 토큰을 받지 못했습니다.');
      }
      socialAccessToken = naverToken.accessToken;

      // 2.x 부터 계정 필드는 모두 nullable 이다.
      final account = result.account;
      providerId = account?.id ?? '';
      final nickname = account?.nickname;
      final realName = account?.name;
      name = (nickname != null && nickname.isNotEmpty)
          ? nickname
          : (realName != null && realName.isNotEmpty ? realName : name);
      final accountEmail = account?.email;
      email =
          (accountEmail != null && accountEmail.isNotEmpty) ? accountEmail : null;
    } on SocialLoginException {
      rethrow;
    } on Exception catch (e) {
      throw SocialLoginException('네이버 로그인에 실패했습니다. ($e)');
    }

    return _loginToBackend(
      provider: AuthProvider.naver,
      socialAccessToken: socialAccessToken,
      providerId: providerId,
      name: name,
      email: email,
    );
  }

  // ── 게스트(둘러보기) — 서버 호출 없음 ─────────────────────
  Future<AuthResult> _signInGuest() async {
    final profile = UserProfile(
      id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      name: '여행자',
      provider: AuthProvider.guest,
    );
    await _persistProfile(profile);
    return AuthResult(profile: profile, isNewUser: true);
  }

  /// 소셜 access token 을 백엔드에 보내 JWT 를 받고 세션을 저장한다.
  Future<AuthResult> _loginToBackend({
    required AuthProvider provider,
    required String socialAccessToken,
    required String providerId,
    required String name,
    String? email,
  }) async {
    final res = await _api.socialLogin(
      providerCode: provider.code,
      socialAccessToken: socialAccessToken,
    );

    await _tokens.save(
      accessToken: res.accessToken,
      refreshToken: res.refreshToken,
    );

    final profile = UserProfile(
      id: '${provider.code}_$providerId',
      name: name,
      provider: provider,
      email: email,
    );
    await _persistProfile(profile);

    return AuthResult(profile: profile, isNewUser: res.isNewUser);
  }

  /// 닉네임 설정/변경 (`PATCH /api/v1/users/me`).
  /// 성공 시 저장된 프로필의 닉네임을 갱신해 반환한다.
  Future<UserProfile> setNickname(String nickname) async {
    await _api.updateNickname(nickname);
    final current = await _readProfile();
    final updated =
        (current ?? _fallbackProfile()).copyWith(nickname: nickname);
    await _persistProfile(updated);
    return updated;
  }

  /// 로그아웃 — 서버 토큰 무효화 + SDK 로그아웃 + 로컬 정리.
  Future<void> signOut() async {
    final profile = await _readProfile();

    if (profile != null && !profile.isGuest) {
      // 서버 로그아웃은 실패하더라도 로컬 정리는 진행한다.
      try {
        await _api.logout();
      } on ApiException {
        // 이미 만료/무효 — 무시
      } on NetworkException {
        // 오프라인 — 로컬만 정리
      }
      await _socialSdkLogout(profile.provider);
    }

    await _tokens.clear();
    await _clearProfile();
  }

  Future<void> _socialSdkLogout(AuthProvider provider) async {
    try {
      switch (provider) {
        case AuthProvider.kakao:
          await UserApi.instance.logout();
        case AuthProvider.naver:
          await FlutterNaverLogin.logOut();
        case AuthProvider.guest:
          break;
      }
    } on Exception {
      // SDK 로그아웃 실패는 치명적이지 않음 — 로컬 세션은 이미 정리됨
    }
  }

  // ── 프로필 저장소 (표시용, 비민감) ───────────────────────
  Future<UserProfile?> _readProfile() async {
    final prefs = await _prefs();
    final raw = prefs.getString(_kStorageKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      await prefs.remove(_kStorageKey);
      return null;
    }
  }

  Future<void> _persistProfile(UserProfile profile) async {
    final prefs = await _prefs();
    await prefs.setString(_kStorageKey, jsonEncode(profile.toJson()));
  }

  Future<void> _clearProfile() async {
    final prefs = await _prefs();
    await prefs.remove(_kStorageKey);
  }

  UserProfile _fallbackProfile() => const UserProfile(
        id: 'unknown',
        name: '여행자',
        provider: AuthProvider.kakao,
      );
}
