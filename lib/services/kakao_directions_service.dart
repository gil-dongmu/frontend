import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

/// 위경도 한 점.
class LatLngPoint {
  const LatLngPoint(this.lat, this.lng);
  final double lat;
  final double lng;
}

/// 길찾기 결과 — 경로 좌표열 + 총거리(m) + 예상시간(초).
class DirectionsResult {
  const DirectionsResult({
    required this.path,
    required this.distanceM,
    required this.durationS,
  });

  final List<LatLngPoint> path;
  final int distanceM;
  final int durationS;

  String get distanceText => distanceM >= 1000
      ? '${(distanceM / 1000).toStringAsFixed(1)}km'
      : '${distanceM}m';

  String get durationText {
    final m = (durationS / 60).round();
    if (m < 60) return '$m분';
    return '${m ~/ 60}시간 ${m % 60}분';
  }
}

/// 카카오모빌리티 자동차 길찾기(내비) REST API 클라이언트.
///
/// 카카오내비 앱을 외부로 띄우지 않고, 경로 데이터를 받아 우리 앱의
/// 인앱 카카오맵 위에 직접 그리기 위해 사용한다.
///   GET https://apis-navi.kakaomobility.com/v1/directions
///   Header: Authorization: KakaoAK {REST_API_KEY}
class KakaoDirectionsService {
  KakaoDirectionsService({http.Client? client})
      : _http = client ?? http.Client();

  final http.Client _http;

  static const _base = 'https://apis-navi.kakaomobility.com/v1/directions';

  /// 자동차 경로 조회. REST 키가 없으면 null 을 반환(직선 폴백 유도).
  Future<DirectionsResult?> carRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    if (ApiConfig.kakaoRestApiKey.isEmpty) return null;

    final uri = Uri.parse('$_base'
        '?origin=$originLng,$originLat'
        '&destination=$destLng,$destLat'
        '&priority=RECOMMEND');

    final res = await _http.get(uri, headers: {
      'Authorization': 'KakaoAK ${ApiConfig.kakaoRestApiKey}',
    }).timeout(const Duration(seconds: 12));

    if (res.statusCode != 200) {
      throw Exception('길찾기 API 오류 (${res.statusCode})');
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final routes = json['routes'] as List?;
    if (routes == null || routes.isEmpty) return null;

    final route = routes.first as Map<String, dynamic>;
    final resultCode = (route['result_code'] as num?)?.toInt();
    if (resultCode != null && resultCode != 0) {
      throw Exception('경로를 찾지 못했습니다 (${route['result_msg']})');
    }

    final summary = route['summary'] as Map<String, dynamic>?;
    final dist = (summary?['distance'] as num?)?.toInt() ?? 0;
    final dur = (summary?['duration'] as num?)?.toInt() ?? 0;

    final path = <LatLngPoint>[];
    for (final section in (route['sections'] as List? ?? const [])) {
      for (final road in ((section as Map)['roads'] as List? ?? const [])) {
        // vertexes: [x, y, x, y, ...] (x=lng, y=lat)
        final vtx = (road as Map)['vertexes'] as List?;
        if (vtx == null) continue;
        for (var i = 0; i + 1 < vtx.length; i += 2) {
          final lng = (vtx[i] as num).toDouble();
          final lat = (vtx[i + 1] as num).toDouble();
          path.add(LatLngPoint(lat, lng));
        }
      }
    }

    return DirectionsResult(path: path, distanceM: dist, durationS: dur);
  }

  void dispose() => _http.close();
}
