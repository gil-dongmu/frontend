/// Mobile/desktop 빌드용 stub.
///
/// JS SDK는 웹에서만 의미가 있다. 이 스텁은 항상 false 를 반환해
/// 서비스가 deeplink/카카오맵 폴백으로 흘러가게 한다.
class KakaoNaviPlatform {
  KakaoNaviPlatform._();

  static Future<bool> tryStartJsSdk({
    required String key,
    required String name,
    required double lng,
    required double lat,
  }) async {
    return false;
  }
}
