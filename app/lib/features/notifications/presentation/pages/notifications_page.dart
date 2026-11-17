import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/config/app_locale.dart';
import '../../../../core/config/pet_species_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/toast_pill.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../auth/presentation/widgets/guest_locked_view.dart';
import '../../domain/entities/app_notification.dart';
import '../l10n/notifications_l10n.dart';
import '../providers/notifications_controller.dart';
import '../widgets/notification_tile.dart';
import '../widgets/notifications_skeleton.dart';

/// หน้าการแจ้งเตือน (/notifications) — เปิดจากปุ่มกระดิ่งบนหน้าแรกและหน้าฟีด
class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage>
    with ToastMixin {
  @override
  void dispose() {
    disposeToast();
    super.dispose();
  }

  Future<void> _handleMarkAll(NotificationsL10n l10n) async {
    final failure = await ref
        .read(notificationsControllerProvider.notifier)
        .markAllAsRead();
    if (!mounted) return;
    showToast(failure?.message ?? l10n.markedAllReadToast);
  }

  Future<void> _handleItemTap(AppNotification item) async {
    final failure = await ref
        .read(notificationsControllerProvider.notifier)
        .markAsRead(item.id);
    if (!mounted) return;
    if (failure != null) {
      showToast(failure.message);
      return;
    }

    context.push(item.targetRoute);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsControllerProvider);
    final controller = ref.read(notificationsControllerProvider.notifier);
    final isEn = ref.watch(appLocaleProvider) == 'en';
    final isGuest = ref.watch(authControllerProvider).isGuest;
    final l10n = NotificationsL10n(isEn);

    // ผู้เยี่ยมชมที่หลุดเข้ามาทาง deep link เห็นเฉพาะการ์ดชวนเข้าสู่ระบบ
    if (isGuest) {
      return Scaffold(
        backgroundColor: AppColors.page,
        body: SafeArea(
          child: Column(
            children: [
              _Header(
                l10n: l10n,
                unreadCount: 0,
                onBack: () => context.pop(),
                onMarkAll: null,
              ),
              Expanded(
                child: GuestLockedView(
                  species: ref.watch(petSpeciesConfigProvider),
                  isEn: isEn,
                  title: isEn
                      ? 'Sign in to see notifications'
                      : 'เข้าสู่ระบบเพื่อดูการแจ้งเตือน',
                  subtitle: isEn
                      ? 'Get likes, comments, followers, and important\npet alerts in real time.'
                      : 'รับข่าวไลก์ คอมเมนต์ ผู้ติดตามใหม่\nและแจ้งเตือนสำคัญของน้องแมวแบบเรียลไทม์',
                  onSignInTap: () => context.push('/login'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.page,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _Header(
                  l10n: l10n,
                  unreadCount: state.unreadCount,
                  onBack: () => context.pop(),
                  onMarkAll: state.unreadCount > 0
                      ? () => _handleMarkAll(l10n)
                      : null,
                ),
                _FilterBar(
                  l10n: l10n,
                  filter: state.filter,
                  unreadCount: state.unreadCount,
                  onChanged: controller.setFilter,
                ),
                Expanded(
                  child: _buildBody(
                    state: state,
                    controller: controller,
                    l10n: l10n,
                    isEn: isEn,
                  ),
                ),
              ],
            ),
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
    );
  }

  Widget _buildBody({
    required NotificationsState state,
    required NotificationsController controller,
    required NotificationsL10n l10n,
    required bool isEn,
  }) {
    if (state.isLoading && state.items.isEmpty) {
      return const NotificationsSkeleton();
    }
    if (state.failure != null && state.items.isEmpty) {
      return ErrorView(
        title: l10n.loadErrorTitle,
        message: state.failure?.message ?? l10n.loadErrorMessage,
        actionLabel: l10n.retry,
        onRetry: controller.retry,
      );
    }

    final visible = state.visibleItems;
    if (visible.isEmpty) {
      final isUnreadFilter = state.filter == NotificationFilter.unread;
      return RefreshIndicator(
        color: AppColors.ink,
        backgroundColor: AppColors.card,
        onRefresh: controller.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 64, 24, 32),
          children: [
            _EmptyNotifications(
              title: isUnreadFilter ? l10n.emptyUnreadTitle : l10n.emptyTitle,
              subtitle: isUnreadFilter
                  ? l10n.emptyUnreadSubtitle
                  : l10n.emptySubtitle,
              actionLabel: isUnreadFilter ? l10n.showAllButton : null,
              onAction: isUnreadFilter
                  ? () => controller.setFilter(NotificationFilter.all)
                  : null,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.ink,
      backgroundColor: AppColors.card,
      onRefresh: controller.refresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
        itemCount: visible.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, index) {
          final item = visible[index];
          return NotificationTile(
            key: ValueKey(item.id),
            item: item,
            isEn: isEn,
            onTap: () => _handleItemTap(item),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.l10n,
    required this.unreadCount,
    required this.onBack,
    required this.onMarkAll,
  });

  final NotificationsL10n l10n;
  final int unreadCount;
  final VoidCallback onBack;
  final VoidCallback? onMarkAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 12, 8),
      decoration: const BoxDecoration(
        color: AppColors.page,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: l10n.backLabel,
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
              l10n.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ),
          if (onMarkAll != null)
            Semantics(
              button: true,
              label: l10n.markAllRead,
              excludeSemantics: true,
              child: InkWell(
                onTap: onMarkAll,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.checkCheck,
                        size: 16,
                        color: AppColors.ink,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        l10n.markAllRead,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.l10n,
    required this.filter,
    required this.unreadCount,
    required this.onChanged,
  });

  final NotificationsL10n l10n;
  final NotificationFilter filter;
  final int unreadCount;
  final ValueChanged<NotificationFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          _FilterChip(
            label: l10n.filterAll,
            selected: filter == NotificationFilter.all,
            onTap: () => onChanged(NotificationFilter.all),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: l10n.filterUnread(unreadCount),
            selected: filter == NotificationFilter.unread,
            onTap: () => onChanged(NotificationFilter.unread),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.btn : AppColors.card,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected ? AppColors.btnBorder : AppColors.line2,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.ink : AppColors.text2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.btn,
            ),
            child: const Icon(LucideIcons.bell, size: 26, color: AppColors.ink),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: AppColors.muted,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                backgroundColor: AppColors.btn,
                foregroundColor: AppColors.ink,
                side: const BorderSide(color: AppColors.btnBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
