import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_profile.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// 소셜 로그인 진입 화면.
///
/// 단청 팔레트(크림 베이스 + 주홍/먹빛) 기반 에디토리얼 카드 형태.
/// Mock 흐름이라 어떤 버튼을 누르든 SDK 호출 없이 데모 프로필이 들어온다.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key, required this.onSignedIn});

  final VoidCallback onSignedIn;

  Future<void> _signIn(BuildContext context, AuthProvider provider) async {
    final app = context.read<AppState>();
    final user = await app.signIn(provider);
    if (user != null && context.mounted) {
      onSignedIn();
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
                provider: AuthProvider.google,
                label: '구글로 시작하기',
                icon: const _GoogleMark(),
                disabled: disabled,
                loading: app.signingInProvider == AuthProvider.google,
                bordered: true,
                onTap: () => _signIn(context, AuthProvider.google),
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

/// G 문자 — 구글 로고 대체
class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4285F4),
            Color(0xFF34A853),
            Color(0xFFFBBC05),
            Color(0xFFEA4335),
          ],
        ),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        'G',
        style: AppType.display(size: 13, color: Colors.white)
            .copyWith(height: 1),
      ),
    );
  }
}
