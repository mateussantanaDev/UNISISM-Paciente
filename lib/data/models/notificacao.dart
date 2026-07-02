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

  /// Aceita **dois shapes**:
  ///
  /// **Backend** (`GET /v1/paciente-app/notificacoes`):
  /// ```json
  /// {
  ///   "id": "...",
  ///   "tipo": "APROVADO",
  ///   "titulo": "...",
  ///   "corpo": "...",
  ///   "encaminhamentoId": "...",
  ///   "criadaEm": "...",
  ///   "lidaEm": null
  /// }
  /// ```
  ///
  /// **Shape interno** (mock): `{em, lida: bool, deepLink, tone}`.
  ///
  /// Adaptações:
  /// - `criadaEm` → `em`
  /// - `lidaEm != null` → `lida: bool`
  /// - `tipo` backend (ex `APROVADO`, `PENDENCIA_REGISTRADA`) → categoria reduzida do app
  /// - `tone` derivado do `tipo` se backend não enviar explícito
  /// - `deepLink` derivado de `encaminhamentoId` quando ausente
  factory Notificacao.fromJson(Map<String, dynamic> j) {
    final tipoRaw = (j['tipo'] as String?) ?? 'SISTEMA';
    final encId = j['encaminhamentoId'] as String?;
    final emRaw = (j['em'] ?? j['criadaEm']) as String?;
    final lidaExplicit = j['lida'] as bool?;
    final lidaEm = j['lidaEm'] as String?;
    return Notificacao(
      id: j['id'] as String,
      tipo: _mapTipoCategoria(tipoRaw),
      titulo: j['titulo'] as String,
      corpo: j['corpo'] as String,
      em: emRaw != null ? DateTime.parse(emRaw) : DateTime.now(),
      lida: lidaExplicit ?? (lidaEm != null),
      deepLink: (j['deepLink'] as String?) ??
          (encId != null ? '/encaminhamento/$encId' : null),
      encaminhamentoId: encId,
      tfdSolicitacaoId: j['tfdSolicitacaoId'] as String?,
      tone: (j['tone'] as String?) ?? _toneFromTipo(tipoRaw),
    );
  }

  /// Mapeia tipos ricos do backend (`APROVADO`, `PENDENCIA_REGISTRADA`, etc.)
  /// para categoria visual do app (`ENCAMINHAMENTO`, `TFD`, `CAMPANHA`, `ALERTA`, `SISTEMA`).
  static String _mapTipoCategoria(String backend) {
    if (backend.startsWith('ENCAMINHAMENTO_') ||
        backend == 'APROVADO' ||
        backend == 'REJEITADO' ||
        backend == 'AGENDADO' ||
        backend == 'PENDENCIA_REGISTRADA' ||
        backend == 'PENDENCIA_RESOLVIDA' ||
        backend == 'RESPOSTA_SUS_DISPONIVEL') {
      return 'ENCAMINHAMENTO';
    }
    if (backend.startsWith('TFD')) return 'TFD';
    if (backend == 'CAMPANHA' || backend == 'BANNER') return 'CAMPANHA';
    if (backend == 'ALERTA') return 'ALERTA';
    return 'SISTEMA';
  }

  static String _toneFromTipo(String backend) {
    switch (backend) {
      case 'APROVADO':
      case 'PENDENCIA_RESOLVIDA':
      case 'RESPOSTA_SUS_DISPONIVEL':
      case 'AGENDADO':
        return 'SUCCESS';
      case 'PENDENCIA_REGISTRADA':
        return 'WARNING';
      case 'REJEITADO':
        return 'CRITICAL';
      default:
        return 'INFO';
    }
  }
}
