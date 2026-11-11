import 'package:go_router/go_router.dart';

import '../../features/feed/presentation/pages/community_page.dart';
import '../../features/feed/presentation/pages/connections_page.dart';
import '../../features/feed/presentation/pages/guidelines_page.dart';
import '../../features/feed/presentation/pages/post_link_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/my_cat/presentation/pages/my_cat_page.dart';
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
            routes: [GoRoute(path: '/', builder: (_, _) => const HomePage())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/community',
                builder: (_, _) => const CommunityPage(),
              ),
              GoRoute(
                path: '/connections',
                builder: (_, _) => const ConnectionsPage(),
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
                  enTitle: 'Nearby',
                  subtitle: 'ค้นหาคาเฟ่ คลินิก และร้านค้ารอบตัว',
                  enSubtitle: 'Find cat cafes, clinics, and shops nearby',
                  notes: [
                    'แผนที่เต็มจอ + หมวดลอย (คาเฟ่/คลินิก/ร้านค้า/ประกาศ/อาบน้ำตัดขน/รับฝาก)',
                    'สลับมุมมอง แผนที่ ↔ รายการ',
                    'หมุดร้านค้าที่มาลงโฆษณา (Business Model จากประชุม)',
                  ],
                  enNotes: [
                    'Full-screen map with floating category filters',
                    'Switch between Map ↔ List views',
                    'Sponsored partner shop pins',
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
                  enTitle: 'Cat AI',
                  subtitle: 'ผู้ช่วยเรื่องแมว — ถามอาการและการดูแล',
                  enSubtitle:
                      'Cat care assistant — ask about symptoms & daily care',
                  notes: [
                    'แชทถาม-ตอบเรื่องแมว (พิมพ์ + เสียง)',
                    'โทรคุยสัตวแพทย์ AI และตรวจใบหน้าแมว (เฟสถัดไป)',
                    'Embedded AI เป็นชั้นบังคับตามมาตรฐาน UNIVERZA',
                  ],
                  enNotes: [
                    'Chat Q&A for cat health & behavior (text + voice)',
                    'AI vet call & cat facial checkup (upcoming phase)',
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
                  enTitle: 'Help',
                  subtitle: 'ประกาศแมวหาย พบแมว และการระดมทุน',
                  enSubtitle: 'Lost & found cats and rescue fundraisers',
                  notes: [
                    'ประกาศ 5 แบบ: แมวหาย / พบแมว / ขอความช่วยเหลือ / รับเลี้ยง / อุปการะ',
                    'ปุ่มฉุกเฉิน — อาการเร่งด่วน + รพ.สัตว์ 24 ชม.',
                    'แมวหายคือหัวใจของแอป — ผูกกับฟีด แท็ก และแชท',
                  ],
                  enNotes: [
                    '5 post types: Lost / Found / Rescue help / Adoption / Foster',
                    'Emergency triage & 24-hour vet clinic finder',
                  ],
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/my-cat',
                builder: (_, _) => const MyCatPage(),
                routes: [
                  GoRoute(
                    path: 'profile',
                    builder: (_, _) => const PlaceholderPage(
                      title: 'Cat ID — บัตรประจำตัวแมว',
                      enTitle: 'Cat ID card',
                      subtitle: 'หน้าย่อยรอบที่ 2 (Slice 2)',
                      enSubtitle: 'Coming in Slice 2',
                      showBack: true,
                      notes: [
                        'บัตรประจำตัวแมว 7 สี + ข้อมูลสุขภาพย่อ + เลขไมโครชิปซ่อนท้าย',
                        'QR code สแกนเปิดหน้าสาธารณะที่ไม่แสดงที่อยู่หรือเบอร์จริง',
                      ],
                      enNotes: [
                        '7-theme Cat ID card with summary health & masked microchip',
                        'Public QR code profile hiding real address and phone number',
                      ],
                    ),
                  ),
                  GoRoute(
                    path: 'health',
                    builder: (_, _) => const PlaceholderPage(
                      title: 'สมุดสุขภาพ',
                      enTitle: 'Health book',
                      subtitle: 'หน้าย่อยรอบที่ 2 (Slice 2)',
                      enSubtitle: 'Coming in Slice 2',
                      showBack: true,
                      notes: [
                        '7 แท็บ: ประวัติ, ร่างกาย, สมุดวัคซีน, ยา, ปฏิทิน, น้ำหนัก, เอกสาร',
                        'การ์ดนัดถัดไป + บันทึกจาก Cat AI และเพิ่มบันทึกสุขภาพ',
                      ],
                      enNotes: [
                        '7 tabs: History, Body, Vaccine book, Medicine, Calendar, Weight, Documents',
                        'Next appointment reminder + Cat AI notes & add record',
                      ],
                    ),
                  ),
                  GoRoute(
                    path: 'tracker',
                    builder: (_, _) => const PlaceholderPage(
                      title: 'ตามหาแมว (Find My)',
                      enTitle: 'Find my cat',
                      subtitle: 'หน้าย่อยรอบที่ 2 (Slice 2)',
                      enSubtitle: 'Coming in Slice 2',
                      showBack: true,
                      notes: [
                        'แผนที่ตำแหน่งแมว + สถานะเขตปลอดภัย + แบตเตอรี่แท็ก',
                        'จัดการอุปกรณ์ แมว.live Tag และส่งเสียงเรียกน้อง',
                      ],
                      enNotes: [
                        'Live location map, safe-zone status & tag battery level',
                        'Manage แมว.live Tag devices and play sound chime',
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
