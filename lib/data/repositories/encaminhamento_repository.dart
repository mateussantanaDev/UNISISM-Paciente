import '../../core/services/push_service.dart';
import '../api/api_client.dart';
import '../models/encaminhamento.dart';

/// Encaminhamentos do paciente.
///
/// **Backend real** (`unisism-ubs@0.18.0+`) expõe um **único endpoint**
/// que retorna tudo embedado:
///
///     GET /v1/paciente-app/meus-encaminhamentos
///         → [{ id, protocolo, status, paciente, solicitacao,
///              anexos: [...], timeline: [...], ... }]
///
///     GET /v1/paciente-app/anexos/:id/download → binário (PDF/IMG)
///
/// O app simula 5 métodos (lista, ativo, obter, anexos, timeline) lendo do
/// **cache em memória** populado na primeira chamada de `listar()`. Cache é
/// invalidado em pull-to-refresh quando `listar()` for re-fetched.
abstract class EncaminhamentoRepository {
  Future<List<Encaminhamento>> listar();
  Future<Encaminhamento?> ativo();
  Future<Encaminhamento> obter(String id);
  Future<List<Anexo>> anexos(String id);
  Future<List<EventoTimeline>> timeline(String id);
  String urlDownloadAnexo(String encId, String anexoId);
}

/// Wrapper de cache: guarda o objeto raw + adapter aplicado.
class _EncCache {
  _EncCache({
    required this.enc,
    required this.anexos,
    required this.timeline,
  });
  final Encaminhamento enc;
  final List<Anexo> anexos;
  final List<EventoTimeline> timeline;
}

class EncaminhamentoRepositoryHttp implements EncaminhamentoRepository {
  EncaminhamentoRepositoryHttp(this.api);
  final ApiClient api;

  List<_EncCache> _cache = const [];

  @override
  Future<List<Encaminhamento>> listar() async {
    final r = await api.get<List>('/paciente-app/meus-encaminhamentos');
    final raw = r.cast<Map<String, dynamic>>();
    _cache = raw
        .map((j) => _EncCache(
              enc: Encaminhamento.fromJson(j),
              anexos: Encaminhamento.anexosFromBackend(j),
              timeline: Encaminhamento.timelineFromBackend(j),
            ))
        .toList();
    final encs = _cache.map((c) => c.enc).toList()
      ..sort((a, b) => b.atualizadoEm.compareTo(a.atualizadoEm));

    // Sincroniza lembretes locais para consultas agendadas (3 dias antes)
    await PushService.instance.syncAppointmentReminders(encs);

    return encs;
  }

  @override
  Future<Encaminhamento?> ativo() async {
    // Backend não tem endpoint dedicado. Lista tudo e filtra.
    final todos = await _ensureCache();
    final ativos = todos
        .where((c) => !const [
              'CONCLUIDO',
              'REJEITADO',
              'CANCELADO',
            ].contains(c.enc.status))
        .toList()
      ..sort((a, b) => b.enc.atualizadoEm.compareTo(a.enc.atualizadoEm));
    return ativos.isEmpty ? null : ativos.first.enc;
  }

  @override
  Future<Encaminhamento> obter(String id) async {
    final cache = await _ensureCache();
    final hit = cache.where((c) => c.enc.id == id).firstOrNull;
    if (hit != null) return hit.enc;
    // Cache miss: re-fetch.
    await listar();
    final hit2 = _cache.where((c) => c.enc.id == id).firstOrNull;
    if (hit2 == null) {
      throw StateError('Encaminhamento não encontrado.');
    }
    return hit2.enc;
  }

  @override
  Future<List<Anexo>> anexos(String id) async {
    final cache = await _ensureCache();
    return cache.where((c) => c.enc.id == id).firstOrNull?.anexos ??
        const [];
  }

  @override
  Future<List<EventoTimeline>> timeline(String id) async {
    final cache = await _ensureCache();
    return cache.where((c) => c.enc.id == id).firstOrNull?.timeline ??
        const [];
  }

  @override
  String urlDownloadAnexo(String encId, String anexoId) {
    // Backend usa apenas `anexoId` no path (não tem `encId`).
    // Posse é validada pelo middleware via CPF do JWT.
    return '${api.dio.options.baseUrl}/paciente-app/anexos/$anexoId/download';
  }

  Future<List<_EncCache>> _ensureCache() async {
    if (_cache.isEmpty) await listar();
    return _cache;
  }
}

