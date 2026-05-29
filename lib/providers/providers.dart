import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../data/api/api_client.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/banner_repository.dart';
import '../data/repositories/dossie_repository.dart';
import '../data/repositories/encaminhamento_repository.dart';
import '../data/repositories/notificacao_repository.dart';
import '../data/repositories/tfd_repository.dart';
import '../data/repositories/ubs_repository.dart';

/// Singleton do ApiClient. Trocar 401-handler é registrado no main.dart.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient.create();
});

/// Cada provider escolhe Mock vs Http baseado em `AppConstants.useMockData`.
/// Quando o backend estiver pronto, trocar `--dart-define=USE_MOCK=false`.

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return AppConstants.useMockData
      ? AuthRepositoryMock(api)
      : AuthRepositoryHttp(api);
});

final encaminhamentoRepositoryProvider = Provider<EncaminhamentoRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return AppConstants.useMockData
      ? EncaminhamentoRepositoryMock()
      : EncaminhamentoRepositoryHttp(api);
});

final dossieRepositoryProvider = Provider<DossieRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return AppConstants.useMockData
      ? DossieRepositoryMock()
      : DossieRepositoryHttp(api);
});

final tfdRepositoryProvider = Provider<TfdRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return AppConstants.useMockData
      ? TfdRepositoryMock()
      : TfdRepositoryHttp(api);
});

final bannerRepositoryProvider = Provider<BannerRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return AppConstants.useMockData
      ? BannerRepositoryMock()
      : BannerRepositoryHttp(api);
});

final notificacaoRepositoryProvider = Provider<NotificacaoRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return AppConstants.useMockData
      ? NotificacaoRepositoryMock()
      : NotificacaoRepositoryHttp(api);
});

final ubsRepositoryProvider = Provider<UbsRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return AppConstants.useMockData
      ? UbsRepositoryMock()
      : UbsRepositoryHttp(api);
});

final minhaUbsProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(ubsRepositoryProvider).minha();
});
