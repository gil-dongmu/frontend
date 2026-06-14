import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../models/festival.dart';
import '../data/mock_festivals.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/common.dart';
import '../widgets/festival_cards.dart';

class SearchScreen extends StatefulWidget {
  final void Function(Festival) onOpenFest;
  const SearchScreen({required this.onOpenFest});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  String q = '';
  List<Festival> results = [];
  bool loading = false;

  static const recent = ['진주유등', '보령머드', '안동 탈춤', '나비축제'];
  static const trending = [
    (rank: 1, name: '진주남강유등축제', change: '↑'),
    (rank: 2, name: '안동국제탈춤페스티벌', change: '↑'),
    (rank: 3, name: '김제지평선축제', change: '—'),
    (rank: 4, name: '화천산천어축제', change: '↓'),
    (rank: 5, name: '보령머드축제', change: 'NEW'),
  ];

  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  /// 입력 디바운스(300ms) — 키 입력마다 API를 때리지 않도록.
  void _onChanged(String value) {
    _debounce?.cancel();
    setState(() {
      q = value;
      loading = value.isNotEmpty;
      if (value.isEmpty) results = [];
    });
    if (value.isEmpty) return;
    _debounce =
        Timer(const Duration(milliseconds: 300), () => _search(value));
  }

  Future<void> _search(String value) async {
    final r = await context.read<AppState>().search(value);
    // 응답이 도착했을 때 입력이 이미 바뀌었으면 버림 (결과 역전 방지)
    if (!mounted || _ctrl.text.trim() != value.trim()) return;
    setState(() {
      results = r;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            // 검색바
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 14, 16, 10),
              child: Row(
                children: [
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: AppColors.ink)),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search,
                              size: 18, color: AppColors.muted),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _ctrl,
                              autofocus: true,
                              onChanged: _onChanged,
                              style: AppType.body(size: 14),
                              decoration: InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: '축제, 지역, 테마로 검색',
                                hintStyle: AppType.body(
                                    size: 14, color: AppColors.muted),
                              ),
                            ),
                          ),
                          if (q.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _ctrl.clear();
                                _onChanged('');
                              },
                              child: const Icon(Icons.close,
                                  size: 16, color: AppColors.muted),
                            ),
                          const SizedBox(width: 6),
                          const Icon(Icons.mic,
                              size: 18, color: AppColors.vermilion),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: q.isEmpty ? _idle(app) : _results(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _idle(AppState app) {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('최근 검색', style: AppType.kicker()),
                  Text('전체 삭제',
                      style: AppType.body(
                          size: 11,
                          weight: FontWeight.w600,
                          color: AppColors.muted)),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: recent
                    .map((r) => GdmChip(
                          label: r,
                          leading: '🕑',
                          active: false,
                          onTap: () {
                            _ctrl.text = r;
                            _onChanged(r);
                          },
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('실시간 인기 (이번 주)', style: AppType.kicker()),
              const SizedBox(height: 12),
              ...trending.map((t) {
                final f = app.all.firstWhere((x) => x.name == t.name,
                    orElse: () => app.all.isNotEmpty
                        ? app.all.first
                        : MockData.festivals.first);
                final color = t.change == '↑'
                    ? AppColors.vermilion
                    : t.change == 'NEW'
                        ? AppColors.teal
                        : AppColors.muted;
                return GestureDetector(
                  onTap: () => widget.onOpenFest(f),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: const BoxDecoration(
                        border: Border(
                            bottom: BorderSide(color: AppColors.line))),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 28,
                          child: Text('${t.rank}',
                              style: AppType.display(
                                  size: 22,
                                  color: t.rank <= 3
                                      ? AppColors.vermilion
                                      : AppColors.muted)),
                        ),
                        Expanded(
                            child: Text(t.name,
                                style: AppType.body(
                                    size: 14, weight: FontWeight.w600))),
                        Text(t.change,
                            style: AppType.body(
                                size: 11,
                                weight: FontWeight.w700,
                                color: color)),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('테마별 둘러보기', style: AppType.kicker()),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: kThemes.where((t) => t.id != 'all').map((t) {
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(t.icon,
                            style: const TextStyle(
                                fontSize: 22, color: AppColors.vermilion)),
                        const SizedBox(height: 6),
                        Text(t.name,
                            style: AppType.body(
                                size: 11, weight: FontWeight.w600)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _results() {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (results.isEmpty) {
      return const GdmEmptyState(
        title: '일치하는 축제가 없어요',
        subtitle: '축제 이름, 지역명, 테마로 다시 검색해 보세요',
      );
    }
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: RichText(
            text: TextSpan(children: [
              TextSpan(
                  text: '"$q" 검색 결과 ',
                  style: AppType.body(
                      size: 11,
                      weight: FontWeight.w600,
                      color: AppColors.muted)),
              TextSpan(
                  text: '${results.length}',
                  style: AppType.body(
                      size: 11,
                      weight: FontWeight.w700,
                      color: AppColors.vermilion)),
              TextSpan(
                  text: '건',
                  style: AppType.body(
                      size: 11,
                      weight: FontWeight.w600,
                      color: AppColors.muted)),
            ]),
          ),
        ),
        ...results.map(
            (f) => FestivalRow(festival: f, onTap: () => widget.onOpenFest(f))),
      ],
    );
  }
}
