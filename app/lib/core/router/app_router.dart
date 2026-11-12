import 'package:go_router/go_router.dart';

import '../../features/feed/presentation/pages/community_page.dart';
import '../../features/feed/presentation/pages/connections_page.dart';
import '../../features/feed/presentation/pages/guidelines_page.dart';
import '../../features/feed/presentation/pages/post_link_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/my_cat/presentation/pages/cat_health_page.dart';
import '../../features/my_cat/presentation/pages/cat_id_page.dart';
import '../../features/my_cat/presentation/pages/cat_tracker_page.dart';
import '../../features/my_cat/presentation/pages/my_cat_page.dart';
import '../../features/nearby/presentation/pages/nearby_page.dart';
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
                builder: (_, _) => const NearbyPage(),
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
                    builder: (_, _) => const CatIdPage(),
                  ),
                  GoRoute(
                    path: 'health',
                    builder: (_, _) => const CatHealthPage(),
                  ),
                  GoRoute(
                    path: 'tracker',
                    builder: (_, state) => CatTrackerPage(
                      initialDeviceMode:
                          state.uri.queryParameters['device'] == '1',
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
