import '../api/api_client.dart';
import '../models/banner.dart';
import 'mock/mock_seed.dart';

/// Banners da SMS. Contrato:
///
/// GET  /paciente/banners            → SmsBannerModel[]  (não expirados, ordenados)
/// POST /paciente/banners/:id/visto                       → 204
abstract class BannerRepository {
  Future<List<SmsBannerModel>> ativos();
  Future<void> marcarVisto(String id);
}

class BannerRepositoryHttp implements BannerRepository {
  BannerRepositoryHttp(this.api);
  final ApiClient api;

  @override
  Future<List<SmsBannerModel>> ativos() async {
    final r = await api.get<List>('/paciente/banners');
    return r.cast<Map<String, dynamic>>().map(SmsBannerModel.fromJson).toList();
  }

  @override
  Future<void> marcarVisto(String id) async {
    await api.post('/paciente/banners/$id/visto');
  }
}

class BannerRepositoryMock implements BannerRepository {
  @override
  Future<List<SmsBannerModel>> ativos() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return MockSeed.banners;
  }

  @override
  Future<void> marcarVisto(String id) async {}
}
