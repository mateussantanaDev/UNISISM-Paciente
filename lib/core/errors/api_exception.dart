/// Exceção tipada da camada API — espelha o `ApiError` da Face UBS (Svelte).
///
/// Campos:
/// - [status]: código HTTP retornado pelo backend
/// - [code]: chave de erro estável (`AUTH_INVALID_CREDENTIALS`, `RATE_LIMIT`, …)
/// - [message]: mensagem amigável já em PT-BR pronta pra exibir
/// - [details]: payload bruto (opcional, pra logging)
class ApiException implements Exception {
  const ApiException({
    required this.status,
    required this.code,
    required this.message,
    this.details,
  });

  final int status;
  final String code;
  final String message;
  final Map<String, dynamic>? details;

  bool get isUnauthorized => status == 401;
  bool get isForbidden => status == 403;
  bool get isNotFound => status == 404;
  bool get isConflict => status == 409;
  bool get isValidation => status == 422;
  bool get isServerError => status >= 500;
  bool get isNetwork => status == 0;

  @override
  String toString() => 'ApiException($status, $code): $message';
}
