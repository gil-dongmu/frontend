import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../data/mock_festivals.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/common.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int step = 0;
  final Set<String> themes = {};
  String? partner;

  static const partners = [
    (id: 'solo', name: '혼자', sub: '여유로운 동선'),
    (id: 'couple', name: '연인과', sub: '로맨틱한 야경'),
    (id: 'family', name: '가족과', sub: '아이 동반 가능'),
    (id: 'friends', name: '친구들과', sub: '체험 + 먹거리'),
  ];

  bool get canNext =>
      step == 0 ? themes.isNotEmpty : (step == 1 ? partner != null : true);

  void _finish() {
    // setPreferences — 선택값을 로컬에 저장해 재시작 후에도 유지
    context.read<AppState>().setPreferences(themes: themes, partner: partner);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            // 진행 표시
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 1단계에서는 뒤로갈 곳이 없으므로 버튼 비활성 (이전에는 온보딩이 통째로 종료됐음)
                  IconButton(
                    onPressed:
                        step > 0 ? () => setState(() => step--) : null,
                    icon: Icon(Icons.arrow_back,
                        color: step > 0 ? AppColors.ink : Colors.transparent),
                  ),
                  Row(
                    children: List.generate(3, (i) {
                      final on = i == step;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: on ? 24 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i <= step ? AppColors.ink : AppColors.line,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                  TextButton(
                    onPressed: _finish,
                    child: Text('건너뛰기',
                        style: AppType.body(
                            size: 13,
                            weight: FontWeight.w600,
                            color: AppColors.muted)),
                  ),
                ],
              ),
            ),
            // 헤더
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('STEP ${step + 1} / 3',
                      style: AppType.kicker(color: AppColors.vermilion)),
                  const SizedBox(height: 12),
                  Text(_title, style: AppType.display(size: 36)),
                  const SizedBox(height: 12),
                  Text(_desc, style: AppType.serif(size: 14)),
                ],
              ),
            ),
            Expanded(child: SingleChildScrollView(child: _body())),
            // CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Opacity(
                opacity: canNext ? 1 : 0.4,
                child: GdmButton(
                  step == 2 ? '길동무 시작하기' : '다음',
                  primary: true,
                  full: true,
                  icon: step == 2 ? Icons.auto_awesome : Icons.arrow_forward,
                  onTap: canNext
                      ? () => step < 2 ? setState(() => step++) : _finish()
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _title => switch (step) {
        0 => '어떤 축제를\n좋아하세요?',
        1 => '누구와\n함께 가시나요?',
        _ => '위치와\n알림 권한',
      };
  String get _desc => switch (step) {
        0 => '관심 있는 테마를 골라주세요 (복수 선택)',
        1 => '동행 유형을 알려주시면 더 맞는 추천을 드려요',
        _ => '주변 축제 추천과 길 안내를 위해 위치가 필요해요',
      };

  Widget _body() {
    switch (step) {
      case 0:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kThemes
                .where((t) => t.id != 'all')
                .map((t) => GdmChip(
                      label: t.name,
                      leading: t.icon,
                      active: themes.contains(t.id),
                      onTap: () => setState(() => themes.contains(t.id)
                          ? themes.remove(t.id)
                          : themes.add(t.id)),
                    ))
                .toList(),
          ),
        );
      case 1:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: partners.map((p) {
              final on = partner == p.id;
              return GestureDetector(
                onTap: () => setState(() => partner = p.id),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: on ? AppColors.ink : AppColors.paper,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: on ? AppColors.ink : AppColors.line, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name,
                                style: AppType.display(
                                    size: 18,
                                    color:
                                        on ? AppColors.cream : AppColors.ink)),
                            const SizedBox(height: 2),
                            Text(p.sub,
                                style: AppType.body(
                                    size: 12,
                                    color: on
                                        ? Colors.white70
                                        : AppColors.muted)),
                          ],
                        ),
                      ),
                      if (on)
                        const Icon(Icons.check, color: AppColors.yellow, size: 22),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      default:
        final perms = [
          (icon: Icons.location_on, name: '위치 정보', desc: '주변 축제 + 실시간 길 안내', critical: true),
          (icon: Icons.notifications, name: '알림', desc: '저장한 축제 시작 알림', critical: false),
          (icon: Icons.cloud_off, name: '오프라인 데이터', desc: '통신 약한 지역 대비 캐싱', critical: false),
        ];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: perms.map((p) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.line, width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: p.critical ? AppColors.vermilion : AppColors.ink,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(p.icon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(p.name, style: AppType.display(size: 15)),
                              if (p.critical) ...[
                                const SizedBox(width: 6),
                                Text('필수',
                                    style: AppType.body(
                                        size: 10,
                                        color: AppColors.vermilion,
                                        weight: FontWeight.w700)),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(p.desc,
                              style: AppType.body(
                                  size: 12, color: AppColors.muted)),
                        ],
                      ),
                    ),
                    _Toggle(on: true),
                  ],
                ),
              );
            }).toList(),
          ),
        );
    }
  }
}

class _Toggle extends StatelessWidget {
  final bool on;
  const _Toggle({required this.on});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 22,
      decoration: BoxDecoration(
        color: on ? AppColors.vermilion : AppColors.line,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Align(
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.all(2),
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
              color: Colors.white, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
