import '../api/api_client.dart';
import '../models/ubs.dart';
import 'mock/mock_seed.dart';

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
    final r = await api.get<Map<String, dynamic>>('/paciente/ubs/minha');
    return Ubs.fromJson(r);
  }
}

class UbsRepositoryMock implements UbsRepository {
  @override
  Future<Ubs> minha() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return MockSeed.ubs;
  }
}
