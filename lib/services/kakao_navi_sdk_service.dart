import 'package:flutter/services.dart';

/// 카카오내비 인앱 주행(KNSDK) 네이티브 브리지.
///
/// 네이티브(MainActivity)의 MethodChannel 'gildongmu/navi' 와 연결된다.
/// 외부 카카오내비 앱을 띄우지 않고, 앱 내부 KNNaviActivity 에서
/// 카카오내비 주행 화면(KNNaviView)을 표시한다. (현재 Android 전용)
class KakaoNaviSdkService {
  static const MethodChannel _channel = MethodChannel('gildongmu/navi');

  /// 출발지(start) → 목적지(goal) 인앱 주행 시작.
  /// 좌표는 WGS84(위경도)로 넘기면 네이티브에서 KATEC 로 변환한다.
  static Future<void> startGuidance({
    required double startLat,
    required double startLng,
    required String startName,
    required double goalLat,
    required double goalLng,
    required String goalName,
  }) {
    return _channel.invokeMethod('startGuidance', {
      'startLat': startLat,
      'startLng': startLng,
      'startName': startName,
      'goalLat': goalLat,
      'goalLng': goalLng,
      'goalName': goalName,
    });
  }
}
