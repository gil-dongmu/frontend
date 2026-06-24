import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// local.properties 에서 민감한 값을 읽어 빌드 시 resValue 로 주입한다.
val localProps = Properties().apply {
    val f = rootProject.file("local.properties")
    if (f.exists()) load(f.inputStream())
}

android {
    namespace = "com.gildongmu.gildongmu"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        resValues = true
        buildConfig = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.gildongmu.gildongmu"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26 // 카카오내비 KNSDK 요구사항(API 26+)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // local.properties 에서 주입 — strings.xml 에 하드코딩하지 않는다.
        resValue("string", "naver_client_secret",
            localProps.getProperty("naver.client.secret") ?: error("naver.client.secret not set in local.properties"))

        // 카카오내비(KNSDK) 네이티브 앱 키 — local.properties 의 knsdk.app.key 에서 주입
        buildConfigField(
            "String", "KNSDK_APP_KEY",
            "\"${localProps.getProperty("knsdk.app.key") ?: ""}\""
        )

        // KNSDK(Realm) APK 용량 최적화용 ABI 필터
        ndk {
            abiFilters += listOf("armeabi-v7a", "arm64-v8a")
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    // 카카오내비 길찾기 SDK with UI — KNNaviView, KNGuidance 등 인앱 주행 화면
    implementation("com.kakaomobility.knsdk:knsdk_ui:1.12.7")
}

flutter {
    source = "../.."
}
