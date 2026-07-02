import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/dossie.dart';
import 'providers.dart';

final dossieResumoProvider = FutureProvider.autoDispose<DossieResumo>((ref) async {
  return ref.watch(dossieRepositoryProvider).resumo();
});

final atendimentosProvider = FutureProvider.autoDispose<List<Atendimento>>(
  (ref) async => ref.watch(dossieRepositoryProvider).atendimentos(),
);

final vacinacoesProvider = FutureProvider.autoDispose<List<Vacinacao>>(
  (ref) async => ref.watch(dossieRepositoryProvider).vacinacoes(),
);

final examesProvider = FutureProvider.autoDispose<List<Exame>>(
  (ref) async => ref.watch(dossieRepositoryProvider).exames(),
);

// ─── Providers de DETALHE (single item) ──────────────────────────────
//
// Backend v0.18.2+ expõe endpoints granulares:
//   GET /paciente-app/dossie/atendimentos/:id   → 1 Atendimento
//   GET /paciente-app/dossie/vacinacoes/:id     → 1 Vacinacao
//   GET /paciente-app/dossie/exames/:id         → 1 Exame
//
// Backend faz audit dual (LGPD 5a + CFM 20a, ação `LEITURA_DOSSIE`) em cada
// hit, então preferimos chamar diretamente — cada abertura de detalhe vira
// trilha de auditoria. Erros 404 (`ATENDIMENTO_NAO_ENCONTRADO`, etc) sobem
// como `ApiException` e a UI mostra empty state amigável.

final atendimentoByIdProvider =
    FutureProvider.autoDispose.family<Atendimento, String>((ref, id) async {
  return ref.watch(dossieRepositoryProvider).atendimento(id);
});

final vacinacaoByIdProvider =
    FutureProvider.autoDispose.family<Vacinacao, String>((ref, id) async {
  return ref.watch(dossieRepositoryProvider).vacinacao(id);
});

final exameByIdProvider =
    FutureProvider.autoDispose.family<Exame, String>((ref, id) async {
  return ref.watch(dossieRepositoryProvider).exame(id);
});
