/// Modelo do paciente logado.
///
/// Backend real (`GET /v1/paciente-app/me` e `paciente` do login/refresh,
/// v0.18.3+) retorna **27 campos**: identificação, filiação, perfil sócio,
/// contato, endereço estruturado, e atenção primária (UBS/ACS/microárea/eSF).
class Paciente {
  const Paciente({
    required this.id,
    required this.nome,
    required this.cpf,
    this.nomeSocial,
    this.cpfFormatado,
    this.dataNascimento,
    this.cartaoSus,
    this.sexo,
    this.fotoUrl,

    // Filiação
    this.nomeMae,
    this.nomePai,

    // Perfil sócio-demográfico
    this.estadoCivil,
    this.escolaridade,
    this.profissao,
    this.racaCor,
    this.grupoSanguineo,

    // Contato
    this.email,
    this.telefone,
    this.telefoneSecundario,

    // Endereço estruturado
    this.endereco,
    this.bairro,
    this.municipio,
    this.uf,
    this.cep,

    // Atenção primária
    this.ubsVinculadaId,
    this.ubsVinculadaNome,
    this.agenteComunitario,
    this.microarea,
    this.equipeSaudeFamilia,

    this.senhaProvisoria = false,
  });

  final String id;
  final String nome;
  final String? nomeSocial;

  /// CPF apenas dígitos (11 chars). Backend normaliza.
  final String cpf;

  /// CPF formatado vindo do backend (`"123.456.789-09"`).
  final String? cpfFormatado;
  final DateTime? dataNascimento;
  final String? cartaoSus;

  /// `M` · `F` · `OUTRO`.
  final String? sexo;
  final String? fotoUrl;

  // ── Filiação ──
  final String? nomeMae;
  final String? nomePai;

  // ── Perfil sócio-demográfico ──
  /// `SOLTEIRO | CASADO | DIVORCIADO | VIUVO | UNIAO_ESTAVEL | OUTRO`
  final String? estadoCivil;
  final String? escolaridade;
  final String? profissao;

  /// `BRANCA | PRETA | PARDA | AMARELA | INDIGENA | NAO_INFORMADA`
  final String? racaCor;

  /// `A_POSITIVO | A_NEGATIVO | B_POSITIVO | B_NEGATIVO | AB_POSITIVO | AB_NEGATIVO | O_POSITIVO | O_NEGATIVO`
  final String? grupoSanguineo;

  // ── Contato ──
  final String? email;
  final String? telefone;
  final String? telefoneSecundario;

  // ── Endereço ──
  final String? endereco;
  final String? bairro;
  final String? municipio;
  final String? uf;
  final String? cep;

  // ── Atenção primária ──
  final String? ubsVinculadaId;
  final String? ubsVinculadaNome;

  /// Agente Comunitário de Saúde (ACS).
  final String? agenteComunitario;

  /// Microárea (subdivisão dentro da área da UBS — `"07"`, `"12A"`, etc).
  final String? microarea;

  /// Equipe Saúde da Família (eSF) — ex: `"ESF 03 · Equipe Verde"`.
  final String? equipeSaudeFamilia;

  /// True quando a senha atual ainda é a provisória (= CPF dígitos).
  /// Router força fluxo bloqueante em `/perfil/trocar-senha`.
  final bool senhaProvisoria;

  String get primeiroNome => (nomeSocial?.isNotEmpty == true ? nomeSocial! : nome)
      .split(' ')
      .first;

  String get nomeExibido =>
      nomeSocial?.isNotEmpty == true ? nomeSocial! : nome;

  String get iniciais {
    final partes = nomeExibido.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
    return (partes.first[0] + partes.last[0]).toUpperCase();
  }

  /// CPF para exibição. Prefere `cpfFormatado` do backend; senão formata
  /// localmente a partir dos dígitos.
  String get cpfDisplay {
    final cf = cpfFormatado;
    if (cf != null && cf.isNotEmpty) return cf;
    final d = cpf.replaceAll(RegExp(r'\D'), '');
    if (d.length != 11) return cpf;
    return '${d.substring(0, 3)}.${d.substring(3, 6)}.${d.substring(6, 9)}-${d.substring(9)}';
  }

  /// Idade calculada — 0 quando `dataNascimento` desconhecida.
  int get idade {
    final dn = dataNascimento;
    if (dn == null) return 0;
    final now = DateTime.now();
    var anos = now.year - dn.year;
    if (now.month < dn.month ||
        (now.month == dn.month && now.day < dn.day)) {
      anos--;
    }
    return anos;
  }

  /// Endereço em uma string ("Rua das Flores, 100 · Centro · Águas Belas/PE").
  String? get enderecoCompleto {
    final partes = <String>[];
    if (endereco != null && endereco!.isNotEmpty) partes.add(endereco!);
    if (bairro != null && bairro!.isNotEmpty) partes.add(bairro!);
    if (municipio != null && municipio!.isNotEmpty) {
      partes.add(uf != null && uf!.isNotEmpty
          ? '$municipio/$uf'
          : municipio!);
    }
    return partes.isEmpty ? null : partes.join(' · ');
  }

