/// Encaminhamento médico — visão paciente (subset do que UBS/SMS veem).
///
/// **Backend real** (`unisism-ubs@0.18.1+`):
/// `GET /v1/paciente-app/meus-encaminhamentos` retorna lista achatada via
/// `mapEncaminhamentoApp` (adapter em `src/modules/paciente-app/application/
/// adapters/encaminhamentoAppAdapter.ts`). Todos os campos abaixo são
/// **fonte de verdade** desse contrato.
class Encaminhamento {
  const Encaminhamento({
    required this.id,
    required this.protocolo,
    required this.status,
    required this.prioridade,
    required this.especialidade,
    required this.criadoEm,
    required this.atualizadoEm,
    this.cid10,
    this.cid10Descricao,
    this.justificativaResumida,
    this.ubsOrigemNome,
    this.medicoSolicitanteNome,
    this.dataAgendamento,
    this.localAgendamento,
    this.observacoesRegulacao,
    this.motivoRejeicao,
    this.pendenciasAbertas = 0,
    this.podeSolicitarTfd = false,
    this.recomendacoes = const [],
  });

  final String id;
  final String protocolo;

  /// Chave canônica (após adapter no backend):
  /// RASCUNHO · AGUARDANDO_REGULACAO · PENDENCIA_DOCUMENTO ·
  /// APROVADO · AGUARDANDO_AGENDAMENTO · AGENDADO · REJEITADO ·
  /// CANCELADO · CONCLUIDO.
  final String status;

  /// ELETIVA / PRIORITARIA / URGENTE / EMERGENCIA
  final String prioridade;

  final String especialidade;
  final String? cid10;
  final String? cid10Descricao;
  final String? justificativaResumida;
  final String? ubsOrigemNome;
  final String? medicoSolicitanteNome;
  final DateTime? dataAgendamento;
  final String? localAgendamento;
  final String? observacoesRegulacao;
  final String? motivoRejeicao;
  final int pendenciasAbertas;
  final bool podeSolicitarTfd;

  /// Lista de orientações curtas vindas de `EspecialidadeRecomendacao`
  /// (admin cadastra; backend faz JOIN case+accent-insensitive com a
  /// especialidade solicitada).
  final List<String> recomendacoes;

  final DateTime criadoEm;
  final DateTime atualizadoEm;

  /// Mensagem amigável pro paciente, derivada do status.
  String get mensagemPaciente {
    switch (status) {
      case 'RASCUNHO':
        return 'Sua UBS ainda está montando seu encaminhamento.';
      case 'AGUARDANDO_REGULACAO':
        return 'Seu encaminhamento foi enviado para a secretaria do município. Aguarde análise.';
      case 'PENDENCIA_DOCUMENTO':
        return 'A secretaria pediu mais documentos. Procure sua UBS.';
      case 'EM_ANALISE':
        return 'Sua solicitação está sendo analisada pela Secretaria de Saúde.';
      case 'AGUARDANDO_AGENDAMENTO':
        return 'Aprovado! Estamos buscando a melhor data para sua consulta.';
      case 'AGENDADO':
        return 'Sua consulta foi marcada. Veja a data e o local abaixo.';
      case 'APROVADO':
        return 'Sua solicitação foi aprovada pela secretaria.';
      case 'REJEITADO':
        return 'Sua solicitação foi recusada. Veja o motivo e procure sua UBS.';
      case 'CANCELADO':
        return 'Seu encaminhamento foi cancelado.';
      case 'CONCLUIDO':
        return 'Atendimento realizado. Cuide-se!';
      default:
        return 'Acompanhe os próximos passos.';
    }
  }

  String get statusLabel {
    switch (status) {
      case 'AGUARDANDO_REGULACAO':
        return 'Esperando análise';
      case 'PENDENCIA_DOCUMENTO':
        return 'Pendência aberta';
      case 'EM_ANALISE':
        return 'Em análise';
      case 'AGUARDANDO_AGENDAMENTO':
        return 'Aguardando data';
      case 'AGENDADO':
        return 'Consulta marcada';
      case 'APROVADO':
        return 'Aprovado';
      case 'REJEITADO':
        return 'Recusado';
      case 'CANCELADO':
        return 'Cancelado';
      case 'CONCLUIDO':
        return 'Atendimento feito';
      case 'RASCUNHO':
      default:
        return 'Em preparação';
    }
  }

