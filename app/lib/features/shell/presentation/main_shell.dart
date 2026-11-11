import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_locale.dart';
import '../../../core/theme/app_colors.dart';
import 'nav_icons.dart';

class _TabMeta {
  const _TabMeta(this.label, this.enLabel, this.icon, this.pill);
  final String label;
  final String enLabel;
  final NavIconName icon;
  final Color pill;
}

/// แท็บล่าง 6 อัน เรียงตามเว็บ prototype พร้อมสีแคปซูลของแต่ละแท็บ (รองรับสลับ ไทย / EN)
const _tabs = [
  _TabMeta('หน้าแรก', 'Home', NavIconName.home, Color(0xFFDCEBFF)),
  _TabMeta('ฟีด', 'Feed', NavIconName.feed, Color(0xFFDCEBFF)),
  _TabMeta('ใกล้ฉัน', 'Nearby', NavIconName.nearby, Color(0xFFD5F0EB)),
  _TabMeta('Cat AI', 'Cat AI', NavIconName.ai, Color(0xFFEDE4FB)),
  _TabMeta('ช่วยเหลือ', 'Help', NavIconName.help, Color(0xFFFDE2EC)),
  _TabMeta('แมวและฉัน', 'My Cat', NavIconName.myCat, Color(0xFFFFF1E6)),
];

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEn = ref.watch(appLocaleProvider) == 'en';
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _BottomBar(
        currentIndex: navigationShell.currentIndex,
        isEn: isEn,
        onSelected: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.currentIndex,
    required this.isEn,
    required this.onSelected,
  });

  final int currentIndex;
  final bool isEn;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(6, 6, 6, bottomInset + 10),
      decoration: const BoxDecoration(
        color: AppColors.navBackground,
        border: Border(top: BorderSide(color: AppColors.line)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F4A3428),
            blurRadius: 20,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        children: [
          for (var i = 0; i < _tabs.length; i++)
            Expanded(
              child: _NavItem(
                meta: _tabs[i],
                isEn: isEn,
                active: i == currentIndex,
                onTap: () => onSelected(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.meta,
    required this.isEn,
    required this.active,
    required this.onTap,
  });

  final _TabMeta meta;
  final bool isEn;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = isEn ? meta.enLabel : meta.label;
    return Semantics(
      button: true,
      selected: active,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        highlightShape: BoxShape.rectangle,
        containedInkWell: true,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 58,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 50,
                height: 34,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (active)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: meta.pill,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    NavIcon(name: meta.icon, active: active),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.5,
                  color: active ? AppColors.ink : AppColors.muted,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
