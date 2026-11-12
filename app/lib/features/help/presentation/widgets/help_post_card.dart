import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/help_data.dart';
import 'help_category_chips.dart';
import 'help_l10n.dart';

/// การ์ดประกาศช่วยเหลือแมว — รองรับกางรายละเอียดแบบ Inline Expansion
class HelpPostCard extends StatelessWidget {
  const HelpPostCard({
    super.key,
    required this.post,
    required this.isExpanded,
    required this.isEn,
    required this.onToggleExpand,
    required this.onSendClue,
    required this.onPrimaryAction,
    required this.onShare,
    this.showManageButton = false,
    this.onManage,
  });

  final HelpPost post;
  final bool isExpanded;
  final bool isEn;
  final VoidCallback onToggleExpand;
  final VoidCallback onSendClue;
  final VoidCallback onPrimaryAction;
  final VoidCallback onShare;
  final bool showManageButton;
  final VoidCallback? onManage;

  @override
  Widget build(BuildContext context) {
    final badgeTheme = helpCategoryColors(post.category);
    final donation = post.donation;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0E9E4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.text.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: post.imageFilePath != null
                    ? Image.file(
                        File(post.imageFilePath!),
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                      )
                    : Image.asset(
                        post.imageAsset,
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 96,
                          height: 96,
                          color: AppColors.media,
                          alignment: Alignment.center,
                          child: const Icon(
                            LucideIcons.cat,
                            size: 28,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3,
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
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: badgeTheme.ink,
                            ),
                          ),
                        ),
                        if (post.isUrgent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              HelpL10n.urgentBadge(isEn),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF991B1B),
                              ),
                            ),
                          ),
                        if (post.status != HelpPostStatus.active)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: post.status == HelpPostStatus.resolved
                                  ? const Color(0xFFDCFCE7)
                                  : AppColors.soft,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              HelpL10n.statusLabel(post.status, isEn),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: post.status == HelpPostStatus.resolved
                                    ? const Color(0xFF166534)
                                    : AppColors.muted,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            post.title(isEn),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2C1810),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (showManageButton && onManage != null)
                          TextButton(
                            onPressed: onManage,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              HelpL10n.managePost(isEn),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      post.summary(isEn),
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.38,
                        color: AppColors.text2,
                      ),
                      maxLines: isExpanded ? null : 2,
                      overflow: isExpanded ? null : TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.mapPin,
                          size: 13,
                          color: Color(0xFF7E6E65),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${post.location(isEn)} · ${HelpL10n.distanceText(post.distanceKm, isEn)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7E6E65),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.clock,
                          size: 13,
                          color: Color(0xFF7E6E65),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            post.timeAgo(isEn),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7E6E65),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (donation != null) ...[
            const SizedBox(height: 12),
            _DonationProgressBlock(donation: donation, isEn: isEn),
          ],
          if (isExpanded) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFCF9F6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.detailTraits(isEn),
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: AppColors.text,
                    ),
                  ),
                  if (post.secretMark(isEn) != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          LucideIcons.shieldCheck,
                          size: 15,
                          color: Color(0xFF92400E),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            post.secretMark(isEn)!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        LucideIcons.messageCircle,
                        size: 15,
                        color: AppColors.ownerTeal,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          post.contactInfo(isEn),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ownerTeal,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    HelpL10n.postedByText(post.postedBy, isEn),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _buildActionButton(),
              const SizedBox(width: 8),
              InkWell(
                onTap: onShare,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.page,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.line2),
                  ),
                  child: const Icon(
                    LucideIcons.share2,
                    size: 16,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: onToggleExpand,
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isExpanded
                            ? HelpL10n.collapseDetails(isEn)
                            : HelpL10n.viewDetails(isEn),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF3D2314),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        isExpanded
                            ? LucideIcons.chevronUp
                            : LucideIcons.chevronRight,
                        size: 16,
                        color: const Color(0xFF3D2314),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    final theme = helpCategoryColors(post.category);

    if (post.category == HelpCategory.lost) {
      final sent = post.clueSent;
      return InkWell(
        onTap: sent ? null : onSendClue,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: sent ? AppColors.soft : theme.bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: sent ? AppColors.line2 : theme.border,
            ),
          ),
          child: Text(
            sent ? HelpL10n.clueSent(isEn) : HelpL10n.sendClue(isEn),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: sent ? AppColors.muted : theme.ink,
            ),
          ),
        ),
      );
    }

    final actionLabel = switch (post.category) {
      HelpCategory.found => HelpL10n.contactFinder(isEn),
      HelpCategory.adoption => HelpL10n.interestedAdopt(isEn),
      HelpCategory.foster => HelpL10n.fosterAction(isEn),
      HelpCategory.helpRequest =>
        HelpL10n.supportCase(post.shortName(isEn), isEn),
      HelpCategory.lost => '',
    };

    return InkWell(
      onTap: onPrimaryAction,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: theme.bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: theme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (post.category == HelpCategory.helpRequest) ...[
              Icon(LucideIcons.handHeart, size: 15, color: theme.ink),
              const SizedBox(width: 6),
            ],
            Text(
              actionLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: theme.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonationProgressBlock extends StatelessWidget {
  const _DonationProgressBlock({
    required this.donation,
    required this.isEn,
  });

  final DonationInfo donation;
  final bool isEn;

  @override
  Widget build(BuildContext context) {
    final closed = donation.isClosed;
    final goalReached = !closed && donation.raisedBaht >= donation.targetBaht;
    final supporters = donation.supportersText(isEn);
    final donorCount = donation.donorCount > 0
        ? donation.donorCount
        : donation.donorAvatars.length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5EFE8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.handHeart,
                size: 15,
                color: Color(0xFF5E4636),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  donation.purpose(isEn),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4A3428),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (closed)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.lock,
                      size: 12,
                      color: Color(0xFF7A6255),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      HelpL10n.donateClosed(isEn),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7A6255),
                      ),
                    ),
                  ],
                )
              else if (goalReached)
                Text(
                  isEn ? 'Target reached' : 'ครบเป้าแล้ว',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F766E),
                  ),
                )
              else
                Text(
                  HelpL10n.remainingBahtText(
                    _formatBaht(donation.remainingBaht),
                    isEn,
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF5E4636),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: donation.progress,
              minHeight: 7,
              backgroundColor: const Color(0xFFE6D9C8),
              valueColor: AlwaysStoppedAnimation<Color>(
                goalReached
                    ? const Color(0xFF63C7A6)
                    : const Color(0xFF9C735B),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '฿${_formatBaht(donation.raisedBaht)} / ฿${_formatBaht(donation.targetBaht)} · ${donation.percent}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3D2314),
                ),
              ),
              const Spacer(),
              if (donorCount > 0)
                Text(
                  HelpL10n.donorsCountText(donorCount, isEn),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7A6255),
                  ),
                ),
            ],
          ),
          if (donation.donorAvatars.isNotEmpty || supporters != null) ...[
            const SizedBox(height: 8),
            const Divider(height: 1, color: Color(0xFFE6D9C8)),
            const SizedBox(height: 8),
            Row(
              children: [
                if (donation.donorAvatars.isNotEmpty) ...[
                  SizedBox(
                    height: 22,
                    width: 14.0 * (donation.donorAvatars.length - 1) + 22,
                    child: Stack(
                      children: [
                        for (var i = 0; i < donation.donorAvatars.length; i++)
                          Positioned(
                            left: i * 14.0,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                                image: DecorationImage(
                                  image: AssetImage(donation.donorAvatars[i]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (supporters != null)
                  Expanded(
                    child: Text(
                      supporters,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF7A6255),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatBaht(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final revIndex = s.length - i;
      buf.write(s[i]);
      if (revIndex > 1 && revIndex % 3 == 1) {
        buf.write(',');
      }
    }
    return buf.toString();
  }
}
