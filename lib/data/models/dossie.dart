/// Dossiê médico do paciente.
///
/// Shape autoritativo: `src/modules/paciente-app/application/use-cases/
/// DossieUseCases.ts` (`unisism-ubs@0.18.1+`).
///
/// Endpoints:
///   GET /v1/paciente-app/dossie/resumo         → DossieResumo
///   GET /v1/paciente-app/dossie/atendimentos   → { items, nextCursor }
///   GET /v1/paciente-app/dossie/vacinacoes     → { items, nextCursor }
///   GET /v1/paciente-app/dossie/exames         → { items, nextCursor }
///
/// As listas vêm paginadas com cursor opaco. O repo do app pode achatar
/// pra `List<T>` quando não precisar de paginação (default 50 itens).

class DossieResumo {
  const DossieResumo({
    required this.totalEncaminhamentos,
    required this.totalAtendimentos,
    required this.totalVacinas,
    required this.totalExames,
    required this.alergias,
    required this.condicoesCronicas,
    required this.medicamentosUsoContinuo,
    this.tipoSanguineo,
  });

  final int totalEncaminhamentos;
  final int totalAtendimentos;
  final int totalVacinas;
  final int totalExames;
  final String? tipoSanguineo;
  final List<String> alergias;
  final List<String> condicoesCronicas;
  final List<String> medicamentosUsoContinuo;

  factory DossieResumo.fromJson(Map<String, dynamic> j) => DossieResumo(
        totalEncaminhamentos: (j['totalEncaminhamentos'] as num?)?.toInt() ?? 0,
        totalAtendimentos: (j['totalAtendimentos'] as num?)?.toInt() ?? 0,
        totalVacinas: (j['totalVacinas'] as num?)?.toInt() ?? 0,
        totalExames: (j['totalExames'] as num?)?.toInt() ?? 0,
        tipoSanguineo: j['tipoSanguineo'] as String?,
        alergias: ((j['alergias'] as List?) ?? const []).cast<String>(),
        condicoesCronicas:
            ((j['condicoesCronicas'] as List?) ?? const []).cast<String>(),
        medicamentosUsoContinuo:
            ((j['medicamentosUsoContinuo'] as List?) ?? const []).cast<String>(),
      );
}

class Atendimento {
  const Atendimento({
    required this.id,
    required this.data,
    required this.tipo,
    required this.localNome,
    required this.profissionalNome,
    this.profissionalEspecialidade,
    this.queixaPrincipal,
    this.cid10,
    this.cid10Descricao,
    this.condutaResumida,
  });

  final String id;
  final DateTime data;

  /// Enum **completo do PEC** (alinhado ao backend v0.14+):
  /// CONSULTA_MEDICA · ENFERMAGEM · VACINACAO · CURATIVO ·
  /// ODONTOLOGICO · PROCEDIMENTO · ACOLHIMENTO
  final String tipo;
  final String localNome;
  final String profissionalNome;
  final String? profissionalEspecialidade;
  final String? queixaPrincipal;
  final String? cid10;

  /// Vem **sempre null** do backend (CID-10 não tem dicionário embarcado).
  /// Frontend pode resolver via lib pt-BR opcional.
  final String? cid10Descricao;
  final String? condutaResumida;

  /// Label amigável pt-BR pra exibir.
  String get tipoLabel {
    switch (tipo) {
      case 'CONSULTA_MEDICA':
        return 'Consulta médica';
      case 'ENFERMAGEM':
        return 'Atendimento de enfermagem';
      case 'VACINACAO':
        return 'Vacinação';
      case 'CURATIVO':
        return 'Curativo';
      case 'ODONTOLOGICO':
        return 'Odontologia';
      case 'PROCEDIMENTO':
        return 'Procedimento';
      case 'ACOLHIMENTO':
        return 'Acolhimento';
      default:
        return tipo;
    }
  }

  factory Atendimento.fromJson(Map<String, dynamic> j) => Atendimento(
        id: j['id'] as String,
        data: DateTime.parse(j['data'] as String),
        tipo: (j['tipo'] as String?) ?? 'PROCEDIMENTO',
        localNome: (j['localNome'] as String?) ?? '',
        profissionalNome: (j['profissionalNome'] as String?) ?? '',
        profissionalEspecialidade: j['profissionalEspecialidade'] as String?,
        queixaPrincipal: j['queixaPrincipal'] as String?,
        cid10: j['cid10'] as String?,
        cid10Descricao: j['cid10Descricao'] as String?,
        condutaResumida: j['condutaResumida'] as String?,
      );
}

class Vacinacao {
  const Vacinacao({
    required this.id,
    required this.vacina,
    required this.dose,
    required this.aplicadaEm,
    required this.localAplicacao,
    this.lote,
    this.fabricante,
    this.via,
    this.aplicadorNome,
  });

  final String id;
  final String vacina;
  final String dose;
  final DateTime aplicadaEm;
  final String localAplicacao;

  /// Nullable — nem todo registro tem lote.
  final String? lote;

  /// Nullable — schema atual não tem `fabricante` (reservado v0.19+).
  final String? fabricante;

  /// Nullable — `INTRAMUSCULAR | ORAL | SUBCUTANEA | ...`
  final String? via;

  /// Nome do profissional que aplicou.
  final String? aplicadorNome;

  factory Vacinacao.fromJson(Map<String, dynamic> j) => Vacinacao(
        id: j['id'] as String,
        vacina: (j['vacina'] as String?) ?? '',
        dose: (j['dose'] as String?) ?? '',
        aplicadaEm: DateTime.parse(j['aplicadaEm'] as String),
        localAplicacao: (j['localAplicacao'] as String?) ?? '',
        lote: j['lote'] as String?,
        fabricante: j['fabricante'] as String?,
        via: j['via'] as String?,
        aplicadorNome: j['aplicadorNome'] as String?,
      );
}

class Exame {
  const Exame({
    required this.id,
    required this.nome,
    required this.realizadoEm,
    required this.solicitanteNome,
    required this.alterado,
    required this.resultadoStatus,
    this.unidadeExecutora,
    this.categoria,
    this.resultadoResumo,
    this.observacoes,
  });

  final String id;
  final String nome;
  final DateTime realizadoEm;
  final String solicitanteNome;

  /// `LABORATORIAL | IMAGEM | FUNCIONAL | OUTROS` — nullable.
  final String? categoria;

  /// Local onde o exame foi realizado.
  final String? unidadeExecutora;

  /// True se `resultadoStatus ∈ {ALTERADO, CRITICO}` (derivado no backend).
  final bool alterado;

  /// `NORMAL | ALTERADO | CRITICO | PENDENTE`.
  final String resultadoStatus;

  /// Resumo do laudo. Nullable enquanto pendente.
  final String? resultadoResumo;

  /// Observações livres. Geralmente null.
  final String? observacoes;

  factory Exame.fromJson(Map<String, dynamic> j) => Exame(
        id: j['id'] as String,
        nome: (j['nome'] as String?) ?? '',
        realizadoEm: DateTime.parse(j['realizadoEm'] as String),
        solicitanteNome: (j['solicitanteNome'] as String?) ?? '',
        unidadeExecutora: j['unidadeExecutora'] as String?,
        categoria: j['categoria'] as String?,
        alterado: (j['alterado'] as bool?) ?? false,
        resultadoStatus: (j['resultadoStatus'] as String?) ?? 'PENDENTE',
        resultadoResumo: j['resultadoResumo'] as String?,
        observacoes: j['observacoes'] as String?,
      );
}
