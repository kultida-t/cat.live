import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';

/// เปิดชีตมาตรฐานของหน้าแมวและฉัน — มีหัวข้อ ปุ่มปิด และ SafeArea
Future<T?> showMyCatSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.sheetBarrier,
    builder: builder,
  );
}

class MyCatSheetFrame extends StatelessWidget {
  const MyCatSheetFrame({
    super.key,
    required this.title,
    required this.child,
    this.trailingAction,
    this.maxHeightFactor = 0.88,
  });

  final String title;
  final Widget child;
  final Widget? trailingAction;
  final double maxHeightFactor;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final available = (media.size.height - media.viewInsets.bottom).clamp(
      240.0,
      media.size.height,
    );
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: available * maxHeightFactor),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line2,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 8, 8),
                  child: Row(
                    children: [
                      Semantics(
                        button: true,
                        label: 'ปิด',
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(LucideIcons.x, size: 20),
                          color: AppColors.text,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      trailingAction ?? const SizedBox(width: 48),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.line),
                Flexible(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ปุ่มสลับแบบเลือก 1 ค่า (segmented toggle) ใช้ร่วมกันในฟอร์มแมวและเจ้าของ
class SegmentedChoiceRow<T> extends StatelessWidget {
  const SegmentedChoiceRow({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<({T value, String label})> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              button: true,
              selected: options[i].value == selected,
              label: options[i].label,
              child: InkWell(
                onTap: () => onChanged(options[i].value),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: options[i].value == selected
                        ? AppColors.btn
                        : AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: options[i].value == selected
                          ? AppColors.btnBorder
                          : AppColors.line2,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    options[i].label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: options[i].value == selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: options[i].value == selected
                          ? AppColors.ink
                          : AppColors.text2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

Future<void> copyLinkAndNotify(
  String url,
  ValueChanged<String> onNotify, {
  String message = 'คัดลอกลิงก์แล้ว',
}) async {
  await Clipboard.setData(ClipboardData(text: url));
  onNotify(message);
}

Future<void> systemShareText(
  String text,
  String subject,
  ValueChanged<String> onNotify,
) async {
  try {
    await SharePlus.instance.share(ShareParams(text: text, subject: subject));
  } on Exception {
    await copyLinkAndNotify(
      text,
      onNotify,
      message: 'เปิดหน้าต่างแชร์ไม่ได้ · คัดลอกลิงก์ให้แล้ว',
    );
  }
}
