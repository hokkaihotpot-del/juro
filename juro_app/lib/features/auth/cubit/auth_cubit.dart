import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../repository/auth_repository.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repo) : super(const AuthInitial());

  final AuthRepository _repo;

  Future<void> checkAuth() async {
    final loggedIn = await _repo.isLoggedIn();
    emit(loggedIn ? const AuthAuthenticated() : const AuthUnauthenticated());
  }

  Future<void> login(String email, String password) async {
    emit(const AuthLoading());
    try {
      await _repo.login(email, password);
      emit(const AuthAuthenticated());
    } catch (e) {
      emit(AuthError(_friendlyError(e)));
    }
  }

  Future<void> signup(String email, String password, String region) async {
    emit(const AuthLoading());
    try {
      await _repo.signup(email, password, region);
      await _repo.login(email, password);
      emit(const AuthAuthenticated());
    } catch (e) {
      emit(AuthError(_friendlyError(e)));
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    emit(const AuthUnauthenticated());
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('401')) return 'メールアドレスまたはパスワードが正しくありません';
    if (msg.contains('400')) return 'すでに登録済みのメールアドレスです';
    if (msg.contains('SocketException') ||
        msg.contains('Connection refused')) {
      return 'サーバーに接続できません。ネットワークを確認してください';
    }
    return 'エラーが発生しました。しばらく後にお試しください';
  }
}
