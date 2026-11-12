import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/toast_pill.dart';
import '../../domain/entities/help_data.dart';
import '../providers/help_controller.dart';
import '../widgets/help_category_chips.dart';
import '../widgets/help_create_post_sheets.dart';
import '../widgets/help_emergency_modal.dart';
import '../widgets/help_filter_sheet.dart';
import '../widgets/help_l10n.dart';
import '../widgets/help_my_posts_sheets.dart';
import '../widgets/help_post_card.dart';
import '../widgets/help_share_sheet.dart';
import '../widgets/help_skeleton.dart';

/// หน้าช่วยเหลือ (/help) — ประกาศแมวหาย พบแมว ขอช่วย รับเลี้ยง อุปการะ และปุ่มฉุกเฉิน
class HelpPage extends ConsumerStatefulWidget {
  const HelpPage({super.key});

  @override
  ConsumerState<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends ConsumerState<HelpPage> with ToastMixin {
  bool _showMyRescueHistory = false;

  @override
  void dispose() {
    disposeToast();
    super.dispose();
  }

  Future<void> _callEmergencyPhone(String phone, bool isEn) async {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(scheme: 'tel', path: cleaned);
    var launched = false;
    try {
      if (await canLaunchUrl(uri)) {
        launched = await launchUrl(uri);
      }
    } catch (_) {
      launched = false;
    }
    if (!launched) {
      await Clipboard.setData(ClipboardData(text: phone));
      if (!mounted) return;
      showToast(HelpL10n.phoneCopiedToast(phone, isEn));
    }
  }

  Future<void> _handleSendClue(HelpPost post, bool isEn) async {
    final ok = await ref.read(helpControllerProvider.notifier).sendClue(post.id);
    if (!mounted || !ok) return;
    showToast(HelpL10n.clueSentToast(post.title(isEn), isEn));
  }

  void _handlePrimaryAction(HelpPost post, bool isEn) {
    final msg = switch (post.category) {
      HelpCategory.found => isEn
          ? 'Opened chat with ${post.ownerName(isEn)} to verify cat'
          : 'เปิดแชตติดต่อ${post.ownerName(isEn)}เพื่อยืนยันตัวแมวแล้ว',
      HelpCategory.helpRequest => isEn
          ? 'Thank you for supporting ${post.title(isEn)}'
          : 'ขอบคุณที่ร่วมส่งกำลังใจให้เคส "${post.title(isEn)}"',
      HelpCategory.adoption || HelpCategory.foster => isEn
          ? 'Sent adoption/foster inquiry to ${post.ownerName(isEn)}'
          : 'ส่งคำขอรับอุปการะถึง${post.ownerName(isEn)}แล้ว',
      HelpCategory.lost => '',
    };
    if (msg.isNotEmpty) {
      showToast(msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(helpControllerProvider);
    final ctrl = ref.read(helpControllerProvider.notifier);
    final isEn = ref.watch(appLocaleProvider) == 'en';
    final snapshot = state.snapshot;

    return ColoredBox(
      color: const Color(0xFFFCF9F6),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                _HelpHeader(
                  title: HelpL10n.pageTitle(isEn),
                  onOpenFilter: () => showHelpFilterSheet(
                    context: context,
                    radiusKm: state.radiusKm,
                    notifyNearbyPosts: state.notifyNearbyPosts,
                    isEn: isEn,
                    onSelectRadius: ctrl.setRadiusKm,
                    onToggleNotify: ctrl.setNotifyNearbyPosts,
                  ),
                ),
                _HelpMainTabs(
                  activeTab: state.mainTab,
                  isEn: isEn,
                  onSelect: ctrl.selectMainTab,
                ),
                Expanded(
                  child: _buildBody(
                    context: context,
                    state: state,
                    ctrl: ctrl,
                    isEn: isEn,
                  ),
                ),
              ],
            ),
            // ปุ่มลอยด้านล่าง: 🚨 ฉุกเฉิน (ซ้าย) และ + สร้างประกาศ (ขวา)
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (snapshot != null)
                    _EmergencyFab(
                      label: HelpL10n.emergencyButton(isEn),
                      hint: HelpL10n.emergencyBannerHint(isEn),
                      onTap: () => showHelpEmergencyModal(
                        context: context,
                        symptoms: snapshot.symptoms,
                        hospital: snapshot.hospital,
                        isEn: isEn,
                        onCallPhone: (phone) =>
                            _callEmergencyPhone(phone, isEn),
                        onNavigateQuery: (placeName) async {
                          final query = Uri.encodeComponent(placeName);
                          final uri = Uri.parse(
                            'https://www.google.com/maps/search/?api=1&query=$query',
                          );
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        },
                        onViewOnMap: () => context.go('/nearby'),
                        onAskCatAi: () => context.go('/cat-ai'),
                      ),
                    ),
                  const Spacer(),
                  _CreatePostFab(
                    label: HelpL10n.createPostButton(isEn),
                    onTap: () => showCreateHelpPostFlow(
                      context: context,
                      isEn: isEn,
                      onSubmit: ctrl.createPost,
                      onToast: showToast,
                    ),
                  ),
                ],
              ),
            ),
            if (toastMessage != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 78,
                child: Center(child: ToastPill(message: toastMessage!)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required HelpState state,
    required HelpController ctrl,
    required bool isEn,
  }) {
    if (state.isLoading && state.snapshot == null) {
      return const HelpSkeleton();
    }

    if (state.errorMessage != null && state.snapshot == null) {
      return ErrorView(
        title: HelpL10n.loadErrorTitle(isEn),
        message: state.errorMessage!,
        actionLabel: HelpL10n.retry(isEn),
        onRetry: ctrl.load,
      );
    }

    final posts = state.visiblePosts;
    final snapshot = state.snapshot;

    if (state.mainTab == HelpMainTab.myPosts && snapshot != null) {
      final totalDonated = snapshot.rescueRecords.fold<int>(
        0,
        (sum, r) => sum + r.amountBaht,
      );
      if (_showMyRescueHistory) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            InkWell(
              onTap: () => setState(() => _showMyRescueHistory = false),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.chevronLeft,
                      size: 18,
                      color: Color(0xFF3D2314),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      HelpL10n.tabMyPosts(isEn),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3D2314),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text.rich(
              TextSpan(
                text: '${HelpL10n.myRescueHistoryBtn(isEn)} ',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C1810),
                ),
                children: [
                  TextSpan(
                    text: isEn
                        ? '· Total donated ฿$totalDonated'
                        : '· บริจาครวม ฿$totalDonated',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isEn ? 'Cats I helped' : 'แมวที่ฉันช่วย',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C1810),
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                setState(() => _showMyRescueHistory = false);
                ctrl.selectMainTab(HelpMainTab.nearby);
                ctrl.selectCategory(HelpCategory.helpRequest);
              },
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFF0E9E4)),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/help/injured.jpg',
                        width: 54,
                        height: 54,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEn ? '“Injured Tabby”' : '“ลายสลิดขาเจ็บ”',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2C1810),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isEn ? 'Donated ฿100' : 'บริจาค ฿100',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: const LinearProgressIndicator(
                                    value: 400 / 2500,
                                    minHeight: 5,
                                    backgroundColor: Color(0xFFE6D9C8),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF9C735B),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '฿400 / ฿2,500',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      LucideIcons.chevronRight,
                      size: 18,
                      color: AppColors.muted,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFF0E9E4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEn ? 'Rescue records' : 'บันทึกการช่วยเหลือ',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2C1810),
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final rec in snapshot.rescueRecords)
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: 28,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Positioned.fill(
                                  child: Center(
                                    child: Container(
                                      width: 1.5,
                                      color: AppColors.line2,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFEF3C7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    LucideIcons.handHeart,
                                    size: 13,
                                    color: Color(0xFF92400E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFCF9F6),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          rec.title(isEn),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF2C1810),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text.rich(
                                          TextSpan(
                                            text: '${rec.type(isEn)} ',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.muted,
                                            ),
                                            children: [
                                              if (rec.amountBaht > 0)
                                                TextSpan(
                                                  text: '฿${rec.amountBaht}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF991B1B),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    rec.date(isEn),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      }

      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
        children: [
          if (posts.isEmpty)
            _HelpEmptyView(
              isMyPosts: true,
              isEn: isEn,
              onResetFilters: ctrl.clearCategory,
            )
          else
            for (final post in posts) ...[
              _MyPostCompactCard(
                post: post,
                isEn: isEn,
                onManage: () => showManageHelpPostSheet(
                  context: context,
                  post: post,
                  isEn: isEn,
                  onChangeStatus: (nextStatus) async {
                    await ctrl.updatePostStatus(post.id, nextStatus);
                    if (!mounted) return;
                    showToast(HelpL10n.statusUpdatedToast(isEn));
                  },
                  onToggleDonationClosed: (closed) async {
                    await ctrl.setDonationClosed(post.id, closed);
                    if (!mounted) return;
                    showToast(
                      closed
                          ? (isEn
                                ? 'Donations closed'
                                : 'ปิดรับบริจาคเรียบร้อยแล้ว')
                          : (isEn
                                ? 'Donations reopened'
                                : 'เปิดรับบริจาคอีกครั้งแล้ว'),
                    );
                  },
                  onEdit: (t, s, l) async {
                    await ctrl.updatePostContent(
                      post.id,
                      title: t,
                      summary: s,
                      location: l,
                    );
                    if (!mounted) return;
                    showToast(HelpL10n.postUpdatedToast(isEn));
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          InkWell(
            onTap: () => setState(() => _showMyRescueHistory = true),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF0E9E4)),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.heartHandshake,
                    size: 22,
                    color: Color(0xFF3D2314),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          HelpL10n.myRescueHistoryBtn(isEn),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2C1810),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isEn
                              ? '${snapshot.rescueRecords.length} cats helped · Donated ฿$totalDonated'
                              : 'แมวที่ช่วย ${snapshot.rescueRecords.length} ตัว · บริจาครวม ฿$totalDonated',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: AppColors.muted,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        const SizedBox(height: 8),
        HelpCategoryChips(
          selectedCategory: state.selectedCategory,
          totalCount: HelpCategory.values.fold<int>(
            0,
            (sum, c) => sum + state.countByCategory(c),
          ),
          countFor: state.countByCategory,
          isEn: isEn,
          onSelectAll: () => ctrl.selectCategory(null),
          onToggle: ctrl.selectCategory,
        ),
        Expanded(
          child: posts.isEmpty
              ? _HelpEmptyView(
                  isMyPosts: false,
                  isEn: isEn,
                  onResetFilters: ctrl.clearCategory,
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: posts.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == posts.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          HelpL10n.safetyFootnote(isEn),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8C7D75),
                          ),
                        ),
                      );
                    }
                    final post = posts[index];
                    return HelpPostCard(
                      post: post,
                      isExpanded: state.expandedPostIds.contains(post.id),
                      isEn: isEn,
                      onToggleExpand: () => ctrl.toggleExpanded(post.id),
                      onSendClue: () => _handleSendClue(post, isEn),
                      onPrimaryAction: () => _handlePrimaryAction(post, isEn),
                      onShare: () => showHelpShareSheet(
                        context: context,
                        post: post,
                        isEn: isEn,
                        onToast: showToast,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _HelpHeader extends StatelessWidget {
  const _HelpHeader({required this.title, required this.onOpenFilter});

  final String title;
  final VoidCallback onOpenFilter;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C1810),
            ),
          ),
          Positioned(
            right: 8,
            child: IconButton(
              onPressed: onOpenFilter,
              tooltip: 'ตั้งค่าช่วยเหลือ',
              icon: const Icon(
                LucideIcons.settings2,
                size: 21,
                color: Color(0xFF3D2314),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpMainTabs extends StatelessWidget {
  const _HelpMainTabs({
    required this.activeTab,
    required this.isEn,
    required this.onSelect,
  });

  final HelpMainTab activeTab;
  final bool isEn;
  final ValueChanged<HelpMainTab> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _MainTabItem(
              label: HelpL10n.tabNearby(isEn),
              active: activeTab == HelpMainTab.nearby,
              onTap: () => onSelect(HelpMainTab.nearby),
            ),
          ),
          Expanded(
            child: _MainTabItem(
              label: HelpL10n.tabMyPosts(isEn),
              active: activeTab == HelpMainTab.myPosts,
              onTap: () => onSelect(HelpMainTab.myPosts),
            ),
          ),
        ],
      ),
    );
  }
}

class _MainTabItem extends StatelessWidget {
  const _MainTabItem({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? const Color(0xFF3D2314) : AppColors.muted,
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 2.5,
            width: active ? 76 : 0,
            decoration: BoxDecoration(
              color: active ? const Color(0xFF3D2314) : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}

class _MyPostCompactCard extends StatelessWidget {
  const _MyPostCompactCard({
    required this.post,
    required this.isEn,
    required this.onManage,
  });

  final HelpPost post;
  final bool isEn;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final badgeTheme = helpCategoryColors(post.category);
    final donation = post.donation;
    final isClosed = donation?.isClosed ?? false;

    return InkWell(
      onTap: onManage,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF0E9E4)),
          boxShadow: [
            BoxShadow(
              color: AppColors.text.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                post.imageAsset,
                width: 58,
                height: 58,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: badgeTheme.bg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          post.category == HelpCategory.helpRequest
                              ? HelpL10n.categoryFullLabel(post.category, isEn)
                              : HelpL10n.categoryLabel(post.category, isEn),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: badgeTheme.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          post.title(isEn),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2C1810),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isClosed
                        ? '${HelpL10n.donateClosed(isEn)} · ${post.timeAgo(isEn)}'
                        : (donation != null &&
                                  donation.raisedBaht >= donation.targetBaht
                              ? (isEn
                                    ? 'Target reached · ${post.timeAgo(isEn)}'
                                    : 'ครบเป้าแล้ว · ${post.timeAgo(isEn)}')
                              : '${HelpL10n.statusLabel(post.status, isEn)} · ${post.timeAgo(isEn)}'),
                    style: const TextStyle(fontSize: 12, color: AppColors.muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (donation != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: donation.progress,
                              minHeight: 5,
                              backgroundColor: const Color(0xFFE6D9C8),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isClosed
                                    ? const Color(0xFFCDBFB0)
                                    : const Color(0xFF63C7A6),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isClosed) ...[
                          const Icon(
                            LucideIcons.lock,
                            size: 11,
                            color: AppColors.muted,
                          ),
                          const SizedBox(width: 3),
                        ],
                        Text(
                          '฿${donation.raisedBaht} / ฿${donation.targetBaht}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmergencyFab extends StatelessWidget {
  const _EmergencyFab({
    required this.label,
    required this.hint,
    required this.onTap,
  });

  final String label;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label - $hint',
      child: Material(
        key: const Key('help-emergency-fab'),
        color: const Color(0xFFC8372D),
        shape: const CircleBorder(),
        elevation: 4,
        shadowColor: const Color(0x40C8372D),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: const SizedBox(
            width: 46,
            height: 46,
            child: Center(
              child: Icon(
                LucideIcons.siren,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CreatePostFab extends StatelessWidget {
  const _CreatePostFab({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFEF3EB),
      borderRadius: BorderRadius.circular(999),
      elevation: 4,
      shadowColor: AppColors.text.withValues(alpha: 0.14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFEEDFD5), width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.plus,
                size: 18,
                color: Color(0xFF3D2314),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3D2314),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpEmptyView extends StatelessWidget {
  const _HelpEmptyView({
    required this.isMyPosts,
    required this.isEn,
    required this.onResetFilters,
  });

  final bool isMyPosts;
  final bool isEn;
  final VoidCallback onResetFilters;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.heartHandshake,
              size: 44,
              color: AppColors.muted,
            ),
            const SizedBox(height: 12),
            Text(
              isMyPosts
                  ? HelpL10n.emptyMyPostsTitle(isEn)
                  : HelpL10n.emptyNearbyTitle(isEn),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isMyPosts
                  ? HelpL10n.emptyMyPostsSubtitle(isEn)
                  : HelpL10n.emptyNearbySubtitle(isEn),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            if (!isMyPosts) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onResetFilters,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF3D2314),
                  side: const BorderSide(color: AppColors.btnBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(HelpL10n.resetFilters(isEn)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
