import '../../models/banner.dart';
import '../../models/dossie.dart';
import '../../models/encaminhamento.dart';
import '../../models/notificacao.dart';
import '../../models/paciente.dart';
import '../../models/tfd.dart';
import '../../models/ubs.dart';

/// Dados demo pra rodar o app sem backend. Tom realista pro município.
class MockSeed {
  MockSeed._();

  static final DateTime _agora = DateTime.now();
  static DateTime _h(int hoursAgo) => _agora.subtract(Duration(hours: hoursAgo));
  static DateTime _d(int daysAgo) => _agora.subtract(Duration(days: daysAgo));
  static DateTime _df(int daysAhead) => _agora.add(Duration(days: daysAhead));

  static const Ubs ubs = Ubs(
    id: 'ubs-031',
    nome: 'UBS Centro - Dr. João Mendes',
    endereco: 'Rua Sete de Setembro, 145',
    bairro: 'Centro',
    cidade: 'São José',
    uf: 'PE',
    cep: '44900-000',
    telefone: '(75) 3641-2200',
    whatsapp: '5575998765432',
    email: 'ubs.centro@saude.muni.gov.br',
    horarioFuncionamento: 'Segunda a Sexta · 07h às 17h',
    coordenadoresNomes: [
      'Dra. Helena Pereira (Coordenadora Médica)',
      'Bianca Lopes (Coordenadora Administrativa)',
    ],
    latitude: -12.026,
    longitude: -38.522,
    observacoes:
        'Vacinação de rotina sem agendamento. Curativos das 08h às 11h. Coleta de sangue às terças e quintas, em jejum, das 07h às 09h.',
  );

  static final Paciente paciente = Paciente(
    id: 'pac-001',
    nome: 'Maria Aparecida Souza',
    cpf: '123.456.789-09',
    dataNascimento: DateTime(1962, 8, 14),
    cartaoSus: '700 1234 5678 9012',
    telefone: '(75) 99876-5432',
    ubsVinculadaId: 'ubs-031',
    ubsVinculadaNome: 'UBS Centro - Dr. João Mendes',
  );

  static final List<Encaminhamento> encaminhamentos = [
    Encaminhamento(
      id: 'enc-100137',
      protocolo: 'UBS-2026-100137',
      status: 'AGENDADO',
      prioridade: 'PRIORITARIA',
      especialidade: 'Cardiologia',
      cid10: 'I10',
      cid10Descricao: 'Hipertensão essencial',
      justificativaResumida:
          'Paciente apresenta hipertensão de difícil controle, em uso de duas classes de anti-hipertensivos.',
      ubsOrigemNome: 'UBS Centro - Dr. João Mendes',
      medicoSolicitanteNome: 'Dr. Ricardo Lima — CRM/BA 12345',
      criadoEm: _d(8),
      atualizadoEm: _h(6),
      pendenciasAbertas: 0,
      podeSolicitarTfd: true,
      dataAgendamento: _df(12).copyWith(hour: 9, minute: 30),
      localAgendamento: 'Hospital Regional de Águas Belas - Ambulatório 3',
    ),
    Encaminhamento(
      id: 'enc-100142',
      protocolo: 'UBS-2026-100142',
      status: 'AGUARDANDO_REGULACAO',
      prioridade: 'ELETIVA',
      especialidade: 'Endocrinologia',
      cid10: 'E11',
      cid10Descricao: 'Diabetes mellitus tipo 2',
      justificativaResumida:
          'Diabetes descompensado, glicemia em jejum acima de 200 nos últimos 3 exames.',
      ubsOrigemNome: 'UBS Centro - Dr. João Mendes',
      medicoSolicitanteNome: 'Dr. Ricardo Lima — CRM/BA 12345',
      criadoEm: _d(2),
      atualizadoEm: _h(20),
      pendenciasAbertas: 0,
      podeSolicitarTfd: false,
    ),
    Encaminhamento(
      id: 'enc-100151',
      protocolo: 'UBS-2026-100151',
      status: 'PENDENCIA_DOCUMENTO',
      prioridade: 'ELETIVA',
      especialidade: 'Ortopedia',
      cid10: 'M54.5',
      cid10Descricao: 'Lombalgia',
      justificativaResumida:
          'Dor lombar crônica sem melhora com tratamento conservador.',
      ubsOrigemNome: 'UBS Centro - Dr. João Mendes',
      medicoSolicitanteNome: 'Dra. Helena Pereira — CRM/BA 23456',
      criadoEm: _d(5),
      atualizadoEm: _h(48),
      pendenciasAbertas: 1,
      podeSolicitarTfd: false,
      observacoesRegulacao:
          'Anexar raio-X de coluna lombar e laudo do fisioterapeuta.',
    ),
    Encaminhamento(
      id: 'enc-099221',
      protocolo: 'UBS-2026-099221',
      status: 'CONCLUIDO',
      prioridade: 'ELETIVA',
      especialidade: 'Oftalmologia',
      ubsOrigemNome: 'UBS Centro - Dr. João Mendes',
      medicoSolicitanteNome: 'Dra. Helena Pereira — CRM/BA 23456',
      criadoEm: _d(180),
      atualizadoEm: _d(90),
    ),
  ];

