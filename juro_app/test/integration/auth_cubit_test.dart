import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:juro_app/features/auth/cubit/auth_cubit.dart';
import 'package:juro_app/features/auth/repository/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('AuthCubit 統合テスト', () {
    late MockAuthRepository repo;

    setUp(() {
      repo = MockAuthRepository();
    });

    // ─── login ───────────────────────────────────────────────────

    blocTest<AuthCubit, AuthState>(
      'login 正常系: AuthLoading → AuthAuthenticated を emit する',
      build: () {
        when(() => repo.login(any(), any())).thenAnswer((_) async => 'token');
        return AuthCubit(repo);
      },
      act: (cubit) => cubit.login('user@example.com', 'Pass1234!'),
      expect: () => [
        const AuthLoading(),
        const AuthAuthenticated(),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'login 異常系（401）: AuthLoading → AuthError を emit し日本語メッセージ含む',
      build: () {
        when(() => repo.login(any(), any()))
            .thenThrow(Exception('401 Unauthorized'));
        return AuthCubit(repo);
      },
      act: (cubit) => cubit.login('user@example.com', 'wrongpass'),
      expect: () => [
        const AuthLoading(),
        isA<AuthError>(),
      ],
      verify: (cubit) {
        final state = cubit.state;
        expect(state, isA<AuthError>());
        expect((state as AuthError).message, contains('パスワード'));
      },
    );

    blocTest<AuthCubit, AuthState>(
      'login ネットワークエラー: AuthError にサーバー接続メッセージ',
      build: () {
        when(() => repo.login(any(), any()))
            .thenThrow(Exception('Connection refused'));
        return AuthCubit(repo);
      },
      act: (cubit) => cubit.login('user@example.com', 'Pass1234!'),
      expect: () => [
        const AuthLoading(),
        isA<AuthError>(),
      ],
      verify: (cubit) {
        final state = cubit.state;
        expect((state as AuthError).message, contains('サーバーに接続できません'));
      },
    );

    // ─── signup ──────────────────────────────────────────────────

    blocTest<AuthCubit, AuthState>(
      'signup 正常系: AuthLoading → AuthAuthenticated を emit する',
      build: () {
        when(() => repo.signup(any(), any(), any())).thenAnswer((_) async {});
        when(() => repo.login(any(), any())).thenAnswer((_) async => 'token');
        return AuthCubit(repo);
      },
      act: (cubit) =>
          cubit.signup('new@example.com', 'Pass1234!', 'jp'),
      expect: () => [
        const AuthLoading(),
        const AuthAuthenticated(),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'signup 異常系（400 メール重複）: AuthError にメッセージ',
      build: () {
        when(() => repo.signup(any(), any(), any()))
            .thenThrow(Exception('400 Email already registered'));
        return AuthCubit(repo);
      },
      act: (cubit) =>
          cubit.signup('dup@example.com', 'Pass1234!', 'jp'),
      expect: () => [
        const AuthLoading(),
        isA<AuthError>(),
      ],
      verify: (cubit) {
        expect((cubit.state as AuthError).message, contains('登録済み'));
      },
    );

    // ─── logout ──────────────────────────────────────────────────

    blocTest<AuthCubit, AuthState>(
      'logout: AuthUnauthenticated を emit する',
      build: () {
        when(() => repo.logout()).thenAnswer((_) async {});
        return AuthCubit(repo);
      },
      act: (cubit) => cubit.logout(),
      expect: () => [const AuthUnauthenticated()],
    );

    // ─── checkAuth ───────────────────────────────────────────────

    blocTest<AuthCubit, AuthState>(
      'checkAuth トークンあり: AuthAuthenticated を emit する',
      build: () {
        when(() => repo.isLoggedIn()).thenAnswer((_) async => true);
        return AuthCubit(repo);
      },
      act: (cubit) => cubit.checkAuth(),
      expect: () => [const AuthAuthenticated()],
    );

    blocTest<AuthCubit, AuthState>(
      'checkAuth トークンなし: AuthUnauthenticated を emit する',
      build: () {
        when(() => repo.isLoggedIn()).thenAnswer((_) async => false);
        return AuthCubit(repo);
      },
      act: (cubit) => cubit.checkAuth(),
      expect: () => [const AuthUnauthenticated()],
    );
  });
}
