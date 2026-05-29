import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/banner.dart';
import 'providers.dart';

final bannersAtivosProvider =
    FutureProvider.autoDispose<List<SmsBannerModel>>((ref) async {
  final list = await ref.watch(bannerRepositoryProvider).ativos();
  final live = list.where((b) => !b.expirado).toList()
    ..sort((a, b) {
      final byPrio = b.prioridadeOrdem.compareTo(a.prioridadeOrdem);
      if (byPrio != 0) return byPrio;
      return b.publicadoEm.compareTo(a.publicadoEm);
    });
  return live;
});
