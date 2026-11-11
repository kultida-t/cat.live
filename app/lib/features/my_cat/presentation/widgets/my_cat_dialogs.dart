import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/toast_pill.dart';
import '../../domain/entities/my_cat_data.dart';
import 'my_cat_l10n.dart';
import 'sheet_chrome.dart';

enum MyCatCreateAction { photo, video, camera, healthRecord, addCat }

/// เมนู "สร้าง" มุมซ้ายบน — ปรับข้อความตามแคปซูลแมวหรือมุมมองตัวฉัน
Future<MyCatCreateAction?> showMyCatCreateSheet(
  BuildContext context, {
  required String? activeCatName,
  bool isEn = false,
}) {
  final displayCat = activeCatName != null
      ? MyCatL10n.catName(activeCatName, isEn)
      : null;
  final photoSub = displayCat != null
      ? (isEn
            ? 'Added to the album of $displayCat'
            : 'เพิ่มเข้าอัลบั้มของ$displayCat')
      : (isEn
            ? 'Choose a photo and cat to upload'
            : 'เลือกรูปและแมวที่ต้องการอัปโหลด');
  final videoSub = displayCat != null
      ? (isEn ? 'Short clip of $displayCat' : 'คลิปสั้นของ$displayCat')
      : (isEn ? 'Choose a cat for a short clip' : 'เลือกแมวเพื่อเพิ่มคลิปสั้น');

  final rows = [
    (
      action: MyCatCreateAction.photo,
      icon: LucideIcons.imagePlus,
      title: isEn ? 'Photos' : 'รูปภาพ',
      subtitle: photoSub,
    ),
    (
      action: MyCatCreateAction.video,
      icon: LucideIcons.clapperboard,
      title: isEn ? 'Video' : 'วิดีโอ',
      subtitle: videoSub,
    ),
    (
      action: MyCatCreateAction.camera,
      icon: LucideIcons.camera,
      title: isEn ? 'Take photo' : 'ถ่ายรูป',
      subtitle: isEn ? 'Open camera' : 'เปิดกล้อง',
    ),
    (
      action: MyCatCreateAction.healthRecord,
      icon: LucideIcons.heartPulse,
      title: isEn ? 'Health log' : 'บันทึกสุขภาพ',
      subtitle: isEn
          ? 'Vaccines, symptoms, weight, documents'
          : 'วัคซีน อาการ น้ำหนัก เอกสาร',
    ),
    (
      action: MyCatCreateAction.addCat,
      icon: LucideIcons.pawPrint,
      title: isEn ? 'Add cat' : 'เพิ่มแมว',
      subtitle: isEn
          ? 'Create a new profile and Cat ID'
          : 'สร้างโปรไฟล์และ Cat ID ใหม่',
    ),
  ];

  return showMyCatSheet<MyCatCreateAction>(
    context,
    builder: (ctx) => Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isEn ? 'Create' : 'สร้าง',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: isEn ? 'Close menu' : 'ปิดเมนู',
                    child: InkWell(
                      onTap: () => Navigator.of(ctx).pop(),
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.soft,
                        ),
                        child: const Icon(
                          LucideIcons.x,
                          size: 18,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const SizedBox(height: 6),
                Semantics(
                  button: true,
                  label: '${rows[i].title} ${rows[i].subtitle}',
                  child: InkWell(
                    onTap: () => Navigator.of(ctx).pop(rows[i].action),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.settingsIconBox,
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(
                              rows[i].icon,
                              size: 20,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rows[i].title,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.text,
                                  ),
                                ),
                                Text(
                                  rows[i].subtitle,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

/// หน้า "ตั้งค่า" เต็มจอ — พื้นขาว 7 แถว + สวิตช์เขียวมินต์ + ปุ่มภาษาในแถวเดียวตรงตามเว็บ
Future<void> showMyCatSettingsSheet(
  BuildContext context, {
  required OwnerNotificationSettings initial,
  required ValueChanged<OwnerNotificationSettings> onSaveSettings,
  required VoidCallback onOpenTagDevice,
  required VoidCallback onOpenGuidelines,
  required ValueChanged<String> onShowMessage,
}) {
  return Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (ctx) => _SettingsFullScreen(
        initial: initial,
        onSaveSettings: onSaveSettings,
        onOpenTagDevice: () {
          Navigator.of(ctx).pop();
          onOpenTagDevice();
        },
        onOpenGuidelines: () {
          Navigator.of(ctx).pop();
          onOpenGuidelines();
        },
        onShowMessage: onShowMessage,
      ),
    ),
  );
}

class _SettingsFullScreen extends StatefulWidget {
  const _SettingsFullScreen({
    required this.initial,
    required this.onSaveSettings,
    required this.onOpenTagDevice,
    required this.onOpenGuidelines,
    required this.onShowMessage,
  });

  final OwnerNotificationSettings initial;
  final ValueChanged<OwnerNotificationSettings> onSaveSettings;
  final VoidCallback onOpenTagDevice;
  final VoidCallback onOpenGuidelines;
  final ValueChanged<String> onShowMessage;

  @override
  State<_SettingsFullScreen> createState() => _SettingsFullScreenState();
}

class _SettingsFullScreenState extends State<_SettingsFullScreen>
    with ToastMixin {
  late OwnerNotificationSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.initial;
  }

  @override
  void dispose() {
    disposeToast();
    super.dispose();
  }

  void _update(OwnerNotificationSettings next) {
    setState(() => _settings = next);
    widget.onSaveSettings(next);
  }

  @override
  Widget build(BuildContext context) {
    final isEn = _settings.locale == 'en';
    return Scaffold(
      backgroundColor: AppColors.card,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Text(
          isEn ? 'Settings' : 'ตั้งค่า',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        actions: [
          Semantics(
            button: true,
            label: isEn ? 'Close settings' : 'ปิดตั้งค่า',
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(LucideIcons.x, size: 20, color: AppColors.text),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 72),
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 6),
                  child: Text(
                    isEn ? 'General' : 'ทั่วไป',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
                    ),
                  ),
                ),
                _SettingsRow(
                  icon: LucideIcons.bell,
                  title: isEn ? 'Notifications' : 'การแจ้งเตือน',
                  trailing: _PillSwitch(
                    value: _settings.pushEnabled,
                    onChanged: (v) {
                      _update(_settings.copyWith(pushEnabled: v));
                      showToast(
                        v
                            ? (isEn
                                  ? 'Notifications enabled'
                                  : 'เปิดการแจ้งเตือนแล้ว')
                            : (isEn
                                  ? 'Notifications paused'
                                  : 'ปิดการแจ้งเตือนแล้ว'),
                      );
                    },
                  ),
                  onTap: () {
                    final nextVal = !_settings.pushEnabled;
                    _update(_settings.copyWith(pushEnabled: nextVal));
                    showToast(
                      nextVal
                          ? (isEn
                                ? 'Notifications enabled'
                                : 'เปิดการแจ้งเตือนแล้ว')
                          : (isEn
                                ? 'Notifications paused'
                                : 'ปิดการแจ้งเตือนแล้ว'),
                    );
                  },
                ),
                _SettingsRow(
                  icon: LucideIcons.moon,
                  title: isEn ? 'Quiet hours' : 'โหมดเงียบ',
                  subtitle: isEn
                      ? 'Mute 22:00–07:00 except emergencies'
                      : 'ไม่แจ้งเตือน 22:00–07:00 ยกเว้นเรื่องฉุกเฉิน',
                  trailing: _PillSwitch(
                    value: _settings.quietHoursEnabled,
                    onChanged: (v) {
                      _update(_settings.copyWith(quietHoursEnabled: v));
                      showToast(
                        v
                            ? (isEn
                                  ? 'Quiet hours enabled (22:00–07:00)'
                                  : 'เปิดโหมดเงียบ 22:00–07:00 แล้ว')
                            : (isEn
                                  ? 'Quiet hours disabled'
                                  : 'ปิดโหมดเงียบแล้ว'),
                      );
                    },
                  ),
                  onTap: () {
                    final nextVal = !_settings.quietHoursEnabled;
                    _update(_settings.copyWith(quietHoursEnabled: nextVal));
                    showToast(
                      nextVal
                          ? (isEn
                                ? 'Quiet hours enabled (22:00–07:00)'
                                : 'เปิดโหมดเงียบ 22:00–07:00 แล้ว')
                          : (isEn
                                ? 'Quiet hours disabled'
                                : 'ปิดโหมดเงียบแล้ว'),
                    );
                  },
                ),
                _SettingsRow(
                  icon: LucideIcons.tag,
                  title: isEn ? 'แมว.live Tag devices' : 'อุปกรณ์ แมว.live Tag',
                  subtitle: isEn
                      ? 'Battery · Sound · Pairing · Add tag'
                      : 'แบตเตอรี่ · เสียง · การเชื่อมต่อ · เพิ่มแท็ก',
                  trailing: const Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: AppColors.muted,
                  ),
                  onTap: widget.onOpenTagDevice,
                ),
                _SettingsRow(
                  icon: LucideIcons.scrollText,
                  title: isEn ? 'Community posting rules' : 'กฎการโพสต์ในชุมชน',
                  subtitle: isEn
                      ? 'Only partner brands may advertise cat food'
                      : 'อาหารแมวโฆษณาได้เฉพาะแบรนด์พาร์ทเนอร์',
                  trailing: const Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: AppColors.muted,
                  ),
                  onTap: widget.onOpenGuidelines,
                ),
                _SettingsRow(
                  icon: LucideIcons.shieldCheck,
                  title: isEn ? 'Privacy' : 'ความเป็นส่วนตัว',
                  subtitle: isEn
                      ? 'PDPA · Public Cat ID fields'
                      : 'PDPA · ข้อมูลบน Cat ID สาธารณะ',
                  trailing: const Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: AppColors.muted,
                  ),
                  onTap: () => showToast(
                    isEn
                        ? 'Privacy · Coming soon'
                        : 'ความเป็นส่วนตัว · หน้านี้กำลังพัฒนา',
                  ),
                ),
                _SettingsRow(
                  icon: LucideIcons.lifeBuoy,
                  title: isEn ? 'Help & Contact' : 'ช่วยเหลือ & ติดต่อทีม',
                  trailing: const Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: AppColors.muted,
                  ),
                  onTap: () => showToast(
                    isEn
                        ? 'Help & Contact · Coming soon'
                        : 'ช่วยเหลือ & ติดต่อทีม · หน้านี้กำลังพัฒนา',
                  ),
                ),
                _SettingsRow(
                  icon: LucideIcons.globe,
                  title: isEn ? 'Language' : 'ภาษา',
                  trailing: _LanguageSegment(
                    locale: _settings.locale,
                    onChanged: (lang) {
                      _update(_settings.copyWith(locale: lang));
                      showToast(
                        lang == 'en'
                            ? 'Switched to English'
                            : 'เปลี่ยนเป็นภาษาไทยแล้ว',
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onShowMessage(
                        isEn
                            ? 'Sign-in is coming soon · Demo account active'
                            : 'ระบบล็อกอินกำลังพัฒนา · ใช้งานด้วยบัญชีตัวอย่าง',
                      );
                    },
                    icon: const Icon(LucideIcons.logOut, size: 16),
                    label: Text(
                      isEn ? 'Sign out' : 'ออกจากระบบ',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.logoutBg,
                      foregroundColor: AppColors.logoutText,
                      side: const BorderSide(color: AppColors.logoutBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    isEn ? 'แมว.live version 0.1' : 'แมว.live เวอร์ชัน 0.1',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
            if (toastMessage != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 18,
                child: Center(child: ToastPill(message: toastMessage!)),
              ),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.trailing,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 58),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.settingsIconBox,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, size: 20, color: AppColors.text),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _PillSwitch extends StatelessWidget {
  const _PillSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 48,
        height: 28,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: value ? AppColors.ownerTealRing : AppColors.unchecked,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 160),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageSegment extends StatelessWidget {
  const _LanguageSegment({required this.locale, required this.onChanged});

  final String locale;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 36,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.settingsIconBox,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (final item in const [
            (id: 'th', label: 'ไทย'),
            (id: 'en', label: 'EN'),
          ])
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(item.id),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: locale == item.id
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: locale == item.id
                        ? const [
                            BoxShadow(
                              color: Color(0x144A3428),
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: locale == item.id
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: locale == item.id
                          ? AppColors.text
                          : AppColors.text2,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// ชีตความน่าเชื่อถือ 3/3 ขั้นตอน (เปิดจากป้าย "ยืนยันตัวตนแล้ว")
Future<void> showVerificationTrustSheet(
  BuildContext context, {
  required OwnerProfile owner,
  required VoidCallback onOpenEditProfile,
  bool isEn = false,
}) {
  final steps = owner.completedVerificationSteps;
  return showMyCatSheet<void>(
    context,
    builder: (ctx) => MyCatSheetFrame(
      title: isEn
          ? 'Trust verification $steps/3 steps'
          : 'ความน่าเชื่อถือ $steps/3 ขั้นตอน',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEn
                  ? 'Completed · the verified badge appears beside your name for donors'
                  : 'ครบแล้ว เครื่องหมายยืนยันจะแสดงข้างชื่อของคุณให้ผู้บริจาคเห็น',
              style: const TextStyle(fontSize: 14, color: AppColors.ink),
            ),
            const SizedBox(height: 14),
            _VerifyRow(
              title: isEn ? 'Phone number' : 'ยืนยันเบอร์โทร',
              verified: owner.isPhoneVerified,
            ),
            const SizedBox(height: 8),
            _VerifyRow(
              title: isEn ? 'National ID card' : 'ยืนยันตัวตนด้วยบัตรประชาชน',
              verified: owner.isIdVerified,
            ),
            const SizedBox(height: 8),
            _VerifyRow(
              title: isEn
                  ? 'Donation account · ${owner.donationAccount.maskedLabel}'
                  : 'บัญชีรับเงินบริจาค · ${owner.donationAccount.maskedLabel}',
              verified: owner.donationAccount.accountNumber.isNotEmpty,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  onOpenEditProfile();
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  backgroundColor: AppColors.btn,
                  foregroundColor: AppColors.ink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(
                      color: AppColors.btnBorder,
                      width: 1.5,
                    ),
                  ),
                ),
                child: Text(
                  isEn ? 'View / edit details' : 'ดู/แก้ไขข้อมูล',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _VerifyRow extends StatelessWidget {
  const _VerifyRow({required this.title, required this.verified});

  final String title;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.page,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Icon(
            verified ? LucideIcons.checkCircle2 : LucideIcons.circle,
            size: 18,
            color: verified ? AppColors.statusSafe : AppColors.unchecked,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
