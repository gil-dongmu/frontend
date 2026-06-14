/// 축제 프로그램 (detailIntro2 / 자체 데이터)
class FestivalProgram {
  final String time;
  final String name;
  final String location;

  const FestivalProgram({
    required this.time,
    required this.name,
    required this.location,
  });
}

/// 축제 모델 — 한국관광공사 TourAPI(KorService2) 응답에 매핑
///
/// searchFestival2 / areaBasedList2 / detailCommon2 / detailIntro2 의
/// 필드를 통합한 표현.
class Festival {
  final String contentId; // TourAPI contentid
  final String name; // title
  final String? nameEn;
  final String region; // areaCode → 시도명
  final String city; // sigunguCode → 시군구명 (또는 addr1 파싱)
  final String theme; // 자체 분류 (cat 또는 키워드)
  final List<String> themes;
  final DateTime? start; // eventstartdate
  final DateTime? end; // eventenddate
  final String? firstImage; // firstimage (대표 이미지 URL)
  final double lat; // mapy
  final double lng; // mapx
  final String address; // addr1
  final String? tel;

  // 상세 (detailCommon2 / detailIntro2 로 보강)
  final String tagline;
  final String overview; // overview
  final String visitors; // 자체/통계 데이터
  final String fee; // usetimefestival
  final String hours; // playtime
  final String parking;
  final List<FestivalProgram> programs;
  final List<String> nearby;

  // 앱 특화: 인구감소지역 가중치
  final bool isDeclineRegion;

  // 내 위치로부터 거리 (km) — 클라이언트 계산
  final double? distanceKm;

  const Festival({
    required this.contentId,
    required this.name,
    this.nameEn,
    required this.region,
    required this.city,
    required this.theme,
    this.themes = const [],
    this.start,
    this.end,
    this.firstImage,
    required this.lat,
    required this.lng,
    required this.address,
    this.tel,
    this.tagline = '',
    this.overview = '',
    this.visitors = '',
    this.fee = '',
    this.hours = '',
    this.parking = '',
    this.programs = const [],
    this.nearby = const [],
    this.isDeclineRegion = false,
    this.distanceKm,
  });

  /// TourAPI item(JSON) → Festival
  /// searchFestival2 / areaBasedList2 공통 필드 기준
  factory Festival.fromTourApi(Map<String, dynamic> j) {
    DateTime? parseYmd(String? s) {
      if (s == null || s.length != 8) return null;
      return DateTime.tryParse(
          '${s.substring(0, 4)}-${s.substring(4, 6)}-${s.substring(6, 8)}');
    }

    double parseD(dynamic v) => double.tryParse('${v ?? ''}') ?? 0;

    final areaCode = '${j['areacode'] ?? ''}';
    final sigungu = '${j['sigungucode'] ?? ''}';

    return Festival(
      contentId: '${j['contentid'] ?? ''}',
      name: '${j['title'] ?? ''}'.replaceAll(RegExp(r'<[^>]*>'), ''),
      region: AreaCodes.regionName(areaCode),
      city: AreaCodes.firstAddrToken('${j['addr1'] ?? ''}'),
      theme: '전통',
      start: parseYmd('${j['eventstartdate'] ?? ''}'),
      end: parseYmd('${j['eventenddate'] ?? ''}'),
      firstImage: (j['firstimage'] as String?)?.isNotEmpty == true
          ? j['firstimage']
          : (j['firstimage2'] as String?),
      lat: parseD(j['mapy']),
      lng: parseD(j['mapx']),
      address: '${j['addr1'] ?? ''}',
      tel: '${j['tel'] ?? ''}',
      isDeclineRegion: AreaCodes.isDecline(areaCode, sigungu),
    );
  }

  Festival copyWith({
    double? distanceKm,
    String? overview,
    String? fee,
    String? hours,
    List<FestivalProgram>? programs,
  }) {
    return Festival(
      contentId: contentId,
      name: name,
      nameEn: nameEn,
      region: region,
      city: city,
      theme: theme,
      themes: themes,
      start: start,
      end: end,
      firstImage: firstImage,
      lat: lat,
      lng: lng,
      address: address,
      tel: tel,
      tagline: tagline,
      overview: overview ?? this.overview,
      visitors: visitors,
      fee: fee ?? this.fee,
      hours: hours ?? this.hours,
      parking: parking,
      programs: programs ?? this.programs,
      nearby: nearby,
      isDeclineRegion: isDeclineRegion,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }

  String get periodLabel {
    if (start == null || end == null) return '상시';
    String md(DateTime d) => '${d.month}/${d.day}';
    return '${md(start!)}–${md(end!)}';
  }
}

/// 지역 코드 매핑 (TourAPI areaCode) + 인구감소지역 판별
class AreaCodes {
  static const Map<String, String> _region = {
    '1': '서울', '2': '인천', '3': '대전', '4': '대구', '5': '광주',
    '6': '부산', '7': '울산', '8': '세종', '31': '경기', '32': '강원',
    '33': '충북', '34': '충남', '35': '전북', '36': '전남', '37': '경북',
    '38': '경남', '39': '제주',
  };

  static String regionName(String code) => _region[code] ?? '전국';

  static String firstAddrToken(String addr) {
    // "경상남도 진주시 ..." → "진주시"
    final parts = addr.split(' ');
    if (parts.length >= 2) return parts[1];
    return parts.isNotEmpty ? parts.first : '';
  }

  /// 행정안전부 지정 인구감소지역(89개 시군구)에 해당하는 area/sigungu 여부.
  /// 데모: 비수도권 광역(서울/인천/경기 제외)을 가산 대상으로 단순화.
  /// 실제 서비스에서는 89개 시군구 코드 테이블로 교체.
  static const _declineMetroExcluded = {'1', '2', '31'};

  static bool isDecline(String areaCode, String sigunguCode) {
    return !_declineMetroExcluded.contains(areaCode);
  }
}
