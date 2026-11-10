import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

/// หน้ากฎการโพสต์ในชุมชน — เปิดจากลิงก์ "กฎการโพสต์" ในหน้าสร้างโพสต์ (ตามเว็บ)
class GuidelinesPage extends StatelessWidget {
  const GuidelinesPage({super.key});

  static const _okItems = [
    'เรื่องราว รูป และวิดีโอน้องแมว',
    'ความรู้ สุขภาพ และคำถามเรื่องแมว',
    'ประกาศแมวหาย พบแมว และหาบ้านให้แมว',
    'ขายหรือแนะนำของใช้แมว เช่น ทราย ของเล่น คอนโดแมว',
    'รีวิวคลินิก ร้าน คาเฟ่ และบริการเกี่ยวกับแมว',
  ];

  static const _noItems = [
    'โฆษณา ขาย หรือรีวิวแบบมีสปอนเซอร์ อาหารแมว ขนมแมว อาหารเปียก และอาหารเม็ด ทุกยี่ห้อ ยกเว้นแบรนด์พาร์ทเนอร์ที่แอปกำหนด',
    'ลิงก์หรือโค้ดส่วนลดร้านขายอาหารแมว',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'ย้อนกลับ',
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go('/community'),
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    icon: const Icon(
                      LucideIcons.arrowLeft,
                      size: 24,
                      color: AppColors.text,
                    ),
                  ),
                  const Text(
                    'กฎการโพสต์ในชุมชน',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                children: [
                  const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'แมว.live เปิดให้ทุกคนโพสต์เรื่องแมวได้แทบทุกเรื่อง ยกเว้นเรื่องเดียวคือ ',
                        ),
                        TextSpan(
                          text: 'การโฆษณาและขายอาหารแมว',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.6,
                      color: AppColors.text2,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3EF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFF3C7BD)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            LucideIcons.shieldAlert,
                            size: 22,
                            color: Color(0xFFC2503B),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'อาหารแมวโฆษณาได้แบรนด์เดียว',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF8F2E1E),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(text: 'เฉพาะ '),
                                    TextSpan(
                                      text: 'แบรนด์อาหารแมวพาร์ทเนอร์ทางการ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' ที่แอปกำหนดเท่านั้นที่โฆษณาหรือขายอาหารแมวในแอปได้ โพสต์ขายหรือโปรโมตอาหารแมวยี่ห้ออื่นจะแชร์ไม่ได้',
                                    ),
                                  ],
                                ),
                                style: TextStyle(
                                  fontSize: 13.5,
                                  height: 1.6,
                                  color: Color(0xFF6B2A1E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _RuleCard(
                    title: 'โพสต์ได้',
                    items: _okItems,
                    icon: LucideIcons.check,
                    iconColor: const Color(0xFF2F7F7A),
                  ),
                  const SizedBox(height: 14),
                  _RuleCard(
                    title: 'โพสต์ไม่ได้',
                    items: _noItems,
                    icon: LucideIcons.x,
                    iconColor: const Color(0xFFC2503B),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'เล่าว่าน้องแมวกินอะไร หรือถามเรื่องโภชนาการได้ตามปกติ ข้อนี้ห้ามเฉพาะการโฆษณาและการขาย',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.6,
                      color: AppColors.muted,
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

class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.title,
    required this.items,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final List<String> items;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(icon, size: 16, color: iconColor),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
