import '../models/festival.dart';
import '../models/course.dart';

/// 데모/폴백 데이터 — API 키가 없거나 네트워크 실패 시 사용.
/// 실제 비수도권 축제 근사 데이터 (좌표/기간 실제값 기반, 일부 수치는 데모).
class MockData {
  static final List<Festival> festivals = [
    Festival(
      contentId: 'demo-jinju',
      name: '진주남강유등축제',
      nameEn: 'Jinju Namgang Yudeung Festival',
      region: '경남',
      city: '진주시',
      theme: '전통',
      themes: const ['전통', '문화예술', '야경'],
      start: DateTime(2026, 10, 1),
      end: DateTime(2026, 10, 12),
      lat: 35.187,
      lng: 128.084,
      address: '경상남도 진주시 본성동 남강 일원',
      tel: '055-749-2480',
      tagline: '남강에 떠오르는 만 개의 등불',
      overview:
          '임진왜란 진주성 전투에서 유래한 유등 띄우기를 모티프로, 진주 남강 일대에 약 만 개의 유등이 강물 위로 떠오른다. 야간 관람이 백미.',
      visitors: '약 280만',
      fee: '대인 ₩10,000',
      hours: '10:00–22:00',
      parking: '공영주차장 8곳 운영',
      isDeclineRegion: true,
      programs: const [
        FestivalProgram(time: '11:00', name: '진주성 개막 퍼레이드', location: '진주성 정문'),
        FestivalProgram(time: '14:00', name: '유등 만들기 체험', location: '체험관 A동'),
        FestivalProgram(time: '17:30', name: '소망등 띄우기', location: '남강 둔치'),
        FestivalProgram(time: '19:00', name: '메인 점등식', location: '진주교 일대'),
        FestivalProgram(time: '20:30', name: '미디어 파사드', location: '진주성벽'),
      ],
      nearby: const ['진주성', '국립진주박물관', '촉석루', '진주냉면 하연옥'],
    ),
    Festival(
      contentId: 'demo-boryeong',
      name: '보령머드축제',
      nameEn: 'Boryeong Mud Festival',
      region: '충남',
      city: '보령시',
      theme: '체험',
      themes: const ['체험', '여름', '바다'],
      start: DateTime(2026, 7, 17),
      end: DateTime(2026, 7, 26),
      lat: 36.317,
      lng: 126.503,
      address: '충청남도 보령시 대천해수욕장',
      tel: '041-930-3882',
      tagline: '온 몸이 캔버스가 되는 여름',
      overview:
          '대천해수욕장에서 머드 체험존, 머드 슬라이드, 머드 마사지존 등 진흙을 활용한 대규모 여름 축제. 외국인 방문객 비율이 가장 높다.',
      visitors: '약 200만',
      fee: '무료 / 일부 체험존 ₩8,000',
      hours: '09:00–22:00',
      parking: '대천해수욕장 공영주차장',
      isDeclineRegion: true,
      programs: const [
        FestivalProgram(time: '10:00', name: '머드 슬라이드 OPEN', location: '메인 머드존'),
        FestivalProgram(time: '13:00', name: '머드 마사지', location: 'B존'),
        FestivalProgram(time: '19:30', name: '비치 콘서트', location: '메인 스테이지'),
        FestivalProgram(time: '21:00', name: '불꽃놀이', location: '해변 일대'),
      ],
      nearby: const ['대천해수욕장', '머드테마파크', '무창포해변'],
    ),
    Festival(
      contentId: 'demo-hampyeong',
      name: '함평나비축제',
      nameEn: 'Hampyeong Butterfly Festival',
      region: '전남',
      city: '함평군',
      theme: '자연',
      themes: const ['자연', '봄', '가족'],
      start: DateTime(2026, 4, 25),
      end: DateTime(2026, 5, 6),
      lat: 35.066,
      lng: 126.516,
      address: '전라남도 함평군 함평엑스포공원',
      tel: '061-320-3349',
      tagline: '꽃밭을 가로지르는 날개의 봄',
      overview:
          '함평엑스포공원 일원에 조성된 유채·자운영 꽃밭과 함께 수천 마리의 나비를 가까이서 볼 수 있는 친환경 생태 축제.',
      visitors: '약 35만',
      fee: '대인 ₩12,000 / 소인 ₩6,000',
      hours: '09:00–18:00',
      parking: '공원 부설 1,400면',
      isDeclineRegion: true,
      programs: const [
        FestivalProgram(time: '10:00', name: '나비 생태관 가이드 투어', location: '나비 곤충생태관'),
        FestivalProgram(time: '14:00', name: '나비 방사 체험', location: '체험광장'),
        FestivalProgram(time: '15:30', name: '자운영 들판 피크닉', location: '서편 들판'),
      ],
      nearby: const ['돌머리해변', '함평 자연생태공원'],
    ),
    Festival(
      contentId: 'demo-andong',
      name: '안동국제탈춤페스티벌',
      nameEn: 'Andong Maskdance Festival',
      region: '경북',
      city: '안동시',
      theme: '문화예술',
      themes: const ['문화예술', '전통', '공연'],
      start: DateTime(2026, 9, 25),
      end: DateTime(2026, 10, 4),
      lat: 36.568,
      lng: 128.729,
      address: '경상북도 안동시 탈춤공원 일원',
      tel: '054-841-6397',
      tagline: '천 개의 가면, 천 개의 이야기',
      overview:
          '하회별신굿탈놀이를 비롯한 한국 전통 탈춤과 세계 각국의 가면 공연이 한자리에 모이는 국제 무형 문화 축제.',
      visitors: '약 110만',
      fee: '무료 입장 / 공연별 ₩5,000~₩20,000',
      hours: '10:00–22:00',
      parking: '탈춤공원 부설 + 셔틀',
      isDeclineRegion: true,
      programs: const [
        FestivalProgram(time: '11:00', name: '개막 거리 퍼레이드', location: '문화의 거리'),
        FestivalProgram(time: '14:00', name: '하회별신굿탈놀이', location: '하회마을 무대'),
        FestivalProgram(time: '20:00', name: '야간 탈불놀이', location: '강변 광장'),
      ],
      nearby: const ['하회마을', '월영교', '안동찜닭골목'],
    ),
    Festival(
      contentId: 'demo-muju',
      name: '무주반딧불축제',
      nameEn: 'Muju Firefly Festival',
      region: '전북',
      city: '무주군',
      theme: '자연',
      themes: const ['자연', '야경', '청정'],
      start: DateTime(2026, 8, 29),
      end: DateTime(2026, 9, 6),
      lat: 36.007,
      lng: 127.661,
      address: '전라북도 무주군 무주읍 일원',
      tel: '063-320-2604',
      tagline: '청정 무주의 작은 별들',
      overview:
          '천연기념물 322호 반딧불이의 서식지 무주에서 펼쳐지는 청정 자연 축제. 반딧불이 신비탐사가 가장 인기 프로그램.',
      visitors: '약 50만',
      fee: '무료 / 탐사 프로그램 ₩7,000',
      hours: '10:00–23:00',
      parking: '예체문화관 공영',
      isDeclineRegion: true,
      programs: const [
        FestivalProgram(time: '19:30', name: '반딧불이 신비탐사', location: '설천면 일원'),
        FestivalProgram(time: '21:00', name: '별빛 야시장', location: '남대천 둔치'),
      ],
      nearby: const ['덕유산 국립공원', '머루와인동굴', '반디랜드'],
    ),
    Festival(
      contentId: 'demo-gimje',
      name: '김제지평선축제',
      nameEn: 'Gimje Horizon Festival',
      region: '전북',
      city: '김제시',
      theme: '농경',
      themes: const ['농경', '전통', '가을'],
      start: DateTime(2026, 10, 8),
      end: DateTime(2026, 10, 12),
      lat: 35.787,
      lng: 126.901,
      address: '전라북도 김제시 벽골제',
      tel: '063-540-3324',
      tagline: '하늘과 땅이 맞닿는 곳',
      overview: '광활한 김제 평야에서 열리는 농경 문화 축제. 황금빛 들판을 배경으로 한 트랙터 퍼레이드와 메뚜기 잡기 체험이 인기.',
      visitors: '약 110만',
      fee: '무료',
      hours: '10:00–21:00',
      parking: '벽골제 공영주차장 2,000면',
      isDeclineRegion: true,
      programs: const [
        FestivalProgram(time: '10:30', name: '벽골제 쌍룡놀이', location: '벽골제'),
        FestivalProgram(time: '16:00', name: '지평선 마라톤', location: '들판 일원'),
      ],
      nearby: const ['벽골제', '아리랑문학마을', '금산사'],
    ),
    Festival(
      contentId: 'demo-hwacheon',
      name: '화천산천어축제',
      nameEn: 'Hwacheon Sancheoneo Ice Festival',
      region: '강원',
      city: '화천군',
      theme: '겨울',
      themes: const ['겨울', '체험', '얼음'],
      start: DateTime(2026, 1, 3),
      end: DateTime(2026, 1, 25),
      lat: 38.108,
      lng: 127.708,
      address: '강원도 화천군 화천읍 화천천',
      tel: '033-441-7575',
      tagline: '얼음 위에서 만나는 청정 산천어',
      overview: '얼어붙은 화천천에서 산천어 얼음낚시·맨손 잡기 등 겨울 체험을 즐길 수 있는 글로벌 4대 겨울 축제.',
      visitors: '약 160만',
      fee: '대인 ₩15,000',
      hours: '08:30–18:00',
      parking: '축제장 공영 + 셔틀',
      isDeclineRegion: true,
      programs: const [
        FestivalProgram(time: '09:00', name: '얼음낚시터 OPEN', location: '화천천 본 낚시터'),
        FestivalProgram(time: '14:00', name: '얼음 조각전 관람', location: '선등거리'),
      ],
      nearby: const ['평화의댐', '비수구미마을'],
    ),
    Festival(
      contentId: 'demo-jeju',
      name: '제주들불축제',
      nameEn: 'Jeju Fire Festival',
      region: '제주',
      city: '제주시',
      theme: '전통',
      themes: const ['전통', '봄', '불꽃'],
      start: DateTime(2026, 3, 6),
      end: DateTime(2026, 3, 8),
      lat: 33.362,
      lng: 126.357,
      address: '제주도 애월읍 새별오름',
      tel: '064-728-2751',
      tagline: '오름을 태우는 정월의 불꽃',
      overview: '새별오름에서 펼쳐지는 정월대보름 들불놓기. 한국에서 가장 큰 규모의 불꽃 축제.',
      visitors: '약 30만',
      fee: '무료',
      hours: '14:00–22:00',
      parking: '셔틀 운영',
      isDeclineRegion: true,
      programs: const [
        FestivalProgram(time: '19:00', name: '달집 태우기', location: '오름 정상'),
        FestivalProgram(time: '20:30', name: '들불 점화', location: '오름 일대'),
      ],
      nearby: const ['새별오름', '한림공원', '협재해변'],
    ),
  ];

