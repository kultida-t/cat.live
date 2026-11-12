import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/social_brand_icons.dart';
import '../../domain/entities/help_data.dart';
import 'help_category_chips.dart';
import 'help_l10n.dart';

/// ชีตแชร์ประกาศช่วยเหลือ — การ์ดพรีวิว + LINE/FB/IG/ส่งในแอป + คัดลอกลิงก์ + แชร์ผ่านแอปอื่น
Future<void> showHelpShareSheet({
  required BuildContext context,
  required HelpPost post,
  required bool isEn,
  required ValueChanged<String> onToast,
}) {
  final shareUrl = 'https://www.xn--y3cm0f.live/help?post=${post.id}';
  final shareText =
      '${HelpL10n.categoryFullLabel(post.category, isEn)}: ${post.title(isEn)} (${post.location(isEn)}) — $shareUrl';
  final badgeTheme = helpCategoryColors(post.category);

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.sheetBarrier,
    builder: (sheetCtx) => Container(
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
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.line2,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  isEn ? 'Share post' : 'แชร์ประกาศ',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C1810),
                  ),
                ),
              ),
              InkWell(
                onTap: () => Navigator.pop(sheetCtx),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: AppColors.soft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.x,
                    size: 18,
                    color: AppColors.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // การ์ดพรีวิวประกาศที่จะแชร์
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFCF9F6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    post.imageAsset,
                    width: 54,
                    height: 54,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                          HelpL10n.categoryLabel(post.category, isEn),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: badgeTheme.ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        post.title(isEn),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2C1810),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${post.location(isEn)} · ${HelpL10n.distanceText(post.distanceKm, isEn)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // แถว 4 ช่องทางแชร์
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ShareChannelButton(
                icon: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.brandLine,
                    shape: BoxShape.circle,
                  ),
                  child: const LineLogoIcon(size: 28),
                ),
                label: 'LINE',
                onTap: () {
                  Navigator.pop(sheetCtx);
                  SharePlus.instance.share(ShareParams(text: shareText));
                },
              ),
              _ShareChannelButton(
                icon: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.brandFacebook,
                    shape: BoxShape.circle,
                  ),
                  child: const FacebookLogoIcon(size: 26),
                ),
                label: 'Facebook',
                onTap: () {
                  Navigator.pop(sheetCtx);
                  SharePlus.instance.share(ShareParams(text: shareText));
                },
              ),
              _ShareChannelButton(
                icon: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                      colors: [
                        Color(0xFFF58529),
                        Color(0xFFDD2A7B),
                        Color(0xFF8134AF),
                      ],
                    ),
                  ),
                  child: const InstagramLogoIcon(size: 24),
                ),
                label: 'Instagram',
                onTap: () {
                  Navigator.pop(sheetCtx);
                  SharePlus.instance.share(ShareParams(text: shareText));
                },
              ),
              _ShareChannelButton(
                icon: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.btn,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.btnBorder),
                  ),
                  child: const Icon(
                    LucideIcons.send,
                    size: 20,
                    color: AppColors.ink,
                  ),
                ),
                label: isEn ? 'In-app' : 'ส่งในแอป',
                onTap: () {
                  Navigator.pop(sheetCtx);
                  onToast(
                    isEn
                        ? 'Shared post in Cat.live chat'
                        : 'ส่งประกาศให้เพื่อนในแอปแล้ว',
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // กล่องลิงก์ + ปุ่มคัดลอก
          Container(
            padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFCF9F6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.link2, size: 16, color: AppColors.muted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    shareUrl,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: shareUrl));
                    if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                    onToast(isEn ? 'Link copied' : 'คัดลอกลิงก์ประกาศแล้ว');
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.btn,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.btnBorder),
                    ),
                    child: Text(
                      isEn ? 'Copy' : 'คัดลอก',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // ปุ่มแชร์ผ่านแอปอื่น
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(sheetCtx);
                SharePlus.instance.share(ShareParams(text: shareText));
              },
              icon: const Icon(LucideIcons.share2, size: 17),
              label: Text(isEn ? 'Share via other apps' : 'แชร์ผ่านแอปอื่น'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.text,
                side: const BorderSide(color: AppColors.line2),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isEn
                ? 'Help spread the word so cats get help faster'
                : 'ช่วยกระจายข่าว ให้น้องได้รับความช่วยเหลือเร็วขึ้น',
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ],
      ),
    ),
  );
}

class _ShareChannelButton extends StatelessWidget {
  const _ShareChannelButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
