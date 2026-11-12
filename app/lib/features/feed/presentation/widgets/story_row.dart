import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../domain/entities/feed_user.dart';

/// แถวสตอรี่เหนือฟีด — วงแหวนฟ้า = ยังไม่ได้ดู, เทา = ดูแล้ว พร้อมเฟดขอบซ้าย-ขวาเมื่อเลื่อนได้
class StoryRow extends StatefulWidget {
  const StoryRow({super.key, required this.users});

  final List<FeedUser> users;

  @override
  State<StoryRow> createState() => _StoryRowState();
}

class _StoryRowState extends State<StoryRow> {
  final ScrollController _scrollController = ScrollController();
  bool _fadeLeft = false;
  bool _fadeRight = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateFades);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateFades());
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_updateFades)
      ..dispose();
    super.dispose();
  }

  void _updateFades() {
    if (!mounted || !_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final nextLeft = pos.pixels > 2;
    final nextRight = pos.pixels < (pos.maxScrollExtent - 2);
    if (nextLeft != _fadeLeft || nextRight != _fadeRight) {
      setState(() {
        _fadeLeft = nextLeft;
        _fadeRight = nextRight;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.users.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.page,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            _fadeLeft ? Colors.transparent : Colors.white,
            Colors.white,
            Colors.white,
            _fadeRight ? Colors.transparent : Colors.white,
          ],
          stops: const [0.0, 0.06, 0.9, 1.0],
        ).createShader(bounds),
        blendMode: BlendMode.dstIn,
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              for (final user in widget.users) ...[
                _Story(user: user),
                if (user != widget.users.last) const SizedBox(width: 14),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Story extends StatelessWidget {
  const _Story({required this.user});

  final FeedUser user;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68,
      child: Column(
        children: [
          StoryAvatar(
            source: user.avatar,
            bg: user.avatarBg,
            size: 56,
            hasUnseenStory: user.hasUnseenStory,
            showSeenRing: true,
          ),
          const SizedBox(height: 6),
          Text(
            user.handle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.4,
              color: AppColors.text2,
            ),
          ),
        ],
      ),
    );
  }
}
