import '../../domain/entities/menu_data.dart';

/// แหล่งข้อมูลจำลองของหน้าเมนูหลัก (/menu) — เรียง 8 รายการตรงเว็บจริง
class MockMenuDataSource {
  MenuSettings _settings = const MenuSettings();

  static const _services = [
    MenuExtraService(
      id: 'svc-tag',
      action: MenuServiceAction.tag,
      isComingSoon: false,
    ),
    MenuExtraService(
      id: 'svc-treats',
      action: MenuServiceAction.treats,
      isComingSoon: false,
    ),
    MenuExtraService(
      id: 'svc-memorial',
      action: MenuServiceAction.memorial,
      isComingSoon: false,
    ),
    MenuExtraService(
      id: 'svc-cremation',
      action: MenuServiceAction.memorialCremation,
      isComingSoon: false,
    ),
    MenuExtraService(
      id: 'svc-memorial-site',
      action: MenuServiceAction.memorialSite,
      isComingSoon: false,
    ),
    MenuExtraService(
      id: 'svc-print-cat-id',
      action: MenuServiceAction.printCatId,
      isComingSoon: false,
    ),
    MenuExtraService(
      id: 'svc-pedigree',
      action: MenuServiceAction.pedigree,
      isComingSoon: true,
    ),
    MenuExtraService(
      id: 'svc-insurance',
      action: MenuServiceAction.insurance,
      isComingSoon: true,
    ),
  ];

  Future<MenuData> fetchMenuData() async {
    return MenuData(
      services: _services,
      settings: _settings,
      appVersion: '0.1',
    );
  }

  Future<MenuSettings> updateSettings(MenuSettings settings) async {
    _settings = settings;
    return _settings;
  }
}
