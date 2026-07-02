import '../api/api_client.dart';
import '../models/banner.dart';

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
    final r = await api.get<List>('/paciente-app/banners');
    return r.cast<Map<String, dynamic>>().map(SmsBannerModel.fromJson).toList();
  }

  @override
  Future<void> marcarVisto(String id) async {
    await api.post('/paciente-app/banners/$id/visto');
  }
}

