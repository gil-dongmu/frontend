import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 백엔드가 발급한 JWT(access/refresh)를 안전 저장소에 보관한다.
///
/// 토큰은 민감 정보이므로 SharedPreferences가 아닌 flutter_secure_storage
/// (iOS Keychain / Android EncryptedSharedPreferences)에 저장한다.
class TokenStore {
  TokenStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _kAccess = 'gildongmu.jwt.access';
  static const _kRefresh = 'gildongmu.jwt.refresh';

  Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _kAccess, value: accessToken);
    await _storage.write(key: _kRefresh, value: refreshToken);
  }

  Future<String?> readAccessToken() => _storage.read(key: _kAccess);

  Future<String?> readRefreshToken() => _storage.read(key: _kRefresh);

  Future<bool> get hasTokens async =>
      (await readAccessToken()) != null && (await readRefreshToken()) != null;

  Future<void> clear() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
  }
}
