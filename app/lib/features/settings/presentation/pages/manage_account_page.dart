import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/config/app_locale.dart';
import '../../../../core/router/auth_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../auth/domain/entities/auth_data.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../domain/entities/settings_data.dart';
import '../providers/settings_controller.dart';
import '../widgets/settings_l10n.dart';
import '../widgets/settings_shared_widgets.dart';
import '../widgets/settings_skeleton.dart';

/// หน้าจัดการบัญชี (/settings/account) — เข้าจากการ์ดบัญชีในหน้าตั้งค่า
/// รวมเมนูที่ผูกกับบัญชี เช่น ลบบัญชี (AUTH-05) ไว้ในจอเดียวให้หาเจอตรงกลุ่ม
class ManageAccountPage extends ConsumerWidget {
  const ManageAccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEn = ref.watch(appLocaleProvider) == 'en';
    final authState = ref.watch(authControllerProvider);
    final settingsState = ref.watch(settingsControllerProvider);
    final isGuest = authState.sessionResolved && authState.isGuest;

    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: Column(
          children: [
            _ManageAccountHeader(
              title: isEn ? 'Manage account' : 'จัดการบัญชี',
              backLabel: SettingsL10n.backLabel(isEn),
              onBack: () =>
                  context.canPop() ? context.pop() : context.go('/settings'),
            ),
            Expanded(
              child: isGuest
                  ? _GuestGate(isEn: isEn)
                  : switch (settingsState.status) {
                      SettingsStatus.loading => const SettingsSkeleton(),
                      SettingsStatus.error => ErrorView(
                        title: SettingsL10n.loadError(isEn),
                        message:
                            settingsState.errorMessage ??
                            SettingsL10n.emptySubtitle(isEn),
                        onRetry: () => ref
                            .read(settingsControllerProvider.notifier)
                            .retry(),
                      ),
                      _ => _buildBody(context, isEn, authState, settingsState),
                    },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    bool isEn,
    AuthState authState,
    SettingsState settingsState,
  ) {
    final data = settingsState.data;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _AccountInfoCard(data: data, authState: authState, isEn: isEn),
        SettingsSectionHeader(title: isEn ? 'Account' : 'บัญชี'),
        SettingsCard(
          children: [
            SettingsRow(
              icon: LucideIcons.userX,
              title: isEn ? 'Delete account' : 'ลบบัญชี',
              subtitle: isEn
                  ? 'Data is kept 30 days before permanent deletion'
                  : 'ข้อมูลถูกเก็บไว้ 30 วันก่อนลบถาวร กู้คืนได้ภายในกำหนด',
              trailing: const Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: AppColors.muted,
              ),
              danger: true,
              onTap: () => context.push('/settings/delete-account'),
            ),
          ],
        ),
      ],
    );
  }
}

class _ManageAccountHeader extends StatelessWidget {
  const _ManageAccountHeader({
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

/// การ์ดสรุปบัญชีบนหน้าจัดการบัญชี — อ่านอย่างเดียว ไม่มีปุ่มลัด
class _AccountInfoCard extends StatelessWidget {
  const _AccountInfoCard({
    required this.data,
    required this.authState,
    required this.isEn,
  });

  final SettingsData? data;
  final AuthState authState;
  final bool isEn;

  @override
  Widget build(BuildContext context) {
    final rawName = authState.session.user?.displayName ?? data?.accountName;
    final displayName = rawName == null || rawName.isEmpty
        ? (isEn ? 'Member' : 'สมาชิก')
        : (isEn && rawName == 'จุฑามาศ ลูกแก้ว' ? 'Jutamas Lukkaew' : rawName);
    final methodLabel = switch (authState.session.user?.method) {
      AuthMethod.apple => 'Apple ID',
      AuthMethod.google => 'Google',
      AuthMethod.line => 'LINE',
      AuthMethod.phoneOtp =>
        authState.session.user?.phoneMasked ?? data?.accountHandle ?? '',
      _ => data?.accountHandle ?? '',
    };
    final avatarSource = data?.accountAvatarSource ?? '';
    final verified = data?.accountVerified ?? false;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          if (avatarSource.isNotEmpty)
            AppAvatar(source: avatarSource, bg: 0xFFFFE89A, size: 48)
          else
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.ownerPillBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.userCheck,
                size: 22,
                color: AppColors.ownerTeal,
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
                  methodLabel,
                  style: const TextStyle(fontSize: 13, color: AppColors.muted),
                ),
              ],
            ),
          ),
          if (verified)
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

/// จอสำหรับ guest ที่เปิดลิงก์ตรงมา — ต้องล็อกอินก่อนจัดการบัญชี
class _GuestGate extends StatelessWidget {
  const _GuestGate({required this.isEn});

  final bool isEn;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.soft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.lockKeyhole,
                size: 30,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isEn ? 'Sign in required' : 'ต้องเข้าสู่ระบบก่อน',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isEn
                  ? 'Please sign in to manage your account.'
                  : 'เข้าสู่ระบบเพื่อจัดการบัญชีของคุณ',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: () =>
                    context.push(loginLocation(returnTo: '/settings/account')),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.ownerTeal,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                ),
                child: Text(
                  isEn ? 'Sign in' : 'เข้าสู่ระบบ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
