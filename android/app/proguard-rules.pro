# OkHttp 플랫폼 선택적 의존성 — Android 런타임에 없는 클래스이므로 경고 억제
-dontwarn org.conscrypt.Conscrypt$Version
-dontwarn org.conscrypt.Conscrypt
-dontwarn org.conscrypt.ConscryptHostnameVerifier
-dontwarn org.openjsse.javax.net.ssl.SSLParameters
-dontwarn org.openjsse.javax.net.ssl.SSLSocket
-dontwarn org.openjsse.net.ssl.OpenJSSE

# 네이버 로그인 SDK — R8이 클래스를 제거하지 않도록 유지
-keep class com.nhn.android.naverlogin.** { *; }
-keep class com.navercorp.nid.** { *; }
-dontwarn com.nhn.android.naverlogin.**
-dontwarn com.navercorp.nid.**
