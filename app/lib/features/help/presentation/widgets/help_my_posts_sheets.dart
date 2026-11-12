import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/help_data.dart';
import 'help_l10n.dart';
import 'help_post_card.dart';

/// ชีตจัดการประกาศของฉัน — ตรงตามเว็บจริง (รายชื่อผู้ใจดี / ดูแบบที่คนอื่นเห็นแบบกางในชีต / ปิด-เปิดรับบริจาค / แก้ไขประกาศ)
Future<void> showManageHelpPostSheet({
  required BuildContext context,
  required HelpPost post,
  required bool isEn,
  required ValueChanged<HelpPostStatus> onChangeStatus,
  required ValueChanged<bool> onToggleDonationClosed,
  required Future<void> Function(String title, String summary, String location)
      onEdit,
}) {
  final donation = post.donation;
  final isGoalReached =
      donation != null && donation.raisedBaht >= donation.targetBaht;
  final isDonationClosed = donation?.isClosed ?? false;
  const sampleDonors = [
    (name: 'noon.mochi', amount: '฿1,000'),
    (name: 'maew.vetnote', amount: '฿800'),
    (name: 'tonkla_meow', amount: '฿350'),
    (name: 'ผู้ใจดี (ไม่แสดงชื่อ)', amount: '฿1,000'),
  ];

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.sheetBarrier,
    builder: (sheetCtx) {
      var showPublicPreview = false;

      return StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.9,
          ),
          decoration: const BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(ctx).viewPadding.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.line2,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        post.imageAsset,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEn
                                ? 'Manage “${post.title(isEn)}”'
                                : 'จัดการประกาศ “${post.title(isEn)}”',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2C1810),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isEn
                                ? 'Visible only to you · ${post.timeAgo(isEn)}'
                                : 'เห็นเฉพาะคุณ · ${post.timeAgo(isEn)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (isGoalReached && !isDonationClosed) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.partyPopper,
                        size: 16,
                        color: Color(0xFF0F766E),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          isEn
                              ? 'Target reached! You can close donations now.'
                              : 'ครบเป้าแล้ว ปิดรับบริจาคได้เลย',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F766E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (donation != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCF9F6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEn
                              ? 'All ${sampleDonors.length} supporters · ฿${donation.raisedBaht}'
                              : 'ผู้ใจดีทั้งหมด ${sampleDonors.length} คน · ฿${donation.raisedBaht}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2C1810),
                          ),
                        ),
                        const SizedBox(height: 10),
                        for (var i = 0; i < sampleDonors.length; i++) ...[
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  sampleDonors[i].name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.text2,
                                  ),
                                ),
                              ),
                              Text(
                                sampleDonors[i].amount,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2C1810),
                                ),
                              ),
                            ],
                          ),
                          if (i < sampleDonors.length - 1)
                            const SizedBox(height: 6),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                // ปุ่ม "ดูแบบที่คนอื่นเห็น" — กางการ์ดตัวอย่างภายในชีตเหมือนเว็บจริง
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () => setModalState(
                          () => showPublicPreview = !showPublicPreview,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  isEn
                                      ? 'View as others see it'
                                      : 'ดูแบบที่คนอื่นเห็น',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2C1810),
                                  ),
                                ),
                              ),
                              Icon(
                                showPublicPreview
                                    ? LucideIcons.chevronDown
                                    : LucideIcons.chevronRight,
                                size: 18,
                                color: AppColors.muted,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (showPublicPreview)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                          child: HelpPostCard(
                            post: post,
                            isExpanded: false,
                            isEn: isEn,
                            onToggleExpand: () {},
                            onSendClue: () {},
                            onPrimaryAction: () {},
                            onShare: () {},
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (donation != null) ...[
                  _ManageCardRow(
                    icon: isDonationClosed
                        ? LucideIcons.lockOpen
                        : LucideIcons.lock,
                    iconBg: isDonationClosed
                        ? const Color(0xFFDDF2EE)
                        : const Color(0xFFFEF3C7),
                    iconColor: isDonationClosed
                        ? const Color(0xFF0F766E)
                        : const Color(0xFFB45309),
                    title: isDonationClosed
                        ? (isEn ? 'Reopen donations' : 'เปิดรับบริจาคอีกครั้ง')
                        : (isEn ? 'Close donations' : 'ปิดรับบริจาค'),
                    subtitle: isDonationClosed
                        ? (isEn
                              ? 'Allow people to donate more'
                              : 'ให้คนบริจาคเพิ่มได้')
                        : (isEn
                              ? 'Target reached · Ready to close'
                              : 'ครบเป้าแล้ว ปิดได้เลย'),
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      onToggleDonationClosed(!isDonationClosed);
                    },
                  ),
                  const SizedBox(height: 8),
                ] else if (post.status == HelpPostStatus.active) ...[
                  _ManageCardRow(
                    icon: LucideIcons.circleCheck,
                    iconBg: const Color(0xFFFEF3C7),
                    iconColor: const Color(0xFFB45309),
                    title: HelpL10n.markResolved(isEn),
                    subtitle:
                        isEn ? 'Mark this post as resolved' : 'ปิดสถานะประกาศนี้',
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      onChangeStatus(HelpPostStatus.resolved);
                    },
                  ),
                  const SizedBox(height: 8),
                ] else ...[
                  _ManageCardRow(
                    icon: LucideIcons.rotateCcw,
                    iconBg: const Color(0xFFDDF2EE),
                    iconColor: AppColors.ownerTeal,
                    title: HelpL10n.reopenPost(isEn),
                    subtitle: isEn
                        ? 'Reopen this help post'
                        : 'เปิดรับความช่วยเหลืออีกครั้ง',
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      onChangeStatus(HelpPostStatus.active);
                    },
                  ),
                  const SizedBox(height: 8),
                ],
                _ManageCardRow(
                  icon: LucideIcons.pencil,
                  iconBg: const Color(0xFFE0E7FF),
                  iconColor: const Color(0xFF1D4ED8),
                  title: isEn ? 'Edit post' : 'แก้ไขประกาศ',
                  subtitle: isEn
                      ? 'Photo, details, target'
                      : 'รูป รายละเอียด เป้าหมาย',
                  onTap: () async {
                    Navigator.pop(sheetCtx);
                    if (!context.mounted) return;
                    await _showEditPostSheet(
                      context: context,
                      post: post,
                      isEn: isEn,
                      onSave: onEdit,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _ManageCardRow extends StatelessWidget {
  const _ManageCardRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2C1810),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: AppColors.muted),
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
    );
  }
}

Future<void> _showEditPostSheet({
  required BuildContext context,
  required HelpPost post,
  required bool isEn,
  required Future<void> Function(String title, String summary, String location)
      onSave,
}) {
  final titleCtrl = TextEditingController(text: post.title(isEn));
  final summaryCtrl = TextEditingController(text: post.summary(isEn));
  final locationCtrl = TextEditingController(text: post.location(isEn));

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.sheetBarrier,
    builder: (sheetCtx) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(sheetCtx).viewPadding.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line2,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              HelpL10n.editPost(isEn),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C1810),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                labelText: HelpL10n.titleAndTraitsLabel(isEn),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: summaryCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: HelpL10n.detailsLabel(isEn),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: locationCtrl,
              decoration: InputDecoration(
                labelText: HelpL10n.locationLabel(isEn),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final t = titleCtrl.text.trim();
                  final l = locationCtrl.text.trim();
                  if (t.isEmpty || l.isEmpty) return;
                  Navigator.pop(sheetCtx);
                  await onSave(t, summaryCtrl.text.trim(), l);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF3D2314),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(HelpL10n.saveChanges(isEn)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
