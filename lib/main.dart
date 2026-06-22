import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import 'app.dart';
import 'services/api_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 소셜 SDK 키는 소스가 아닌 env.json 으로 주입한다.
  //   flutter run --dart-define-from-file=env.json
  if (ApiConfig.hasKakaoNativeKey || ApiConfig.hasKakaoJsKey) {
    KakaoSdk.init(
      nativeAppKey: ApiConfig.kakaoNativeAppKey,
      javaScriptAppKey: ApiConfig.kakaoJsKey,
    );
  }

  if (ApiConfig.hasNaverKeys) {
    await FlutterNaverLogin.initSdk(
      clientId: ApiConfig.naverClientId,
      clientSecret: ApiConfig.naverClientSecret,
      clientName: ApiConfig.naverClientName,
    );
  }

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const GilDongMuApp());
}
