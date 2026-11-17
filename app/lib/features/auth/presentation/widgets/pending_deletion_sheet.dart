import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/auth_controller.dart';

/// ชีตแจ้งบัญชีที่กำลังรอลบ (AUTH-05) — ผู้ใช้เลือกกู้คืน หรือลบถาวรต่อ
/// คืนค่า true = กู้คืนสำเร็จ, false = เลือกลบถาวรต่อไป, null = ปิดชีตเฉย ๆ
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
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.logoutBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.triangleAlert,
                size: 30,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'บัญชีนี้กำลังรอลบ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'บัญชีของคุณอยู่ในช่วงรอลบ 30 วัน เหลือเวลากู้คืนอีก $days วัน\n'
              'หากไม่กู้คืนภายในกำหนด ข้อมูลทั้งหมดจะถูกลบถาวร',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.55,
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
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
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
              height: 50,
              child: OutlinedButton(
                onPressed: _busy ? null : _continueDeletion,
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.logoutBg,
                  foregroundColor: AppColors.logoutText,
                  side: const BorderSide(color: AppColors.logoutBorder),
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  'ลบบัญชีถาวรต่อไป',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
