import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import 'my_cat_l10n.dart';
import 'sheet_chrome.dart';

enum CatIdPrintOption { selfPrint, collarTag, stickerSheet }

/// ชีต "สั่งพิมพ์ป้าย <ชื่อแมว>" ตรงตามเว็บ www.แมว.live/my-cat/profile
Future<void> showCatIdPrintSheet(
  BuildContext context, {
  required String catName,
  bool isEn = false,
  required ValueChanged<String> onNotify,
}) {
  return showMyCatSheet<void>(
    context,
    builder: (ctx) => _CatIdPrintSheetBody(
      catName: catName,
      isEn: isEn,
      onNotify: onNotify,
    ),
  );
}

class _CatIdPrintSheetBody extends StatefulWidget {
  const _CatIdPrintSheetBody({
    required this.catName,
    required this.isEn,
    required this.onNotify,
  });

  final String catName;
  final bool isEn;
  final ValueChanged<String> onNotify;

  @override
  State<_CatIdPrintSheetBody> createState() => _CatIdPrintSheetBodyState();
}

class _CatIdPrintSheetBodyState extends State<_CatIdPrintSheetBody> {
  CatIdPrintOption _selected = CatIdPrintOption.selfPrint;

  @override
  Widget build(BuildContext context) {
    final isEn = widget.isEn;
    final displayCat = MyCatL10n.catName(widget.catName, isEn);

    final options = [
      (
        value: CatIdPrintOption.selfPrint,
        icon: LucideIcons.printer,
        title: isEn ? 'Print card yourself' : 'พิมพ์บัตรเอง',
        subtitle: isEn
            ? 'Print at home or save as a card-sized PDF'
            : 'พิมพ์ที่บ้านหรือบันทึกเป็น PDF ขนาดบัตร',
        price: isEn ? 'Free' : 'ฟรี',
      ),
      (
        value: CatIdPrintOption.collarTag,
        icon: LucideIcons.tag,
        title: isEn ? 'QR collar tag' : 'ป้ายห้อยคอ QR',
        subtitle: isEn
            ? 'Waterproof acrylic 2.5 cm with ring'
            : 'อะคริลิก กันน้ำ ขนาด 2.5 ซม. พร้อมห่วง',
        price: '฿149',
      ),
      (
        value: CatIdPrintOption.stickerSheet,
        icon: LucideIcons.sticker,
        title: isEn ? 'QR stickers' : 'สติกเกอร์ QR',
        subtitle: isEn
            ? 'For carrier or crate, 6 stickers'
            : 'ติดกรงหรือกระเป๋าใส่แมว 6 ชิ้น',
        price: '฿79',
      ),
    ];

    final ctaLabel = _selected == CatIdPrintOption.selfPrint
        ? (isEn ? 'Print / Save as PDF' : 'พิมพ์ / บันทึกเป็น PDF')
        : (isEn ? 'Submit tag order' : 'ส่งคำสั่งทำป้าย');

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line2,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isEn
                          ? 'Print tag · $displayCat'
                          : 'สั่งพิมพ์ป้าย $displayCat',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: isEn ? 'Close' : 'ปิด',
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
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
              const SizedBox(height: 16),
              for (var i = 0; i < options.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                _PrintOptionTile(
                  icon: options[i].icon,
                  title: options[i].title,
                  subtitle: options[i].subtitle,
                  price: options[i].price,
                  selected: _selected == options[i].value,
                  onTap: () => setState(() => _selected = options[i].value),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  final picked = options.firstWhere(
                    (o) => o.value == _selected,
                  );
                  Navigator.of(context).pop();
                  if (_selected == CatIdPrintOption.selfPrint) {
                    widget.onNotify(
                      isEn
                          ? 'Prepared $displayCat\'s Cat ID PDF (demo)'
                          : 'เตรียมบัตรของ$displayCatสำหรับพิมพ์/บันทึก PDF แล้ว (จำลอง)',
                    );
                  } else {
                    widget.onNotify(
                      isEn
                          ? 'Order saved (${picked.title}) · team will confirm before production (demo)'
                          : 'บันทึกคำสั่ง${picked.title}แล้ว · ทีมงานจะติดต่อยืนยันก่อนผลิต (จำลอง)',
                    );
                  }
                },
                icon: const Icon(LucideIcons.printer, size: 18),
                label: Text(
                  ctaLabel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
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
              ),
              const SizedBox(height: 12),
              Text(
                isEn
                    ? 'All tags include a QR to the public profile · never prints real address or phone'
                    : 'ป้ายทุกแบบมี QR ไปหน้าโปรไฟล์สาธารณะ · ไม่พิมพ์ที่อยู่หรือเบอร์โทรจริง',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrintOptionTile extends StatelessWidget {
  const _PrintOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String price;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$title $price',
      child: Material(
        color: selected ? const Color(0x80FFF1E6) : AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? AppColors.btnBorder : AppColors.line,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.soft,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, size: 21, color: AppColors.ink),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
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

