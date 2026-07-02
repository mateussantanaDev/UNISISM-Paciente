import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/api/api_client.dart';
import '../errors/api_exception.dart';

/// Resultado de um download bem-sucedido.
class DownloadResult {
  const DownloadResult({
    required this.pathLocal,
    required this.filename,
    required this.mimeType,
    required this.tamanhoBytes,
  });

  final String pathLocal;
  final String filename;
  final String mimeType;
  final int tamanhoBytes;
}

/// Progresso do download (0.0–1.0 quando totalBytes conhecido).
class DownloadProgress {
  const DownloadProgress({
    required this.recebido,
    required this.total,
  });

  final int recebido;
  final int total;

  double? get fraction {
    if (total <= 0) return null;
    final f = recebido / total;
    return f.clamp(0.0, 1.0);
  }

  /// Texto curto pronto pra UI: "1.2 MB de 3.5 MB" ou "1.2 MB".
  String get formatado {
    final r = _fmt(recebido);
    if (total <= 0) return r;
    return '$r de ${_fmt(total)}';
  }

  static String _fmt(int b) {
    if (b < 1024) return '${b}B';
    final kb = b / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(0)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }
}

/// Service real de download de anexos (`GET /paciente-app/anexos/:id/download`).
///
/// Backend exige `Authorization: Bearer <token>` (interceptor cuida) + aplica:
/// - Rate limit 60/15min/conta + 200/1h/conta + 300/15min/IP → `429 RATE_LIMIT_EXCEDIDO`
/// - ClamAV scan obrigatório → `409 ANEXO_NAO_LIBERADO { scanStatus }`
/// - Path traversal guard → `404 ANEXO_NAO_ENCONTRADO`
/// - Anti-enumeration por CPF do JWT → `404`
///
/// Headers de resposta seguidos:
/// - `Content-Type` → mimeType
/// - `Content-Disposition: attachment; filename="..."; filename*=UTF-8''...`
/// - `Content-Length` → tamanho real (usado pra progress)
///
/// Após baixar, expõe helpers `abrir()` e `compartilhar()`.
class AnexoDownloadService {
  AnexoDownloadService(this._api);

  final ApiClient _api;
  final _log = Logger(printer: PrettyPrinter(methodCount: 0));