  static final List<Anexo> anexos = [
    Anexo(
      id: 'anx-1',
      nome: 'Solicitacao_Medica_Cardiologia.pdf',
      tipo: 'application/pdf',
      tamanhoBytes: 248_310,
      criadoEm: _d(8),
      url: 'https://example.com/anx-1.pdf',
    ),
    Anexo(
      id: 'anx-2',
      nome: 'Eletrocardiograma_recente.pdf',
      tipo: 'application/pdf',
      tamanhoBytes: 1_540_200,
      criadoEm: _d(7),
      url: 'https://example.com/anx-2.pdf',
    ),
    Anexo(
      id: 'anx-3',
      nome: 'Cartao_SUS.jpg',
      tipo: 'image/jpeg',
      tamanhoBytes: 412_000,
      criadoEm: _d(8),
      url: 'https://example.com/anx-3.jpg',
    ),
  ];

  static final List<EventoTimeline> timeline = [
    EventoTimeline(
      id: 'ev-1',
      tipo: 'CRIACAO',
      titulo: 'Encaminhamento criado pela sua UBS',
      descricao:
          'Sua UBS Centro registrou seu encaminhamento para Cardiologia e enviou à Regulação Municipal.',
      autorNome: 'Bianca Lopes',
      autorPapel: 'Atendente UBS',
      em: _d(8),
    ),
    EventoTimeline(
      id: 'ev-2',
      tipo: 'ANEXO',
      titulo: 'Eletrocardiograma anexado',
      autorNome: 'Bianca Lopes',
      autorPapel: 'Atendente UBS',
      em: _d(7),
    ),
    EventoTimeline(
      id: 'ev-3',
      tipo: 'ATUALIZACAO',
      titulo: 'Em análise pela Regulação',
      descricao: 'Sua solicitação está sendo analisada pelos médicos reguladores.',
      autorNome: 'Sistema',
      autorPapel: 'UNISISM',
      em: _d(5),
    ),
    EventoTimeline(
      id: 'ev-4',
      tipo: 'APROVACAO',
      titulo: 'Solicitação aprovada',
      descricao:
          'A regulação aprovou seu encaminhamento. Estamos buscando a melhor data para a consulta.',
      autorNome: 'Dr. André Carvalho',
      autorPapel: 'Médico Regulador SMS',
      em: _h(36),
    ),
    EventoTimeline(
      id: 'ev-5',
      tipo: 'AGENDAMENTO',
      titulo: 'Consulta marcada!',
      descricao:
          'Sua consulta foi marcada no Hospital Regional. Confira os detalhes acima e leve um documento com foto.',
      autorNome: 'Daniel Rocha',
      autorPapel: 'Agendamento SMS',
      em: _h(6),
    ),
  ];

  // --- Dossiê ---

  static const DossieResumo dossieResumo = DossieResumo(
    totalEncaminhamentos: 4,
    totalAtendimentos: 21,
    totalVacinas: 14,
    tipoSanguineo: 'O+',
    alergias: ['Dipirona', 'Iodo (contraste)'],
    condicoesCronicas: ['Hipertensão arterial', 'Diabetes tipo 2'],
    medicamentosUsoContinuo: ['Losartana 50mg', 'Metformina 850mg', 'AAS 100mg'],
  );

