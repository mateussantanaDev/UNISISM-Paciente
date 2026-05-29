/// Unidade Básica de Saúde — informações da UBS vinculada ao paciente.
class Ubs {
  const Ubs({
    required this.id,
    required this.nome,
    required this.endereco,
    required this.bairro,
    required this.cidade,
    required this.uf,
    required this.cep,
    required this.telefone,
    required this.horarioFuncionamento,
    required this.coordenadoresNomes,
    this.whatsapp,
    this.email,
    this.latitude,
    this.longitude,
    this.observacoes,
  });

  final String id;
  final String nome;
  final String endereco;
  final String bairro;
  final String cidade;
  final String uf;
  final String cep;
  final String telefone;
  final String? whatsapp;
  final String? email;
  final String horarioFuncionamento;
  final List<String> coordenadoresNomes;
  final double? latitude;
  final double? longitude;
  final String? observacoes;

  String get enderecoCompleto =>
      '$endereco, $bairro · $cidade/$uf · $cep';

  factory Ubs.fromJson(Map<String, dynamic> j) => Ubs(
        id: j['id'] as String,
        nome: j['nome'] as String,
        endereco: j['endereco'] as String,
        bairro: j['bairro'] as String,
        cidade: j['cidade'] as String,
        uf: j['uf'] as String,
        cep: j['cep'] as String,
        telefone: j['telefone'] as String,
        whatsapp: j['whatsapp'] as String?,
        email: j['email'] as String?,
        horarioFuncionamento: j['horarioFuncionamento'] as String,
        coordenadoresNomes:
            ((j['coordenadoresNomes'] as List?) ?? []).cast<String>(),
        latitude: (j['latitude'] as num?)?.toDouble(),
        longitude: (j['longitude'] as num?)?.toDouble(),
        observacoes: j['observacoes'] as String?,
      );
}
