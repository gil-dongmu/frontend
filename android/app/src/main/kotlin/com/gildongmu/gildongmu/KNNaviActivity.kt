package com.gildongmu.gildongmu

import android.os.Bundle
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.kakaomobility.knsdk.KNSDK
import com.kakaomobility.knsdk.common.objects.KNError
import com.kakaomobility.knsdk.common.objects.KNPOI
import com.kakaomobility.knsdk.guidance.knguidance.KNGuidance
import com.kakaomobility.knsdk.guidance.knguidance.KNGuidance_CitsGuideDelegate
import com.kakaomobility.knsdk.guidance.knguidance.KNGuidance_GuideStateDelegate
import com.kakaomobility.knsdk.guidance.knguidance.KNGuidance_LocationGuideDelegate
import com.kakaomobility.knsdk.guidance.knguidance.KNGuidance_RouteGuideDelegate
import com.kakaomobility.knsdk.guidance.knguidance.KNGuidance_SafetyGuideDelegate
import com.kakaomobility.knsdk.guidance.knguidance.KNGuidance_VoiceGuideDelegate
import com.kakaomobility.knsdk.guidance.knguidance.citsguide.KNGuide_Cits
import com.kakaomobility.knsdk.guidance.knguidance.locationguide.KNGuide_Location
import com.kakaomobility.knsdk.guidance.knguidance.routeguide.KNGuide_Route
import com.kakaomobility.knsdk.guidance.knguidance.safetyguide.KNGuide_Safety
import com.kakaomobility.knsdk.guidance.knguidance.safetyguide.objects.KNSafety
import com.kakaomobility.knsdk.guidance.knguidance.voiceguide.KNGuide_Voice
import com.kakaomobility.knsdk.trip.kntrip.KNTrip
import com.kakaomobility.knsdk.trip.kntrip.knroute.KNRoute
import com.kakaomobility.knsdk.trip.kntrip.knrouteconfiguration.KNRouteAvoidOption
import com.kakaomobility.knsdk.trip.kntrip.knrouteconfiguration.KNRoutePriority
import com.kakaomobility.knsdk.ui.view.KNNaviView

/**
 * 카카오내비 인앱 주행 화면.
 *
 * 외부 카카오내비 앱을 띄우지 않고, 이 액티비티(우리 앱 내부)에서
 * KNNaviView 로 턴바이턴 주행 안내를 표시한다.
 *
 * ⚠️ 스캐폴드 주의:
 *  - 일부 import 경로 / enum 값은 KNSDK 버전에 따라 다를 수 있어, 빌드 시
 *    API 레퍼런스(https://developers.kakaomobility.com/reference/android-ui-ref-kotlin/)
 *    와 공식 샘플에 맞춰 조정 필요.
 *  - KNSDK 초기화(install + initializeWithAppKey)가 선행돼야 한다(아래 ensureInit).
 *  - 좌표는 KATEC 이므로 WGS84(lat/lng) → KNSDK.WGS84ToKATEC 로 변환해서 KNPOI 생성.
 */
