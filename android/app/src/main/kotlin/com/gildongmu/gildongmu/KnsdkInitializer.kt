package com.gildongmu.gildongmu

import android.app.Application
import com.kakaomobility.knsdk.KNLanguageType
import com.kakaomobility.knsdk.KNSDK
import com.kakaomobility.knsdk.common.objects.KNError

/**
 * KNSDK 설치/초기화를 1회만 수행하는 헬퍼.
 * 앱키는 BuildConfig.KNSDK_APP_KEY (local.properties 의 knsdk.app.key) 에서 주입된다.
 */
object KnsdkInitializer {
    private var initialized = false

    fun ensureInit(app: Application, completion: (KNError?) -> Unit) {
        if (initialized) {
            completion(null)
            return
        }
        // 컨텍스트 등록 및 DB/파일 저장 경로 설정
        KNSDK.install(app, "${app.filesDir}/KNSample")
        KNSDK.initializeWithAppKey(
            BuildConfig.KNSDK_APP_KEY,
            BuildConfig.VERSION_NAME ?: "1.0.0",
            aUserKey = "gildongmu-user",
            aLangType = KNLanguageType.KNLanguageType_KOREAN,
            aCompletion = { error ->
                if (error == null) initialized = true
                completion(error)
            }
        )
    }
}
