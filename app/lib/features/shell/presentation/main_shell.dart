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

class _NavItem extends StatefulWidget {
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
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> with SingleTickerProviderStateMixin {
  late final AnimationController _selectCtrl;
  late final Animation<double> _pillScaleX;
  late final Animation<double> _pillOpacity;
  late final Animation<double> _iconScale;
  late final Animation<double> _iconTranslateY;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _selectCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
      value: widget.active ? 1.0 : 0.0,
    );

    // Active Pill: 350ms (0.0 -> 0.78 ของ 450ms), Cubic(0.22, 1, 0.36, 1)
    final pillCurve = CurvedAnimation(
      parent: _selectCtrl,
      curve: const Interval(0.0, 0.78, curve: Cubic(0.22, 1.0, 0.36, 1.0)),
    );
    _pillScaleX = Tween<double>(begin: 0.4, end: 1.0).animate(pillCurve);
    _pillOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(pillCurve);

    // Icon Spring Pop (.nav-pop): 450ms, Cubic(0.34, 1.56, 0.64, 1)
    _iconScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.8, end: 1.12)
            .chain(CurveTween(curve: const Cubic(0.34, 1.56, 0.64, 1.0))),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.12, end: 1.0).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 40,
      ),
    ]).animate(_selectCtrl);

    _iconTranslateY = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 2.0, end: -2.0)
            .chain(CurveTween(curve: const Cubic(0.34, 1.56, 0.64, 1.0))),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -2.0, end: -1.0).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 40,
      ),
    ]).animate(_selectCtrl);
  }

  @override
  void didUpdateWidget(covariant _NavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.active && widget.active) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _selectCtrl.value = 1.0;
      } else {
        _selectCtrl.forward(from: 0.0);
      }
    } else if (oldWidget.active && !widget.active) {
      _selectCtrl.value = 0.0;
    }
  }

  @override
  void dispose() {
    _selectCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.isEn ? widget.meta.enLabel : widget.meta.label;
    final active = widget.active;

    return Semantics(
      button: true,
      selected: active,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.9 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.ease,
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
                          child: AnimatedBuilder(
                            animation: _selectCtrl,
                            builder: (_, child) => Opacity(
                              opacity: _pillOpacity.value,
                              child: Transform.scale(
                                scaleX: _pillScaleX.value,
                                child: child,
                              ),
                            ),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: widget.meta.pill,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                      AnimatedBuilder(
                        animation: _selectCtrl,
                        builder: (_, child) {
                          if (!active) return child!;
                          return Transform.translate(
                            offset: Offset(0, _iconTranslateY.value),
                            child: Transform.scale(
                              scale: _iconScale.value,
                              child: child,
                            ),
                          );
                        },
                        child: NavIcon(name: widget.meta.icon, active: active),
                      ),
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
      ),
    );
  }
}
