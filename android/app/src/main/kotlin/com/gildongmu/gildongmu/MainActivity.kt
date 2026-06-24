package com.gildongmu.gildongmu

import android.content.Intent
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// flutter_naver_login 2.x 는 FlutterFragmentActivity 를 요구한다.
class MainActivity : FlutterFragmentActivity() {

    companion object {
        private const val CHANNEL = "gildongmu/navi"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // 카카오내비 인앱 주행 화면 시작
                    "startGuidance" -> {
                        val intent = Intent(this, KNNaviActivity::class.java).apply {
                            putExtra("startLat", call.argument<Double>("startLat") ?: 0.0)
                            putExtra("startLng", call.argument<Double>("startLng") ?: 0.0)
                            putExtra("startName", call.argument<String>("startName") ?: "출발지")
                            putExtra("goalLat", call.argument<Double>("goalLat") ?: 0.0)
                            putExtra("goalLng", call.argument<Double>("goalLng") ?: 0.0)
                            putExtra("goalName", call.argument<String>("goalName") ?: "목적지")
                        }
                        startActivity(intent)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