  /// Baixa o anexo `anexoId` pro diretório temporário do app.
  /// - [onProgress]: callback opcional pra UI (LinearProgressIndicator)
  /// - [cancelToken]: cancela o download
  ///
  /// Lança [ApiException] em caso de erro do backend (ANEXO_NAO_LIBERADO,
  /// RATE_LIMIT_EXCEDIDO, ANEXO_NAO_ENCONTRADO, etc).
  Future<DownloadResult> baixar({
    required String anexoId,
    String? nomeSugerido,
    void Function(DownloadProgress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final tempPath = '${tempDir.path}/unisism_$anexoId.bin';

    try {
      final response = await _api.dio.get<List<int>>(
        '/paciente-app/anexos/$anexoId/download',
        options: Options(
          responseType: ResponseType.bytes,
          // Permite que o interceptor lance `ApiException` em erros 4xx
          validateStatus: (s) => s != null && s < 400,
          // Evita timeout em arquivos grandes
          receiveTimeout: const Duration(minutes: 5),
        ),
        cancelToken: cancelToken,
        onReceiveProgress: (recebido, total) {
          if (onProgress != null) {
            onProgress(DownloadProgress(recebido: recebido, total: total));
          }
        },
      );

      final bytes = response.data ?? const <int>[];
      if (bytes.isEmpty) {
        throw const ApiException(
          status: 500,
          code: 'FALHA_LEITURA_ARQUIVO',
          message: 'Arquivo vazio retornado pelo servidor.',
        );
      }

      // Headers vêm como List<String> no Dio
      final headers = response.headers;
      final mimeType = headers.value('content-type') ?? 'application/octet-stream';
      final cd = headers.value('content-disposition') ?? '';
      final filename = _parseContentDispositionFilename(cd) ??
          nomeSugerido ??
          'arquivo_$anexoId';

      // Renomeia pra extensão correta + nome amigável.
      final finalPath = '${tempDir.path}/${_safeFilename(filename)}';
      final file = File(finalPath);
      await file.writeAsBytes(bytes, flush: true);
      // Apaga o temp `.bin` se ainda existir
      try {
        final tempFile = File(tempPath);
        if (await tempFile.exists()) await tempFile.delete();
      } catch (_) {/* não crítico */}

      _log.i('✓ Anexo baixado: $filename (${bytes.length}B)');
      return DownloadResult(
        pathLocal: finalPath,
        filename: filename,
        mimeType: mimeType,
        tamanhoBytes: bytes.length,
      );
    } on DioException catch (e) {
      // O ApiClient interceptor já mapeia pra ApiException no `e.error`.
      final err = e.error;
      if (err is ApiException) throw err;
      // Fallback genérico
      throw ApiException(
        status: e.response?.statusCode ?? 0,
        code: 'FALHA_LEITURA_ARQUIVO',
        message: 'Falha ao baixar arquivo. Tente novamente.',
      );
    }
  }

  /// Abre o arquivo baixado no app default do sistema (PDF reader, galeria, etc).
  Future<void> abrir(DownloadResult r) async {
    final result = await OpenFilex.open(r.pathLocal, type: r.mimeType);
    if (result.type != ResultType.done) {
      _log.w('OpenFile falhou: ${result.message}');
      throw ApiException(
        status: 500,
        code: 'NAO_FOI_POSSIVEL_ABRIR',
        message:
            'Não foi possível abrir esse arquivo. Tente compartilhar pra outro app.',
      );
    }
  }

  /// Compartilha o arquivo via sheet nativo (WhatsApp, e-mail, salvar, etc).
  Future<void> compartilhar(DownloadResult r) async {
    await Share.shareXFiles(
      [XFile(r.pathLocal, mimeType: r.mimeType, name: r.filename)],
      subject: r.filename,
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────

  /// Extrai `filename` de um header `Content-Disposition` seguindo RFC 5987/6266.
  /// Suporta:
  ///   `attachment; filename="arquivo.pdf"`
  ///   `attachment; filename*=UTF-8''Relat%C3%B3rio.pdf`
  static String? _parseContentDispositionFilename(String cd) {
    if (cd.isEmpty) return null;

    // RFC 5987: filename*=UTF-8''xxx (prioridade — preserva acentos)
    final extended = RegExp(
      r"filename\*\s*=\s*([^']+)'[^']*'([^;]+)",
      caseSensitive: false,
    ).firstMatch(cd);
    if (extended != null) {
      final encoded = extended.group(2)?.trim() ?? '';
      try {
        return Uri.decodeComponent(encoded);
      } catch (_) {/* segue pro fallback */}
    }

    // Fallback ASCII-safe: filename="..."
    final basic = RegExp(
      r'filename\s*=\s*"([^"]+)"',
      caseSensitive: false,
    ).firstMatch(cd);
    if (basic != null) return basic.group(1);

    // Fallback: filename=arquivo.pdf (sem aspas)
    final unquoted = RegExp(
      r'filename\s*=\s*([^;\s]+)',
      caseSensitive: false,
    ).firstMatch(cd);
    return unquoted?.group(1);
  }

  /// Sanitiza nome de arquivo (remove chars inválidos no FS, limita tamanho).
  static String _safeFilename(String nome) {
    final clean = nome.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_');
    if (clean.length <= 120) return clean;
    // Preserva extensão
    final dot = clean.lastIndexOf('.');
    if (dot > 0 && clean.length - dot <= 10) {
      return clean.substring(0, 110) + clean.substring(dot);
    }
    return clean.substring(0, 120);
  }
}
