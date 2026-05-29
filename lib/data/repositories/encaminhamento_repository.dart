import '../api/api_client.dart';
import '../models/encaminhamento.dart';
import 'mock/mock_seed.dart';

/// Encaminhamentos. Contrato:
///
/// GET   /paciente/encaminhamentos                              → Encaminhamento[]
/// GET   /paciente/encaminhamentos/ativo                        → Encaminhamento | null
/// GET   /paciente/encaminhamentos/:id                          → Encaminhamento
/// GET   /paciente/encaminhamentos/:id/anexos                   → Anexo[]
/// GET   /paciente/encaminhamentos/:id/timeline                 → EventoTimeline[]
/// GET   /paciente/encaminhamentos/:id/anexos/:anexoId/download → binary (PDF/image)
abstract class EncaminhamentoRepository {
  Future<List<Encaminhamento>> listar();
  Future<Encaminhamento?> ativo();
  Future<Encaminhamento> obter(String id);
  Future<List<Anexo>> anexos(String id);
  Future<List<EventoTimeline>> timeline(String id);
  String urlDownloadAnexo(String encId, String anexoId);
}

class EncaminhamentoRepositoryHttp implements EncaminhamentoRepository {
  EncaminhamentoRepositoryHttp(this.api);
  final ApiClient api;

  @override
  Future<List<Encaminhamento>> listar() async {
    final r = await api.get<List>('/paciente/encaminhamentos');
    return r.cast<Map<String, dynamic>>().map(Encaminhamento.fromJson).toList();
  }

  @override
  Future<Encaminhamento?> ativo() async {
    final r = await api.get<dynamic>('/paciente/encaminhamentos/ativo');
    if (r == null) return null;
    return Encaminhamento.fromJson(r as Map<String, dynamic>);
  }

  @override
  Future<Encaminhamento> obter(String id) async {
    final r = await api.get<Map<String, dynamic>>('/paciente/encaminhamentos/$id');
    return Encaminhamento.fromJson(r);
  }

  @override
  Future<List<Anexo>> anexos(String id) async {
    final r = await api.get<List>('/paciente/encaminhamentos/$id/anexos');
    return r.cast<Map<String, dynamic>>().map(Anexo.fromJson).toList();
  }

  @override
  Future<List<EventoTimeline>> timeline(String id) async {
    final r = await api.get<List>('/paciente/encaminhamentos/$id/timeline');
    return r.cast<Map<String, dynamic>>().map(EventoTimeline.fromJson).toList();
  }

  @override
  String urlDownloadAnexo(String encId, String anexoId) {
    return '${api.dio.options.baseUrl}/paciente/encaminhamentos/$encId/anexos/$anexoId/download';
  }
}

class EncaminhamentoRepositoryMock implements EncaminhamentoRepository {
  @override
  Future<List<Encaminhamento>> listar() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return MockSeed.encaminhamentos;
  }

  @override
  Future<Encaminhamento?> ativo() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final ativos = MockSeed.encaminhamentos
        .where((e) => !['CONCLUIDO', 'REJEITADO', 'CANCELADO'].contains(e.status))
        .toList();
    if (ativos.isEmpty) return null;
    return ativos.first;
  }

  @override
  Future<Encaminhamento> obter(String id) async {
    await Future.delayed(const Duration(milliseconds: 350));
    return MockSeed.encaminhamentos.firstWhere(
      (e) => e.id == id,
      orElse: () => MockSeed.encaminhamentos.first,
    );
  }

  @override
  Future<List<Anexo>> anexos(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return MockSeed.anexos;
  }

  @override
  Future<List<EventoTimeline>> timeline(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return MockSeed.timeline;
  }

  @override
  String urlDownloadAnexo(String encId, String anexoId) =>
      'mock://download/$encId/$anexoId';
}
