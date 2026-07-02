import '../api/api_client.dart';
import '../models/tfd.dart';

/// TFD — Tratamento Fora de Domicílio. Contrato:
///
/// GET    /paciente/tfd/viagens                          → TfdViagem[]   (com vaga, futuras)
/// GET    /paciente/tfd/viagens/:id                      → TfdViagem
/// GET    /paciente/tfd/solicitacoes                     → TfdSolicitacao[]
/// GET    /paciente/tfd/solicitacoes/:id                 → TfdSolicitacao
/// POST   /paciente/tfd/solicitacoes
///        { viagemId, encaminhamentoId, justificativa, acompanhante? }
///                                                       → TfdSolicitacao
/// DELETE /paciente/tfd/solicitacoes/:id                 → 204 (cancela)
abstract class TfdRepository {
  Future<List<TfdViagem>> listarViagens();
  Future<TfdViagem> obterViagem(String id);
  Future<List<TfdSolicitacao>> minhasSolicitacoes();
  Future<TfdSolicitacao> obterSolicitacao(String id);
  Future<TfdSolicitacao> solicitar({
    required String viagemId,
    String? encaminhamentoId,
    required String justificativa,
    String? acompanhante,
  });
  Future<void> cancelar(String id);
}

class TfdRepositoryHttp implements TfdRepository {
  TfdRepositoryHttp(this.api);
  final ApiClient api;

  @override
  Future<List<TfdViagem>> listarViagens() async {
    final r = await api.get<List>('/paciente-app/tfd/viagens');
    return r.cast<Map<String, dynamic>>().map(TfdViagem.fromJson).toList();
  }

  @override
  Future<TfdViagem> obterViagem(String id) async {
    final r = await api.get<Map<String, dynamic>>('/paciente-app/tfd/viagens/$id');
    return TfdViagem.fromJson(r);
  }

  @override
  Future<List<TfdSolicitacao>> minhasSolicitacoes() async {
    final r = await api.get<List>('/paciente-app/tfd/solicitacoes');
    return r.cast<Map<String, dynamic>>().map(TfdSolicitacao.fromJson).toList();
  }

  @override
  Future<TfdSolicitacao> obterSolicitacao(String id) async {
    final r = await api.get<Map<String, dynamic>>('/paciente-app/tfd/solicitacoes/$id');
    return TfdSolicitacao.fromJson(r);
  }

  @override
  Future<TfdSolicitacao> solicitar({
    required String viagemId,
    String? encaminhamentoId,
    required String justificativa,
    String? acompanhante,
  }) async {
    final r = await api.post<Map<String, dynamic>>(
      '/paciente-app/tfd/solicitacoes',
      body: {
        'viagemId': viagemId,
        if (encaminhamentoId != null) 'encaminhamentoId': encaminhamentoId,
        'justificativa': justificativa,
        if (acompanhante != null) 'acompanhante': acompanhante,
      },
    );
    return TfdSolicitacao.fromJson(r);
  }

  @override
  Future<void> cancelar(String id) async {
    await api.delete('/paciente-app/tfd/solicitacoes/$id');
  }
}