  /// Shape **autoritativo** do backend (após adapter — shape achatado).
  /// Aceita também o shape legado com `solicitacao.*` aninhado pra
  /// compat com mocks antigos / clientes pre-adapter.
  factory Encaminhamento.fromJson(Map<String, dynamic> j) {
    // Backend novo (após adapter) já manda flat — preferir esses campos.
    // Backend legado (sem adapter) ainda aninha em `solicitacao.*`.
    final solicitacao = j['solicitacao'] as Map<String, dynamic>?;

    final especialidade = (j['especialidade'] ??
            solicitacao?['especialidadeSolicitada']) as String? ??
        '—';
    final prioridade = (j['prioridade'] ?? solicitacao?['prioridade']) as String? ??
        'ELETIVA';
    final cid10 = (j['cid10'] ?? solicitacao?['cid10']) as String?;
    final cidDescricao = (j['cid10Descricao'] ?? solicitacao?['cidDescricao']) as String?;
    final justificativa = (j['justificativaResumida'] ??
        solicitacao?['justificativaClinica']) as String?;
    final medicoSolicitante = (j['medicoSolicitanteNome'] ??
        solicitacao?['medicoSolicitante']) as String?;
    final ubsOrigem = (j['ubsOrigemNome'] ?? j['unidadeOrigem']) as String?;
    final dataAgRaw = (j['dataAgendamento'] ?? j['agendamentoPrevisto']) as String?;

    return Encaminhamento(
      id: j['id'] as String,
      protocolo: j['protocolo'] as String,
      status: j['status'] as String,
      prioridade: prioridade,
      especialidade: especialidade,
      cid10: cid10,
      cid10Descricao: cidDescricao,
      justificativaResumida: justificativa,
      ubsOrigemNome: ubsOrigem,
      medicoSolicitanteNome: medicoSolicitante,
      dataAgendamento:
          dataAgRaw == null ? null : DateTime.tryParse(dataAgRaw),
      localAgendamento: j['localAgendamento'] as String?,
      observacoesRegulacao: j['observacoesRegulacao'] as String?,
      motivoRejeicao: j['motivoRejeicao'] as String?,
      pendenciasAbertas: (j['pendenciasAbertas'] as num?)?.toInt() ?? 0,
      podeSolicitarTfd: (j['podeSolicitarTfd'] as bool?) ?? false,
      recomendacoes:
          ((j['recomendacoes'] as List?) ?? const []).cast<String>(),
      criadoEm: DateTime.parse(j['criadoEm'] as String),
      atualizadoEm: DateTime.parse(j['atualizadoEm'] as String),
    );
  }

  /// Extrai anexos embedados.
  /// Backend (após adapter) manda:
  ///   `[{ id, nome, tipo: 'PDF'|'IMG'|'DOC', tamanhoBytes, adicionadoEm, descricao }]`
  static List<Anexo> anexosFromBackend(Map<String, dynamic> j) {
    final raw = (j['anexos'] as List?) ?? const [];
    return raw.cast<Map<String, dynamic>>().map((a) {
      final nome = (a['nome'] as String?) ?? '';
      // Backend após adapter manda `tamanhoBytes` direto. Legado manda `tamanhoKb`.
      final tamanhoBytes = (a['tamanhoBytes'] as num?)?.toInt() ??
          (((a['tamanhoKb'] as num?)?.toInt() ?? 0) * 1024);
      // Backend após adapter manda `adicionadoEm`. Legado manda `uploadEm`/`criadoEm`.
      final dataRaw =
          (a['adicionadoEm'] ?? a['uploadEm'] ?? a['criadoEm']) as String?;
      return Anexo(
        id: a['id'] as String,
        nome: nome,
        // Backend após adapter já manda PDF|IMG|DOC. Fallback: deriva da extensão.
        tipo: (a['tipo'] as String?) ?? _mapTipoAnexo(nome),
        tamanhoBytes: tamanhoBytes,
        criadoEm: dataRaw != null ? DateTime.parse(dataRaw) : DateTime.now(),
        descricao: a['descricao'] as String?,
        url: a['url'] as String?,
      );
    }).toList();
  }

