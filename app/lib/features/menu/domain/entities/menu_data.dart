import 'package:equatable/equatable.dart';

/// รายการบริการเสริมบนหน้าเมนู
enum MenuServiceAction {
  tag,
  treats,
  memorial,
  memorialCremation,
  memorialSite,
  printCatId,
  pedigree,
  insurance,
}

class MenuExtraService extends Equatable {
  const MenuExtraService({
    required this.id,
    required this.action,
    required this.isComingSoon,
  });

  final String id;
  final MenuServiceAction action;
  final bool isComingSoon;

  @override
  List<Object?> get props => [id, action, isComingSoon];
}

/// การตั้งค่าผู้ใช้บนหน้าเมนูหลัก
class MenuSettings extends Equatable {
  const MenuSettings({
    this.pushEnabled = true,
    this.quietHoursEnabled = true,
    this.locale = 'th',
  });

  final bool pushEnabled;
  final bool quietHoursEnabled;
  final String locale;

  MenuSettings copyWith({
    bool? pushEnabled,
    bool? quietHoursEnabled,
    String? locale,
  }) {
    return MenuSettings(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      locale: locale ?? this.locale,
    );
  }

  @override
  List<Object?> get props => [pushEnabled, quietHoursEnabled, locale];
}

/// ข้อมูลรวมของหน้าเมนูหลัก (/menu)
class MenuData extends Equatable {
  const MenuData({
    required this.services,
    required this.settings,
    required this.appVersion,
  });

  final List<MenuExtraService> services;
  final MenuSettings settings;
  final String appVersion;

  MenuData copyWith({
    List<MenuExtraService>? services,
    MenuSettings? settings,
    String? appVersion,
  }) {
    return MenuData(
      services: services ?? this.services,
      settings: settings ?? this.settings,
      appVersion: appVersion ?? this.appVersion,
    );
  }

  @override
  List<Object?> get props => [services, settings, appVersion];
}
