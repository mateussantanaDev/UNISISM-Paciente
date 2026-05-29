import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/api_exception.dart';

/// Cliente HTTP central. Singleton.
///
/// Padrão herdado da Face UBS:
/// - Interceptor de auth injeta `Authorization: Bearer <token>`
/// - Em 401, dispara `onUnauthorized` (callback global) — o app redireciona pra login
/// - Mapeia erros do backend `{ code, message, details }` para `ApiException`
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
      },
      validateStatus: (s) => s != null && s < 500,
    ));
    return ApiClient._(dio: dio, storage: const FlutterSecureStorage());
  }

  final Dio dio;
  final FlutterSecureStorage storage;
  final Logger _log = Logger(printer: PrettyPrinter(methodCount: 0));

  /// Callback global pra 401. App registra na inicialização.
  void Function()? onUnauthorized;

  // --- Tokens ---

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

  // --- Interceptors ---

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
        // Status < 500 é tratado aqui (validateStatus). Lança erro pra >= 400.
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
        final apiErr = _toApiException(e);
        if (apiErr.isUnauthorized) {
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

  ApiException _toApiException(DioException e) {
    final status = e.response?.statusCode ?? 0;
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      return ApiException(
        status: status,
        code: data['code']?.toString() ?? 'UNKNOWN',
        message: data['message']?.toString() ?? _defaultMessage(status),
        details: (data['details'] as Map<String, dynamic>?) ?? data,
      );
    }
    return ApiException(
      status: status,
      code: status == 0 ? 'NETWORK_OFFLINE' : 'UNKNOWN',
      message: _defaultMessage(status),
    );
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

  // --- Helpers HTTP ---

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
