import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/auth_data.dart';
import '../../domain/usecases/auth_rules.dart';
import 'auth_l10n.dart';

/// แสดงสถานะการกรอก PIN ผิด — ถ้าล็อกอยู่จะนับถอยหลังเวลาที่เหลือและเสนอทาง OTP
/// ถ้ายังไม่ล็อกแต่เคยผิดแล้วจะแสดงจำนวนครั้งที่เหลือ
class PinLockNotice extends StatefulWidget {
  const PinLockNotice({
    super.key,
    required this.status,
    required this.isEn,
    this.onExpired,
    this.onUseOtp,
  });

  final PinAttemptStatus? status;
  final bool isEn;

  /// เรียกเมื่อครบเวลาล็อก เพื่อให้หน้าจอโหลดสถานะใหม่
  final VoidCallback? onExpired;

  /// ทางเลือกไปยืนยันตัวตนด้วย OTP — แสดงเฉพาะตอนล็อกและหน้านั้นส่งมาให้
  final VoidCallback? onUseOtp;

  @override
  State<PinLockNotice> createState() => _PinLockNoticeState();
}

class _PinLockNoticeState extends State<PinLockNotice> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant PinLockNotice oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTicker();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  bool get _locked => widget.status?.isLockedAt(DateTime.now()) ?? false;

  /// นับถอยหลังทุกวินาทีเฉพาะตอนล็อก — ครบเวลาแล้วหยุดและแจ้งหน้าจอให้โหลดใหม่
  void _syncTicker() {
    if (!_locked) {
      _ticker?.cancel();
      _ticker = null;
      return;
    }
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (_locked) {
        setState(() {});
        return;
      }
      _ticker?.cancel();
      _ticker = null;
      widget.onExpired?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.status;
    if (status == null) return const SizedBox.shrink();
    final now = DateTime.now();
    if (status.isLockedAt(now)) {
      return _buildLocked(status.secondsUntilUnlock(now));
    }
    if (status.remainingAttempts >= AuthRules.pinMaxAttempts) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        AuthL10n.pinAttemptsLeft(status.remainingAttempts, widget.isEn),
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: AppColors.muted,
        ),
      ),
    );
  }

  Widget _buildLocked(int seconds) {
    final mm = (seconds ~/ 60).toString().padLeft(2, '0');
    final ss = (seconds % 60).toString().padLeft(2, '0');
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
        decoration: BoxDecoration(
          color: AppColors.btn,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.btnBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: AppColors.ownerPillBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.lockKeyhole,
                    size: 16,
                    color: AppColors.ownerTeal,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AuthL10n.pinLockedTitle(widget.isEn),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          height: 1.4,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text.rich(
                        TextSpan(
                          style: const TextStyle(
                            fontSize: 12.5,
                            height: 1.6,
                            color: AppColors.muted,
                          ),
                          children: [
                            TextSpan(
                              text: AuthL10n.pinLockedDetail(widget.isEn),
                            ),
                            TextSpan(
                              text: ' $mm:$ss',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.ownerTeal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.onUseOtp != null) ...[
              const SizedBox(height: 4),
              Semantics(
                button: true,
                label: AuthL10n.pinLockOtpBtn(widget.isEn),
                child: TextButton(
                  onPressed: widget.onUseOtp,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    foregroundColor: AppColors.ownerTeal,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  child: Text(
                    AuthL10n.pinLockOtpBtn(widget.isEn),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
