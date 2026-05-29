import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/encaminhamento.dart';
import 'providers.dart';

final encaminhamentoAtivoProvider =
    FutureProvider.autoDispose<Encaminhamento?>((ref) async {
  return ref.watch(encaminhamentoRepositoryProvider).ativo();
});

final encaminhamentosProvider =
    FutureProvider.autoDispose<List<Encaminhamento>>((ref) async {
  return ref.watch(encaminhamentoRepositoryProvider).listar();
});

/// Encaminhamentos ativos (não-CONCLUIDO/REJEITADO/CANCELADO).
/// Usado na home pra montar o carrossel.
final encaminhamentosAtivosProvider =
    FutureProvider.autoDispose<List<Encaminhamento>>((ref) async {
  final todos = await ref.watch(encaminhamentoRepositoryProvider).listar();
  return todos
      .where(
          (e) => !['CONCLUIDO', 'REJEITADO', 'CANCELADO'].contains(e.status))
      .toList()
    ..sort((a, b) => b.atualizadoEm.compareTo(a.atualizadoEm));
});

final encaminhamentoByIdProvider = FutureProvider.autoDispose
    .family<Encaminhamento, String>((ref, id) async {
  return ref.watch(encaminhamentoRepositoryProvider).obter(id);
});

final anexosProvider =
    FutureProvider.autoDispose.family<List<Anexo>, String>((ref, id) async {
  return ref.watch(encaminhamentoRepositoryProvider).anexos(id);
});

final timelineProvider = FutureProvider.autoDispose
    .family<List<EventoTimeline>, String>((ref, id) async {
  return ref.watch(encaminhamentoRepositoryProvider).timeline(id);
});
