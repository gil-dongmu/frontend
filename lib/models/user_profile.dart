import '../theme/app_colors.dart';
import 'package:flutter/material.dart';

enum AuthProvider {
  kakao,
  naver,
  guest;

  /// 백엔드 `POST /api/v1/auth/login/{provider}` 의 path 코드.
  /// (서버 Provider enum: KAKAO("kakao"), NAVER("naver"))
  String get code => switch (this) {
        AuthProvider.kakao => 'kakao',
        AuthProvider.naver => 'naver',
        AuthProvider.guest => 'guest',
      };

  /// 백엔드 로그인 API를 호출하는 실제 소셜 제공자인지 여부.
  /// guest(둘러보기)는 서버를 호출하지 않는 로컬 전용 모드.
  bool get isSocial => this == AuthProvider.kakao || this == AuthProvider.naver;

  String get label => switch (this) {
        AuthProvider.kakao => '카카오',
        AuthProvider.naver => '네이버',
        AuthProvider.guest => '둘러보기',
      };

  Color get brandColor => switch (this) {
        AuthProvider.kakao => const Color(0xFFFEE500),
        AuthProvider.naver => const Color(0xFF03C75A),
        AuthProvider.guest => AppColors.cream,
      };

  Color get onBrandColor => switch (this) {
        AuthProvider.kakao => const Color(0xFF191919),
        AuthProvider.naver => Colors.white,
        AuthProvider.guest => AppColors.inkSoft,
      };
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.provider,
    this.email,
    this.photoUrl,
    this.nickname,
  });

  final String id;
  final String name;
  final AuthProvider provider;
  final String? email;
  final String? photoUrl;

  /// 백엔드에서 설정한 닉네임(`PATCH /api/v1/users/me`).
  /// 신규 회원은 닉네임 설정 전까지 null.
  final String? nickname;

  bool get isGuest => provider == AuthProvider.guest;

  /// 화면에 표시할 이름 — 닉네임 우선, 없으면 소셜 프로필 이름.
  String get displayName =>
      (nickname != null && nickname!.isNotEmpty) ? nickname! : name;

  /// 이름 첫 글자 — 아바타 폴백
  String get initial => displayName.isEmpty
      ? '여'
      : displayName.characters.first.toUpperCase();

  UserProfile copyWith({
    String? id,
    String? name,
    AuthProvider? provider,
    String? email,
    String? photoUrl,
    String? nickname,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      provider: provider ?? this.provider,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      nickname: nickname ?? this.nickname,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'provider': provider.name,
        if (email != null) 'email': email,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (nickname != null) 'nickname': nickname,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      provider: AuthProvider.values.firstWhere(
        (p) => p.name == json['provider'],
        orElse: () => AuthProvider.guest,
      ),
      email: json['email'] as String?,
      photoUrl: json['photoUrl'] as String?,
      nickname: json['nickname'] as String?,
    );
  }
}

/// 로그인 결과 — 발급된 프로필과 신규 회원 여부.
/// 백엔드 `LoginResponse.isNewUser` 를 그대로 전달해
/// 신규 회원이면 닉네임 설정 화면으로 분기한다.
class AuthResult {
  const AuthResult({required this.profile, required this.isNewUser});

  final UserProfile profile;
  final bool isNewUser;
}
