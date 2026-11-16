import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/config/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/toast_pill.dart';
import '../../domain/entities/settings_data.dart';
import '../providers/settings_controller.dart';
import 'settings_l10n.dart';
import 'settings_shared_widgets.dart';

/// 1. ชีตจัดการประเภทการแจ้งเตือน 8 หมวด (NOTI-01) — "มีคนพบแมว" ปิดไม่ได้
Future<void> showNotificationCategoriesSheet(
  BuildContext context, {
  required void Function(String message) onToast,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _NotificationCategoriesSheet(onToast: onToast),
  );
}

class _NotificationCategoriesSheet extends ConsumerWidget {
  const _NotificationCategoriesSheet({required this.onToast});
  final void Function(String message) onToast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final isEn = ref.watch(appLocaleProvider) == 'en';
    final categories = state.data?.notificationCategories ?? const {};
    final maxHeight = MediaQuery.sizeOf(context).height * 0.82;

    return _SheetToastWrapper(
      builder: (showSheetToast) => SafeArea(
        top: false,
        child: SizedBox(
          height: maxHeight,
          child: Column(
            children: [
              _SheetHeader(
                title: SettingsL10n.notiCategoriesTitle(isEn),
                onClose: () =>
                    Navigator.of(context, rootNavigator: true).pop(),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: NotificationCategoryKey.values.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final key = NotificationCategoryKey.values[index];
                    final enabled = key.isLocked || (categories[key] ?? true);
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(
                              SettingsL10n.categoryTitle(key, isEn),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text,
                              ),
                            ),
                          ),
                          if (key.isLocked) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.ownerPillBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                SettingsL10n.notiLockedBadge(isEn),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ownerTeal,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      trailing: SettingsMintSwitch(
                        value: enabled,
                        onChanged: key.isLocked
                            ? (_) => showSheetToast(
                                SettingsL10n.notiLockedToast(isEn),
                              )
                            : (v) => controller.toggleCategory(key, v),
                      ),
                      onTap: key.isLocked
                          ? () => showSheetToast(
                              SettingsL10n.notiLockedToast(isEn),
                            )
                          : () => controller.toggleCategory(key, !enabled),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 2. ชีตตั้งค่าช่วงเวลาโหมดเงียบ (NOTI-02)
Future<void> showQuietHoursSheet(
  BuildContext context, {
  required void Function(String message) onToast,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _QuietHoursSheet(onToast: onToast),
  );
}

class _QuietHoursSheet extends ConsumerWidget {
  const _QuietHoursSheet({required this.onToast});
  final void Function(String message) onToast;

  static const _presets = [
    ('22:00', '07:00'),
    ('23:00', '06:00'),
    ('21:00', '08:00'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(settingsControllerProvider).data;
    final controller = ref.read(settingsControllerProvider.notifier);
    final isEn = ref.watch(appLocaleProvider) == 'en';
    final currentStart = data?.quietStart ?? '22:00';
    final currentEnd = data?.quietEnd ?? '07:00';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SheetHeader(
              title: SettingsL10n.quietScheduleAction(isEn),
              onClose: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 8),
            for (final (start, end) in _presets) ...[
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () async {
                  await controller.setQuietRange(start, end);
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  onToast(
                    isEn
                        ? 'Quiet hours set to $start–$end'
                        : 'ตั้งโหมดเงียบเป็น $start–$end แล้ว',
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: (start == currentStart && end == currentEnd)
                        ? AppColors.ownerPillBg
                        : AppColors.soft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: (start == currentStart && end == currentEnd)
                          ? AppColors.ownerTealRing
                          : AppColors.line,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.moon,
                        size: 18,
                        color: AppColors.ink,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '$start – $end',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                      const Spacer(),
                      if (start == currentStart && end == currentEnd)
                        const Icon(
                          LucideIcons.check,
                          size: 18,
                          color: AppColors.ownerTeal,
                        ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.settingsIconBox,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    LucideIcons.info,
                    size: 16,
                    color: AppColors.ink,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      SettingsL10n.quietScheduleNote(isEn),
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 3. ชีตความเป็นส่วนตัว & PDPA (PDPA-01 / PDPA-02)
Future<void> showPdpaSheet(
  BuildContext context, {
  required void Function(String message) onToast,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _PdpaSheet(onToast: onToast),
  );
}

class _PdpaSheet extends ConsumerWidget {
  const _PdpaSheet({required this.onToast});
  final void Function(String message) onToast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(settingsControllerProvider).data;
    final controller = ref.read(settingsControllerProvider.notifier);
    final isEn = ref.watch(appLocaleProvider) == 'en';
    final consents = data?.pdpaConsents ?? const <PdpaConsentItem>[];
    final requested = data?.dataExportRequested ?? false;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.82;

    return _SheetToastWrapper(
      builder: (showSheetToast) => SafeArea(
        top: false,
        child: SizedBox(
          height: maxHeight,
          child: Column(
            children: [
              _SheetHeader(
                title: SettingsL10n.pdpaRowTitle(isEn),
                onClose: () =>
                    Navigator.of(context, rootNavigator: true).pop(),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    for (final item in consents)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.soft,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    SettingsL10n.pdpaConsentTitle(
                                      item.key,
                                      isEn,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.text,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    SettingsL10n.pdpaConsentDesc(
                                      item.key,
                                      isEn,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    SettingsL10n.pdpaVersionLine(
                                      item.version,
                                      item.updatedAtLabel,
                                      isEn,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            SettingsMintSwitch(
                              value: item.granted,
                              onChanged: (v) async {
                                await controller.togglePdpaConsent(
                                  item.key,
                                  v,
                                );
                                showSheetToast(
                                  isEn
                                      ? 'Consent preference updated'
                                      : 'บันทึกความยินยอมแล้ว',
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      onPressed: requested
                          ? null
                          : () async {
                              final ok = await controller.requestDataExport();
                              if (ok) {
                                showSheetToast(
                                  SettingsL10n.dataExportToast(isEn),
                                );
                              }
                            },
                    icon: Icon(
                      requested ? LucideIcons.check : LucideIcons.download,
                      size: 16,
                    ),
                    label: Text(SettingsL10n.dataExportBtn(requested, isEn)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => _showLegalDialog(
                            context,
                            title: SettingsL10n.privacyPolicyTitle(isEn),
                            body: isEn
                                ? 'Maew.live collects only data required to care for your cats, locate lost pets, and keep the community safe (Policy v1.0). Sensitive fields such as phone numbers and addresses are encrypted and never shown publicly without consent.'
                                : 'แมว.live เก็บข้อมูลเท่าที่จำเป็นต่อการดูแลน้องแมว ตามหาแมวหาย และความปลอดภัยในชุมชน (นโยบายเวอร์ชัน v1.0) ข้อมูลอ่อนไหวอย่างเบอร์โทรและที่อยู่ถูกเข้ารหัส และจะไม่เปิดเผยสาธารณะหากไม่ได้รับความยินยอม',
                          ),
                          icon: const Icon(LucideIcons.fileText, size: 15),
                          label: Text(SettingsL10n.privacyPolicyTitle(isEn)),
                        ),
                      ),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => _showLegalDialog(
                            context,
                            title: SettingsL10n.termsTitle(isEn),
                            body: isEn
                                ? 'Users must respect community guidelines, avoid unauthorized commercial pet food ads, and verify medical advice with a licensed veterinarian (Terms v1.0).'
                                : 'ผู้ใช้งานตกลงปฏิบัติตามกติกาชุมชน งดโฆษณาอาหารแมวเชิงพาณิชย์โดยไม่ได้รับอนุญาต และใช้วิจารณญาณปรึกษาสัตวแพทย์สำหรับข้อมูลสุขภาพสัตว์เลี้ยง (ข้อกำหนดเวอร์ชัน v1.0)',
                          ),
                          icon: const Icon(LucideIcons.scrollText, size: 15),
                          label: Text(SettingsL10n.termsTitle(isEn)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  void _showLegalDialog(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// 4. ชีตศูนย์ช่วยเหลือ & ติดต่อทีม (SET-01)
Future<void> showHelpCenterSheet(
  BuildContext context, {
  required void Function(String message) onToast,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _HelpCenterSheet(onToast: onToast),
  );
}

class _HelpCenterSheet extends ConsumerStatefulWidget {
  const _HelpCenterSheet({required this.onToast});
  final void Function(String message) onToast;

  @override
  ConsumerState<_HelpCenterSheet> createState() => _HelpCenterSheetState();
}

class _HelpCenterSheetState extends ConsumerState<_HelpCenterSheet> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit(bool isEn) async {
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();
    if (subject.isEmpty || message.isEmpty) {
      widget.onToast(
        isEn
            ? 'Please enter both subject and details'
            : 'กรุณากรอกหัวข้อและรายละเอียดก่อนส่ง',
      );
      return;
    }
    setState(() => _sending = true);
    final ok = await ref
        .read(settingsControllerProvider.notifier)
        .submitSupportMessage(subject: subject, message: message);
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok) {
      _subjectController.clear();
      _messageController.clear();
      Navigator.of(context).pop();
      widget.onToast(
        isEn
            ? 'Message sent! Our team will reply soon.'
            : 'ส่งข้อความถึงทีมงานแล้ว จะรีบติดต่อกลับครับ',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final faqs = ref.watch(settingsControllerProvider).data?.faqs ?? const [];
    final isEn = ref.watch(appLocaleProvider) == 'en';

    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: maxHeight,
          child: Column(
            children: [
              _SheetHeader(
                title: SettingsL10n.helpCenterTitle(isEn),
                onClose: () =>
                    Navigator.of(context, rootNavigator: true).pop(),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    Text(
                      isEn ? 'Frequently Asked Questions' : 'คำถามที่พบบ่อย (FAQ)',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final faq in faqs)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: AppColors.soft,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 2,
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(
                            14,
                            0,
                            14,
                            14,
                          ),
                          shape: const Border(),
                          title: Text(
                            isEn ? faq.questionEn : faq.questionTh,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text,
                            ),
                          ),
                          children: [
                            Text(
                              isEn ? faq.answerEn : faq.answerTh,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      isEn ? 'Contact Support Team' : 'ส่งข้อความถึงทีมงาน',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _subjectController,
                      decoration: InputDecoration(
                        hintText: isEn
                            ? 'Subject (e.g. Tag pairing issue)'
                            : 'หัวข้อ (เช่น ปัญหาการผูก Tag)',
                        filled: true,
                        fillColor: AppColors.soft,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.line),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.line),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _messageController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: isEn
                            ? 'Describe your issue or suggestion...'
                            : 'อธิบายปัญหาหรือข้อเสนอแนะของคุณ...',
                        filled: true,
                        fillColor: AppColors.soft,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.line),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.line),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: _sending ? null : () => _submit(isEn),
                      icon: const Icon(LucideIcons.send, size: 16),
                      label: Text(
                        _sending
                            ? (isEn ? 'Sending...' : 'กำลังส่ง...')
                            : (isEn ? 'Send message' : 'ส่งข้อความ'),
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isEn
                          ? 'Direct channels: LINE @maewlive · support@maew.live'
                          : 'ช่องทางติดต่อตรง: LINE @maewlive · support@maew.live',
                      textAlign: TextAlign.center,
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
        ),
      ),
    );
  }
}

/// 5. Dialog ยืนยันออกจากระบบตรงเว็บจริง
Future<void> showSignOutConfirmDialog(
  BuildContext context, {
  required bool isEn,
  required VoidCallback onConfirm,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(SettingsL10n.signOutConfirmTitle(isEn)),
      content: Text(SettingsL10n.signOutConfirmBody(isEn)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(SettingsL10n.cancel(isEn)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.logoutText,
          ),
          onPressed: () {
            Navigator.of(ctx).pop();
            onConfirm();
          },
          child: Text(SettingsL10n.signOut(isEn)),
        ),
      ],
    ),
  );
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(LucideIcons.x, size: 20, color: AppColors.text),
          ),
        ],
      ),
    );
  }
}

class _SheetToastWrapper extends StatefulWidget {
  const _SheetToastWrapper({required this.builder});

  final Widget Function(void Function(String) showToast) builder;

  @override
  State<_SheetToastWrapper> createState() => _SheetToastWrapperState();
}

class _SheetToastWrapperState extends State<_SheetToastWrapper> with ToastMixin {
  @override
  void dispose() {
    disposeToast();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.builder(showToast),
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
    );
  }
}
