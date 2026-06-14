// 길동무 스모크 테스트.
//
// 기존 템플릿(카운터 앱, MyApp)은 실제 앱과 무관해 컴파일조차 되지 않았다.
// 스플래시 화면 렌더링 + onDone 콜백 호출을 검증한다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gildongmu/screens/splash_screen.dart';

void main() {
  testWidgets('스플래시가 브랜드 텍스트를 표시하고 onDone을 호출한다', (tester) async {
    var done = false;
    await tester.pumpWidget(
      MaterialApp(home: SplashScreen(onDone: () => done = true)),
    );

    expect(find.text('길\n동무'), findsOneWidget);
    expect(find.text('지방축제 통합 내비게이션'), findsOneWidget);
    expect(done, isFalse);

    // 스플래시 타이머(2400ms) 경과 후 onDone 호출
    await tester.pump(const Duration(milliseconds: 2500));
    expect(done, isTrue);
  });
}
