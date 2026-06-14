import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../models/festival.dart';
import '../models/user_profile.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/common.dart';
import '../widgets/festival_image.dart';

class MyPageScreen extends StatefulWidget {
  final void Function(Festival) onOpenFest;
  final VoidCallback onSignOut;
  const MyPageScreen({required this.onOpenFest, required this.onSignOut});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  int tab = 0; // 0 방문 1 찜 2 리뷰

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final user = app.currentUser;
    final visited = app.all.skip(2).take(3).toList();
    final saved = app.saved; // 실제 찜 목록만 표시 (가짜 폴백 제거)

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Row(
            children: [
              Expanded(child: Text('마이', style: AppType.display(size: 32))),
              IconButton(
                tooltip: '로그아웃',
                icon: const Icon(Icons.logout, color: AppColors.ink),
                onPressed: () => _confirmSignOut(context),
              ),
            ],
          ),
        ),
        // 프로필 카드
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
                color: AppColors.ink, borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                Row(children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                        color: AppColors.vermilion, shape: BoxShape.circle),
                    child: Text(user?.initial ?? '여',
                        style:
                            AppType.display(size: 24, color: Colors.white)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('여행자 LEVEL 03',
                                style: AppType.kicker(color: AppColors.yellow)
                                    .copyWith(letterSpacing: 1.8)),
                            if (user != null) ...[
                              const SizedBox(width: 8),
                              _ProviderBadge(provider: user.provider),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(user?.name ?? '축제 동무',
                            style: AppType.display(
                                size: 22, color: AppColors.cream)),
                        if (user?.email != null) ...[
                          const SizedBox(height: 2),
                          Text(user!.email!,
                              style: AppType.body(
                                  size: 11, color: Colors.white70)),
                        ],
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 18),
                Row(children: [
                  _stat('12', '방문 축제'),
                  const SizedBox(width: 8),
                  _stat('${saved.length}', '찜한 축제'),
                  const SizedBox(width: 8),
                  _stat('7', '리뷰'),
                ]),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('다음 레벨 LV.04 「길 닦이」',
                            style: AppType.body(
                                size: 10,
                                weight: FontWeight.w700,
                                color: Colors.white70)),
                        Text('3회 남음',
                            style: AppType.body(
                                size: 10,
                                weight: FontWeight.w700,
                                color: Colors.white70)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: 0.6,
                        minHeight: 6,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        valueColor:
                            const AlwaysStoppedAnimation(AppColors.yellow),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // 빠른 메뉴
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: Row(
            children: [
              _quick(Icons.bookmark_border, '찜'),
              _quick(Icons.flag_outlined, '방문'),
              _quick(Icons.star_border, '리뷰'),
              _quick(Icons.route, '코스'),
            ],
          ),
        ),
        // 탭
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Row(
            children: ['방문 기록', '찜한 축제', '내 리뷰'].asMap().entries.map((e) {
              final on = tab == e.key;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => tab = e.key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                            color: on ? AppColors.vermilion : AppColors.line,
                            width: on ? 2.5 : 1),
                      ),
                    ),
                    child: Center(
                      child: Text(e.value,
                          style: AppType.body(
                              size: 13,
                              weight: FontWeight.w700,
                              color: on ? AppColors.ink : AppColors.muted)),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        if (tab == 0)
          ...visited.map((f) => _visitedRow(f))
        else if (tab == 1)
          ...(saved.isEmpty
              ? [_emptySaved()]
              : saved.map<Widget>((f) => _savedRow(f)))
        else
          ..._reviews(app),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _stat(String n, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(n,
                style: AppType.display(size: 22, color: AppColors.yellow)
                    .copyWith(height: 1)),
            const SizedBox(height: 4),
            Text(label,
                style: AppType.body(size: 10, color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _quick(IconData icon, String label) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 18, color: AppColors.vermilion),
            ),
            const SizedBox(height: 6),
            Text(label,
                style: AppType.body(size: 11, weight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _visitedRow(Festival f) {
    return InkWell(
      onTap: () => widget.onOpenFest(f),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.line))),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child:
                  SizedBox(width: 60, height: 60, child: FestivalImage(festival: f)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(f.name, style: AppType.display(size: 15)),
                  const SizedBox(height: 2),
                  const MetaLine(['2025년 방문', '리뷰 작성됨']),
                  const SizedBox(height: 4),
                  Row(
                    children: List.generate(
                        5,
                        (i) => Icon(
                            i < 4 ? Icons.star : Icons.star_border,
                            size: 12,
                            color: AppColors.yellow)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.muted),
          ],
        ),
      ),
    );
  }

  Widget _emptySaved() {
    return const GdmEmptyState(
      title: '아직 찜한 축제가 없어요',
      subtitle: '축제 상세 화면의 북마크를 눌러 추가해 보세요',
      size: 80,
    );
  }

  Widget _savedRow(Festival f) {
    return InkWell(
      onTap: () => widget.onOpenFest(f),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.line))),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child:
                  SizedBox(width: 60, height: 60, child: FestivalImage(festival: f)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(f.name, style: AppType.display(size: 15)),
                  const SizedBox(height: 2),
                  MetaLine(['${f.region} ${f.city}', f.periodLabel]),
                ],
              ),
            ),
            const Icon(Icons.bookmark, size: 16, color: AppColors.vermilion),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final app = context.read<AppState>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('로그아웃하시겠어요?', style: AppType.display(size: 18)),
        content: Text(
          app.currentUser?.isGuest ?? true
              ? '둘러보기 세션이 종료됩니다.'
              : '${app.currentUser?.name ?? "계정"} 으로 다시 로그인할 수 있어요.',
          style: AppType.body(size: 13, color: AppColors.inkSoft),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text('취소', style: AppType.body(weight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text('로그아웃',
                style: AppType.body(
                    weight: FontWeight.w800, color: AppColors.vermilion)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await app.signOut();
      if (!mounted) return;
      widget.onSignOut();
    }
  }

  List<Widget> _reviews(AppState app) {
    final items = app.all.take(2).toList();
    return items.map((f) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.line))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(f.name, style: AppType.display(size: 14)),
                Row(
                  children: List.generate(
                      5,
                      (i) => Icon(i < 4 ? Icons.star : Icons.star_border,
                          size: 11, color: AppColors.yellow)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('"넓은 현장과 알찬 프로그램. 주차장이 조금 멀지만 셔틀이 잘 되어 있어요."',
                style: AppType.serif(size: 13)),
            const SizedBox(height: 6),
            Text('2025.09.12', style: AppType.kicker().copyWith(letterSpacing: 0.8)),
          ],
        ),
      );
    }).toList();
  }
}

class _ProviderBadge extends StatelessWidget {
  const _ProviderBadge({required this.provider});

  final AuthProvider provider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        provider.label,
        style: AppType.body(
          size: 9,
          weight: FontWeight.w800,
          color: Colors.white,
        ).copyWith(letterSpacing: 0.6),
      ),
    );
  }
}