  static Course courseFor(Festival f) {
    if (f.contentId == 'demo-jinju') {
      return const Course(
        title: '진주 유등 + 남강 미식',
        days: [
          CourseDay(day: 1, items: [
            CourseItem(time: '11:30', type: CourseItemType.food, name: '하연옥 본점', desc: '진주냉면 발상지', cost: 14000),
            CourseItem(time: '14:00', type: CourseItemType.spot, name: '진주성', desc: '논개의 의로움이 깃든 곳', cost: 2000),
            CourseItem(time: '16:00', type: CourseItemType.festival, name: '유등 만들기 체험', desc: '내 등 직접 만들기', cost: 8000),
            CourseItem(time: '18:30', type: CourseItemType.food, name: '천황식당', desc: '진주식 육회비빔밥', cost: 13000),
            CourseItem(time: '20:00', type: CourseItemType.festival, name: '메인 점등식 + 미디어 파사드', desc: '축제의 하이라이트', cost: 10000),
            CourseItem(time: '22:30', type: CourseItemType.stay, name: '동방호텔 진주', desc: '남강 뷰 객실', cost: 89000),
          ]),
          CourseDay(day: 2, items: [
            CourseItem(time: '08:30', type: CourseItemType.food, name: '봉수산식당', desc: '진주 헛제삿밥', cost: 12000),
            CourseItem(time: '10:00', type: CourseItemType.spot, name: '국립진주박물관', desc: '임진왜란 전시실', cost: 0),
            CourseItem(time: '12:30', type: CourseItemType.spot, name: '촉석루 + 의암', desc: '논개 투신처 답사', cost: 0),
          ]),
        ],
      );
    }
    // 기본 1일 코스 (축제 + 주변)
    return Course(
      title: '${f.city} ${f.name} 코스',
      days: [
        CourseDay(day: 1, items: [
          CourseItem(time: '11:00', type: CourseItemType.festival, name: f.name, desc: f.tagline, cost: 10000, lat: f.lat, lng: f.lng),
          if (f.nearby.isNotEmpty)
            CourseItem(time: '14:00', type: CourseItemType.spot, name: f.nearby.first, desc: '주변 관광지', cost: 0),
          if (f.nearby.length > 1)
            CourseItem(time: '18:00', type: CourseItemType.food, name: f.nearby.last, desc: '지역 맛집', cost: 13000),
        ]),
      ],
    );
  }
}

/// 테마 카테고리 (필터/온보딩)
class ThemeCategory {
  final String id;
  final String name;
  final String icon; // 머티리얼 아이콘 대용 텍스트(이모지/심볼)
  const ThemeCategory(this.id, this.name, this.icon);
}

const kThemes = [
  ThemeCategory('all', '전체', '◉'),
  ThemeCategory('전통', '전통', '⛩'),
  ThemeCategory('자연', '자연·꽃', '✿'),
  ThemeCategory('먹거리', '먹거리', '◐'),
  ThemeCategory('체험', '체험', '✦'),
  ThemeCategory('문화예술', '문화예술', '♪'),
  ThemeCategory('농경', '농경', '✤'),
  ThemeCategory('겨울', '겨울', '❅'),
];

const kRegions = [
  '전체', '강원', '충북', '충남', '대전', '세종',
  '전북', '전남', '광주', '경북', '경남', '대구', '부산', '울산', '제주',
];
