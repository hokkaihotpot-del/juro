import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';

class AuthRepository {
  final _client = ApiClient.instance;

  Future<String> login(String email, String password) async {
    final response = await _client.dio.post(
      Endpoints.token,
      data: {'email': email, 'password': password},
    );
    final token = response.data['access_token'] as String;
    await _client.saveToken(token);
    return token;
  }

  Future<void> signup(String email, String password, String region) async {
    await _client.dio.post(
      Endpoints.signup,
      data: {'email': email, 'password': password, 'region': region},
    );
  }

  Future<void> logout() async {
    await _client.clearToken();
  }

  Future<bool> isLoggedIn() => _client.hasToken();
}
