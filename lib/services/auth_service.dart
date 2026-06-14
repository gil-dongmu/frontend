import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';

/// 소셜 로그인 (Mock).
///
/// 실제 OAuth 연동 전 데모/UI 검증용. 호출하면 약간의 지연 후
/// 제공자별 미리 정의된 데모 프로필을 반환한다.
///
/// 실제 키 연동 시 이 파일만 SDK 호출로 교체하면 된다.
///   - 카카오: kakao_flutter_sdk_user
///   - 구글: google_sign_in
class AuthService {
  AuthService({SharedPreferences? prefs}) : _prefsOverride = prefs;

  final SharedPreferences? _prefsOverride;
  static const _kStorageKey = 'gildongmu.auth.user';

  Future<SharedPreferences> _prefs() async =>
      _prefsOverride ?? await SharedPreferences.getInstance();

  /// 저장된 프로필 복원 (앱 시작 시).
  Future<UserProfile?> restore() async {
    final prefs = await _prefs();
    final raw = prefs.getString(_kStorageKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return UserProfile.fromJson(json);
    } catch (_) {
      await prefs.remove(_kStorageKey);
      return null;
    }
  }

  /// 제공자별 mock 로그인. 실제 SDK 연동 시 분기 내부만 교체.
  Future<UserProfile> signIn(AuthProvider provider) async {
    // SDK 호출 시간 흉내
    await Future<void>.delayed(const Duration(milliseconds: 650));

    final profile = switch (provider) {
      AuthProvider.kakao => const UserProfile(
          id: 'kakao_demo_8821',
          name: '김카카오',
          provider: AuthProvider.kakao,
          email: 'demo@kakao.com',
        ),
      AuthProvider.google => const UserProfile(
          id: 'google_demo_7714',
          name: 'Lee Google',
          provider: AuthProvider.google,
          email: 'demo@gmail.com',
        ),
      AuthProvider.guest => UserProfile(
          id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
          name: '여행자',
          provider: AuthProvider.guest,
        ),
    };

    await _persist(profile);
    return profile;
  }

  Future<void> signOut() async {
    final prefs = await _prefs();
    await prefs.remove(_kStorageKey);
  }

  Future<void> _persist(UserProfile profile) async {
    final prefs = await _prefs();
    await prefs.setString(_kStorageKey, jsonEncode(profile.toJson()));
  }
}
