import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/anexo_download_service.dart';
import '../core/services/refresh_scheduler.dart';
import '../data/api/api_client.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/banner_repository.dart';
import '../data/repositories/dossie_repository.dart';
import '../data/repositories/encaminhamento_repository.dart';
import '../data/repositories/notificacao_repository.dart';
import '../data/repositories/tfd_repository.dart';
import '../data/repositories/ubs_repository.dart';

/// Singleton do ApiClient. O 401-handler é registrado em `main.dart`.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient.create();
});

// ============================================================
// Repositories — 100% HTTP contra o backend real.
// Mocks foram removidos da árvore de produção. Para testes em
// preview/QA, instanciar os Repos diretamente nos testes.
// ============================================================

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryHttp(ref.watch(apiClientProvider));
});

final encaminhamentoRepositoryProvider = Provider<EncaminhamentoRepository>((ref) {
  return EncaminhamentoRepositoryHttp(ref.watch(apiClientProvider));
});

final dossieRepositoryProvider = Provider<DossieRepository>((ref) {
  return DossieRepositoryHttp(ref.watch(apiClientProvider));
});

final tfdRepositoryProvider = Provider<TfdRepository>((ref) {
  return TfdRepositoryHttp(ref.watch(apiClientProvider));
});

final bannerRepositoryProvider = Provider<BannerRepository>((ref) {
  return BannerRepositoryHttp(ref.watch(apiClientProvider));
});

final notificacaoRepositoryProvider = Provider<NotificacaoRepository>((ref) {
  return NotificacaoRepositoryHttp(ref.watch(apiClientProvider));
});

final ubsRepositoryProvider = Provider<UbsRepository>((ref) {
  return UbsRepositoryHttp(ref.watch(apiClientProvider));
});

final minhaUbsProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(ubsRepositoryProvider).minha();
});

/// Service de download de anexos médicos.
/// Singleton — baixa via Dio com Bearer header, parsea Content-Disposition.
final anexoDownloadServiceProvider = Provider<AnexoDownloadService>((ref) {
  return AnexoDownloadService(ref.watch(apiClientProvider));
});

/// Agenda refresh proativo (5 min antes do access expirar).
/// Wirado no `main.dart` ao receber login bem-sucedido.
final refreshSchedulerProvider = Provider<RefreshScheduler>((ref) {
  return RefreshScheduler(ref.watch(authRepositoryProvider));
});
