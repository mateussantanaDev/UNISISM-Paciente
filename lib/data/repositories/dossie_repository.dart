import '../api/api_client.dart';
import '../models/dossie.dart';
import 'mock/mock_seed.dart';

/// Dossiê. Contrato:
///
/// GET /paciente/dossie/resumo        → DossieResumo
/// GET /paciente/dossie/atendimentos  → Atendimento[]
/// GET /paciente/dossie/vacinacoes    → Vacinacao[]
/// GET /paciente/dossie/exames        → Exame[]
abstract class DossieRepository {
  Future<DossieResumo> resumo();
  Future<List<Atendimento>> atendimentos();
  Future<List<Vacinacao>> vacinacoes();
  Future<List<Exame>> exames();
}

class DossieRepositoryHttp implements DossieRepository {
  DossieRepositoryHttp(this.api);
  final ApiClient api;

  @override
  Future<DossieResumo> resumo() async {
    final r = await api.get<Map<String, dynamic>>('/paciente/dossie/resumo');
    return DossieResumo.fromJson(r);
  }

  @override
  Future<List<Atendimento>> atendimentos() async {
    final r = await api.get<List>('/paciente/dossie/atendimentos');
    return r.cast<Map<String, dynamic>>().map(Atendimento.fromJson).toList();
  }

  @override
  Future<List<Vacinacao>> vacinacoes() async {
    final r = await api.get<List>('/paciente/dossie/vacinacoes');
    return r.cast<Map<String, dynamic>>().map(Vacinacao.fromJson).toList();
  }

  @override
  Future<List<Exame>> exames() async {
    final r = await api.get<List>('/paciente/dossie/exames');
    return r.cast<Map<String, dynamic>>().map(Exame.fromJson).toList();
  }
}

class DossieRepositoryMock implements DossieRepository {
  @override
  Future<DossieResumo> resumo() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return MockSeed.dossieResumo;
  }

  @override
  Future<List<Atendimento>> atendimentos() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return MockSeed.atendimentos;
  }

  @override
  Future<List<Vacinacao>> vacinacoes() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return MockSeed.vacinacoes;
  }

  @override
  Future<List<Exame>> exames() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return MockSeed.exames;
  }
}
