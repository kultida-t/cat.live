import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/config/app_locale.dart';
import '../../../../core/config/app_text_scale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/toast_pill.dart';
import '../../../auth/domain/entities/auth_data.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../domain/entities/settings_data.dart';
import '../providers/settings_controller.dart';
import '../widgets/settings_l10n.dart';
import '../widgets/settings_shared_widgets.dart';
import '../widgets/settings_sheets.dart';
import '../widgets/settings_skeleton.dart';

/// หน้าตั้งค่าและศูนย์ช่วยเหลือ (/settings — อ้างอิง SET-01, PDPA-01, NOTI-01/02)
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key, this.initialSection});

  /// เปิดชีตเฉพาะทางอัตโนมัติเมื่อลิงก์มาจากหน้าอื่น ('privacy', 'help', 'notifications')
  final String? initialSection;

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> with ToastMixin {
  bool _openedInitialSection = false;
  int _versionTapCount = 0;

  @override
  void dispose() {
    disposeToast();
    super.dispose();
  }

  void _maybeOpenInitialSection() {
    if (_openedInitialSection || widget.initialSection == null) return;
    _openedInitialSection = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (widget.initialSection) {
        case 'privacy':
          showPdpaSheet(context, onToast: showToast);
        case 'help':
          showHelpCenterSheet(context, onToast: showToast);
        case 'notifications':
          showNotificationCategoriesSheet(context, onToast: showToast);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final locale = ref.watch(appLocaleProvider);
    final isEn = locale == 'en';
    final textPreset = ref.watch(appTextScaleProvider);

    if (state.status == SettingsStatus.ready) {
      _maybeOpenInitialSection();
    }

    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _Header(
                  title: SettingsL10n.pageTitle(isEn),
                  backLabel: SettingsL10n.backLabel(isEn),
                  onBack: () => context.pop(),
                ),
                Expanded(
                  child: switch (state.status) {
                    SettingsStatus.loading => const SettingsSkeleton(),
                    SettingsStatus.error => ErrorView(
                      title: SettingsL10n.loadError(isEn),
                      message:
                          state.errorMessage ??
                          SettingsL10n.emptySubtitle(isEn),
                      onRetry: controller.retry,
                    ),
                    SettingsStatus.empty => _EmptySettingsView(
                      isEn: isEn,
                      onRetry: controller.retry,
                    ),
                    SettingsStatus.ready => _buildContent(
                      context,
                      data: state.data!,
                      isEn: isEn,
                      locale: locale,
                      textPreset: textPreset,
                      controller: controller,
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

  Widget _buildContent(
    BuildContext context, {
    required SettingsData data,
    required bool isEn,
    required String locale,
    required AppTextSizePreset textPreset,
    required SettingsController controller,
  }) {
    final enabledCategories = data.notificationCategories.values
        .where((v) => v)
        .length;
    final totalCategories = NotificationCategoryKey.values.length;
    final grantedPdpa = data.pdpaConsents.where((e) => e.granted).length;
    final authState = ref.watch(authControllerProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 36),
      children: [
        _AccountSummaryCard(
          data: data,
          authState: authState,
          isEn: isEn,
          onSignInTap: () => context.push('/login'),
        ),
        SettingsSectionHeader(title: SettingsL10n.sectionAccount(isEn)),
        SettingsCard(
          children: [
            SettingsRow(
              icon: LucideIcons.globe,
              title: SettingsL10n.languageTitle(isEn),
              trailing: SettingsSegmentGroup<String>(
                options: const ['th', 'en'],
                selected: locale,
                labelBuilder: (val) => val == 'en' ? 'EN' : 'ไทย',
                onChanged: (next) {
                  ref.read(appLocaleProvider.notifier).setLocale(next);
                  showToast(
                    next == 'en'
                        ? 'Switched to English'
                        : 'เปลี่ยนเป็นภาษาไทยแล้ว',
                  );
                },
              ),
            ),
            SettingsRow(
              icon: LucideIcons.type,
              title: SettingsL10n.textSizeTitle(isEn),
              trailing: SettingsSegmentGroup<AppTextSizePreset>(
                options: AppTextSizePreset.values,
                selected: textPreset,
                labelBuilder: (p) => SettingsL10n.textSizeLabel(p, isEn),
                onChanged: (next) {
                  ref.read(appTextScaleProvider.notifier).setPreset(next);
                  showToast(SettingsL10n.textSizeChangedToast(next, isEn));
                },
              ),
            ),
          ],
        ),
        SettingsSectionHeader(title: SettingsL10n.sectionNotifications(isEn)),
        SettingsCard(
          children: [
            SettingsRow(
              icon: LucideIcons.bell,
              title: SettingsL10n.pushTitle(isEn),
              trailing: SettingsMintSwitch(
                value: data.pushEnabled,
                onChanged: (v) async {
                  await controller.togglePush(v);
                  showToast(SettingsL10n.pushToast(v, isEn));
                },
              ),
              onTap: () async {
                final next = !data.pushEnabled;
                await controller.togglePush(next);
                showToast(SettingsL10n.pushToast(next, isEn));
              },
            ),
            SettingsRow(
              icon: LucideIcons.moon,
              title: SettingsL10n.quietHoursTitle(isEn),
              subtitle: SettingsL10n.quietHoursSubtitle(
                data.quietStart,
                data.quietEnd,
                isEn,
              ),
              trailing: SettingsMintSwitch(
                value: data.quietHoursEnabled,
                onChanged: (v) async {
                  await controller.toggleQuietHours(v);
                  showToast(
                    SettingsL10n.quietHoursToast(
                      v,
                      data.quietStart,
                      data.quietEnd,
                      isEn,
                    ),
                  );
                },
              ),
              onTap: () => showQuietHoursSheet(context, onToast: showToast),
            ),
            SettingsRow(
              icon: LucideIcons.slidersHorizontal,
              title: SettingsL10n.notiCategoriesTitle(isEn),
              subtitle: SettingsL10n.notiCategoriesSubtitle(
                enabledCategories,
                totalCategories,
                isEn,
              ),
              trailing: const Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: AppColors.muted,
              ),
              onTap: () =>
                  showNotificationCategoriesSheet(context, onToast: showToast),
            ),
          ],
        ),
        SettingsSectionHeader(title: SettingsL10n.sectionPrivacy(isEn)),
        SettingsCard(
          children: [
            SettingsRow(
              icon: LucideIcons.shieldCheck,
              title: SettingsL10n.pdpaRowTitle(isEn),
              subtitle: SettingsL10n.pdpaRowSubtitle(
                grantedPdpa,
                data.pdpaConsents.length,
                isEn,
              ),
              trailing: const Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: AppColors.muted,
              ),
              onTap: () => showPdpaSheet(context, onToast: showToast),
            ),
          ],
        ),
        SettingsSectionHeader(title: SettingsL10n.sectionSupport(isEn)),
        SettingsCard(
          children: [
            SettingsRow(
              icon: LucideIcons.tag,
              title: SettingsL10n.tagDevicesTitle(isEn),
              subtitle: SettingsL10n.tagDevicesSubtitle(isEn),
              trailing: const Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: AppColors.muted,
              ),
              onTap: () => context.push('/settings/tracker'),
            ),
            SettingsRow(
              icon: LucideIcons.scrollText,
              title: SettingsL10n.communityRulesTitle(isEn),
              subtitle: SettingsL10n.communityRulesSubtitle(isEn),
              trailing: const Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: AppColors.muted,
              ),
              onTap: () => context.push('/settings/guidelines'),
            ),
            SettingsRow(
              icon: LucideIcons.lifeBuoy,
              title: SettingsL10n.helpCenterTitle(isEn),
              subtitle: SettingsL10n.helpCenterSubtitle(isEn),
              trailing: const Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: AppColors.muted,
              ),
              onTap: () => showHelpCenterSheet(context, onToast: showToast),
            ),
          ],
        ),
        const SizedBox(height: 22),
        if (authState.isGuest)
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: () => context.push('/login'),
              icon: const Icon(LucideIcons.logIn, size: 17),
              label: Text(
                isEn ? 'Sign in / Register' : 'เข้าสู่ระบบ / สมัครสมาชิก',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.ownerTeal,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
            ),
          )
        else
          SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => showSignOutConfirmDialog(
                context,
                isEn: isEn,
                onConfirm: () async {
                  await ref.read(authControllerProvider.notifier).signOut();
                  if (!context.mounted) return;
                  showToast(SettingsL10n.signOutDoneToast(isEn));
                  context.push('/login');
                },
              ),
              icon: const Icon(LucideIcons.logOut, size: 17),
              label: Text(
                SettingsL10n.signOut(isEn),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.logoutBg,
                foregroundColor: AppColors.logoutText,
                side: const BorderSide(color: AppColors.logoutBorder),
                shape: const StadiumBorder(),
              ),
            ),
          ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {
            _versionTapCount++;
            if (_versionTapCount >= 5) {
              _versionTapCount = 0;
              context.push('/feature-flags');
            }
          },
          child: Text(
            SettingsL10n.versionFooter(data.appVersion, isEn),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.backLabel,
    required this.onBack,
  });

  final String title;
  final String backLabel;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 6),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: backLabel,
            excludeSemantics: true,
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(14),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  LucideIcons.chevronLeft,
                  size: 24,
                  color: AppColors.text,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountSummaryCard extends StatelessWidget {
  const _AccountSummaryCard({
    required this.data,
    required this.authState,
    required this.isEn,
    required this.onSignInTap,
  });

  final SettingsData data;
  final AuthState authState;
  final bool isEn;
  final VoidCallback onSignInTap;

  @override
  Widget build(BuildContext context) {
    final isGuest = authState.isGuest;
    final rawName = authState.session.user?.displayName ?? data.accountName;
    final displayName = isGuest
        ? (isEn ? 'Guest Mode' : 'ผู้เยี่ยมชม (Guest Mode)')
        : (isEn && rawName == 'จุฑามาศ ลูกแก้ว' ? 'Jutamas Lukkaew' : rawName);
    final methodLabel = switch (authState.session.user?.method) {
      AuthMethod.apple => 'Apple ID',
      AuthMethod.google => 'Google',
      AuthMethod.line => 'LINE',
      AuthMethod.phoneOtp =>
        authState.session.user?.phoneMasked ?? data.accountHandle,
      _ => data.accountHandle,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          if (!isGuest && data.accountAvatarSource.isNotEmpty)
            AppAvatar(
              source: data.accountAvatarSource,
              bg: 0xFFFFE89A,
              size: 44,
            )
          else
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isGuest ? AppColors.soft : AppColors.ownerPillBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isGuest ? LucideIcons.compass : LucideIcons.userCheck,
                size: 22,
                color: isGuest ? AppColors.muted : AppColors.ownerTeal,
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isGuest
                      ? (isEn
                            ? 'Browsing without an account'
                            : 'กำลังใช้งานแบบไม่ระบุตัวตน')
                      : methodLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          if (isGuest)
            TextButton(
              onPressed: onSignInTap,
              child: Text(
                isEn ? 'Sign in' : 'เข้าสู่ระบบ',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ownerTeal,
                ),
              ),
            )
          else if (data.accountVerified)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.ownerPillBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                SettingsL10n.verifiedBadge(isEn),
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ownerTeal,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptySettingsView extends StatelessWidget {
  const _EmptySettingsView({required this.isEn, required this.onRetry});

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
            const Icon(LucideIcons.settings, size: 42, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(
              SettingsL10n.emptyTitle(isEn),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              SettingsL10n.emptySubtitle(isEn),
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: Text(SettingsL10n.retry(isEn)),
            ),
          ],
        ),
      ),
    );
  }
}
