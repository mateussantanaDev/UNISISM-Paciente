import '../api/api_client.dart';
import '../models/ubs.dart';

/// UBS. Contrato:
///
/// GET /paciente/ubs/minha → Ubs
abstract class UbsRepository {
  Future<Ubs> minha();
}

class UbsRepositoryHttp implements UbsRepository {
  UbsRepositoryHttp(this.api);
  final ApiClient api;

  @override
  Future<Ubs> minha() async {
    final r = await api.get<Map<String, dynamic>>('/paciente-app/ubs/minha');
    return Ubs.fromJson(r);
  }
}

