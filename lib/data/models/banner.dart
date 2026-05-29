/// Banner publicado pela Secretaria de Saúde — campanhas, alertas, comunicados.
class SmsBannerModel {
  const SmsBannerModel({
    required this.id,
    required this.titulo,
    required this.corpo,
    required this.tone,
    required this.publicadoEm,
    this.imagemUrl,
    this.ctaLabel,
    this.ctaUrl,
    this.expiraEm,
    this.prioridadeOrdem = 0,
  });

  final String id;
  final String titulo;
  final String corpo;

  /// URGENTE / CAMPANHA / INFO / ATENCAO
  final String tone;
  final DateTime publicadoEm;
  final String? imagemUrl;
  final String? ctaLabel;
  final String? ctaUrl;
  final DateTime? expiraEm;
  final int prioridadeOrdem;

  bool get expirado =>
      expiraEm != null && DateTime.now().isAfter(expiraEm!);

  factory SmsBannerModel.fromJson(Map<String, dynamic> j) => SmsBannerModel(
        id: j['id'] as String,
        titulo: j['titulo'] as String,
        corpo: j['corpo'] as String,
        tone: j['tone'] as String,
        publicadoEm: DateTime.parse(j['publicadoEm'] as String),
        imagemUrl: j['imagemUrl'] as String?,
        ctaLabel: j['ctaLabel'] as String?,
        ctaUrl: j['ctaUrl'] as String?,
        expiraEm: j['expiraEm'] == null
            ? null
            : DateTime.parse(j['expiraEm'] as String),
        prioridadeOrdem: (j['prioridadeOrdem'] as num?)?.toInt() ?? 0,
      );
}
