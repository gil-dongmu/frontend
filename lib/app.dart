import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_state.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'models/festival.dart';
import 'models/user_profile.dart';
import 'widgets/bottom_nav.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/nickname_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/discover_screen.dart';
import 'screens/recommend_screen.dart';
import 'screens/mypage_screen.dart';
import 'screens/search_screen.dart';
import 'screens/detail_screen.dart';

class GilDongMuApp extends StatelessWidget {
  const GilDongMuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: '길동무',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const _Root(),
      ),
    );
  }
}

enum _Phase { splash, login, nickname, onboarding, main }

class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  _Phase phase = _Phase.splash;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final app = context.read<AppState>();
      // 저장된 로그인 우선 복원 — 끝나야 main으로 직행할지 판단 가능
      await app.restoreAuth();
      // 데이터/위치 초기 로드는 병렬로
      // ignore: use_build_context_synchronously
      app.bootstrap();
    });
  }

  void _onSplashDone() {
    final app = context.read<AppState>();
    setState(() {
      phase = app.isAuthenticated ? _Phase.main : _Phase.login;
    });
  }

  void _onSignedIn(AuthResult result) {
    setState(() {
      if (result.profile.isGuest) {
        // 게스트는 닉네임 없이 바로 온보딩
        phase = _Phase.onboarding;
      } else if (result.isNewUser) {
        // 신규 회원 → 닉네임 설정 → 온보딩
        phase = _Phase.nickname;
      } else {
        // 기존 회원 → 바로 메인
        phase = _Phase.main;
      }
    });
  }

  void _onNicknameDone() => setState(() => phase = _Phase.onboarding);

  void _onOnboardingDone() => setState(() => phase = _Phase.main);

  void _onSignOut() => setState(() => phase = _Phase.login);

  @override
  Widget build(BuildContext context) {
    return switch (phase) {
      _Phase.splash => SplashScreen(onDone: _onSplashDone),
      _Phase.login => LoginScreen(onSignedIn: _onSignedIn),
      _Phase.nickname => NicknameScreen(onDone: _onNicknameDone),
      _Phase.onboarding => OnboardingScreen(onDone: _onOnboardingDone),
      _Phase.main => _MainShell(onSignOut: _onSignOut),
    };
  }
}

class _MainShell extends StatefulWidget {
  const _MainShell({required this.onSignOut});

  final VoidCallback onSignOut;

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  int tab = 0;

  void _openFest(Festival f) {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => DetailScreen(festival: f)));
  }

  void _openSearch() {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => SearchScreen(onOpenFest: _openFest)));
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    // 로딩 화면 — 스피너 대신 홈 레이아웃 스켈레톤
    if (app.state == LoadState.loading || app.state == LoadState.idle) {
      return const Scaffold(
        body: SafeArea(child: _SkeletonHome()),
      );
    }

    // IndexedStack — 탭을 오가도 각 화면의 스크롤/상태가 유지된다
    final body = IndexedStack(
      index: tab,
      children: [
        HomeScreen(
            onOpenFest: _openFest,
            onOpenSearch: _openSearch,
            onGoTab: (t) => setState(() => tab = t)),
        DiscoverScreen(onOpenFest: _openFest),
        RecommendScreen(onOpenFest: _openFest),
        MyPageScreen(
          onOpenFest: _openFest,
          onSignOut: widget.onSignOut,
        ),
      ],
    );

    return Scaffold(
      body: SafeArea(bottom: false, child: body),
      bottomNavigationBar: BottomNav(
        index: tab,
        onChanged: (i) => setState(() => tab = i),
      ),
    );
  }
}

/// 초기 로딩 스켈레톤 — 홈 레이아웃을 닮은 펄스 박스
class _SkeletonHome extends StatefulWidget {
  const _SkeletonHome();

  @override
  State<_SkeletonHome> createState() => _SkeletonHomeState();
}

class _SkeletonHomeState extends State<_SkeletonHome>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _box(double w, double h, {double r = 12}) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: AppColors.line.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(r),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.45, end: 1.0).animate(_c),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _box(120, 30),
            const SizedBox(height: 8),
            _box(70, 12),
            const SizedBox(height: 24),
            _box(double.infinity, 180, r: 18),
            const SizedBox(height: 24),
            _box(140, 18),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _box(double.infinity, 200, r: 16)),
              const SizedBox(width: 12),
              Expanded(child: _box(double.infinity, 200, r: 16)),
            ]),
            const SizedBox(height: 16),
            _box(double.infinity, 64, r: 14),
          ],
        ),
      ),
    );
  }
}
