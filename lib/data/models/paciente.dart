/// Modelo do paciente logado.
class Paciente {
  const Paciente({
    required this.id,
    required this.nome,
    required this.cpf,
    required this.dataNascimento,
    this.cartaoSus,
    this.email,
    this.telefone,
    this.fotoUrl,
    this.ubsVinculadaId,
    this.ubsVinculadaNome,
  });

  final String id;
  final String nome;
  final String cpf;
  final DateTime dataNascimento;
  final String? cartaoSus;
  final String? email;
  final String? telefone;
  final String? fotoUrl;
  final String? ubsVinculadaId;
  final String? ubsVinculadaNome;

  String get primeiroNome => nome.split(' ').first;

  String get iniciais {
    final partes = nome.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
    return (partes.first[0] + partes.last[0]).toUpperCase();
  }

  factory Paciente.fromJson(Map<String, dynamic> j) => Paciente(
        id: j['id'] as String,
        nome: j['nome'] as String,
        cpf: j['cpf'] as String,
        dataNascimento: DateTime.parse(j['dataNascimento'] as String),
        cartaoSus: j['cartaoSus'] as String?,
        email: j['email'] as String?,
        telefone: j['telefone'] as String?,
        fotoUrl: j['fotoUrl'] as String?,
        ubsVinculadaId: j['ubsVinculadaId'] as String?,
        ubsVinculadaNome: j['ubsVinculadaNome'] as String?,
      );
}
