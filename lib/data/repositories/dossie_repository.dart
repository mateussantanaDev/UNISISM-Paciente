import '../api/api_client.dart';
import '../models/dossie.dart';

/// Dossiê médico. Contrato `unisism-ubs@0.18.2+`:
///
///   GET /paciente-app/dossie/resumo                          → DossieResumo
///   GET /paciente-app/dossie/atendimentos[?cursor&limit]     → { items, nextCursor }
///   GET /paciente-app/dossie/atendimentos/:id                → Atendimento     (v0.18.2+)
///   GET /paciente-app/dossie/vacinacoes[?cursor&limit]       → { items, nextCursor }
///   GET /paciente-app/dossie/vacinacoes/:id                  → Vacinacao       (v0.18.2+)
///   GET /paciente-app/dossie/exames[?cursor&limit]           → { items, nextCursor }
///   GET /paciente-app/dossie/exames/:id                      → Exame           (v0.18.2+)
///
/// As 3 listas vêm **paginadas com cursor**. Detalhe granular tem shape
/// idêntico ao item da lista (mesmo factory).
abstract class DossieRepository {
  Future<DossieResumo> resumo();
  Future<List<Atendimento>> atendimentos();
  Future<DossiePagina<Atendimento>> atendimentosPaginado({String? cursor, int? limit});
  Future<Atendimento> atendimento(String id);
  Future<List<Vacinacao>> vacinacoes();
  Future<DossiePagina<Vacinacao>> vacinacoesPaginado({String? cursor, int? limit});
  Future<Vacinacao> vacinacao(String id);
  Future<List<Exame>> exames();
  Future<DossiePagina<Exame>> examesPaginado({String? cursor, int? limit});
  Future<Exame> exame(String id);
}

/// Wrapper paginado `{items, nextCursor}`.
class DossiePagina<T> {
  const DossiePagina({required this.items, this.nextCursor});
  final List<T> items;
  final String? nextCursor;

  bool get temMais => nextCursor != null && nextCursor!.isNotEmpty;
}

class DossieRepositoryHttp implements DossieRepository {
  DossieRepositoryHttp(this.api);
  final ApiClient api;

  @override
  Future<DossieResumo> resumo() async {
    final r = await api.get<Map<String, dynamic>>('/paciente-app/dossie/resumo');
    return DossieResumo.fromJson(r);
  }

  // ─── ATENDIMENTOS ───────────────────────────────────────────────

  @override
  Future<List<Atendimento>> atendimentos() async {
    final p = await atendimentosPaginado();
    return p.items;
  }

  @override
  Future<DossiePagina<Atendimento>> atendimentosPaginado({
    String? cursor,
    int? limit,
  }) async {
    final r = await _pag('/paciente-app/dossie/atendimentos', cursor, limit);
    return DossiePagina<Atendimento>(
      items: _toList(r, Atendimento.fromJson),
      nextCursor: r['nextCursor'] as String?,
    );
  }

  @override
  Future<Atendimento> atendimento(String id) async {
    final r = await api.get<Map<String, dynamic>>(
      '/paciente-app/dossie/atendimentos/$id',
    );
    return Atendimento.fromJson(r);
  }

  // ─── VACINAÇÕES ─────────────────────────────────────────────────

  @override
  Future<List<Vacinacao>> vacinacoes() async {
    final p = await vacinacoesPaginado();
    return p.items;
  }

  @override
  Future<DossiePagina<Vacinacao>> vacinacoesPaginado({
    String? cursor,
    int? limit,
  }) async {
    final r = await _pag('/paciente-app/dossie/vacinacoes', cursor, limit);
    return DossiePagina<Vacinacao>(
      items: _toList(r, Vacinacao.fromJson),
      nextCursor: r['nextCursor'] as String?,
    );
  }

  @override
  Future<Vacinacao> vacinacao(String id) async {
    final r = await api.get<Map<String, dynamic>>(
      '/paciente-app/dossie/vacinacoes/$id',
    );
    return Vacinacao.fromJson(r);
  }

  // ─── EXAMES ─────────────────────────────────────────────────────

  @override
  Future<List<Exame>> exames() async {
    final p = await examesPaginado();
    return p.items;
  }

  @override
  Future<DossiePagina<Exame>> examesPaginado({
    String? cursor,
    int? limit,
  }) async {
    final r = await _pag('/paciente-app/dossie/exames', cursor, limit);
    return DossiePagina<Exame>(
      items: _toList(r, Exame.fromJson),
      nextCursor: r['nextCursor'] as String?,
    );
  }

  @override
  Future<Exame> exame(String id) async {
    final r = await api.get<Map<String, dynamic>>(
      '/paciente-app/dossie/exames/$id',
    );
    return Exame.fromJson(r);
  }

  // ─── HELPERS ────────────────────────────────────────────────────

  /// Faz GET tolerante a 2 shapes:
  ///   - Novo (v0.14+): `{ items: [...], nextCursor: "..." | null }`
  ///   - Legado: `[...]` array puro (envelopado em `{items: array}` automaticamente)
  Future<Map<String, dynamic>> _pag(String path, String? cursor, int? limit) async {
    final query = <String, dynamic>{};
    if (cursor != null && cursor.isNotEmpty) query['cursor'] = cursor;
    if (limit != null && limit > 0) query['limit'] = limit;
    final r = await api.get<dynamic>(path, query: query.isEmpty ? null : query);
    if (r is Map<String, dynamic>) return r;
    if (r is List) return {'items': r, 'nextCursor': null};
    return const {'items': [], 'nextCursor': null};
  }

  List<T> _toList<T>(
    Map<String, dynamic> raw,
    T Function(Map<String, dynamic>) factory,
  ) {
    final list = (raw['items'] as List?) ?? const [];
    return list.cast<Map<String, dynamic>>().map(factory).toList();
  }
}
