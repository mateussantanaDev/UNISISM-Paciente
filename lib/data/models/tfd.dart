/// TFD — Tratamento Fora de Domicílio (transporte sanitário compartilhado).
///
/// Shape autoritativo: `src/modules/paciente-app/application/use-cases/
/// TfdPacienteUseCases.ts` (`unisism-ubs@0.18.1+`).

/// Coordenada geográfica `{lat, lng}` — futuro: integração com mapas.
class GeoCoord {
  const GeoCoord({required this.lat, required this.lng});
  final double lat;
  final double lng;

  factory GeoCoord.fromJson(Map<String, dynamic> j) => GeoCoord(
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
      );
}

/// Veículo / viagem programada da SMS.
class TfdViagem {
  const TfdViagem({
    required this.id,
    required this.destinoCidade,
    required this.destinoUf,
    required this.destinoLocal,
    required this.dataPartida,
    required this.horaPartida,
    required this.localEmbarque,
    required this.vagasTotal,
    required this.vagasOcupadas,
    required this.veiculoDescricao,
    required this.veiculoPlaca,
    this.observacoes,
    this.motoristaNome,
    this.coordOrigem,
    this.coordDestino,
  });

  final String id;
  final String destinoCidade;
  final String destinoUf;
  final String destinoLocal;
  final DateTime dataPartida;
  final String horaPartida;
  final String localEmbarque;
  final int vagasTotal;
  final int vagasOcupadas;
  final String veiculoDescricao;
  final String veiculoPlaca;
  final String? observacoes;
  final String? motoristaNome;

  /// Reservado — backend retorna `null` hoje.
  final GeoCoord? coordOrigem;
  final GeoCoord? coordDestino;

  int get vagasDisponiveis => vagasTotal - vagasOcupadas;
  bool get temVaga => vagasDisponiveis > 0;
  double get ocupacaoPct => vagasTotal == 0 ? 0 : vagasOcupadas / vagasTotal;

  factory TfdViagem.fromJson(Map<String, dynamic> j) => TfdViagem(
        id: j['id'] as String,
        destinoCidade: (j['destinoCidade'] as String?) ?? '',
        destinoUf: (j['destinoUf'] as String?) ?? '',
        destinoLocal: (j['destinoLocal'] as String?) ?? '',
        dataPartida: DateTime.parse(j['dataPartida'] as String),
        horaPartida: (j['horaPartida'] as String?) ?? '',
        localEmbarque: (j['localEmbarque'] as String?) ?? '',
        vagasTotal: (j['vagasTotal'] as num?)?.toInt() ?? 0,
        vagasOcupadas: (j['vagasOcupadas'] as num?)?.toInt() ?? 0,
        veiculoDescricao: (j['veiculoDescricao'] as String?) ?? '',
        veiculoPlaca: (j['veiculoPlaca'] as String?) ?? '',
        observacoes: j['observacoes'] as String?,
        motoristaNome: j['motoristaNome'] as String?,
        coordOrigem: j['coordOrigem'] == null
            ? null
            : GeoCoord.fromJson(j['coordOrigem'] as Map<String, dynamic>),
        coordDestino: j['coordDestino'] == null
            ? null
            : GeoCoord.fromJson(j['coordDestino'] as Map<String, dynamic>),
      );
}

/// Solicitação do paciente para uma viagem.
class TfdSolicitacao {
  const TfdSolicitacao({
    required this.id,
    required this.viagemId,
    required this.status,
    required this.criadaEm,
    required this.viagem,
    required this.prioridade,
    this.numeroAssento,
    this.justificativaPaciente,
    this.motivoRecusa,
    this.encaminhamentoId,
    this.encaminhamentoProtocolo,
    this.aprovadaEm,
    this.acompanhante,
  });

  final String id;
  final String viagemId;

  /// AGUARDANDO | APROVADA | RECUSADA | CANCELADA | EMBARCADA | CONCLUIDA
  final String status;
  final DateTime criadaEm;
  final TfdViagem viagem;

  /// NORMAL | PRIORITARIA | URGENTE.
  /// **Derivada pelo servidor** a partir do encaminhamento anexado.
  final String prioridade;

  final String? numeroAssento;
  final String? justificativaPaciente;
  final String? motivoRecusa;

  /// ID do encaminhamento que originou a solicitação (quando informado).
  final String? encaminhamentoId;
  final String? encaminhamentoProtocolo;
  final DateTime? aprovadaEm;
  final String? acompanhante;

  /// True quando esta solicitação ainda pode ser cancelada pelo paciente.
  bool get cancelavel => status == 'AGUARDANDO';

  String get statusLabel {
    switch (status) {
      case 'AGUARDANDO':
        return 'Esperando análise';
      case 'APROVADA':
        return 'Vaga confirmada';
      case 'RECUSADA':
        return 'Vaga recusada';
      case 'CANCELADA':
        return 'Cancelada';
      case 'EMBARCADA':
        return 'Em viagem';
      case 'CONCLUIDA':
        return 'Concluída';
      default:
        return status;
    }
  }

  factory TfdSolicitacao.fromJson(Map<String, dynamic> j) => TfdSolicitacao(
        id: j['id'] as String,
        viagemId: j['viagemId'] as String,
        status: j['status'] as String,
        criadaEm: DateTime.parse(j['criadaEm'] as String),
        viagem: TfdViagem.fromJson(j['viagem'] as Map<String, dynamic>),
        prioridade: (j['prioridade'] as String?) ?? 'NORMAL',
        numeroAssento: j['numeroAssento'] as String?,
        justificativaPaciente: j['justificativaPaciente'] as String?,
        motivoRecusa: j['motivoRecusa'] as String?,
        encaminhamentoId: j['encaminhamentoId'] as String?,
        encaminhamentoProtocolo: j['encaminhamentoProtocolo'] as String?,
        aprovadaEm: j['aprovadaEm'] == null
            ? null
            : DateTime.parse(j['aprovadaEm'] as String),
        acompanhante: j['acompanhante'] as String?,
      );
}
