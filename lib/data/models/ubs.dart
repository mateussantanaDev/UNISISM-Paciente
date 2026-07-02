/// Unidade Básica de Saúde — informações da UBS vinculada ao paciente.
///
/// Shape autoritativo (`GET /v1/paciente-app/ubs/minha`, v0.13+):
/// ```json
/// {
///   "id": "uuid",
///   "nome": "...",
///   "endereco": "..." | null,
///   "bairro": "..." | null,
///   "cidade": "...",
///   "uf": "PE",
///   "cep": "44001-000" | null,
///   "telefone": "75..." | null,
///   "whatsapp": "75..." | null,
///   "email": "..." | null,
///   "horarios": {
///     "segunda":  { "abre": "07:00", "fecha": "17:00" } | null,
///     "terca":    { "abre": "07:00", "fecha": "17:00" } | null,
///     ...
///   } | null,
///   "horarioFuncionamento": "Segunda a Sexta · 07:00 às 17:00",
///   "coordenadoresNomes": ["Dra. ..."],
///   "latitude": -12.26,
///   "longitude": -38.96,
///   "observacoes": "..." | null
/// }
/// ```
class Ubs {
  const Ubs({
    required this.id,
    required this.nome,
    required this.cidade,
    required this.uf,
    required this.horarioFuncionamento,
    required this.coordenadoresNomes,
    this.endereco,
    this.bairro,
    this.cep,
    this.telefone,
    this.whatsapp,
    this.email,
    this.horarios,
    this.latitude,
    this.longitude,
    this.observacoes,
  });

  final String id;
  final String nome;

  /// **Nullable** — backend pode não ter o endereço cadastrado ainda.
  final String? endereco;
  final String? bairro;
  final String cidade;
  final String uf;
  final String? cep;
  final String? telefone;
  final String? whatsapp;
  final String? email;

  /// Horários estruturados — chaves: `segunda`, `terca`, `quarta`, `quinta`,
  /// `sexta`, `sabado`, `domingo`. Valor `null` = fechado nesse dia.
  /// `null` na raiz = UBS ainda não cadastrou horários estruturados (use o
  /// `horarioFuncionamento` plain text).
  final Map<String, HorarioDia?>? horarios;

  /// Texto curto pré-formatado pra UI quando UBS não tem `horarios` estruturado.
  /// Sempre presente (backend gera "Consulte a UBS" como fallback).
  final String horarioFuncionamento;

  final List<String> coordenadoresNomes;
  final double? latitude;
  final double? longitude;
  final String? observacoes;

  String get enderecoCompleto {
    final partes = <String>[];
    if (endereco != null && endereco!.isNotEmpty) partes.add(endereco!);
    if (bairro != null && bairro!.isNotEmpty) partes.add(bairro!);
    partes.add('$cidade/$uf');
    if (cep != null && cep!.isNotEmpty) partes.add(cep!);
    return partes.join(' · ');
  }

  /// True se backend cadastrou `horarios` estruturado (renderizar tabela).
  bool get temHorariosEstruturados =>
      horarios != null && horarios!.isNotEmpty;

  factory Ubs.fromJson(Map<String, dynamic> j) {
    final horariosRaw = j['horarios'];
    Map<String, HorarioDia?>? horarios;
    if (horariosRaw is Map<String, dynamic>) {
      horarios = horariosRaw.map((dia, h) {
        if (h == null) return MapEntry(dia, null);
        if (h is Map<String, dynamic>) {
          return MapEntry(dia, HorarioDia.fromJson(h));
        }
        return MapEntry(dia, null);
      });
    }
    return Ubs(
      id: j['id'] as String,
      nome: j['nome'] as String,
      endereco: j['endereco'] as String?,
      bairro: j['bairro'] as String?,
      cidade: j['cidade'] as String,
      uf: j['uf'] as String,
      cep: j['cep'] as String?,
      telefone: j['telefone'] as String?,
      whatsapp: j['whatsapp'] as String?,
      email: j['email'] as String?,
      horarios: horarios,
      horarioFuncionamento:
          (j['horarioFuncionamento'] as String?) ?? 'Consulte a UBS',
      coordenadoresNomes:
          ((j['coordenadoresNomes'] as List?) ?? const []).cast<String>(),
      latitude: (j['latitude'] as num?)?.toDouble(),
      longitude: (j['longitude'] as num?)?.toDouble(),
      observacoes: j['observacoes'] as String?,
    );
  }
}

/// Horário de um dia da semana — `abre`/`fecha` em formato `HH:MM` (24h).
class HorarioDia {
  const HorarioDia({required this.abre, required this.fecha});

  final String abre;
  final String fecha;

  String get formatado => '$abre às $fecha';

  factory HorarioDia.fromJson(Map<String, dynamic> j) => HorarioDia(
        abre: j['abre'] as String,
        fecha: j['fecha'] as String,
      );
}
