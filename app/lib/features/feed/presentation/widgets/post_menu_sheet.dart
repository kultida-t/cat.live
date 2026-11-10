import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/post.dart';

enum PostMenuAction { notInterested, hideAuthor, copyLink, report, delete }

typedef PostMenuResult = ({PostMenuAction action, String? reason});

const _reportReasons = [
  'ทารุณหรือทำร้ายสัตว์',
  'ซื้อขายแมว / หลอกลวง',
  'สแปมหรือโฆษณา',
  'ภาพหรือข้อความไม่เหมาะสม',
  'ข้อมูลเท็จ / ปลอมตัวเป็นคนอื่น',
  'อื่น ๆ',
];

const _dangerColor = Color(0xFFB42318);

/// เมนู ··· ของโพสต์ — bottom sheet หน้าตาและข้อความตามเว็บ (www.แมว.live)
/// ขั้นรายงาน/ลบอยู่ในชีตเดียวกัน คืนค่าเมนูที่เลือก (และเหตุผลถ้ารายงาน)
Future<PostMenuResult?> showPostMenuSheet(BuildContext context, Post post) {
  return showModalBottomSheet<PostMenuResult>(
    context: context,
    backgroundColor: Colors.white,
    barrierColor: const Color(0x594A3428),
    isScrollControlled: true,
    showDragHandle: false,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.85,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _PostMenuBody(post: post),
  );
}

enum _Step { menu, report, delete }

class _PostMenuBody extends StatefulWidget {
  const _PostMenuBody({required this.post});

  final Post post;

  @override
  State<_PostMenuBody> createState() => _PostMenuBodyState();
}

class _PostMenuBodyState extends State<_PostMenuBody> {
  _Step _step = _Step.menu;

  void _pick(PostMenuAction action, [String? reason]) =>
      Navigator.pop(context, (action: action, reason: reason));

  String get _title => switch (_step) {
    _Step.menu => 'ตัวเลือกโพสต์',
    _Step.report => 'รายงานโพสต์',
    _Step.delete => 'ลบโพสต์นี้?',
  };

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: AppColors.line2,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: Row(
              children: [
                _step == _Step.menu
                    ? const SizedBox(width: 44, height: 44)
                    : IconButton(
                        tooltip: 'ย้อนกลับ',
                        onPressed: () => setState(() => _step = _Step.menu),
                        icon: const Icon(
                          LucideIcons.arrowLeft,
                          size: 24,
                          color: AppColors.text,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                      ),
                Expanded(
                  child: Text(
                    _title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'ปิด',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    LucideIcons.x,
                    size: 20,
                    color: AppColors.text,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              child: switch (_step) {
                _Step.menu => _menu(),
                _Step.report => _report(),
                _Step.delete => _delete(),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _menu() {
    final post = widget.post;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        children: [
          if (!post.isOwn) ...[
            _MenuRow(
              icon: LucideIcons.thumbsDown,
              title: 'ไม่สนใจโพสต์นี้',
              subtitle: 'จะแสดงโพสต์แบบนี้น้อยลง',
              onTap: () => _pick(PostMenuAction.notInterested),
            ),
            _MenuRow(
              icon: LucideIcons.eyeOff,
              title: 'ซ่อนโพสต์จาก ${post.author.handle}',
              subtitle: 'ยังติดตามอยู่ แต่จะไม่เห็นในฟีด',
              onTap: () => _pick(PostMenuAction.hideAuthor),
            ),
          ],
          _MenuRow(
            icon: LucideIcons.copy,
            title: 'คัดลอกลิงก์',
            onTap: () => _pick(PostMenuAction.copyLink),
          ),
          if (post.isOwn)
            _MenuRow(
              icon: LucideIcons.trash2,
              title: 'ลบโพสต์',
              danger: true,
              onTap: () => setState(() => _step = _Step.delete),
            )
          else
            _MenuRow(
              icon: LucideIcons.flag,
              title: 'รายงานโพสต์',
              danger: true,
              onTap: () => setState(() => _step = _Step.report),
            ),
        ],
      ),
    );
  }

  Widget _report() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(
            'เลือกเหตุผล ทีมแมว.live จะตรวจสอบภายใน 24 ชม. และ '
            '${widget.post.author.handle} จะไม่รู้ว่าใครรายงาน',
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.text2,
            ),
          ),
        ),
        for (final reason in _reportReasons)
          _MenuRow(
            title: reason,
            topBorder: true,
            onTap: () => _pick(PostMenuAction.report, reason),
          ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  LucideIcons.shieldAlert,
                  size: 15,
                  color: AppColors.text2,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ถ้าแมวตกอยู่ในอันตรายตอนนี้ ให้แจ้งมูลนิธิหรือเจ้าหน้าที่ในพื้นที่ทันที',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    color: AppColors.text2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _delete() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'โพสต์ ยอดถูกใจ และความคิดเห็นทั้งหมดจะหายไป และกู้คืนไม่ได้',
            style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.text2),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => _pick(PostMenuAction.delete),
            style: FilledButton.styleFrom(
              backgroundColor: _dangerColor,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'ลบโพสต์',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() => _step = _Step.menu),
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: AppColors.text,
            ),
            child: const Text('ยกเลิก', style: TextStyle(fontSize: 15)),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.title,
    required this.onTap,
    this.icon,
    this.subtitle,
    this.danger = false,
    this.topBorder = false,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback onTap;
  final bool danger;
  final bool topBorder;

  @override
  Widget build(BuildContext context) {
    final color = danger ? _dangerColor : AppColors.text;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          border: topBorder
              ? const Border(top: BorderSide(color: AppColors.line))
              : null,
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 15, height: 1.4, color: color),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: AppColors.text2,
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
