import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/festival.dart';
import '../services/api_config.dart';
import '../services/kakao_directions_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// 인앱 카카오맵 경로 보기.
///
/// 카카오내비 앱을 외부로 띄우지 않고, 카카오모빌리티 길찾기 API 로 받은
/// 자동차 경로를 카카오 지도 JS SDK(WebView) 위에 직접 그려 앱 안에서 보여준다.
/// (카카오내비의 '주행 안내' 화면 자체는 카카오가 외부 앱으로만 제공하므로
///  여기서는 경로/거리/시간 표시까지를 인앱으로 처리한다.)
class InAppMapScreen extends StatefulWidget {
  final Festival festival;
  final double originLat;
  final double originLng;
  final bool hasRealLocation;

  const InAppMapScreen({
    super.key,
    required this.festival,
    required this.originLat,
    required this.originLng,
    this.hasRealLocation = false,
  });

  @override
  State<InAppMapScreen> createState() => _InAppMapScreenState();
}

class _InAppMapScreenState extends State<InAppMapScreen> {
  WebViewController? _controller;
  DirectionsResult? _route;
  bool _loading = true;
  int _progress = 0;
  String? _error; // 치명적(키 없음) — 폴백 화면 표시
  String? _routeNote; // 경로 조회 실패 등 안내(지도는 그대로 표시)

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (!ApiConfig.hasKakaoJsKey) {
      setState(() {
        _loading = false;
        _error = '카카오 지도 JS 키(KAKAO_JS_KEY)가 설정되지 않았습니다.';
      });
      return;
    }

    // 1) 길찾기 API 로 실제 도로 경로 조회 (REST 키 없으면 null → 직선 폴백)
    final svc = KakaoDirectionsService();
    try {
      _route = await svc.carRoute(
        originLat: widget.originLat,
        originLng: widget.originLng,
        destLat: widget.festival.lat,
        destLng: widget.festival.lng,
      );
      if (_route == null && !ApiConfig.hasKakaoRestKey) {
        _routeNote = '길찾기 키 미설정 — 출발·도착 직선만 표시합니다.';
      }
    } on Exception catch (e) {
      _routeNote = '경로를 불러오지 못해 직선으로 표시합니다. ($e)';
    } finally {
      svc.dispose();
    }

    // 2) 카카오 지도 JS SDK 를 WebView 에 직접 렌더링
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.cream)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
        onNavigationRequest: (request) {
          final uri = Uri.tryParse(request.url);
          if (uri == null) return NavigationDecision.prevent;
          if (uri.scheme != 'http' && uri.scheme != 'https') {
            return NavigationDecision.prevent;
          }
          final h = uri.host;
          final allowed = h == 'localhost' ||
              h.endsWith('kakao.com') ||
              h.endsWith('kakaocdn.net') ||
              h.endsWith('daum.net') ||
              h.endsWith('daumcdn.net');
          return allowed
              ? NavigationDecision.navigate
              : NavigationDecision.prevent;
        },
      ))
      ..loadHtmlString(_buildHtml(), baseUrl: ApiConfig.kakaoMapBaseUrl);

    if (!mounted) return;
    setState(() {
      _controller = controller;
      _loading = false;
    });
  }

  String _buildHtml() {
    final oLat = widget.originLat;
    final oLng = widget.originLng;
    final dLat = widget.festival.lat;
    final dLng = widget.festival.lng;

    final pts = _route?.path ?? const <LatLngPoint>[];
    final pathJs = pts.length > 1
        ? pts.map((p) => 'new kakao.maps.LatLng(${p.lat}, ${p.lng})').join(', ')
        : 'orig, dest';

    return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
<style>html,body{margin:0;padding:0;height:100%}#map{width:100%;height:100%}</style>
<script src="https://dapi.kakao.com/v2/maps/sdk.js?appkey=${ApiConfig.kakaoJsKey}&autoload=false"></script>
</head>
<body>
<div id="map"></div>
<script>
kakao.maps.load(function () {
  var dest = new kakao.maps.LatLng($dLat, $dLng);
  var orig = new kakao.maps.LatLng($oLat, $oLng);
  var map = new kakao.maps.Map(document.getElementById('map'), { center: dest, level: 6 });

  new kakao.maps.Marker({ map: map, position: orig });
  new kakao.maps.Marker({ map: map, position: dest });

  var path = [$pathJs];
  var line = new kakao.maps.Polyline({
    path: path, strokeWeight: 5, strokeColor: '#E4572E',
    strokeOpacity: 0.9, strokeStyle: 'solid'
  });
  line.setMap(map);

  var bounds = new kakao.maps.LatLngBounds();
  bounds.extend(orig);
  bounds.extend(dest);
  for (var i = 0; i < path.length; i++) { bounds.extend(path[i]); }
  map.setBounds(bounds);
});
</script>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    final route = _route;
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: AppColors.ink),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('카카오맵 경로', style: AppType.display(size: 18)),
                        Text(
                          route != null
                              ? '${widget.festival.name} · ${route.distanceText} · ${route.durationText}'
                              : widget.festival.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              AppType.body(size: 11, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  if (_controller != null)
                    IconButton(
                      tooltip: '새로고침',
                      onPressed: _controller!.reload,
                      icon: const Icon(Icons.refresh,
                          size: 20, color: AppColors.ink),
                    ),
                ],
              ),
            ),
            if (_routeNote != null)
              Container(
                width: double.infinity,
                color: AppColors.line.withValues(alpha: 0.4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Text(_routeNote!,
                    style: AppType.body(size: 11, color: AppColors.muted)),
              ),
            if (!_loading && _controller != null && _progress < 100)
              LinearProgressIndicator(
                value: _progress / 100,
                minHeight: 2,
                backgroundColor: AppColors.line,
                valueColor: const AlwaysStoppedAnimation(AppColors.vermilion),
              ),
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.vermilion),
      );
    }
    if (_error != null || _controller == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map_outlined, size: 40, color: AppColors.muted),
              const SizedBox(height: 12),
              Text(
                _error ?? '지도를 표시할 수 없습니다.',
                textAlign: TextAlign.center,
                style: AppType.body(size: 13, color: AppColors.inkSoft),
              ),
            ],
          ),
        ),
      );
    }
    return WebViewWidget(controller: _controller!);
  }
}
