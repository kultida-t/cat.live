import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_locale.dart';
import '../../../../core/error/failure.dart';
import '../../data/datasources/mock_menu_data_source.dart';
import '../../data/repositories/menu_repository_impl.dart';
import '../../domain/entities/menu_data.dart';
import '../../domain/repositories/menu_repository.dart';
import '../../domain/usecases/get_menu_data.dart';
import '../../domain/usecases/save_menu_settings.dart';

enum MenuStatus { loading, empty, error, ready }

class MenuState {
  const MenuState({
    this.status = MenuStatus.loading,
    this.data,
    this.errorMessage,
  });

  final MenuStatus status;
  final MenuData? data;
  final String? errorMessage;

  MenuState copyWith({
    MenuStatus? status,
    MenuData? data,
    String? errorMessage,
  }) {
    return MenuState(
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: errorMessage,
    );
  }
}

final menuDataSourceProvider = Provider<MockMenuDataSource>(
  (ref) => MockMenuDataSource(),
);

final menuRepositoryProvider = Provider<MenuRepository>(
  (ref) => MenuRepositoryImpl(ref.read(menuDataSourceProvider)),
);

final menuControllerProvider = NotifierProvider<MenuController, MenuState>(
  MenuController.new,
);

class MenuController extends Notifier<MenuState> {
  GetMenuData get _getMenuData => GetMenuData(ref.read(menuRepositoryProvider));
  SaveMenuSettings get _saveSettings =>
      SaveMenuSettings(ref.read(menuRepositoryProvider));

  @override
  MenuState build() {
    Future.microtask(_load);
    return const MenuState(status: MenuStatus.loading);
  }

  Future<void> _load() async {
    try {
      final raw = await _getMenuData();
      if (raw.services.isEmpty) {
        state = const MenuState(status: MenuStatus.empty);
        return;
      }
      final currentLocale = ref.read(appLocaleProvider);
      final synced = raw.copyWith(
        settings: raw.settings.copyWith(locale: currentLocale),
      );
      state = MenuState(status: MenuStatus.ready, data: synced);
    } on Failure catch (e) {
      state = MenuState(status: MenuStatus.error, errorMessage: e.message);
    } catch (_) {
      state = const MenuState(
        status: MenuStatus.error,
        errorMessage: 'โหลดเมนูไม่สำเร็จ กรุณาลองใหม่อีกครั้ง',
      );
    }
  }

  Future<void> retry() async {
    state = const MenuState(status: MenuStatus.loading);
    await _load();
  }

  Future<Failure?> updateSettings(MenuSettings next) async {
    final prevData = state.data;
    if (prevData == null) return null;
    final prevSettings = prevData.settings;
    state = state.copyWith(data: prevData.copyWith(settings: next));
    if (next.locale != prevSettings.locale) {
      ref.read(appLocaleProvider.notifier).setLocale(next.locale);
    }
    try {
      await _saveSettings(next);
      return null;
    } on Failure catch (e) {
      state = state.copyWith(data: prevData.copyWith(settings: prevSettings));
      if (next.locale != prevSettings.locale) {
        ref.read(appLocaleProvider.notifier).setLocale(prevSettings.locale);
      }
      return e;
    } catch (_) {
      state = state.copyWith(data: prevData.copyWith(settings: prevSettings));
      if (next.locale != prevSettings.locale) {
        ref.read(appLocaleProvider.notifier).setLocale(prevSettings.locale);
      }
      return const UnknownFailure('บันทึกการตั้งค่าไม่สำเร็จ ลองใหม่อีกครั้ง');
    }
  }
}
