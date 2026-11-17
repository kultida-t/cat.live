import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/delete_account_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/cat_ai/presentation/pages/cat_ai_page.dart';
import '../../features/cat_ai/presentation/pages/cat_face_check_page.dart';
import '../../features/feature_flags/presentation/pages/feature_flags_page.dart';
import '../../features/feed/presentation/pages/community_page.dart';
import '../../features/feed/presentation/pages/connections_page.dart';
import '../../features/feed/presentation/pages/guidelines_page.dart';
import '../../features/feed/presentation/pages/post_link_page.dart';
import '../../features/help/presentation/pages/help_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/menu/presentation/pages/menu_page.dart';
import '../../features/messages/presentation/pages/chat_room_page.dart';
import '../../features/messages/presentation/pages/messages_page.dart';
import '../../features/my_cat/presentation/pages/cat_health_page.dart';
import '../../features/my_cat/presentation/pages/cat_id_page.dart';
import '../../features/my_cat/presentation/pages/cat_tracker_page.dart';
import '../../features/my_cat/presentation/pages/my_cat_page.dart';
import '../../features/nearby/presentation/pages/nearby_page.dart';
import '../../features/notifications/presentation/pages/notification_help_alert_page.dart';
import '../../features/notifications/presentation/pages/notification_post_detail_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/notifications/presentation/pages/received_treats_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/shell/presentation/main_shell.dart';
import '../../features/tag/presentation/pages/tag_page.dart';
import '../../features/treats/presentation/pages/treats_page.dart';

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
      GoRoute(
        path: '/login',
        builder: (_, state) => LoginPage(
          returnTo: state.uri.queryParameters['return'],
          initialRegister: state.uri.queryParameters['mode'] == 'register',
        ),
      ),
      GoRoute(
        path: '/feature-flags',
        builder: (_, _) => const FeatureFlagsPage(),
      ),
      GoRoute(path: '/menu', builder: (_, _) => const MenuPage()),
      GoRoute(
        path: '/settings',
        builder: (_, state) =>
            SettingsPage(initialSection: state.uri.queryParameters['section']),
      ),
      GoRoute(
        path: '/settings/delete-account',
        builder: (_, _) => const DeleteAccountPage(),
      ),
      GoRoute(
        path: '/settings/guidelines',
        builder: (_, _) => const GuidelinesPage(),
      ),
      GoRoute(
        path: '/settings/tracker',
        builder: (_, _) => const CatTrackerPage(initialDeviceMode: true),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, _) => const NotificationsPage(),
      ),
      GoRoute(
        path: '/notifications/post/:id',
        builder: (_, state) => NotificationPostDetailPage(
          postId: state.pathParameters['id']!,
          openComments: state.uri.queryParameters['comments'] == '1',
        ),
      ),
      GoRoute(
        path: '/notifications/connections',
        builder: (_, _) =>
            const ConnectionsPage(initialTab: ConnectionsTab.followers),
      ),
      GoRoute(
        path: '/notifications/treats',
        builder: (_, _) => const ReceivedTreatsPage(),
      ),
      GoRoute(
        path: '/notifications/help',
        builder: (_, _) => const NotificationHelpAlertPage(),
      ),
      GoRoute(
        path: '/notifications/health',
        builder: (_, state) =>
            CatHealthPage(initialCatId: state.uri.queryParameters['cat']),
      ),
      GoRoute(
        path: '/treats',
        builder: (_, state) =>
            TreatsPage(initialRecipientId: state.uri.queryParameters['to']),
      ),
      GoRoute(path: '/messages', builder: (_, _) => const MessagesPage()),
      GoRoute(
        path: '/messages/:id',
        builder: (_, state) =>
            ChatRoomPage(threadId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/cat-profile', builder: (_, _) => const CatIdPage()),
      GoRoute(
        path: '/cat-ai/face-check',
        builder: (_, _) => const CatFaceCheckPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/', builder: (_, _) => const HomePage()),
              GoRoute(path: '/search', builder: (_, _) => const SearchPage()),
              GoRoute(path: '/tag', builder: (_, _) => const TagPage()),
            ],
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
              GoRoute(path: '/nearby', builder: (_, _) => const NearbyPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/cat-ai', builder: (_, _) => const CatAiPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/help', builder: (_, _) => const HelpPage()),
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