class KNNaviActivity : AppCompatActivity(),
    KNGuidance_GuideStateDelegate,
    KNGuidance_LocationGuideDelegate,
    KNGuidance_RouteGuideDelegate,
    KNGuidance_SafetyGuideDelegate,
    KNGuidance_VoiceGuideDelegate,
    KNGuidance_CitsGuideDelegate {

    private lateinit var naviView: KNNaviView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_kn_navi)
        naviView = findViewById(R.id.navi_view)

        val sLat = intent.getDoubleExtra("startLat", 0.0)
        val sLng = intent.getDoubleExtra("startLng", 0.0)
        val sName = intent.getStringExtra("startName") ?: "출발지"
        val gLat = intent.getDoubleExtra("goalLat", 0.0)
        val gLng = intent.getDoubleExtra("goalLng", 0.0)
        val gName = intent.getStringExtra("goalName") ?: "목적지"

        KnsdkInitializer.ensureInit(application) { error ->
            if (error != null) {
                toastAndFinish("내비 초기화 실패: ${error.code} ${error.msg}")
                return@ensureInit
            }
            runOnUiThread { startTrip(sLat, sLng, sName, gLat, gLng, gName) }
        }
    }

    private fun startTrip(
        sLat: Double, sLng: Double, sName: String,
        gLat: Double, gLng: Double, gName: String,
    ) {
        // WGS84(lat/lng) → KATEC 변환
        val s = KNSDK.WGS84ToKATEC(sLng, sLat)
        val g = KNSDK.WGS84ToKATEC(gLng, gLat)
        val start = KNPOI(sName, s.x.toInt(), s.y.toInt(), sName)
        val goal = KNPOI(gName, g.x.toInt(), g.y.toInt(), gName)

        KNSDK.makeTripWithStart(start, goal, null) { error, trip ->
            if (error != null || trip == null) {
                toastAndFinish("경로 생성 실패: ${error?.msg}")
                return@makeTripWithStart
            }
            val priority = KNRoutePriority.KNRoutePriority_Recommand
            val avoid = KNRouteAvoidOption.KNRouteAvoidOption_None.value
            trip.routeWithPriority(priority, avoid) { rErr, _ ->
                if (rErr != null) {
                    toastAndFinish("경로 요청 실패: ${rErr.msg}")
                    return@routeWithPriority
                }
                KNSDK.sharedGuidance()?.apply {
                    guideStateDelegate = this@KNNaviActivity
                    locationGuideDelegate = this@KNNaviActivity
                    routeGuideDelegate = this@KNNaviActivity
                    safetyGuideDelegate = this@KNNaviActivity
                    voiceGuideDelegate = this@KNNaviActivity
                    citsGuideDelegate = this@KNNaviActivity
                    naviView.initWithGuidance(this, trip, priority, avoid)
                }
            }
        }
    }

    private fun toastAndFinish(msg: String) = runOnUiThread {
        Toast.makeText(this, msg, Toast.LENGTH_LONG).show()
        finish()
    }

    // ── KNGuidance_GuideStateDelegate ──────────────────────
    override fun guidanceGuideStarted(guidance: KNGuidance) = naviView.guidanceGuideStarted(guidance)
    override fun guidanceCheckingRouteChange(guidance: KNGuidance) = naviView.guidanceCheckingRouteChange(guidance)
    override fun guidanceRouteUnchanged(guidance: KNGuidance) = naviView.guidanceRouteUnchanged(guidance)
    override fun guidanceRouteUnchangedWithError(guidnace: KNGuidance, error: KNError) = naviView.guidanceRouteUnchangedWithError(guidnace, error)
    override fun guidanceOutOfRoute(guidance: KNGuidance) = naviView.guidanceOutOfRoute(guidance)
    override fun guidanceRouteChanged(guidance: KNGuidance) = naviView.guidanceRouteChanged(guidance)
    override fun guidanceGuideEnded(guidance: KNGuidance) = naviView.guidanceGuideEnded(guidance)
    override fun guidanceDidUpdateRoutes(guidance: KNGuidance, routes: List<KNRoute>, multiRouteInfo: com.kakaomobility.knsdk.trip.kntrip.knroute.KNMultiRouteInfo?) =
        naviView.guidanceDidUpdateRoutes(guidance, routes, multiRouteInfo)

    // ── KNGuidance_LocationGuideDelegate ───────────────────
    override fun guidanceDidUpdateLocation(guidance: KNGuidance, locationGuide: KNGuide_Location) =
        naviView.guidanceDidUpdateLocation(guidance, locationGuide)

    // ── KNGuidance_RouteGuideDelegate ──────────────────────
    override fun guidanceDidUpdateRouteGuide(guidance: KNGuidance, routeGuide: KNGuide_Route) =
        naviView.guidanceDidUpdateRouteGuide(guidance, routeGuide)

    // ── KNGuidance_SafetyGuideDelegate ─────────────────────
    override fun guidanceDidUpdateSafetyGuide(guidance: KNGuidance, safetyGuide: KNGuide_Safety?) =
        naviView.guidanceDidUpdateSafetyGuide(guidance, safetyGuide)
    override fun guidanceDidUpdateAroundSafeties(guidance: KNGuidance, safeties: List<KNSafety>?) =
        naviView.guidanceDidUpdateAroundSafeties(guidance, safeties)

    // ── KNGuidance_VoiceGuideDelegate ──────────────────────
    override fun shouldPlayVoiceGuide(guidance: KNGuidance, voiceGuide: KNGuide_Voice, newData: MutableList<ByteArray>): Boolean =
        naviView.shouldPlayVoiceGuide(guidance, voiceGuide, newData)
    override fun willPlayVoiceGuide(guidance: KNGuidance, voiceGuide: KNGuide_Voice) =
        naviView.willPlayVoiceGuide(guidance, voiceGuide)
    override fun didFinishPlayVoiceGuide(guidance: KNGuidance, voiceGuide: KNGuide_Voice) =
        naviView.didFinishPlayVoiceGuide(guidance, voiceGuide)

    // ── KNGuidance_CitsGuideDelegate ───────────────────────
    override fun didUpdateCitsGuide(guidance: KNGuidance, citsGuide: KNGuide_Cits) =
        naviView.didUpdateCitsGuide(guidance, citsGuide)
}
