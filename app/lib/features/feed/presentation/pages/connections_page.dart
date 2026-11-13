import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/toast_pill.dart';
import '../../../messages/domain/entities/messages_data.dart';
import '../../../messages/presentation/providers/messages_controller.dart';
import '../../domain/entities/feed_user.dart';
import '../providers/feed_controller.dart';

enum ConnectionsTab { followers, following, suggested }

enum _SortOrder { defaultOrder, latest, alphabetical }

/// หน้า "ผู้ติดตาม / กำลังติดตาม / แนะนำ" — เปิดจากแถวกำลังติดตามในแท็บฟีด
class ConnectionsPage extends ConsumerStatefulWidget {
  const ConnectionsPage({
    super.key,
    this.initialTab = ConnectionsTab.following,
  });

  final ConnectionsTab initialTab;

  @override
  ConsumerState<ConnectionsPage> createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends ConsumerState<ConnectionsPage>
    with ToastMixin {
  late ConnectionsTab _tab = widget.initialTab;
  final _search = TextEditingController();
  _SortOrder _sort = _SortOrder.defaultOrder;

  @override
  void dispose() {
    disposeToast();
    _search.dispose();
    super.dispose();
  }

  Future<void> _toggleFollow(FeedUser user) async {
    final failure = await ref
        .read(feedControllerProvider.notifier)
        .toggleFollowUser(user);
    if (!mounted || failure == null) return;
    showToast(failure.message);
  }

  Future<void> _openMessage(FeedUser user) async {
    final peer = ChatUser(
      id: user.id,
      handle: user.handle,
      name: user.displayName,
      avatarSource: user.avatar,
      avatarBg: user.avatarBg,
    );
    final thread = await ref
        .read(messagesControllerProvider.notifier)
        .openOrCreateForPeer(peer);
    if (!mounted) return;
    context.push('/messages/${thread.id}');
  }

  void _cycleSort() {
    setState(() {
      _sort = switch (_sort) {
        _SortOrder.defaultOrder => _SortOrder.latest,
        _SortOrder.latest => _SortOrder.alphabetical,
        _SortOrder.alphabetical => _SortOrder.defaultOrder,
      };
    });
  }

  List<FeedUser> _filteredUsers(FeedState state) {
    final base = switch (_tab) {
      ConnectionsTab.followers => state.followerAccounts,
      ConnectionsTab.following => state.followedAccounts,
      ConnectionsTab.suggested => state.allSuggestedAccounts,
    };
    final q = _search.text.trim().toLowerCase();
    final filtered = q.isEmpty
        ? [...base]
        : base.where((u) {
            final handleMatch = u.handle.toLowerCase().contains(q);
            final nameMatch = (u.name ?? '').toLowerCase().contains(q);
            return handleMatch || nameMatch;
          }).toList();
    switch (_sort) {
      case _SortOrder.defaultOrder:
        return filtered;
      case _SortOrder.latest:
        return filtered.reversed.toList();
      case _SortOrder.alphabetical:
        filtered.sort(
          (a, b) => a.handle.toLowerCase().compareTo(b.handle.toLowerCase()),
        );
        return filtered;
    }
  }

  String _currentHandle(FeedState state) {
    for (final account in state.accounts) {
      if (account.id == 'me') return account.handle;
    }
    return 'jutamas.lk';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(feedControllerProvider);
    final users = _filteredUsers(state);
    final followersCount = state.followerAccounts.length;
    final followingCount = state.followedAccounts.length;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              ColoredBox(
                color: AppColors.page,
                child: SafeArea(
                  bottom: false,
                  child: _HeaderBar(
                    handle: _currentHandle(state),
                    onBack: () => Navigator.of(context).pop(),
                    onAddFriend: () =>
                        setState(() => _tab = ConnectionsTab.suggested),
                  ),
                ),
              ),
              _TabBar(
                tab: _tab,
                followersCount: followersCount,
                followingCount: followingCount,
                onChanged: (t) => setState(() => _tab = t),
              ),
              _SearchBox(
                controller: _search,
                onChanged: (_) => setState(() {}),
              ),
              _SortBar(sort: _sort, onToggle: _cycleSort),
              Expanded(
                child: users.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 40,
                          ),
                          child: Text(
                            _search.text.trim().isNotEmpty
                                ? 'ไม่พบบัญชีที่ค้นหา'
                                : switch (_tab) {
                                    ConnectionsTab.followers =>
                                      'ยังไม่มีผู้ติดตาม',
                                    ConnectionsTab.following =>
                                      'ยังไม่ได้ติดตามใคร',
                                    ConnectionsTab.suggested =>
                                      'ติดตามครบทุกบัญชีแล้ว',
                                  },
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: users.length,
                        padding: const EdgeInsets.only(bottom: 16),
                        itemBuilder: (_, i) {
                          final user = users[i];
                          return _AccountRow(
                            tab: _tab,
                            user: user,
                            onToggleFollow: () => _toggleFollow(user),
                            onMessage: () => _openMessage(user),
                            onRemoveFollower: () => ref
                                .read(feedControllerProvider.notifier)
                                .removeFollower(user),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        if (toastMessage != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: IgnorePointer(
              child: Center(child: ToastPill(message: toastMessage!)),
            ),
          ),
      ],
    );
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.handle,
    required this.onBack,
    required this.onAddFriend,
  });

  final String handle;
  final VoidCallback onBack;
  final VoidCallback onAddFriend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            Semantics(
              button: true,
              label: 'ย้อนกลับ',
              child: IconButton(
                onPressed: onBack,
                icon: const Icon(
                  LucideIcons.chevronLeft,
                  size: 24,
                  color: AppColors.text,
                ),
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              ),
            ),
            Expanded(
              child: Text(
                handle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ),
            Semantics(
              button: true,
              label: 'ค้นหาเพื่อนเพิ่ม',
              child: IconButton(
                onPressed: onAddFriend,
                icon: const Icon(
                  LucideIcons.userPlus,
                  size: 24,
                  color: AppColors.text,
                ),
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.tab,
    required this.followersCount,
    required this.followingCount,
    required this.onChanged,
  });

  final ConnectionsTab tab;
  final int followersCount;
  final int followingCount;
  final ValueChanged<ConnectionsTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = [
      (ConnectionsTab.followers, '$followersCount ผู้ติดตาม'),
      (ConnectionsTab.following, '$followingCount กำลังติดตาม'),
      (ConnectionsTab.suggested, 'แนะนำ'),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          for (final (value, label) in items)
            Expanded(
              child: Semantics(
                button: true,
                selected: tab == value,
                label: label,
                child: InkWell(
                  onTap: () => onChanged(value),
                  child: SizedBox(
                    height: 44,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: tab == value
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: tab == value
                                  ? AppColors.text
                                  : AppColors.muted,
                            ),
                          ),
                        ),
                        if (tab == value)
                          Positioned(
                            left: 12,
                            right: 12,
                            bottom: 0,
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: AppColors.ink,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.soft,
          borderRadius: BorderRadius.circular(14),
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          textAlignVertical: TextAlignVertical.center,
          style: const TextStyle(fontSize: 15, color: AppColors.text),
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            hintText: 'ค้นหาชื่อผู้ใช้หรือชื่อที่แสดง',
            hintStyle: const TextStyle(fontSize: 15, color: AppColors.muted),
            prefixIcon: const Icon(
              LucideIcons.search,
              size: 20,
              color: AppColors.muted,
            ),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                    icon: const Icon(
                      LucideIcons.x,
                      size: 16,
                      color: AppColors.muted,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _SortBar extends StatelessWidget {
  const _SortBar({required this.sort, required this.onToggle});

  final _SortOrder sort;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final label = switch (sort) {
      _SortOrder.defaultOrder => 'ค่าเริ่มต้น',
      _SortOrder.latest => 'ล่าสุด',
      _SortOrder.alphabetical => 'ชื่อ ก–ฮ / A–Z',
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
      child: Row(
        children: [
          const Text(
            'เรียงลำดับตาม ',
            style: TextStyle(fontSize: 13.5, color: AppColors.text2),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const Spacer(),
          Semantics(
            button: true,
            label: 'เปลี่ยนการเรียงลำดับ (ตอนนี้: $label)',
            child: IconButton(
              onPressed: onToggle,
              icon: const Icon(
                LucideIcons.arrowDownUp,
                size: 20,
                color: AppColors.text,
              ),
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.tab,
    required this.user,
    required this.onToggleFollow,
    required this.onMessage,
    required this.onRemoveFollower,
  });

  final ConnectionsTab tab;
  final FeedUser user;
  final VoidCallback onToggleFollow;
  final VoidCallback onMessage;
  final VoidCallback onRemoveFollower;

  @override
  Widget build(BuildContext context) {
    final (
      String buttonLabel,
      String semanticLabel,
      Color bg,
      Color borderColor,
      double borderWidth,
      Color textColor,
      VoidCallback onTap,
    ) = switch (tab) {
      ConnectionsTab.followers when user.isFollowing => (
        'ส่งข้อความ',
        'ส่งข้อความถึง ${user.handle}',
        AppColors.soft,
        AppColors.line2,
        1.0,
        AppColors.text,
        onMessage,
      ),
      ConnectionsTab.followers => (
        'ติดตามกลับ',
        'ติดตามกลับ ${user.handle}',
        AppColors.btn,
        AppColors.btnBorder,
        1.5,
        AppColors.ink,
        onToggleFollow,
      ),
      ConnectionsTab.following => (
        'กำลังติดตาม',
        'เลิกติดตาม ${user.handle}',
        AppColors.btnFollowing,
        AppColors.line2,
        1.0,
        AppColors.text,
        onToggleFollow,
      ),
      ConnectionsTab.suggested => (
        'ติดตาม',
        'ติดตาม ${user.handle}',
        AppColors.btn,
        AppColors.btnBorder,
        1.5,
        AppColors.ink,
        onToggleFollow,
      ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Row(
          children: [
            StoryAvatar(
              source: user.avatar,
              bg: user.avatarBg,
              size: 43,
              hasUnseenStory: user.hasUnseenStory,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    user.handle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  if (user.name != null && user.name!.isNotEmpty)
                    Text(
                      user.name!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              button: true,
              label: semanticLabel,
              child: GestureDetector(
                onTap: onTap,
                behavior: HitTestBehavior.opaque,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: Center(
                    child: Container(
                      width: 112,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: borderColor,
                          width: borderWidth,
                        ),
                      ),
                      child: Text(
                        buttonLabel,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (tab == ConnectionsTab.followers)
              Semantics(
                button: true,
                label: 'ลบ ${user.handle} ออกจากผู้ติดตาม',
                child: IconButton(
                  onPressed: onRemoveFollower,
                  icon: const Icon(
                    LucideIcons.x,
                    size: 20,
                    color: AppColors.text,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 44,
                  ),
                ),
              )
            else
              const SizedBox(width: 36),
          ],
        ),
      ),
    );
  }
}
