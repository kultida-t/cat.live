import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

enum PostMenuAction { notInterested, hideAuthor, copyLink, report, delete }

/// เมนู ··· ของโพสต์ — bottom sheet ตาม design-spec คืนค่าเมนูที่ผู้ใช้เลือก
Future<PostMenuAction?> showPostMenuSheet(
  BuildContext context, {
  required bool isOwnPost,
}) {
  return showModalBottomSheet<PostMenuAction>(
    context: context,
    backgroundColor: AppColors.page,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      final items = <(PostMenuAction, String, bool)>[
        (PostMenuAction.notInterested, 'ไม่สนใจ', false),
        (PostMenuAction.hideAuthor, 'ซ่อนโพสต์จากบัญชีนี้', false),
        (PostMenuAction.copyLink, 'คัดลอกลิงก์', false),
        (PostMenuAction.report, 'รายงาน', true),
        if (isOwnPost) (PostMenuAction.delete, 'ลบโพสต์', true),
      ];
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (action, label, danger) in items)
              _MenuTile(
                label: label,
                danger: danger,
                onTap: () => Navigator.pop(context, action),
              ),
            _MenuTile(
              label: 'ยกเลิก',
              muted: true,
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    },
  );
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.label,
    required this.onTap,
    this.danger = false,
    this.muted = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool danger;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 48),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: muted
              ? null
              : const Border(bottom: BorderSide(color: AppColors.line)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: danger || muted ? FontWeight.w600 : FontWeight.w400,
            color: danger
                ? AppColors.danger
                : muted
                ? AppColors.muted
                : AppColors.text,
          ),
        ),
      ),
    );
  }
}
