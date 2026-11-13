import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/config/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/toast_pill.dart';
import '../../domain/entities/menu_data.dart';
import '../providers/menu_controller.dart';
import '../widgets/menu_l10n.dart';
import '../widgets/menu_service_grid.dart';
import '../widgets/menu_skeleton.dart';

/// หน้าเมนูหลัก (/menu) — เปิดซ้อนทับจากปุ่ม ≡ บนหน้าแรกและหน้าฟีด
class MenuPage extends ConsumerStatefulWidget {
  const MenuPage({super.key});

  @override
  ConsumerState<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends ConsumerState<MenuPage> with ToastMixin {
  @override
  void dispose() {
    disposeToast();
    super.dispose();
  }

  void _handleServiceTap(MenuExtraService service, bool isEn) {
    final title = MenuL10n.serviceTitle(service.action, isEn);
    if (service.isComingSoon) {
      showToast(
        isEn
            ? '$title — Coming soon'
            : '$title — เร็ว ๆ นี้ จะเปิดให้บริการเร็ว ๆ นี้',
      );
      return;
    }
    showToast(
      isEn
          ? '$title — Coming soon in the next phase'
          : '$title — กำลังพัฒนา จะมาในเฟสถัดไป',
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(menuControllerProvider);
    final controller = ref.read(menuControllerProvider.notifier);
    final isEn = ref.watch(appLocaleProvider) == 'en';

    return Scaffold(
      backgroundColor: AppColors.card,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 10, 6),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/brand/maew-logo.png',
                        width: 118,
                        height: 34,
                        semanticLabel: 'แมว.live',
                      ),
                      const Spacer(),
                      Semantics(
                        button: true,
                        label: MenuL10n.closeLabel(isEn),
                        excludeSemantics: true,
                        child: InkWell(
                          onTap: () => context.pop(),
                          borderRadius: BorderRadius.circular(14),
                          child: const SizedBox(
                            width: 44,
                            height: 44,
                            child: Icon(
                              LucideIcons.x,
                              size: 22,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: switch (state.status) {
                    MenuStatus.loading => const MenuSkeleton(),
                    MenuStatus.error => ErrorView(
                      title: MenuL10n.loadError(isEn),
                      message:
                          state.errorMessage ?? MenuL10n.emptySubtitle(isEn),
                      onRetry: controller.retry,
                    ),
                    MenuStatus.empty => _EmptyMenuCard(
                      isEn: isEn,
                      onRetry: controller.retry,
                    ),
                    MenuStatus.ready => ListView(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
                      children: [
                        MenuServiceGrid(
                          services: state.data!.services,
                          isEn: isEn,
                          onSelectService: (svc) =>
                              _handleServiceTap(svc, isEn),
                        ),
                      ],
                    ),
                  },
                ),
              ],
            ),
            if (toastMessage != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 24,
                child: IgnorePointer(
                  child: Center(child: ToastPill(message: toastMessage!)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMenuCard extends StatelessWidget {
  const _EmptyMenuCard({required this.isEn, required this.onRetry});

  final bool isEn;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.layoutGrid,
              size: 36,
              color: AppColors.muted,
            ),
            const SizedBox(height: 12),
            Text(
              MenuL10n.emptyTitle(isEn),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              MenuL10n.emptySubtitle(isEn),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 44,
              child: FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  foregroundColor: AppColors.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(MenuL10n.retry(isEn)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
