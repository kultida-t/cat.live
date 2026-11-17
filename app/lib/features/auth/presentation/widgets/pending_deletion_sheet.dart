import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/auth_controller.dart';

/// ชีตแจ้งบัญชีที่กำลังรอลบ (AUTH-05) — ผู้ใช้เลือกกู้คืน หรือลบถาวรตามกำหนด
/// คืนค่า true = กู้คืนสำเร็จ, false = เลือกปล่อยให้ลบตามกำหนด, null = ปิดชีตเฉย ๆ
Future<bool?> showPendingDeletionSheet(
  BuildContext context, {
  required int daysRemaining,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _PendingDeletionSheet(daysRemaining: daysRemaining),
  );
}

class _PendingDeletionSheet extends ConsumerStatefulWidget {
  const _PendingDeletionSheet({required this.daysRemaining});

  final int daysRemaining;

  @override
  ConsumerState<_PendingDeletionSheet> createState() =>
      _PendingDeletionSheetState();
}

class _PendingDeletionSheetState extends ConsumerState<_PendingDeletionSheet> {
  bool _busy = false;
  String? _error;

  Future<void> _restore() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await ref
        .read(authControllerProvider.notifier)
        .restorePendingDeletion();
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      // เลยกำหนด 30 วันแล้ว → บัญชีถูกลบถาวร แจ้งแล้วปิดชีต
      setState(() {
        _busy = false;
        _error = 'บัญชีนี้เลยระยะเวลากู้คืน 30 วันแล้ว ถูกลบถาวรเรียบร้อย';
      });
    }
  }

  Future<void> _continueDeletion() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    await ref.read(authControllerProvider.notifier).confirmPermanentDeletion();
    if (!mounted) return;
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final days = widget.daysRemaining < 0 ? 0 : widget.daysRemaining;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: AppColors.healthReminderBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.clock,
                size: 32,
                color: AppColors.healthReminderClockInk,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'บัญชีนี้กำลังรอลบ',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.healthReminderBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'เหลือเวลากู้คืนอีก $days วัน',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.healthReminderClockInk,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'บัญชีของคุณอยู่ในระหว่างรอลบตามคำขอ\nข้อมูลทั้งหมดยังเก็บไว้อย่างปลอดภัย',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.6,
                color: AppColors.text2,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'ถ้าเปลี่ยนใจ เพียงกดกู้คืนบัญชีด้านล่าง\nทุกอย่างจะกลับมาเหมือนเดิมทันที',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                color: AppColors.muted,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.danger,
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _busy ? null : _restore,
                icon: const Icon(LucideIcons.rotateCcw, size: 17),
                label: Text(
                  _busy ? 'กำลังดำเนินการ...' : 'กู้คืนบัญชี',
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
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: TextButton(
                onPressed: _busy ? null : _continueDeletion,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.logoutText,
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  'ลบถาวรตามกำหนด',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
