import 'package:go_router/go_router.dart';

import '../../features/cat_ai/presentation/pages/cat_ai_page.dart';
import '../../features/feed/presentation/pages/community_page.dart';
import '../../features/feed/presentation/pages/connections_page.dart';
import '../../features/feed/presentation/pages/guidelines_page.dart';
import '../../features/feed/presentation/pages/post_link_page.dart';
import '../../features/help/presentation/pages/help_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/my_cat/presentation/pages/cat_health_page.dart';
import '../../features/my_cat/presentation/pages/cat_id_page.dart';
import '../../features/my_cat/presentation/pages/cat_tracker_page.dart';
import '../../features/my_cat/presentation/pages/my_cat_page.dart';
import '../../features/nearby/presentation/pages/nearby_page.dart';
import '../../features/shell/presentation/main_shell.dart';

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
      GoRoute(path: '/cat-profile', builder: (_, _) => const CatIdPage()),
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
              GoRoute(path: '/cat-ai', builder: (_, _) => const CatAiPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/help',
                builder: (_, _) => const HelpPage(),
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
