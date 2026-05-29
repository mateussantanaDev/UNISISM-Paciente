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
