/// Dossiê médico do paciente.

class DossieResumo {
  const DossieResumo({
    required this.totalEncaminhamentos,
    required this.totalAtendimentos,
    required this.totalVacinas,
    required this.tipoSanguineo,
    required this.alergias,
    required this.condicoesCronicas,
    required this.medicamentosUsoContinuo,
  });

  final int totalEncaminhamentos;
  final int totalAtendimentos;
  final int totalVacinas;
  final String? tipoSanguineo;
  final List<String> alergias;
  final List<String> condicoesCronicas;
  final List<String> medicamentosUsoContinuo;

  factory DossieResumo.fromJson(Map<String, dynamic> j) => DossieResumo(
        totalEncaminhamentos: (j['totalEncaminhamentos'] as num).toInt(),
        totalAtendimentos: (j['totalAtendimentos'] as num).toInt(),
        totalVacinas: (j['totalVacinas'] as num).toInt(),
        tipoSanguineo: j['tipoSanguineo'] as String?,
        alergias: ((j['alergias'] as List?) ?? []).cast<String>(),
        condicoesCronicas: ((j['condicoesCronicas'] as List?) ?? []).cast<String>(),
        medicamentosUsoContinuo:
            ((j['medicamentosUsoContinuo'] as List?) ?? []).cast<String>(),
      );
}

class Atendimento {
  const Atendimento({
    required this.id,
    required this.data,
    required this.tipo,
    required this.localNome,
    required this.profissionalNome,
    required this.profissionalEspecialidade,
    this.queixaPrincipal,
    this.cid10,
    this.cid10Descricao,
    this.condutaResumida,
  });

  final String id;
  final DateTime data;

  /// CONSULTA / EMERGENCIA / EXAME / VACINACAO / RETORNO
  final String tipo;
  final String localNome;
  final String profissionalNome;
  final String profissionalEspecialidade;
  final String? queixaPrincipal;
  final String? cid10;
  final String? cid10Descricao;
  final String? condutaResumida;

  factory Atendimento.fromJson(Map<String, dynamic> j) => Atendimento(
        id: j['id'] as String,
        data: DateTime.parse(j['data'] as String),
        tipo: j['tipo'] as String,
        localNome: j['localNome'] as String,
        profissionalNome: j['profissionalNome'] as String,
        profissionalEspecialidade: j['profissionalEspecialidade'] as String,
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
    required this.lote,
    required this.localAplicacao,
  });

  final String id;
  final String vacina;
  final String dose;
  final DateTime aplicadaEm;
  final String lote;
  final String localAplicacao;

  factory Vacinacao.fromJson(Map<String, dynamic> j) => Vacinacao(
        id: j['id'] as String,
        vacina: j['vacina'] as String,
        dose: j['dose'] as String,
        aplicadaEm: DateTime.parse(j['aplicadaEm'] as String),
        lote: j['lote'] as String,
        localAplicacao: j['localAplicacao'] as String,
      );
}

class Exame {
  const Exame({
    required this.id,
    required this.nome,
    required this.realizadoEm,
    required this.solicitanteNome,
    required this.resultadoResumo,
    this.alterado = false,
    this.urlLaudo,
  });

  final String id;
  final String nome;
  final DateTime realizadoEm;
  final String solicitanteNome;
  final String resultadoResumo;
  final bool alterado;
  final String? urlLaudo;

  factory Exame.fromJson(Map<String, dynamic> j) => Exame(
        id: j['id'] as String,
        nome: j['nome'] as String,
        realizadoEm: DateTime.parse(j['realizadoEm'] as String),
        solicitanteNome: j['solicitanteNome'] as String,
        resultadoResumo: j['resultadoResumo'] as String,
        alterado: (j['alterado'] as bool?) ?? false,
        urlLaudo: j['urlLaudo'] as String?,
      );
}
