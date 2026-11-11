import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../domain/entities/my_cat_data.dart';
import 'my_cat_l10n.dart';

/// มุมมอง "ตัวฉัน" — โทนเขียวมินต์ (#0B5E58 / #D8E9E6) + กริดแมว 3 คอลัมน์ตรงตามเว็บ
class OwnerProfileView extends StatelessWidget {
  const OwnerProfileView({
    super.key,
    required this.owner,
    required this.cats,
    required this.onEditProfile,
    required this.onShareProfile,
    required this.onOpenVerification,
    required this.onOpenMessages,
    required this.onSelectCat,
    this.isEn = false,
  });

  final OwnerProfile owner;
  final List<CatProfile> cats;
  final VoidCallback onEditProfile;
  final VoidCallback onShareProfile;
  final VoidCallback onOpenVerification;
  final VoidCallback onOpenMessages;
  final ValueChanged<String> onSelectCat;
  final bool isEn;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GradientAvatar(
                source: owner.avatarSource,
                bg: owner.avatarBg,
                size: 84,
                gradientColors: const [
                  AppColors.ownerRingStart,
                  AppColors.ownerRingMid,
                  AppColors.ownerRingEnd,
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _StatColumn(
                        value: '${cats.length}',
                        label: isEn ? 'Cat' : 'แมว',
                      ),
                    ),
                    Expanded(
                      child: _StatColumn(
                        value: '${owner.followerCount}',
                        label: isEn ? 'Followers' : 'ผู้ติดตาม',
                      ),
                    ),
                    Expanded(
                      child: _StatColumn(
                        value: '${owner.helpedCount}',
                        label: isEn ? 'Help' : 'ช่วยเหลือ',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Flexible(
                child: Text(
                  MyCatL10n.ownerName(owner.displayName, isEn),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Semantics(
                button: true,
                label: isEn
                    ? 'Verified · see details'
                    : 'ยืนยันตัวตนแล้ว ดูรายละเอียด',
                child: InkWell(
                  onTap: onOpenVerification,
                  borderRadius: BorderRadius.circular(999),
                  child: const SizedBox(
                    width: 28,
                    height: 28,
                    child: Center(
                      child: Icon(
                        LucideIcons.badgeCheck,
                        size: 20,
                        color: AppColors.ownerTeal,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (owner.bio.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              MyCatL10n.ownerBio(owner.bio, isEn),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.ownerTeal,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            isEn
                ? '@${owner.handle} · Member since ${MyCatL10n.memberSince(owner.memberSince, true)}'
                : '@${owner.handle} · สมาชิกตั้งแต่ ${owner.memberSince}',
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          if (owner.privacy.showDistrict && owner.district.isNotEmpty) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(
                  LucideIcons.mapPin,
                  size: 13,
                  color: AppColors.muted,
                ),
                const SizedBox(width: 4),
                Text(
                  MyCatL10n.ownerDistrict(owner.district, isEn),
                  style: const TextStyle(fontSize: 13, color: AppColors.muted),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _OwnerActionButton(
                  label: isEn ? 'Share profile' : 'แชร์โปรไฟล์',
                  icon: LucideIcons.share2,
                  onTap: onShareProfile,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MessagesActionButton(
                  unreadCount: owner.unreadMessagesCount,
                  isEn: isEn,
                  onTap: onOpenMessages,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onEditProfile,
              icon: const Icon(
                LucideIcons.notebookPen,
                size: 16,
                color: AppColors.ownerTeal,
              ),
              label: Text(
                isEn ? 'Edit profile' : 'แก้ไขโปรไฟล์',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ownerTeal,
                ),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44),
                backgroundColor: AppColors.card,
                side: const BorderSide(
                  color: AppColors.ownerTealRing,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isEn
                ? 'My cats ${cats.length} cats'
                : 'แมวของฉัน ${cats.length} ตัว',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 10),
          if (cats.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.ownerTealBorder),
              ),
              child: Text(
                isEn
                    ? 'No cats yet. Tap "+ Add cat" above to create a profile'
                    : 'ยังไม่มีแมวในบัญชี กด "+ เพิ่มแมว" ด้านบนเพื่อสร้างโปรไฟล์',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.muted),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.84,
              ),
              itemCount: cats.length,
              itemBuilder: (context, index) => _MyCatGridCard(
                cat: cats[index],
                isEn: isEn,
                onTap: () => onSelectCat(cats[index].id),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _OwnerActionButton extends StatelessWidget {
  const _OwnerActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16, color: AppColors.text),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          backgroundColor: AppColors.card,
          side: const BorderSide(color: AppColors.ownerTealBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _MessagesActionButton extends StatelessWidget {
  const _MessagesActionButton({
    required this.unreadCount,
    required this.onTap,
    this.isEn = false,
  });

  final int unreadCount;
  final VoidCallback onTap;
  final bool isEn;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'ข้อความ $unreadCount รายการยังไม่อ่าน',
      child: Material(
        color: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.ownerTealBorder),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      LucideIcons.messageCircleHeart,
                      size: 16,
                      color: AppColors.text,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isEn ? 'Messages' : 'ข้อความ',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: 8,
                    right: 10,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.heart,
                        border: Border.all(color: AppColors.card, width: 2),
                      ),
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

class _MyCatGridCard extends StatelessWidget {
  const _MyCatGridCard({
    required this.cat,
    required this.onTap,
    this.isEn = false,
  });

  final CatProfile cat;
  final VoidCallback onTap;
  final bool isEn;

  @override
  Widget build(BuildContext context) {
    final name = MyCatL10n.catName(cat.name, isEn);
    final breed = MyCatL10n.breed(cat.breed, isEn);
    return Semantics(
      button: true,
      label: '$name $breed',
      child: Material(
        color: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.ownerTealBorder),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppAvatar(source: cat.avatarSource, bg: cat.avatarBg, size: 62),
                const SizedBox(height: 6),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  breed,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.muted,
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
