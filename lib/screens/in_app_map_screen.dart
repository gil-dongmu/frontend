import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/festival.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// 앱 내부 카카오맵 길찾기 (WebView) — 모바일 전용.
///
/// 외부 브라우저/앱으로 나가지 않고 앱 안에서 카카오맵 길찾기를 띄운다.
/// `https://map.kakao.com/link/from/.../to/...` 패턴은 카카오 키 없이 동작.
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
  late final WebViewController _controller;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    final f = widget.festival;
    final originName =
        Uri.encodeComponent(widget.hasRealLocation ? '내 위치' : '진주시 본성동');
    final url = 'https://map.kakao.com/link/from/'
        '$originName,${widget.originLat},${widget.originLng}'
        '/to/${Uri.encodeComponent(f.name)},${f.lat},${f.lng}';

    _controller = WebViewController()
      // 카카오맵 렌더링에 JavaScript 필수
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.cream)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
        onNavigationRequest: (request) async {
          final uri = Uri.tryParse(request.url);
          if (uri == null) return NavigationDecision.prevent;
          // 카카오/다음 계열 도메인만 웹뷰 내에서 허용 (보안)
          if (uri.scheme == 'http' || uri.scheme == 'https') {
            final h = uri.host;
            final allowed = h.endsWith('kakao.com') ||
                h.endsWith('kakaocdn.net') ||
                h.endsWith('daum.net') ||
                h.endsWith('daumcdn.net');
            return allowed
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          }
          // 앱 스킴(kakaonavi:// 등)은 외부 앱으로 위임
          try {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (_) {
            // 해당 앱 미설치 — 무시하고 웹뷰 유지
          }
          return NavigationDecision.prevent;
        },
      ))
      ..loadRequest(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
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
                        Text('카카오맵 길찾기',
                            style: AppType.display(size: 18)),
                        Text(widget.festival.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.body(
                                size: 11, color: AppColors.muted)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: '새로고침',
                    onPressed: _controller.reload,
                    icon: const Icon(Icons.refresh,
                        size: 20, color: AppColors.ink),
                  ),
                ],
              ),
            ),
            // 로딩 진행 바
            if (_progress < 100)
              LinearProgressIndicator(
                value: _progress / 100,
                minHeight: 2,
                backgroundColor: AppColors.line,
                valueColor:
                    const AlwaysStoppedAnimation(AppColors.vermilion),
              ),
            // 지도
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: WebViewWidget(controller: _controller),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
