import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_profile.dart';
import '../providers/app_state.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// 소셜 로그인 진입 화면.
///
/// 단청 팔레트(크림 베이스 + 주홍/먹빛) 기반 에디토리얼 카드 형태.
/// 카카오/네이버 SDK 로 로그인한 뒤 백엔드에서 JWT 를 발급받는다.
/// 신규 회원이면 [onSignedIn] 에 isNewUser=true 가 전달되어
/// 닉네임 설정 화면으로 이어진다.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key, required this.onSignedIn});

  /// (isNewUser) — 신규 회원이면 닉네임 설정으로 분기한다.
  final void Function(AuthResult result) onSignedIn;

  Future<void> _signIn(BuildContext context, AuthProvider provider) async {
    final app = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await app.signIn(provider);
      if (result != null && context.mounted) {
        onSignedIn(result);
      }
    } on SocialLoginException catch (e) {
      // 취소는 app.signIn 단계에서 null 로 흡수됨 — 여기 오는 건 실제 오류
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } on NetworkException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final disabled = app.isSigningIn;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              _Brand(),
              const Spacer(flex: 3),
              _ProviderButton(
                provider: AuthProvider.kakao,
                label: '카카오로 시작하기',
                icon: const _KakaoMark(),
                disabled: disabled,
                loading: app.signingInProvider == AuthProvider.kakao,
                onTap: () => _signIn(context, AuthProvider.kakao),
              ),
              const SizedBox(height: 10),
              _ProviderButton(
                provider: AuthProvider.naver,
                label: '네이버로 시작하기',
                icon: const _NaverMark(),
                disabled: disabled,
                loading: app.signingInProvider == AuthProvider.naver,
                onTap: () => _signIn(context, AuthProvider.naver),
              ),
              const SizedBox(height: 18),
              _GuestRow(
                disabled: disabled,
                loading: app.signingInProvider == AuthProvider.guest,
                onTap: () => _signIn(context, AuthProvider.guest),
              ),
              const SizedBox(height: 16),
              _Terms(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.vermilion,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'GIL · DONG · MU',
            style: AppType.kicker(color: Colors.white)
                .copyWith(letterSpacing: 2.4, fontSize: 11),
          ),
        ),
        const SizedBox(height: 22),
        Text('가는 길마다,\n축제 한 자락.',
            style: AppType.display(size: 36, height: 1.18)),
        const SizedBox(height: 14),
        Text(
          '비수도권·인구감소지역 축제를 먼저 비추는\n동선 중심 여행 동무.',
          style: AppType.serif(size: 14, color: AppColors.inkSoft),
        ),
      ],
    );
  }
}

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    required this.provider,
    required this.label,
    required this.icon,
    required this.onTap,
    required this.disabled,
    required this.loading,
    this.bordered = false,
  });

  final AuthProvider provider;
  final String label;
  final Widget icon;
  final VoidCallback onTap;
  final bool disabled;
  final bool loading;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final bg = provider.brandColor;
    final fg = provider.onBrandColor;

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: disabled ? null : onTap,
          child: Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: bordered
                  ? Border.all(color: AppColors.line, width: 1)
                  : null,
            ),
            child: Row(
              children: [
                SizedBox(width: 22, height: 22, child: Center(child: icon)),
                Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: AppType.body(
                        size: 15,
                        weight: FontWeight.w700,
                        color: fg,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 22,
                  height: 22,
                  child: loading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation(fg),
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GuestRow extends StatelessWidget {
  const _GuestRow({
    required this.onTap,
    required this.disabled,
    required this.loading,
  });

  final VoidCallback onTap;
  final bool disabled;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: disabled ? null : onTap,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.inkSoft,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '로그인 없이 둘러보기',
            style: AppType.body(
              size: 13,
              weight: FontWeight.w700,
              color: AppColors.inkSoft,
            ).copyWith(decoration: TextDecoration.underline),
          ),
          const SizedBox(width: 8),
          if (loading)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppColors.inkSoft),
              ),
            )
          else
            const Icon(Icons.arrow_forward, size: 14, color: AppColors.inkSoft),
        ],
      ),
    );
  }
}

class _Terms extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      '계속하면 길동무 이용약관 및 개인정보 처리방침에 동의합니다.',
      textAlign: TextAlign.center,
      style: AppType.body(
        size: 11,
        weight: FontWeight.w500,
        color: AppColors.muted,
      ),
    );
  }
}

/// 카카오 말풍선 — 단순 SVG 대체 (CustomPaint 없이 가벼운 표현)
class _KakaoMark extends StatelessWidget {
  const _KakaoMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFF191919),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.chat_bubble, size: 11, color: Color(0xFFFEE500)),
    );
  }
}

/// N 문자 — 네이버 로고 대체 (흰 N on 네이버 그린은 버튼 배경이 이미 초록이라
/// 여기서는 화이트 라운드 위 그린 N 으로 대비를 준다)
class _NaverMark extends StatelessWidget {
  const _NaverMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'N',
        style: AppType.display(size: 13, color: const Color(0xFF03C75A))
            .copyWith(height: 1, fontWeight: FontWeight.w900),
      ),
    );
  }
}
