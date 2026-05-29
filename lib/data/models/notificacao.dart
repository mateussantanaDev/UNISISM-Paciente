/// Notificação direta ao paciente.

class Notificacao {
  const Notificacao({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.corpo,
    required this.em,
    required this.lida,
    this.deepLink,
    this.encaminhamentoId,
    this.tfdSolicitacaoId,
    this.tone = 'INFO',
  });

  final String id;

  /// ENCAMINHAMENTO / TFD / CAMPANHA / ALERTA / SISTEMA
  final String tipo;
  final String titulo;
  final String corpo;
  final DateTime em;
  final bool lida;

  /// Rota interna pra abrir ao tocar (ex: `/encaminhamento/abc-123`).
  final String? deepLink;
  final String? encaminhamentoId;
  final String? tfdSolicitacaoId;

  /// INFO / WARNING / CRITICAL / SUCCESS
  final String tone;

  Notificacao copyWith({bool? lida}) => Notificacao(
        id: id,
        tipo: tipo,
        titulo: titulo,
        corpo: corpo,
        em: em,
        lida: lida ?? this.lida,
        deepLink: deepLink,
        encaminhamentoId: encaminhamentoId,
        tfdSolicitacaoId: tfdSolicitacaoId,
        tone: tone,
      );

  factory Notificacao.fromJson(Map<String, dynamic> j) => Notificacao(
        id: j['id'] as String,
        tipo: j['tipo'] as String,
        titulo: j['titulo'] as String,
        corpo: j['corpo'] as String,
        em: DateTime.parse(j['em'] as String),
        lida: (j['lida'] as bool?) ?? false,
        deepLink: j['deepLink'] as String?,
        encaminhamentoId: j['encaminhamentoId'] as String?,
        tfdSolicitacaoId: j['tfdSolicitacaoId'] as String?,
        tone: (j['tone'] as String?) ?? 'INFO',
      );
}
