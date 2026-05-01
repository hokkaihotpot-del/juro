import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/models/daily_menu.dart';

class MenuRepository {
  final _client = ApiClient.instance;

  Future<DailyMenuProposal> proposeMenu() async {
    final response = await _client.dio.get(Endpoints.menuPropose);
    return DailyMenuProposal.fromJson(
        response.data as Map<String, dynamic>);
  }
}