  factory Paciente.fromJson(Map<String, dynamic> j) => Paciente(
        id: j['id'] as String,
        nome: j['nome'] as String,
        nomeSocial: j['nomeSocial'] as String?,
        cpf: j['cpf'] as String,
        cpfFormatado: j['cpfFormatado'] as String?,
        dataNascimento: j['dataNascimento'] != null
            ? DateTime.tryParse(j['dataNascimento'] as String)
            : null,
        cartaoSus: j['cartaoSus'] as String?,
        sexo: j['sexo'] as String?,
        fotoUrl: j['fotoUrl'] as String?,

        nomeMae: j['nomeMae'] as String?,
        nomePai: j['nomePai'] as String?,

        estadoCivil: j['estadoCivil'] as String?,
        escolaridade: j['escolaridade'] as String?,
        profissao: j['profissao'] as String?,
        racaCor: j['racaCor'] as String?,
        grupoSanguineo: j['grupoSanguineo'] as String?,

        email: j['email'] as String?,
        telefone: j['telefone'] as String?,
        telefoneSecundario: j['telefoneSecundario'] as String?,

        endereco: j['endereco'] as String?,
        bairro: j['bairro'] as String?,
        municipio: j['municipio'] as String?,
        uf: j['uf'] as String?,
        cep: j['cep'] as String?,

        ubsVinculadaId: j['ubsVinculadaId'] as String?,
        ubsVinculadaNome: j['ubsVinculadaNome'] as String?,
        agenteComunitario: j['agenteComunitario'] as String?,
        microarea: j['microarea'] as String?,
        equipeSaudeFamilia: j['equipeSaudeFamilia'] as String?,

        senhaProvisoria: j['senhaProvisoria'] as bool? ?? false,
      );

  Paciente copyWith({bool? senhaProvisoria}) => Paciente(
        id: id,
        nome: nome,
        nomeSocial: nomeSocial,
        cpf: cpf,
        cpfFormatado: cpfFormatado,
        dataNascimento: dataNascimento,
        cartaoSus: cartaoSus,
        sexo: sexo,
        fotoUrl: fotoUrl,
        nomeMae: nomeMae,
        nomePai: nomePai,
        estadoCivil: estadoCivil,
        escolaridade: escolaridade,
        profissao: profissao,
        racaCor: racaCor,
        grupoSanguineo: grupoSanguineo,
        email: email,
        telefone: telefone,
        telefoneSecundario: telefoneSecundario,
        endereco: endereco,
        bairro: bairro,
        municipio: municipio,
        uf: uf,
        cep: cep,
        ubsVinculadaId: ubsVinculadaId,
        ubsVinculadaNome: ubsVinculadaNome,
        agenteComunitario: agenteComunitario,
        microarea: microarea,
        equipeSaudeFamilia: equipeSaudeFamilia,
        senhaProvisoria: senhaProvisoria ?? this.senhaProvisoria,
      );

  /// Labels pt-BR pra exibir enums.
  static String? labelSexo(String? s) {
    switch (s) {
      case 'M':
        return 'Masculino';
      case 'F':
        return 'Feminino';
      case 'OUTRO':
        return 'Outro';
      default:
        return null;
    }
  }

  static String? labelEstadoCivil(String? s) {
    switch (s) {
      case 'SOLTEIRO':
        return 'Solteiro(a)';
      case 'CASADO':
        return 'Casado(a)';
      case 'DIVORCIADO':
        return 'Divorciado(a)';
      case 'VIUVO':
        return 'Viúvo(a)';
      case 'UNIAO_ESTAVEL':
        return 'União estável';
      case 'OUTRO':
        return 'Outro';
      default:
        return null;
    }
  }

  static String? labelRacaCor(String? s) {
    switch (s) {
      case 'BRANCA':
        return 'Branca';
      case 'PRETA':
        return 'Preta';
      case 'PARDA':
        return 'Parda';
      case 'AMARELA':
        return 'Amarela';
      case 'INDIGENA':
        return 'Indígena';
      case 'NAO_INFORMADA':
        return null;
      default:
        return null;
    }
  }

  static String? labelGrupoSanguineo(String? s) {
    switch (s) {
      case 'A_POSITIVO':
        return 'A+';
      case 'A_NEGATIVO':
        return 'A−';
      case 'B_POSITIVO':
        return 'B+';
      case 'B_NEGATIVO':
        return 'B−';
      case 'AB_POSITIVO':
        return 'AB+';
      case 'AB_NEGATIVO':
        return 'AB−';
      case 'O_POSITIVO':
        return 'O+';
      case 'O_NEGATIVO':
        return 'O−';
      default:
        return null;
    }
  }
}
