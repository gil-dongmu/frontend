import '../theme/app_colors.dart';
import 'package:flutter/material.dart';

enum AuthProvider {
  kakao,
  google,
  guest;

  String get label => switch (this) {
        AuthProvider.kakao => '카카오',
        AuthProvider.google => '구글',
        AuthProvider.guest => '둘러보기',
      };

  Color get brandColor => switch (this) {
        AuthProvider.kakao => const Color(0xFFFEE500),
        AuthProvider.google => Colors.white,
        AuthProvider.guest => AppColors.cream,
      };

  Color get onBrandColor => switch (this) {
        AuthProvider.kakao => const Color(0xFF191919),
        AuthProvider.google => AppColors.ink,
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
  });

  final String id;
  final String name;
  final AuthProvider provider;
  final String? email;
  final String? photoUrl;

  bool get isGuest => provider == AuthProvider.guest;

  /// 이름 첫 글자 — 아바타 폴백
  String get initial =>
      name.isEmpty ? '여' : name.characters.first.toUpperCase();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'provider': provider.name,
        if (email != null) 'email': email,
        if (photoUrl != null) 'photoUrl': photoUrl,
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
    );
  }
}
