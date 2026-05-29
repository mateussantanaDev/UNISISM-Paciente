import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/notificacao.dart';
import 'providers.dart';

/// Contagem de notificações não lidas — usado no badge da bottom nav.
final naoLidasCountProvider = FutureProvider.autoDispose<int>((ref) async {
  return ref.watch(notificacaoRepositoryProvider).contagemNaoLidas();
});

/// Lista completa de notificações.
final notificacoesListProvider = FutureProvider.autoDispose<List<Notificacao>>(
  (ref) async => ref.watch(notificacaoRepositoryProvider).listar(),
);

class NotificacaoController extends Notifier<void> {
  @override
  void build() {}

  Future<void> marcarLida(String id) async {
    await ref.read(notificacaoRepositoryProvider).marcarLida(id);
    ref.invalidate(naoLidasCountProvider);
    ref.invalidate(notificacoesListProvider);
  }

  Future<void> marcarTodasLidas() async {
    await ref.read(notificacaoRepositoryProvider).marcarTodasLidas();
    ref.invalidate(naoLidasCountProvider);
    ref.invalidate(notificacoesListProvider);
  }
}

final notificacaoControllerProvider =
    NotifierProvider<NotificacaoController, void>(NotificacaoController.new);
