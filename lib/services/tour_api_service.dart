import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../models/festival.dart';
import 'api_config.dart';

/// 한국관광공사 TourAPI(KorService2) 클라이언트.
///
/// 지원 오퍼레이션:
///  - searchFestival2   : 기간별 축제 검색
///  - areaBasedList2    : 지역(시도/시군구) 기반 목록
///  - locationBasedList2: 현재 위치 반경 기반 목록
///  - searchKeyword2    : 키워드 검색
///  - detailCommon2     : 공통 상세(개요 등)
///  - detailIntro2      : 소개 상세(운영시간/입장료/주최 등)
///  - detailImage2      : 추가 이미지
class TourApiService {
  final http.Client _client;
  TourApiService([http.Client? client]) : _client = client ?? http.Client();

  Map<String, String> _common({int rows = 20, int page = 1}) => {
        'serviceKey': ApiConfig.tourApiKey,
        'MobileOS': ApiConfig.mobileOS,
        'MobileApp': ApiConfig.mobileApp,
        '_type': 'json',
        'numOfRows': '$rows',
        'pageNo': '$page',
      };

  Uri _uri(String op, Map<String, String> params) {
    // serviceKey는 이미 디코딩된 키를 query에 그대로 싣되, http 패키지가 인코딩.
    return Uri.parse('${ApiConfig.tourApiBase}/$op')
        .replace(queryParameters: params);
  }

  /// 응답 본문에서 item 리스트 안전 추출 (item이 단일 객체/배열/빈값 모두 대응)
  List<Map<String, dynamic>> _items(Map<String, dynamic> json) {
    try {
      final body = json['response']?['body'];
      final items = body?['items'];
      if (items == null || items == '') return [];
      final item = items['item'];
      if (item == null) return [];
      if (item is List) return item.cast<Map<String, dynamic>>();
      return [Map<String, dynamic>.from(item)];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> _get(String op, Map<String, String> params) async {
    if (!ApiConfig.hasTourKey) {
      throw const TourApiException('TOUR_API_KEY 미설정 (api_config.dart 참고)');
    }
    final res = await _client.get(_uri(op, params)).timeout(
          const Duration(seconds: 12),
        );
    if (res.statusCode != 200) {
      throw TourApiException('HTTP ${res.statusCode}');
    }
    // data.go.kr는 오류 시 XML(SERVICE ERROR)을 반환하기도 함
    if (res.body.trimLeft().startsWith('<')) {
      throw TourApiException('API 오류 응답: ${_extractXmlMsg(res.body)}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  String _extractXmlMsg(String xml) {
    final m = RegExp(r'<returnAuthMsg>(.*?)</returnAuthMsg>').firstMatch(xml) ??
        RegExp(r'<errMsg>(.*?)</errMsg>').firstMatch(xml);
    return m?.group(1) ?? '알 수 없는 오류';
  }

  /// 기간별 축제 검색. [from]~[to] 사이 시작하는 축제.
  Future<List<Festival>> searchFestivals({
    DateTime? from,
    String? areaCode,
    String arrange = 'Q', // A:제목 C:수정일 D:생성일 O:대표이미지+제목 Q:수정일+대표이미지 R:생성일+대표이미지
    int rows = 30,
    int page = 1,
  }) async {
    final start = from ?? DateTime.now();
    final params = _common(rows: rows, page: page)
      ..addAll({
        'eventStartDate': DateFormat('yyyyMMdd').format(start),
        'arrange': arrange,
        if (areaCode != null) 'areaCode': areaCode,
      });
    final json = await _get('searchFestival2', params);
    return _items(json).map(Festival.fromTourApi).toList();
  }

  /// 지역 기반 축제 목록
  Future<List<Festival>> areaBasedFestivals({
    String? areaCode,
    String? sigunguCode,
    int rows = 30,
    int page = 1,
  }) async {
    final params = _common(rows: rows, page: page)
      ..addAll({
        'contentTypeId': ApiConfig.contentTypeFestival,
        'arrange': 'Q',
        if (areaCode != null) 'areaCode': areaCode,
        if (sigunguCode != null) 'sigunguCode': sigunguCode,
      });
    final json = await _get('areaBasedList2', params);
    return _items(json).map(Festival.fromTourApi).toList();
  }

  /// 현재 위치 반경 기반 축제 목록
  Future<List<Festival>> nearbyFestivals({
    required double lat,
    required double lng,
    int radiusMeters = 50000,
    int rows = 30,
  }) async {
    final params = _common(rows: rows)
      ..addAll({
        'contentTypeId': ApiConfig.contentTypeFestival,
        'mapX': '$lng',
        'mapY': '$lat',
        'radius': '$radiusMeters',
        'arrange': 'E', // E: 거리순 (위치기반)
      });
    final json = await _get('locationBasedList2', params);
    return _items(json).map(Festival.fromTourApi).toList();
  }

  /// 키워드 검색
  Future<List<Festival>> searchKeyword(String keyword, {int rows = 30}) async {
    final params = _common(rows: rows)
      ..addAll({
        'keyword': keyword,
        'contentTypeId': ApiConfig.contentTypeFestival,
        'arrange': 'Q',
      });
    final json = await _get('searchKeyword2', params);
    return _items(json).map(Festival.fromTourApi).toList();
  }

  /// 상세 보강 — 개요(detailCommon2) + 소개(detailIntro2)를 합쳐 Festival 갱신
  Future<Festival> enrichDetail(Festival f) async {
    String overview = f.overview;
    String fee = f.fee;
    String hours = f.hours;

    try {
      final common = await _get('detailCommon2', {
        'serviceKey': ApiConfig.tourApiKey,
        'MobileOS': ApiConfig.mobileOS,
        'MobileApp': ApiConfig.mobileApp,
        '_type': 'json',
        'contentId': f.contentId,
        'overviewYN': 'Y',
        'defaultYN': 'Y',
      });
      final c = _items(common).firstOrNull;
      if (c != null) {
        overview = '${c['overview'] ?? overview}'.replaceAll(RegExp(r'<[^>]*>'), '');
      }
    } catch (_) {}

    try {
      final intro = await _get('detailIntro2', {
        'serviceKey': ApiConfig.tourApiKey,
        'MobileOS': ApiConfig.mobileOS,
        'MobileApp': ApiConfig.mobileApp,
        '_type': 'json',
        'contentId': f.contentId,
        'contentTypeId': ApiConfig.contentTypeFestival,
      });
      final i = _items(intro).firstOrNull;
      if (i != null) {
        final ut = '${i['usetimefestival'] ?? ''}'.replaceAll(RegExp(r'<[^>]*>'), '');
        final pt = '${i['playtime'] ?? ''}'.replaceAll(RegExp(r'<[^>]*>'), '');
        if (ut.isNotEmpty) fee = ut;
        if (pt.isNotEmpty) hours = pt;
      }
    } catch (_) {}

    return f.copyWith(overview: overview, fee: fee, hours: hours);
  }
}

class TourApiException implements Exception {
  final String message;
  const TourApiException(this.message);
  @override
  String toString() => 'TourApiException: $message';
}

extension _FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
