import 'dart:async';

import 'package:flutter/material.dart';

/// ข้อความแจ้งสั้น ๆ รูปเม็ดยาสีน้ำตาล — สี/ขนาดตามเว็บ (role=status)
class ToastPill extends StatelessWidget {
  const ToastPill({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xD94A3428),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            height: 1.5,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}

/// จัดการ toast ที่หายเองใน 1.8 วินาที — เรียก [showToast] แล้ววาง [ToastPill]
/// ตามค่า [toastMessage]; ต้องเรียก [disposeToast] ใน `dispose()`
mixin ToastMixin<T extends StatefulWidget> on State<T> {
  Timer? _toastTimer;
  String? toastMessage;

  void showToast(String message) {
    _toastTimer?.cancel();
    setState(() => toastMessage = message);
    _toastTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => toastMessage = null);
    });
  }

  void disposeToast() => _toastTimer?.cancel();
}