  static final List<Atendimento> atendimentos = [
    Atendimento(
      id: 'at-1',
      data: _d(20),
      tipo: 'CONSULTA',
      localNome: 'UBS Centro',
      profissionalNome: 'Dr. Ricardo Lima',
      profissionalEspecialidade: 'Clínica Geral',
      queixaPrincipal: 'Pressão alta com dor de cabeça frequente',
      cid10: 'I10',
      cid10Descricao: 'Hipertensão essencial',
      condutaResumida:
          'Encaminhar à Cardiologia. Ajustar dose de Losartana. Retornar em 30 dias.',
    ),
    Atendimento(
      id: 'at-2',
      data: _d(58),
      tipo: 'EXAME',
      localNome: 'Laboratório Municipal',
      profissionalNome: 'Equipe de coleta',
      profissionalEspecialidade: 'Análises clínicas',
      condutaResumida: 'Coleta de hemograma, glicemia e perfil lipídico.',
    ),
    Atendimento(
      id: 'at-3',
      data: _d(120),
      tipo: 'CONSULTA',
      localNome: 'UBS Centro',
      profissionalNome: 'Dra. Helena Pereira',
      profissionalEspecialidade: 'Clínica Geral',
      queixaPrincipal: 'Renovação de receita',
    ),
  ];

  static final List<Vacinacao> vacinacoes = [
    Vacinacao(
      id: 'vc-1',
      vacina: 'Influenza 2026',
      dose: 'Dose anual',
      aplicadaEm: _d(45),
      lote: 'INF-2026-A',
      localAplicacao: 'UBS Centro',
    ),
    Vacinacao(
      id: 'vc-2',
      vacina: 'COVID-19 Bivalente',
      dose: 'Reforço',
      aplicadaEm: _d(200),
      lote: 'COV-BV-09',
      localAplicacao: 'UBS Centro',
    ),
    Vacinacao(
      id: 'vc-3',
      vacina: 'Tétano',
      dose: 'Reforço',
      aplicadaEm: _d(1100),
      lote: 'TET-2023-02',
      localAplicacao: 'UBS Centro',
    ),
  ];

  static final List<Exame> exames = [
    Exame(
      id: 'ex-1',
      nome: 'Hemograma completo',
      realizadoEm: _d(60),
      solicitanteNome: 'Dr. Ricardo Lima',
      resultadoResumo: 'Dentro dos valores de referência.',
      alterado: false,
    ),
    Exame(
      id: 'ex-2',
      nome: 'Glicemia em jejum',
      realizadoEm: _d(60),
      solicitanteNome: 'Dr. Ricardo Lima',
      resultadoResumo: 'Glicemia 142 mg/dL — discretamente acima.',
      alterado: true,
    ),
    Exame(
      id: 'ex-3',
      nome: 'Eletrocardiograma',
      realizadoEm: _d(7),
      solicitanteNome: 'Dr. Ricardo Lima',
      resultadoResumo: 'Ritmo sinusal, sem alterações isquêmicas agudas.',
      alterado: false,
    ),
  ];

  // --- TFD ---

  static final List<TfdViagem> tfdViagens = [
    TfdViagem(
      id: 'vg-1',
      destinoCidade: 'Águas Belas',
      destinoUf: 'PE',
      destinoLocal: 'Hospital Regional - Ambulatório Cardiologia',
      dataPartida: _df(12),
      horaPartida: '05:30',
      localEmbarque: 'Praça Central - UBS Centro',
      vagasTotal: 14,
      vagasOcupadas: 9,
      veiculoDescricao: 'Van Iveco Daily - Branca',
      veiculoPlaca: 'OUW-3A12',
      motoristaNome: 'José Carlos Andrade',
      observacoes: 'Levar documento com foto, cartão SUS e a receita atual.',
    ),
    TfdViagem(
      id: 'vg-2',
      destinoCidade: 'Salvador',
      destinoUf: 'PE',
      destinoLocal: 'Hospital Santa Izabel - Oncologia',
      dataPartida: _df(5),
      horaPartida: '04:00',
      localEmbarque: 'Rodoviária Municipal',
      vagasTotal: 18,
      vagasOcupadas: 17,
      veiculoDescricao: 'Micro-ônibus - Azul',
      veiculoPlaca: 'PJN-7K88',
      motoristaNome: 'Antonio Ferreira',
    ),
    TfdViagem(
      id: 'vg-3',
      destinoCidade: 'Águas Belas',
      destinoUf: 'PE',
      destinoLocal: 'Hospital Inácia Pinto - Pequena cirurgia',
      dataPartida: _df(20),
      horaPartida: '06:00',
      localEmbarque: 'Praça Central - UBS Centro',
      vagasTotal: 14,
      vagasOcupadas: 3,
      veiculoDescricao: 'Van Iveco Daily - Branca',
      veiculoPlaca: 'OUW-3A12',
    ),
  ];

