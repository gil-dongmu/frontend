import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'token_store.dart';

/// 백엔드(길동무 API) 호출 중 발생한 오류.
///
/// 서버의 `ErrorResponse { code, message }` 를 그대로 담는다.
/// 예: code == 'DUPLICATE_NICKNAME', 'INVALID_SOCIAL_TOKEN' 등.
class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
  });

  final int statusCode;
  final String code;
  final String message;

  bool get isUnauthorized => statusCode == 401;
  bool get isDuplicateNickname => code == 'DUPLICATE_NICKNAME';

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}

/// 백엔드가 응답했으나(혹은 응답조차 못 받아) 본문을 해석할 수 없을 때.
class NetworkException implements Exception {
  const NetworkException(this.message);
  final String message;

  @override
  String toString() => 'NetworkException: $message';
}

/// 백엔드 인증/유저 API 클라이언트.
///
/// - access token 을 Authorization 헤더에 자동으로 싣는다.
/// - 401 응답을 받으면 refresh token 으로 재발급(/auth/reissue)을 한 번
///   시도한 뒤 원 요청을 재시도한다.
class ApiClient {
  ApiClient({
    TokenStore? tokenStore,
    http.Client? httpClient,
    String? baseUrl,
    Duration? timeout,
  })  : _tokens = tokenStore ?? TokenStore(),
        _http = httpClient ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConfig.apiBaseUrl,
        _timeout = timeout ?? const Duration(seconds: 15);

  final TokenStore _tokens;
  final http.Client _http;
  final String _baseUrl;
  final Duration _timeout;

  static const _jsonHeaders = {'Content-Type': 'application/json'};

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  // ── 인증 (토큰 불필요) ─────────────────────────────────

  /// 소셜 access token 으로 로그인. 백엔드가 자체 JWT 를 발급한다.
  /// 반환값: { accessToken, refreshToken, isNewUser }
  Future<({String accessToken, String refreshToken, bool isNewUser})>
      socialLogin({
    required String providerCode,
    required String socialAccessToken,
  }) async {
    final res = await _send(
      () => _http
          .post(
            _uri('/api/v1/auth/login/$providerCode'),
            headers: _jsonHeaders,
            body: jsonEncode({'accessToken': socialAccessToken}),
          )
          .timeout(_timeout),
    );
    final json = _decode(res);
    return (
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      isNewUser: (json['isNewUser'] as bool?) ?? false,
    );
  }

  // ── 인증 (토큰 필요) ───────────────────────────────────

  /// 닉네임 설정/변경 — 신규 회원 온보딩에 사용.
  Future<void> updateNickname(String nickname) async {
    await _authedSend(
      (token) => _http
          .patch(
            _uri('/api/v1/users/me'),
            headers: {..._jsonHeaders, 'Authorization': 'Bearer $token'},
            body: jsonEncode({'nickname': nickname}),
          )
          .timeout(_timeout),
    );
  }

  /// 로그아웃 — 서버의 refresh token 을 무효화한다.
  Future<void> logout() async {
    await _authedSend(
      (token) => _http
          .post(
            _uri('/api/v1/auth/logout'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(_timeout),
    );
  }

  /// refresh token 으로 access/refresh 재발급. 성공 시 저장소를 갱신한다.
  /// 갱신 가능 여부를 반환한다(만료/무효면 false).
  Future<bool> reissue() async {
    final refresh = await _tokens.readRefreshToken();
    if (refresh == null) return false;

    final http.Response res;
    try {
      res = await _http
          .post(
            _uri('/api/v1/auth/reissue'),
            headers: _jsonHeaders,
            body: jsonEncode({'refreshToken': refresh}),
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw const NetworkException('서버 응답이 지연되고 있습니다.');
    } on http.ClientException catch (e) {
      throw NetworkException(e.message);
    }

    if (res.statusCode == 200) {
      final json = _decode(res);
      await _tokens.save(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
      );
      return true;
    }
    // 401/유효하지 않은 refresh → 재로그인 필요
    return false;
  }

  // ── 내부 헬퍼 ──────────────────────────────────────────

  /// 토큰이 필요 없는 요청. 네트워크 오류만 변환한다.
  Future<http.Response> _send(
    Future<http.Response> Function() request,
  ) async {
    try {
      final res = await request();
      _ensureSuccess(res);
      return res;
    } on TimeoutException {
      throw const NetworkException('서버 응답이 지연되고 있습니다.');
    } on http.ClientException catch (e) {
      throw NetworkException(e.message);
    }
  }

  /// 토큰이 필요한 요청. 401 이면 재발급 후 한 번 재시도한다.
  Future<http.Response> _authedSend(
    Future<http.Response> Function(String token) request,
  ) async {
    final token = await _tokens.readAccessToken();
    if (token == null) {
      throw const ApiException(
        statusCode: 401,
        code: 'NO_TOKEN',
        message: '로그인이 필요합니다.',
      );
    }

    http.Response res;
    try {
      res = await request(token);
    } on TimeoutException {
      throw const NetworkException('서버 응답이 지연되고 있습니다.');
    } on http.ClientException catch (e) {
      throw NetworkException(e.message);
    }

    if (res.statusCode == 401 && await reissue()) {
      final refreshed = await _tokens.readAccessToken();
      if (refreshed != null) {
        try {
          res = await request(refreshed);
        } on TimeoutException {
          throw const NetworkException('서버 응답이 지연되고 있습니다.');
        } on http.ClientException catch (e) {
          throw NetworkException(e.message);
        }
      }
    }

    _ensureSuccess(res);
    return res;
  }

  /// 2xx 가 아니면 ApiException 으로 변환한다.
  void _ensureSuccess(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;

    var code = 'UNKNOWN';
    var message = '요청을 처리하지 못했습니다. (${res.statusCode})';
    if (res.body.isNotEmpty) {
      try {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        code = (json['code'] as String?) ?? code;
        message = (json['message'] as String?) ?? message;
      } on FormatException {
        // 본문이 JSON 이 아님 — 기본 메시지 유지
      }
    }
    throw ApiException(
      statusCode: res.statusCode,
      code: code,
      message: message,
    );
  }

  Map<String, dynamic> _decode(http.Response res) {
    try {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } on FormatException {
      throw const NetworkException('서버 응답을 해석할 수 없습니다.');
    }
  }

  void dispose() => _http.close();
}
