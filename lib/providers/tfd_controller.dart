import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/tfd.dart';
import 'providers.dart';

final viagensTfdProvider = FutureProvider.autoDispose<List<TfdViagem>>((ref) async {
  return ref.watch(tfdRepositoryProvider).listarViagens();
});

final viagemTfdProvider =
    FutureProvider.autoDispose.family<TfdViagem, String>((ref, id) async {
  return ref.watch(tfdRepositoryProvider).obterViagem(id);
});

final solicitacoesTfdProvider = FutureProvider.autoDispose<List<TfdSolicitacao>>(
  (ref) async => ref.watch(tfdRepositoryProvider).minhasSolicitacoes(),
);

final solicitacaoTfdProvider = FutureProvider.autoDispose
    .family<TfdSolicitacao, String>((ref, id) async {
  return ref.watch(tfdRepositoryProvider).obterSolicitacao(id);
});

class TfdController extends Notifier<void> {
  @override
  void build() {}

  Future<TfdSolicitacao> solicitar({
    required String viagemId,
    String? encaminhamentoId,
    required String justificativa,
    String? acompanhante,
  }) async {
    final r = await ref.read(tfdRepositoryProvider).solicitar(
          viagemId: viagemId,
          encaminhamentoId: encaminhamentoId,
          justificativa: justificativa,
          acompanhante: acompanhante,
        );
    ref.invalidate(solicitacoesTfdProvider);
    ref.invalidate(viagensTfdProvider);
    return r;
  }

  Future<void> cancelar(String id) async {
    await ref.read(tfdRepositoryProvider).cancelar(id);
    ref.invalidate(solicitacoesTfdProvider);
    ref.invalidate(viagensTfdProvider);
  }
}

final tfdControllerProvider =
    NotifierProvider<TfdController, void>(TfdController.new);