  static final List<TfdSolicitacao> tfdSolicitacoes = [
    TfdSolicitacao(
      id: 'sol-1',
      viagemId: 'vg-2',
      status: 'APROVADA',
      criadaEm: _d(3),
      viagem: tfdViagens[1],
      prioridade: 'PRIORITARIA',
      numeroAssento: '07',
      justificativaPaciente: 'Consulta de retorno na oncologia, viagem essencial.',
      aprovadaEm: _h(20),
      encaminhamentoProtocolo: 'UBS-2026-099833',
    ),
  ];

  // --- Banners ---

  static final List<SmsBannerModel> banners = [
    SmsBannerModel(
      id: 'bn-1',
      titulo: 'Campanha de Vacinação contra a Gripe',
      corpo:
          'Está aberta a campanha 2026 da vacinação contra Influenza. Procure sua UBS de segunda a sexta, das 8h às 16h. Idosos têm prioridade.',
      tone: 'CAMPANHA',
      publicadoEm: _d(2),
      ctaLabel: 'Saber mais',
      ctaUrl: 'https://saude.muni.gov.br/campanha-gripe-2026',
      prioridadeOrdem: 10,
    ),
    SmsBannerModel(
      id: 'bn-2',
      titulo: 'Alerta: surto de dengue na região',
      corpo:
          'Foi registrado aumento de casos de dengue no bairro Centro. Elimine recipientes com água parada e procure a UBS em caso de febre alta com dor no corpo.',
      tone: 'URGENTE',
      publicadoEm: _h(15),
      prioridadeOrdem: 100,
    ),
    SmsBannerModel(
      id: 'bn-3',
      titulo: 'Mutirão de exames cardiológicos',
      corpo:
          'Pacientes hipertensos podem agendar eletrocardiograma sem espera no próximo sábado, das 7h às 12h, na UBS Centro.',
      tone: 'INFO',
      publicadoEm: _d(4),
      prioridadeOrdem: 5,
    ),
  ];

  // --- Notificações ---

  static final List<Notificacao> notificacoes = [
    Notificacao(
      id: 'nt-1',
      tipo: 'ENCAMINHAMENTO',
      titulo: 'Sua consulta foi marcada!',
      corpo:
          'Cardiologia no Hospital Regional de Águas Belas. Toque aqui para ver detalhes.',
      em: _h(6),
      lida: false,
      tone: 'SUCCESS',
      deepLink: '/encaminhamento/enc-100137',
      encaminhamentoId: 'enc-100137',
    ),
    Notificacao(
      id: 'nt-2',
      tipo: 'TFD',
      titulo: 'Vaga no TFD confirmada',
      corpo: 'Sua vaga na viagem para Salvador foi aprovada. Assento 07.',
      em: _h(20),
      lida: false,
      tone: 'SUCCESS',
      deepLink: '/tfd/solicitacao/sol-1',
      tfdSolicitacaoId: 'sol-1',
    ),
    Notificacao(
      id: 'nt-3',
      tipo: 'ENCAMINHAMENTO',
      titulo: 'Solicitação aprovada pela Regulação',
      corpo: 'Seu encaminhamento UBS-2026-100137 foi aprovado.',
      em: _h(36),
      lida: true,
      tone: 'INFO',
      deepLink: '/encaminhamento/enc-100137',
      encaminhamentoId: 'enc-100137',
    ),
    Notificacao(
      id: 'nt-4',
      tipo: 'CAMPANHA',
      titulo: 'Vacinação contra a gripe começou',
      corpo: 'Idosos e grupos prioritários podem procurar sua UBS.',
      em: _d(2),
      lida: true,
      tone: 'INFO',
    ),
  ];
}
