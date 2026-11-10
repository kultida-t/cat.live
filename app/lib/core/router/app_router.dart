import 'package:go_router/go_router.dart';

import '../../features/feed/presentation/pages/community_page.dart';
import '../../features/feed/presentation/pages/guidelines_page.dart';
import '../../features/feed/presentation/pages/post_link_page.dart';
import '../../features/shell/presentation/main_shell.dart';
import '../../features/shell/presentation/placeholder_page.dart';

/// เส้นทางหลัก — แท็บล่าง 6 อัน แต่ละอันเก็บสถานะของตัวเอง (เลื่อนค้างไว้เมื่อสลับแท็บ)
GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/p/:id',
        builder: (_, state) =>
            PostLinkPage(postId: state.pathParameters['id']!),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => const PlaceholderPage(
                  title: 'แมว.live',
                  subtitle: 'ภาพรวมแมวของฉันและทางลัดต่าง ๆ',
                  notes: [
                    'แมวของฉัน — การ์ดแมวพร้อมทางลัดสมุดสุขภาพ ประกาศ และแท็ก',
                    'ทางลัด — สร้างโพสต์ แจ้งแมวหาย ค้นหาสถานที่',
                    'หน้าเปิดแอป — แมววิ่งเข้าหาเจ้าของตอนเปิดแอป (ทีหลัง)',
                  ],
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/community',
                builder: (_, _) => const CommunityPage(),
              ),
              GoRoute(
                path: '/guidelines',
                builder: (_, _) => const GuidelinesPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/nearby',
                builder: (_, _) => const PlaceholderPage(
                  title: 'ใกล้ฉัน',
                  subtitle: 'ค้นหาคาเฟ่ คลินิก และร้านค้ารอบตัว',
                  notes: [
                    'แผนที่เต็มจอ + หมวดลอย (คาเฟ่/คลินิก/ร้านค้า/ประกาศ/อาบน้ำตัดขน/รับฝาก)',
                    'สลับมุมมอง แผนที่ ↔ รายการ',
                    'หมุดร้านค้าที่มาลงโฆษณา (Business Model จากประชุม)',
                  ],
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/cat-ai',
                builder: (_, _) => const PlaceholderPage(
                  title: 'Cat AI',
                  subtitle: 'ผู้ช่วยเรื่องแมว — ถามอาการและการดูแล',
                  notes: [
                    'แชทถาม-ตอบเรื่องแมว (พิมพ์ + เสียง)',
                    'โทรคุยสัตวแพทย์ AI และตรวจใบหน้าแมว (เฟสถัดไป)',
                    'Embedded AI เป็นชั้นบังคับตามมาตรฐาน UNIVERZA',
                  ],
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/help',
                builder: (_, _) => const PlaceholderPage(
                  title: 'ช่วยเหลือ',
                  subtitle: 'ประกาศแมวหาย พบแมว และการระดมทุน',
                  notes: [
                    'ประกาศ 5 แบบ: แมวหาย / พบแมว / ขอความช่วยเหลือ / รับเลี้ยง / อุปการะ',
                    'ปุ่มฉุกเฉิน — อาการเร่งด่วน + รพ.สัตว์ 24 ชม.',
                    'แมวหายคือหัวใจของแอป — ผูกกับฟีด แท็ก และแชท',
                  ],
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/my-cat',
                builder: (_, _) => const PlaceholderPage(
                  title: 'แมวและฉัน',
                  subtitle: 'โปรไฟล์ของฉันและแมวทุกตัว',
                  notes: [
                    'โปรไฟล์เจ้าของ — ยืนยันตัวตน บัญชีรับบริจาค ที่อยู่รับขนม (ลับ)',
                    'โปรไฟล์แมวหลายตัว — Cat ID + QR และสมุดบันทึกสุขภาพ',
                    'ตามหาแมว Find My + โหมดแมวหาย + เมนูร้านค้า (แท็ก/ปลอกคอ/ขนม)',
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
