import 'package:flutter/material.dart';

import '../models/festival.dart';
import '../models/course.dart';
import '../data/mock_festivals.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/common.dart';

class CourseScreen extends StatefulWidget {
  final Festival festival;
  const CourseScreen({required this.festival});

  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> {
  int activeDay = 1;
  late final Course course;

  @override
  void initState() {
    super.initState();
    course = MockData.courseFor(widget.festival);
  }

  Color _color(CourseItemType t) => switch (t) {
        CourseItemType.festival => AppColors.vermilion,
        CourseItemType.food => AppColors.yellow,
        CourseItemType.spot => AppColors.plum,
        CourseItemType.stay => AppColors.teal,
      };

  IconData _icon(CourseItemType t) => switch (t) {
        CourseItemType.festival => Icons.celebration,
        CourseItemType.food => Icons.restaurant,
        CourseItemType.spot => Icons.location_on,
        CourseItemType.stay => Icons.hotel,
      };

  String _label(CourseItemType t) => switch (t) {
        CourseItemType.festival => '축제',
        CourseItemType.food => '맛집',
        CourseItemType.spot => '관광',
        CourseItemType.stay => '숙박',
      };

  @override
  Widget build(BuildContext context) {
    final day = course.days.firstWhere((d) => d.day == activeDay,
        orElse: () => course.days.first);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: AppColors.ink)),
                  Expanded(
                      child: Text('코스 만들기', style: AppType.display(size: 22))),
                  const Icon(Icons.edit_outlined, color: AppColors.ink),
                ],
              ),
            ),
            // 타이틀 카드
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: AppColors.ink, borderRadius: BorderRadius.circular(18)),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AI 자동 코스 · ${course.days.length}일',
                          style: AppType.kicker(color: AppColors.yellow)
                              .copyWith(letterSpacing: 2)),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(right: 60),
                        child: Text(course.title,
                            style:
                                AppType.display(size: 22, color: AppColors.cream)),
                      ),
                      const SizedBox(height: 10),
                      Row(children: [
                        _miniStat('${course.days.length}', '일'),
                        const SizedBox(width: 16),
                        _miniStat('${course.placeCount}', '곳'),
                        const SizedBox(width: 16),
                        _miniStat(
                            '₩${(course.total / 10000).toStringAsFixed(1)}만', ''),
                      ]),
                    ],
                  ),
                  Positioned(
                      top: 0, right: 0, child: GdmStamp('1박\n2일', size: 48)),
                ],
              ),
            ),
            // 데이 탭
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: course.days.map((d) {
                  final on = activeDay == d.day;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => activeDay = d.day),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: on ? AppColors.vermilion : AppColors.paper,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: on ? AppColors.vermilion : AppColors.line),
                        ),
                        child: Text('DAY ${d.day}  (${d.items.length}곳)',
                            style: AppType.display(
                                size: 14,
                                color: on ? Colors.white : AppColors.ink)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            // 타임라인
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                children: [
                  Row(children: [
                    // 축제 시작일 기준 N일차 날짜 (시작일 없으면 오늘 기준)
                    Builder(builder: (_) {
                      final base = widget.festival.start ?? DateTime.now();
                      final d = base.add(Duration(days: activeDay - 1));
                      return Text('${d.month}월 ${d.day}일 일정',
                          style: AppType.kicker());
                    }),
                    const Spacer(),
                    RichText(
                      text: TextSpan(children: [
                        TextSpan(
                            text: '예산 ',
                            style: AppType.body(
                                size: 11,
                                weight: FontWeight.w600,
                                color: AppColors.inkSoft)),
                        TextSpan(
                            text: '₩${(day.total / 1000).toStringAsFixed(0)}k',
                            style: AppType.body(
                                size: 11,
                                weight: FontWeight.w700,
                                color: AppColors.vermilion)),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  ...day.items.asMap().entries.map((e) => _itemTile(
                      e.key, e.value, e.key == day.items.length - 1)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                        child: GdmButton('장소 추가',
                            dark: true, icon: Icons.add)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: GdmButton('AI 재추천',
                            dark: true, icon: Icons.auto_awesome)),
                  ]),
                  const SizedBox(height: 16),
                  // 합계
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                        color: AppColors.yellow,
                        borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${course.days.length}일 합계',
                                  style: AppType.kicker(color: AppColors.ink)
                                      .copyWith(letterSpacing: 1.8)),
                              const SizedBox(height: 4),
                              Text('₩${_comma(course.total)}',
                                  style: AppType.display(size: 28)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('1인 기준 · 카드',
                                style: AppType.kicker(color: AppColors.ink)
                                    .copyWith(letterSpacing: 1)),
                            const SizedBox(height: 4),
                            Text('2인 동행 시 -15%',
                                style: AppType.body(size: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // 지역 기여 지표 — 공모전 핵심 컨셉을 정량적으로 표현
                  if (widget.festival.isDeclineRegion) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                          color: AppColors.teal,
                          borderRadius: BorderRadius.circular(14)),
                      child: Row(children: [
                        const Icon(Icons.volunteer_activism,
                            size: 18, color: Colors.white),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '이 코스의 ₩${_comma(course.total)}이 인구감소지역 '
                            '${widget.festival.city} 경제에 직접 쓰입니다',
                            style: AppType.body(
                                size: 12,
                                weight: FontWeight.w600,
                                color: Colors.white),
                          ),
                        ),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.line))),
              child: GdmButton('이 코스로 출발하기',
                  primary: true, full: true, icon: Icons.route),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String v, String unit) {
    return RichText(
      text: TextSpan(children: [
        TextSpan(
            text: v,
            style: AppType.body(
                size: 11, weight: FontWeight.w700, color: AppColors.yellow)),
        TextSpan(
            text: unit,
            style: AppType.body(
                size: 11, weight: FontWeight.w700, color: Colors.white)),
      ]),
    );
  }

  Widget _itemTile(int i, CourseItem item, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: _color(item.type),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.cream, width: 3),
                ),
                child: Icon(_icon(item.type),
                    size: 12,
                    color: item.type == CourseItemType.food
                        ? AppColors.ink
                        : Colors.white),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: AppColors.line)),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(item.time, style: AppType.display(size: 16)),
                    const SizedBox(width: 8),
                    GdmBadge(_label(item.type),
                        color: _color(item.type),
                        dark: item.type == CourseItemType.food),
                  ]),
                  const SizedBox(height: 4),
                  Text(item.name,
                      style: AppType.body(size: 14, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(item.desc,
                      style: AppType.body(size: 12, color: AppColors.muted)),
                  if (item.cost > 0) ...[
                    const SizedBox(height: 6),
                    Text('₩${_comma(item.cost)}',
                        style: AppType.body(
                            size: 11,
                            weight: FontWeight.w700,
                            color: AppColors.vermilion)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _comma(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
