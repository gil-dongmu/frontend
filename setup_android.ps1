# ----------------------------------------------------------------
# GilDongMu - add Android platform + auto-patch required settings
#
# Usage (from project folder):
#   powershell -ExecutionPolicy Bypass -File .\setup_android.ps1
#
# Steps:
#   1. flutter create  - generate android/ folder
#   2. AndroidManifest - internet/location permissions + kakaonavi queries
#   3. build.gradle    - raise minSdk to 23 (required by geolocator 13)
# ----------------------------------------------------------------
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Error "flutter command not found. Add Flutter SDK to PATH first."
}

function Write-Utf8NoBom([string]$Path, [string]$Text) {
    $enc = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText((Resolve-Path $Path), $Text, $enc)
}

# 1) Generate Android platform -----------------------------------
Write-Host "`n[1/3] flutter create (android platform)..." -ForegroundColor Cyan
flutter create . --platforms=android --org com.gildongmu
if ($LASTEXITCODE -ne 0) { Write-Error "flutter create failed." }

# 2) Patch AndroidManifest.xml -----------------------------------
Write-Host "`n[2/3] Patching AndroidManifest.xml..." -ForegroundColor Cyan
$manifestPath = "android/app/src/main/AndroidManifest.xml"
$xml = Get-Content $manifestPath -Raw

# Permissions (internet + location) - insert before <application>
if ($xml -notmatch "ACCESS_FINE_LOCATION") {
    $perms = @'
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
    <application
'@
    $xml = $xml -replace "    <application", $perms
}

# KakaoNavi deeplink - Android 11+ needs <queries> for canLaunchUrl
if ($xml -notmatch "kakaonavi") {
    $queries = @'
    <queries>
        <intent>
            <action android:name="android.intent.action.VIEW"/>
            <data android:scheme="kakaonavi"/>
        </intent>
        <intent>
            <action android:name="android.intent.action.VIEW"/>
            <data android:scheme="https"/>
        </intent>
    </queries>
</manifest>
'@
    $xml = $xml -replace "</manifest>", $queries
}

# (optional) Google Maps key placeholder - uncomment after getting a key
if ($xml -notmatch "com.google.android.geo.API_KEY") {
    $maps = @'
        <!-- Uncomment and set key to enable Google Maps
        <meta-data android:name="com.google.android.geo.API_KEY"
                   android:value="YOUR_GOOGLE_MAPS_KEY"/>
        -->
        <activity
'@
    $xml = $xml -replace "        <activity", $maps
}

Write-Utf8NoBom $manifestPath $xml
Write-Host "  -> permissions + kakaonavi queries + maps key slot added"

# 3) Raise minSdk to 23 ------------------------------------------
Write-Host "`n[3/3] Setting minSdk = 23..." -ForegroundColor Cyan
$gradleKts = "android/app/build.gradle.kts"
$gradle = "android/app/build.gradle"
if (Test-Path $gradleKts) {
    $g = (Get-Content $gradleKts -Raw) -replace "minSdk = flutter\.minSdkVersion", "minSdk = 23"
    Write-Utf8NoBom $gradleKts $g
} elseif (Test-Path $gradle) {
    $g = (Get-Content $gradle -Raw) -replace "minSdkVersion flutter\.minSdkVersion", "minSdkVersion 23"
    Write-Utf8NoBom $gradle $g
}
Write-Host "  -> done"

Write-Host @"

----------------------------------------------------------------
DONE. How to run on mobile:

  1. Connect a device (either one):
     - Real phone: USB cable + enable Developer options > USB debugging
     - Emulator: Android Studio > Device Manager > start a device

  2. Check and run:
     flutter devices
     flutter run                                      (demo data)
     flutter run --dart-define=TOUR_API_KEY=YOUR_KEY  (real data)

  Location permission is requested at runtime by the app.
----------------------------------------------------------------
"@ -ForegroundColor Green
