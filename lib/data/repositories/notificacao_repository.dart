import '../api/api_client.dart';
import '../models/notificacao.dart';

/// Notificações.
///
/// **Backend real** (`unisism-ubs@0.18.0+`):
///
///     GET   /v1/paciente-app/notificacoes          → [{id, tipo, titulo, corpo, criadaEm, lidaEm, ...}]
///                                                    (query opcional `?apenasNaoLidas=true`)
///     GET   /v1/paciente-app/notificacoes/count    → { naoLidas: number }
///     POST  /v1/paciente-app/notificacoes/:id/lida → 204
///     POST  /v1/paciente-app/notificacoes/marcar-todas-lidas → { atualizadas: number }
abstract class NotificacaoRepository {
  Future<List<Notificacao>> listar();
  Future<int> contagemNaoLidas();
  Future<void> marcarLida(String id);
  Future<void> marcarTodasLidas();
}

class NotificacaoRepositoryHttp implements NotificacaoRepository {
  NotificacaoRepositoryHttp(this.api);
  final ApiClient api;

  @override
  Future<List<Notificacao>> listar() async {
    final r = await api.get<List>('/paciente-app/notificacoes');
    return r.cast<Map<String, dynamic>>().map(Notificacao.fromJson).toList();
  }

  @override
  Future<int> contagemNaoLidas() async {
    final r = await api
        .get<Map<String, dynamic>>('/paciente-app/notificacoes/count');
    // Backend usa `naoLidas`; aceita `count` como fallback (mock).
    return ((r['naoLidas'] ?? r['count']) as num?)?.toInt() ?? 0;
  }

  @override
  Future<void> marcarLida(String id) async {
    await api.post('/paciente-app/notificacoes/$id/lida');
  }

  @override
  Future<void> marcarTodasLidas() async {
    await api.post('/paciente-app/notificacoes/marcar-todas-lidas');
  }
}

