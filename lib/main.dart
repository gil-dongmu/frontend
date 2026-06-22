import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import 'app.dart';
import 'services/api_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 카카오 SDK 키는 소스가 아닌 env.json 으로 주입한다.
  //   flutter run --dart-define-from-file=env.json
  if (ApiConfig.hasKakaoNativeKey || ApiConfig.hasKakaoJsKey) {
    KakaoSdk.init(
      nativeAppKey: ApiConfig.kakaoNativeAppKey,
      javaScriptAppKey: ApiConfig.kakaoJsKey,
    );
  }

  // 네이버 로그인은 flutter_naver_login 2.x 부터 Dart initSdk 가 사라졌다.
  // client id/secret/name 은 android strings.xml + Manifest meta-data 와
  // iOS Info.plist 에서 네이티브 SDK 가 직접 읽어간다.

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const GilDongMuApp());
}