  /// Extrai timeline embedada.
  /// Backend (após adapter) já manda enum app-friendly:
  ///   tipo ∈ CRIACAO | ANEXO | PENDENCIA | APROVACAO | AGENDAMENTO | REJEICAO | ATUALIZACAO
  static List<EventoTimeline> timelineFromBackend(Map<String, dynamic> j) {
    final raw = (j['timeline'] as List?) ?? const [];
    return raw.cast<Map<String, dynamic>>().map((e) {
      final tipoRaw = (e['tipo'] as String?) ?? 'ATUALIZACAO';
      return EventoTimeline(
        id: e['id'] as String,
        // Backend após adapter já manda enum app; legado manda CRIADO/DOCUMENTO_ANEXADO/...
        tipo: _normalizeTipoEvento(tipoRaw),
        titulo: (e['titulo'] as String?) ?? '',
        descricao: e['descricao'] as String?,
        autorNome: (e['autor'] ?? e['autorNome']) as String?,
        autorPapel: e['autorPapel'] as String?,
        em: DateTime.parse(e['em'] as String),
      );
    }).toList();
  }

  static String _mapTipoAnexo(String nome) {
    final n = nome.toLowerCase();
    if (n.endsWith('.pdf')) return 'PDF';
    if (n.endsWith('.jpg') ||
        n.endsWith('.jpeg') ||
        n.endsWith('.png') ||
        n.endsWith('.heic') ||
        n.endsWith('.webp')) {
      return 'IMG';
    }
    return 'DOC';
  }

  /// Aceita tipos do adapter (CRIACAO|ANEXO|...) E tipos legados internos
  /// do backend (CRIADO|DOCUMENTO_ANEXADO|RESPOSTA_SUS_RECEBIDA|...).
  static String _normalizeTipoEvento(String s) {
    switch (s) {
      // Já no formato app
      case 'CRIACAO':
      case 'ANEXO':
      case 'PENDENCIA':
      case 'APROVACAO':
      case 'AGENDAMENTO':
      case 'REJEICAO':
      case 'ATUALIZACAO':
        return s;
      // Formato interno legado → traduz
      case 'CRIADO':
        return 'CRIACAO';
      case 'DOCUMENTO_ANEXADO':
      case 'RESPOSTA_SUS_RECEBIDA':
        return 'ANEXO';
      case 'PENDENCIA_REGISTRADA':
        return 'PENDENCIA';
      case 'APROVADO':
        return 'APROVACAO';
      case 'AGENDADO':
        return 'AGENDAMENTO';
      case 'REJEITADO':
        return 'REJEICAO';
      case 'ENVIADO_REGULACAO':
      case 'OBSERVACAO':
      case 'EDITADO':
      default:
        return 'ATUALIZACAO';
    }
  }
}

/// Anexo de um encaminhamento.
class Anexo {
  const Anexo({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.tamanhoBytes,
    required this.criadoEm,
    this.descricao,
    this.url,
  });

  final String id;
  final String nome;

  /// PDF | IMG | DOC (vem do adapter do backend).
  final String tipo;
  final int tamanhoBytes;
  final DateTime criadoEm;

  /// Descrição livre vinda do backend (geralmente null).
  final String? descricao;

  /// URL absoluta caso o adapter futuramente envie um link direto.
  /// Hoje sempre null — use `urlDownloadAnexo()` do `EncaminhamentoRepository`.
  final String? url;

  factory Anexo.fromJson(Map<String, dynamic> j) => Anexo(
        id: j['id'] as String,
        nome: j['nome'] as String,
        tipo: j['tipo'] as String,
        tamanhoBytes: (j['tamanhoBytes'] as num).toInt(),
        criadoEm: DateTime.parse(
          (j['adicionadoEm'] ?? j['uploadEm'] ?? j['criadoEm']) as String,
        ),
        descricao: j['descricao'] as String?,
        url: j['url'] as String?,
      );
}

/// Evento da timeline do encaminhamento (versão paciente).
class EventoTimeline {
  const EventoTimeline({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.em,
    this.descricao,
    this.autorNome,
    this.autorPapel,
  });

  final String id;

  /// CRIACAO, ANEXO, PENDENCIA, APROVACAO, AGENDAMENTO, REJEICAO, ATUALIZACAO
  final String tipo;
  final String titulo;
  final String? descricao;
  final String? autorNome;
  final String? autorPapel;
  final DateTime em;

  factory EventoTimeline.fromJson(Map<String, dynamic> j) => EventoTimeline(
        id: j['id'] as String,
        tipo: j['tipo'] as String,
        titulo: j['titulo'] as String,
        descricao: j['descricao'] as String?,
        autorNome: (j['autor'] ?? j['autorNome']) as String?,
        autorPapel: j['autorPapel'] as String?,
        em: DateTime.parse(j['em'] as String),
      );
}
