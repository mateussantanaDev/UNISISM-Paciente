import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/api_exception.dart';

/// Cliente HTTP central. Singleton.
///
/// Funcionalidades:
/// - Interceptor de auth injeta `Authorization: Bearer <token>`
/// - **Refresh rotativo single-flight** em 401 (v0.18.0+):
///   - Em 401, tenta `POST /paciente-app/auth/refresh` UMA vez
///   - Sucesso → reexecuta a request original transparentemente
///   - Falha (REUSE_DETECTED/EXPIRADO/REVOGADO) → limpa tokens + `onUnauthorized`
///   - Single-flight: múltiplas requests 401 simultâneas esperam o **mesmo**
///     refresh promise; evita corrida e múltiplas chamadas ao backend.
/// - Mapeia erros do backend `{ error: { code, message, details } }` para `ApiException`
class ApiClient {
  ApiClient._({required this.dio, required this.storage}) {
    _attachInterceptors();
  }

  factory ApiClient.create() {
    final dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'X-Client-Platform': 'flutter-mobile',
        'X-Client-Version': AppConstants.appVersion,
        'x-api-key': AppConstants.apiKey,
      },
      validateStatus: (s) => s != null && s < 500,
    ));
    return ApiClient._(dio: dio, storage: const FlutterSecureStorage());
  }

  final Dio dio;
  final FlutterSecureStorage storage;
  final Logger _log = Logger(printer: PrettyPrinter(methodCount: 0));

  /// Callback global pra 401 fatal (refresh esgotado). App registra na boot.
  void Function()? onUnauthorized;

  // ─── Refresh single-flight ───────────────────────────────────────
  // Quando >1 request bate 401 ao mesmo tempo, todas aguardam UM refresh.
  Completer<bool>? _refreshing;

  /// Endpoints que NÃO disparam refresh em 401 (auth público / o próprio refresh).
  static const _authPaths = <String>{
    '/paciente-app/auth/login',
    '/paciente-app/auth/refresh',
    '/paciente-app/auth/esqueci-senha',
    '/paciente-app/auth/redefinir-senha',
    '/paciente-app/auth/ativar-conta',
  };

  // ─── Tokens ──────────────────────────────────────────────────────

  Future<String?> getAccessToken() async {
    return storage.read(key: AppConstants.kTokenAccess);
  }

  Future<String?> getRefreshToken() async {
    return storage.read(key: AppConstants.kTokenRefresh);
  }

  Future<void> setTokens({required String access, required String refresh}) async {
    await storage.write(key: AppConstants.kTokenAccess, value: access);
    await storage.write(key: AppConstants.kTokenRefresh, value: refresh);
  }

  Future<void> clearTokens() async {
    await storage.delete(key: AppConstants.kTokenAccess);
    await storage.delete(key: AppConstants.kTokenRefresh);
  }

  Future<bool> hasSession() async {
    final t = await getAccessToken();
    return t != null && t.isNotEmpty;
  }

  // ─── Interceptors ────────────────────────────────────────────────

  void _attachInterceptors() {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await getAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        _log.d('→ ${options.method} ${options.uri}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        _log.d('← ${response.statusCode} ${response.requestOptions.uri}');
        final s = response.statusCode ?? 0;
        if (s >= 400) {
          handler.reject(DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
          ));
          return;
        }
        handler.next(response);
      },
      onError: (e, handler) async {
        final status = e.response?.statusCode ?? 0;
        final path = e.requestOptions.path;

        // ── 401 não-fatal → tenta refresh single-flight ──
        if (status == 401 &&
            !_isAuthPath(path) &&
            e.requestOptions.extra['__refresh_retried__'] != true) {
          final refreshed = await _tryRefresh();
          if (refreshed) {
            try {
              // Re-tenta a request original com novo access token.
              final retryOptions = e.requestOptions
                ..extra['__refresh_retried__'] = true;
              final newToken = await getAccessToken();
              if (newToken != null && newToken.isNotEmpty) {
                retryOptions.headers['Authorization'] = 'Bearer $newToken';
              }
              final retried = await dio.fetch<dynamic>(retryOptions);
              return handler.resolve(retried);
            } catch (retryErr) {
              // Falhou de novo — segue pro fluxo fatal abaixo.
              _log.w('Retry pós-refresh falhou: $retryErr');
            }
          }
          // Refresh falhou (REUSE/EXPIRADO/REVOGADO/INVALIDO) — fatal.
          await clearTokens();
          onUnauthorized?.call();
        }

        final apiErr = _toApiException(e);
        // Fallback fatal pra outros 401 (ex: paths excluídos)
        if (apiErr.isUnauthorized && !_isAuthPath(path)) {
          await clearTokens();
          onUnauthorized?.call();
        }
        _log.w('⚠ ${apiErr.toString()}');
        handler.reject(DioException(
          requestOptions: e.requestOptions,
          response: e.response,
          type: e.type,
          error: apiErr,
        ));
      },
    ));
  }

  bool _isAuthPath(String path) {
    return _authPaths.any((p) => path.endsWith(p) || path.contains(p));
  }

  /// Tenta refresh. Retorna true se rolou sucesso e o novo access tá salvo.
  /// Single-flight: chamadas concorrentes aguardam o mesmo Future.
  Future<bool> _tryRefresh() async {
    final inflight = _refreshing;
    if (inflight != null) return inflight.future;

    final completer = Completer<bool>();
    _refreshing = completer;

    try {
      final refresh = await getRefreshToken();
      if (refresh == null || refresh.isEmpty) {
        completer.complete(false);
        return false;
      }

      // Cria Dio "limpo" sem interceptors pra não recursar.
      final raw = Dio(BaseOptions(
        baseUrl: dio.options.baseUrl,
        connectTimeout: dio.options.connectTimeout,
        receiveTimeout: dio.options.receiveTimeout,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'X-Client-Platform': 'flutter-mobile',
          'X-Client-Version': AppConstants.appVersion,
          'x-api-key': AppConstants.apiKey,
        },
        validateStatus: (s) => s != null && s < 500,
      ));

      final r = await raw.post<dynamic>(
        '/paciente-app/auth/refresh',
        data: {'refreshToken': refresh},
      );

      if ((r.statusCode ?? 0) >= 400) {
        completer.complete(false);
        return false;
      }

      final data = r.data;
      if (data is! Map<String, dynamic>) {
        completer.complete(false);
        return false;
      }

      final newAccess = (data['token'] ?? data['accessToken']) as String?;
      final newRefresh = (data['refreshToken'] as String?) ?? '';
      if (newAccess == null || newAccess.isEmpty) {
        completer.complete(false);
        return false;
      }

      await setTokens(access: newAccess, refresh: newRefresh);
      _log.i('✓ Refresh rotativo concluído');
      completer.complete(true);
      return true;
    } catch (e) {
      _log.w('Refresh falhou: $e');
      if (!completer.isCompleted) completer.complete(false);
      return false;
    } finally {
      _refreshing = null;
    }
  }

  ApiException _toApiException(DioException e) {
    final status = e.response?.statusCode ?? 0;
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      // Backend real usa shape envelopado `{ error: { code, message, details } }`.
      // Mock/spec ideal usa shape plano `{ code, message, details }`. Suportar ambos.
      final payload = (data['error'] is Map<String, dynamic>)
          ? data['error'] as Map<String, dynamic>
          : data;
      return ApiException(
        status: status,
        code: payload['code']?.toString() ?? _codeForStatus(status),
        message: payload['message']?.toString() ?? _defaultMessage(status),
        details: (payload['details'] as Map<String, dynamic>?) ?? payload,
      );
    }
    return ApiException(
      status: status,
      code: status == 0 ? 'NETWORK_OFFLINE' : _codeForStatus(status),
      message: _defaultMessage(status),
    );
  }

  String _codeForStatus(int status) {
    return switch (status) {
      0 => 'NETWORK_OFFLINE',
      400 || 422 => 'VALIDATION_ERROR',
      401 => 'TOKEN_INVALIDO',
      403 => 'FORBIDDEN_RESOURCE',
      404 => 'NOT_FOUND',
      409 => 'CONFLICT',
      429 => 'RATE_LIMIT_EXCEDIDO',
      >= 500 => 'INTERNAL_ERROR',
      _ => 'UNKNOWN',
    };
  }

  String _defaultMessage(int status) {
    return switch (status) {
      0 => 'Sem conexão com a internet. Verifique sua rede e tente de novo.',
      401 => 'Sua sessão expirou. Entre novamente.',
      403 => 'Você não tem permissão para essa ação.',
      404 => 'Não encontramos o que você procurou.',
      409 => 'Esta ação entra em conflito com algo já feito.',
      422 => 'Alguns campos não foram preenchidos corretamente.',
      429 => 'Muitas tentativas. Espere alguns segundos.',
      >= 500 => 'O servidor está com problemas. Tente em alguns minutos.',
      _ => 'Algo deu errado. Tente novamente.',
    };
  }

  // ─── Helpers HTTP ────────────────────────────────────────────────

  Future<T> get<T>(String path, {Map<String, dynamic>? query}) async {
    final r = await dio.get(path, queryParameters: query);
    return r.data as T;
  }

  Future<T> post<T>(String path, {Object? body, Map<String, dynamic>? query}) async {
    final r = await dio.post(path, data: body, queryParameters: query);
    return r.data as T;
  }

  Future<T> put<T>(String path, {Object? body}) async {
    final r = await dio.put(path, data: body);
    return r.data as T;
  }

  Future<T> patch<T>(String path, {Object? body}) async {
    final r = await dio.patch(path, data: body);
    return r.data as T;
  }

  Future<void> delete(String path) async {
    await dio.delete(path);
  }
}
