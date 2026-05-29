import '../api/api_client.dart';
import '../models/notificacao.dart';
import 'mock/mock_seed.dart';

/// Notificações. Contrato:
///
/// GET   /paciente/notificacoes                      → Notificacao[]
/// GET   /paciente/notificacoes/contagem-nao-lidas   → { count: number }
/// POST  /paciente/notificacoes/:id/marcar-lida      → 204
/// POST  /paciente/notificacoes/marcar-todas-lidas   → 204
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
    final r = await api.get<List>('/paciente/notificacoes');
    return r.cast<Map<String, dynamic>>().map(Notificacao.fromJson).toList();
  }

  @override
  Future<int> contagemNaoLidas() async {
    final r = await api.get<Map<String, dynamic>>('/paciente/notificacoes/contagem-nao-lidas');
    return (r['count'] as num).toInt();
  }

  @override
  Future<void> marcarLida(String id) async {
    await api.post('/paciente/notificacoes/$id/marcar-lida');
  }

  @override
  Future<void> marcarTodasLidas() async {
    await api.post('/paciente/notificacoes/marcar-todas-lidas');
  }
}

class NotificacaoRepositoryMock implements NotificacaoRepository {
  final List<Notificacao> _items = [...MockSeed.notificacoes];

  @override
  Future<List<Notificacao>> listar() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _items;
  }

  @override
  Future<int> contagemNaoLidas() async {
    await Future.delayed(const Duration(milliseconds: 80));
    return _items.where((n) => !n.lida).length;
  }

  @override
  Future<void> marcarLida(String id) async {
    final i = _items.indexWhere((n) => n.id == id);
    if (i >= 0) _items[i] = _items[i].copyWith(lida: true);
  }

  @override
  Future<void> marcarTodasLidas() async {
    for (var i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(lida: true);
    }
  }
}
