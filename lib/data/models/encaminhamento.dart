/// Encaminhamento médico — visão paciente (subset do que UBS/SMS veem).
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
  });

  final String id;
  final String protocolo;

  /// Chave canônica: RASCUNHO, AGUARDANDO_REGULACAO, PENDENCIA_DOCUMENTO,
  /// EM_ANALISE, AGUARDANDO_AGENDAMENTO, AGENDADO, APROVADO, REJEITADO,
  /// CANCELADO, CONCLUIDO.
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
  final DateTime criadoEm;
  final DateTime atualizadoEm;

  /// Mensagem amigável pro paciente, derivada do status.
  String get mensagemPaciente {
    switch (status) {
      case 'RASCUNHO':
        return 'Sua UBS ainda está montando seu encaminhamento.';
      case 'AGUARDANDO_REGULACAO':
        return 'Seu encaminhamento foi enviado para a regulação do município. Aguarde análise.';
      case 'PENDENCIA_DOCUMENTO':
        return 'A regulação pediu mais documentos. Procure sua UBS.';
      case 'EM_ANALISE':
        return 'Sua solicitação está sendo analisada pela Secretaria de Saúde.';
      case 'AGUARDANDO_AGENDAMENTO':
        return 'Aprovado! Estamos buscando a melhor data para sua consulta.';
      case 'AGENDADO':
        return 'Sua consulta foi marcada. Veja a data e o local abaixo.';
      case 'APROVADO':
        return 'Sua solicitação foi aprovada pela regulação.';
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

  factory Encaminhamento.fromJson(Map<String, dynamic> j) => Encaminhamento(
        id: j['id'] as String,
        protocolo: j['protocolo'] as String,
        status: j['status'] as String,
        prioridade: j['prioridade'] as String,
        especialidade: j['especialidade'] as String,
        cid10: j['cid10'] as String?,
        cid10Descricao: j['cid10Descricao'] as String?,
        justificativaResumida: j['justificativaResumida'] as String?,
        ubsOrigemNome: j['ubsOrigemNome'] as String?,
        medicoSolicitanteNome: j['medicoSolicitanteNome'] as String?,
        dataAgendamento: j['dataAgendamento'] == null
            ? null
            : DateTime.parse(j['dataAgendamento'] as String),
        localAgendamento: j['localAgendamento'] as String?,
        observacoesRegulacao: j['observacoesRegulacao'] as String?,
        motivoRejeicao: j['motivoRejeicao'] as String?,
        pendenciasAbertas: (j['pendenciasAbertas'] as num?)?.toInt() ?? 0,
        podeSolicitarTfd: (j['podeSolicitarTfd'] as bool?) ?? false,
        criadoEm: DateTime.parse(j['criadoEm'] as String),
        atualizadoEm: DateTime.parse(j['atualizadoEm'] as String),
      );
}

/// Anexo de um encaminhamento.
class Anexo {
  const Anexo({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.tamanhoBytes,
    required this.criadoEm,
    this.url,
  });

  final String id;
  final String nome;
  final String tipo;
  final int tamanhoBytes;
  final DateTime criadoEm;
  final String? url;

  factory Anexo.fromJson(Map<String, dynamic> j) => Anexo(
        id: j['id'] as String,
        nome: j['nome'] as String,
        tipo: j['tipo'] as String,
        tamanhoBytes: (j['tamanhoBytes'] as num).toInt(),
        criadoEm: DateTime.parse(j['criadoEm'] as String),
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
        autorNome: j['autorNome'] as String?,
        autorPapel: j['autorPapel'] as String?,
        em: DateTime.parse(j['em'] as String),
      );
}
