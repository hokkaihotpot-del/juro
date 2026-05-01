import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/models/daily_menu.dart';
import '../repository/menu_repository.dart';

part 'menu_state.dart';

class MenuCubit extends Cubit<MenuState> {
  MenuCubit(this._repo) : super(const MenuInitial());

  final MenuRepository _repo;

  Future<void> proposeMenu() async {
    emit(const MenuLoading());
    try {
      final proposal = await _repo.proposeMenu();
      emit(MenuLoaded(proposal));
    } catch (e) {
      emit(MenuError(_friendlyError(e)));
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('401')) return '再度ログインしてください';
    if (msg.contains('SocketException') ||
        msg.contains('Connection refused')) {
      return 'サーバーに接続できません';
    }
    return '献立の取得に失敗しました。しばらく後にお試しください';
  }
}
