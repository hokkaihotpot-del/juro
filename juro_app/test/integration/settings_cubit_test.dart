import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:juro_app/features/settings/cubit/settings_cubit.dart';
import 'package:juro_app/features/settings/repository/settings_repository.dart';
import 'package:juro_app/core/models/settings.dart';
import 'package:juro_app/core/models/allergy_item.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

// ─── テスト用ファクトリ ─────────────────────────────────────────────────────

AppSettings _fakeSettings({
  String region = 'jp',
  bool correctionEnabled = true,
}) =>
    AppSettings(
      region: region,
      preprocessingCorrectionEnabled: correctionEnabled,
      nutritionLimits: const NutritionLimit(
        phosphorusLimitMg: 800,
        potassiumLimitMg: 2000,
        sodiumLimitG: 6.0,
      ),
    );

AllergyListResponse _fakeAllergies([List<AllergyItem>? items]) =>
    AllergyListResponse(
      items: items ?? [],
      total: items?.length ?? 0,
    );

DoctorInfo _fakeDoctor() => const DoctorInfo(
      id: 'doc-001',
      doctorName: '山田太郎',
      email: 'yamada@hospital.jp',
    );

void main() {
  group('SettingsCubit 統合テスト', () {
    late MockSettingsRepository repo;

    setUp(() {
      repo = MockSettingsRepository();
    });

    // ─── loadSettings ────────────────────────────────────────────

    blocTest<SettingsCubit, SettingsState>(
      'loadSettings 正常系: SettingsLoading → SettingsLoaded を emit する',
      build: () {
        when(() => repo.getSettings())
            .thenAnswer((_) async => _fakeSettings());
        when(() => repo.getAllergies())
            .thenAnswer((_) async => _fakeAllergies());
        when(() => repo.getDoctors()).thenAnswer((_) async => []);
        return SettingsCubit(repo);
      },
      act: (cubit) => cubit.loadSettings(),
      expect: () => [
        const SettingsLoading(),
        isA<SettingsLoaded>(),
      ],
      verify: (cubit) {
        final state = cubit.state as SettingsLoaded;
        expect(state.settings.region, equals('jp'));
        expect(state.settings.preprocessingCorrectionEnabled, isTrue);
        expect(state.allergies, isEmpty);
        expect(state.doctors, isEmpty);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'loadSettings エラー: SettingsError を emit する',
      build: () {
        when(() => repo.getSettings())
            .thenThrow(Exception('Network error'));
        return SettingsCubit(repo);
      },
      act: (cubit) => cubit.loadSettings(),
      expect: () => [
        const SettingsLoading(),
        isA<SettingsError>(),
      ],
    );

    // ─── togglePreprocessing ─────────────────────────────────────

    blocTest<SettingsCubit, SettingsState>(
      'togglePreprocessing false: 補正フラグが false の SettingsLoaded を emit',
      build: () {
        when(() => repo.getSettings())
            .thenAnswer((_) async => _fakeSettings());
        when(() => repo.getAllergies())
            .thenAnswer((_) async => _fakeAllergies());
        when(() => repo.getDoctors()).thenAnswer((_) async => []);
        when(() => repo.updateSettings(preprocessingEnabled: false))
            .thenAnswer(
                (_) async => _fakeSettings(correctionEnabled: false));
        return SettingsCubit(repo);
      },
      seed: () => SettingsLoaded(
        settings: _fakeSettings(),
        allergies: const [],
        doctors: const [],
      ),
      act: (cubit) => cubit.togglePreprocessing(false),
      expect: () => [isA<SettingsLoaded>()],
      verify: (cubit) {
        final state = cubit.state as SettingsLoaded;
        expect(state.settings.preprocessingCorrectionEnabled, isFalse);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'togglePreprocessing: SettingsLoaded でない場合は何も emit しない',
      build: () => SettingsCubit(repo),
      // 初期状態 SettingsInitial のまま
      act: (cubit) => cubit.togglePreprocessing(false),
      expect: () => [],
    );

    // ─── changeRegion ─────────────────────────────────────────────

    blocTest<SettingsCubit, SettingsState>(
      'changeRegion: region が更新された SettingsLoaded を emit する',
      build: () {
        when(() => repo.updateSettings(region: 'us'))
            .thenAnswer((_) async => _fakeSettings(region: 'us'));
        return SettingsCubit(repo);
      },
      seed: () => SettingsLoaded(
        settings: _fakeSettings(),
        allergies: const [],
        doctors: const [],
      ),
      act: (cubit) => cubit.changeRegion('us'),
      expect: () => [isA<SettingsLoaded>()],
      verify: (cubit) {
        expect((cubit.state as SettingsLoaded).settings.region, equals('us'));
      },
    );

    // ─── addDoctor ───────────────────────────────────────────────

    blocTest<SettingsCubit, SettingsState>(
      'addDoctor 正常系: loadSettings が呼び出され doctors リストが更新される',
      build: () {
        when(() => repo.addDoctor(any(), any(), any()))
            .thenAnswer((_) async => _fakeDoctor());
        when(() => repo.getSettings())
            .thenAnswer((_) async => _fakeSettings());
        when(() => repo.getAllergies())
            .thenAnswer((_) async => _fakeAllergies());
        when(() => repo.getDoctors())
            .thenAnswer((_) async => [_fakeDoctor()]);
        return SettingsCubit(repo);
      },
      seed: () => SettingsLoaded(
        settings: _fakeSettings(),
        allergies: const [],
        doctors: const [],
      ),
      act: (cubit) =>
          cubit.addDoctor('山田太郎', 'yamada@hospital.jp', null),
      expect: () => [
        const SettingsLoading(),
        isA<SettingsLoaded>(),
      ],
      verify: (cubit) {
        final state = cubit.state as SettingsLoaded;
        expect(state.doctors.length, equals(1));
        expect(state.doctors.first.doctorName, equals('山田太郎'));
      },
    );

    // ─── deleteAllergy ───────────────────────────────────────────

    blocTest<SettingsCubit, SettingsState>(
      'deleteAllergy 正常系: loadSettings 後にアレルギーリストが空になる',
      build: () {
        when(() => repo.deleteAllergy(any())).thenAnswer((_) async {});
        when(() => repo.getSettings())
            .thenAnswer((_) async => _fakeSettings());
        when(() => repo.getAllergies())
            .thenAnswer((_) async => _fakeAllergies());
        when(() => repo.getDoctors()).thenAnswer((_) async => []);
        return SettingsCubit(repo);
      },
      seed: () => SettingsLoaded(
        settings: _fakeSettings(),
        allergies: const [
          AllergyItem(id: 'a-1', ingredientName: 'えび', isPreset: true)
        ],
        doctors: const [],
      ),
      act: (cubit) => cubit.deleteAllergy('a-1'),
      expect: () => [
        const SettingsLoading(),
        isA<SettingsLoaded>(),
      ],
      verify: (cubit) {
        expect((cubit.state as SettingsLoaded).allergies, isEmpty);
      },
    );
  });
}
