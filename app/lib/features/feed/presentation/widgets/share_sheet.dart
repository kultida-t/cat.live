import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/social_brand_icons.dart';
import '../../../../core/widgets/toast_pill.dart';
import '../../domain/entities/feed_user.dart';
import '../../domain/entities/post.dart';
import '../providers/feed_providers.dart';

/// ชีตแชร์โพสต์ — ส่งให้เพื่อนในแอป คัดลอกลิงก์ แชร์ต่อ LINE/Facebook/IG/TikTok/อีเมล
/// (หน้าตาและข้อความตามเว็บ www.แมว.live)
Future<void> showShareSheet(BuildContext context, Post post) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x594A3428),
    builder: (context) => _ShareSheet(post: post),
  );
}

enum _Step { main, apps, email }

class _ShareSheet extends ConsumerStatefulWidget {
  const _ShareSheet({required this.post});

  final Post post;

  @override
  ConsumerState<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends ConsumerState<_ShareSheet> with ToastMixin {
  final _search = TextEditingController();
  final _email = TextEditingController();
  final _selected = <String>{};
  var _step = _Step.main;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    _email.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    disposeToast();
    _search.dispose();
    _email.dispose();
    super.dispose();
  }

  String get _url => AppConfig.postUrl(widget.post.id);

  String get _snippet {
    final caption = widget.post.caption;
    return caption.length > 80 ? caption.substring(0, 80) : caption;
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _url));
    if (mounted) showToast('คัดลอกลิงก์แล้ว');
  }

  Future<bool> _open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Exception {
      return false;
    }
  }

  Future<void> _openApp(String label, Uri uri) async {
    final ok = await _open(uri);
    if (mounted) showToast(ok ? 'เปิด $label แล้ว' : 'เปิด $label ไม่ได้');
  }

  Future<void> _copyThenOpen(String label, Uri uri) async {
    await Clipboard.setData(ClipboardData(text: _url));
    final ok = await _open(uri);
    if (mounted) {
      showToast(
        ok
            ? 'คัดลอกลิงก์แล้ว · วางใน $label ได้เลย'
            : 'คัดลอกลิงก์แล้ว แต่เปิด $label ไม่ได้',
      );
    }
  }

  Future<void> _systemShare() async {
    try {
      await SharePlus.instance.share(
        ShareParams(title: 'แมว.live', text: '$_snippet\n$_url'),
      );
    } on Exception {
      await _copy();
    }
  }

  Future<void> _sendEmail() async {
    final to = _email.text.trim();
    final subject = '${widget.post.author.displayName} · แมว.live';
    final body =
        '$_snippet\n\n$_url\n\nส่งจาก $placeholderCurrentUserEmail ผ่าน แมว.live';
    final uri = Uri(
      scheme: 'mailto',
      path: to,
      query:
          'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );
    final ok = await _open(uri);
    if (mounted) showToast(ok ? 'เปิดแอปอีเมลแล้ว' : 'เปิดแอปอีเมลไม่ได้');
  }

  void _sendToFriends() {
    // ส่งข้อความในแอปจริงต้องรอระบบแชต (เฟสถัดไป) — ตอนนี้แจ้งผลเหมือนเว็บ
    showToast('ส่งให้ ${_selected.length} คนแล้ว');
    setState(_selected.clear);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final accounts = ref.watch(accountsProvider);
    final query = _search.text.trim().toLowerCase();

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: (media.size.height - media.viewInsets.bottom) * 0.85,
            ),
            child: Container(
              padding: EdgeInsets.only(bottom: 16 + media.padding.bottom),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 10),
                    decoration: BoxDecoration(
                      color: AppColors.line2,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 4, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'แชร์',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                        IconButton(
                          tooltip: 'ปิด',
                          onPressed: () => Navigator.pop(context),
                          constraints: const BoxConstraints(
                            minWidth: 44,
                            minHeight: 44,
                          ),
                          icon: const Icon(
                            LucideIcons.x,
                            size: 24,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _SearchField(controller: _search),
                  Flexible(
                    child: accounts.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.muted,
                        ),
                      ),
                      error: (_, _) => _EmptyNote(
                        'โหลดรายชื่อไม่สำเร็จ',
                        onRetry: () => ref.invalidate(accountsProvider),
                      ),
                      data: (all) {
                        final shown = [
                          for (final a in all)
                            if (a.id != 'me' &&
                                a.handle.toLowerCase().contains(query))
                              a,
                        ];
                        return _AccountGrid(
                          accounts: shown,
                          selected: _selected,
                          onToggle: (id) => setState(() {
                            _selected.contains(id)
                                ? _selected.remove(id)
                                : _selected.add(id);
                          }),
                        );
                      },
                    ),
                  ),
                  _bottom(),
                ],
              ),
            ),
          ),
          if (toastMessage != null)
            Positioned(
              left: 0,
              right: 0,
              top: -56,
              child: IgnorePointer(
                child: Center(child: ToastPill(message: toastMessage!)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _bottom() {
    if (_selected.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: _PastelButton(
          label: _selected.length > 1
              ? 'ส่งแยกกัน (${_selected.length})'
              : 'ส่ง',
          height: 48,
          fontSize: 15,
          onTap: _sendToFriends,
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: switch (_step) {
        _Step.email => _emailForm(),
        _Step.apps => _apps(),
        _Step.main => _main(),
      },
    );
  }

  Widget _main() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
          constraints: const BoxConstraints(minHeight: 44),
          decoration: BoxDecoration(
            color: AppColors.soft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.copy, size: 16, color: AppColors.muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _url.replaceFirst(RegExp(r'^https?://'), ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, color: AppColors.text2),
                ),
              ),
              _PastelButton(
                label: 'คัดลอก',
                height: 36,
                fontSize: 13,
                radius: 10,
                horizontalPadding: 14,
                onTap: _copy,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _OptionButton(
                icon: LucideIcons.copy,
                label: 'คัดลอกลิงก์',
                onTap: _copy,
              ),
              _OptionButton(
                icon: LucideIcons.share2,
                label: 'แชร์ไป…',
                onTap: () => setState(() => _step = _Step.apps),
              ),
              _OptionButton(
                icon: LucideIcons.mail,
                label: 'อีเมล',
                onTap: () => setState(() => _step = _Step.email),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _subHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'ย้อนกลับ',
            onPressed: () => setState(() => _step = _Step.main),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
            icon: const Icon(
              LucideIcons.arrowLeft,
              size: 20,
              color: AppColors.text,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.text2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _apps() {
    final line = Uri.https('social-plugins.line.me', '/lineit/share', {
      'url': _url,
      'text': _snippet,
    });
    final facebook = Uri.https('www.facebook.com', '/sharer/sharer.php', {
      'u': _url,
    });
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _subHeader('แชร์ไปที่แอป'),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              _AppButton(
                label: 'LINE',
                background: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.brandLine,
                ),
                glyph: const LineLogoIcon(size: 30),
                onTap: () => _openApp('LINE', line),
              ),
              _AppButton(
                label: 'Facebook',
                background: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.brandFacebook,
                ),
                glyph: const FacebookLogoIcon(size: 26),
                onTap: () => _openApp('Facebook', facebook),
              ),
              _AppButton(
                label: 'Instagram',
                background: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: Alignment(-0.4, 2.1),
                    radius: 2.2,
                    colors: [
                      Color(0xFFFDF497),
                      Color(0xFFFD5949),
                      Color(0xFFD6249F),
                      Color(0xFF285AEB),
                    ],
                    stops: [0, 0.45, 0.6, 0.9],
                  ),
                ),
                glyph: const InstagramLogoIcon(size: 26),
                onTap: () => _copyThenOpen(
                  'Instagram',
                  Uri.https('www.instagram.com', '/direct/inbox/'),
                ),
              ),
              _AppButton(
                label: 'TikTok',
                background: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF111111),
                ),
                glyph: const TikTokLogoIcon(size: 26),
                onTap: () => _copyThenOpen(
                  'TikTok',
                  Uri.https('www.tiktok.com', '/messages'),
                ),
              ),
              _AppButton(
                label: 'อื่น ๆ',
                background: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.soft,
                ),
                glyph: const Icon(
                  LucideIcons.ellipsis,
                  size: 24,
                  color: AppColors.ink,
                ),
                onTap: _systemShare,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _emailForm() {
    final canSend = _email.text.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Transform.translate(
            offset: const Offset(-8, 0),
            child: _subHeader('ส่งทางอีเมล'),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Container(
                    constraints: const BoxConstraints(minHeight: 44),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: const BoxDecoration(
                      color: AppColors.soft,
                      border: Border(bottom: BorderSide(color: AppColors.line)),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 44,
                          child: Text(
                            'จาก',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            placeholderCurrentUserEmail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                        Text(
                          'บัญชีของคุณ',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    constraints: const BoxConstraints(minHeight: 44),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    color: Colors.white,
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 44,
                          child: Text(
                            'ถึง',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _email,
                            autofocus: true,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.text,
                            ),
                            decoration: const InputDecoration(
                              isCollapsed: true,
                              border: InputBorder.none,
                              hintText: 'อีเมลเพื่อน',
                              hintStyle: TextStyle(
                                fontSize: 15,
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Opacity(
            opacity: canSend ? 1 : 0.4,
            child: _PastelButton(
              label: 'ส่งอีเมล',
              height: 48,
              fontSize: 15,
              radius: 12,
              bold: true,
              leading: const Icon(
                LucideIcons.mail,
                size: 20,
                color: AppColors.ink,
              ),
              onTap: canSend ? _sendEmail : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      constraints: const BoxConstraints(minHeight: 44),
      decoration: BoxDecoration(
        color: AppColors.soft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.search, size: 20, color: AppColors.muted),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(fontSize: 15, color: AppColors.text),
              decoration: const InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'ค้นหา',
                hintStyle: TextStyle(fontSize: 15, color: AppColors.muted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountGrid extends StatelessWidget {
  const _AccountGrid({
    required this.accounts,
    required this.selected,
    required this.onToggle,
  });

  final List<FeedUser> accounts;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) return const _EmptyNote('ไม่พบบัญชีนี้');
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Wrap(
        runSpacing: 16,
        children: [
          for (final a in accounts)
            FractionallySizedBox(
              widthFactor: 1 / 3,
              child: _AccountTile(
                account: a,
                selected: selected.contains(a.id),
                onTap: () => onToggle(a.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.account,
    required this.selected,
    required this.onTap,
  });

  final FeedUser account;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: account.handle,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                StoryAvatar(
                  source: account.avatar,
                  bg: account.avatarBg,
                  size: 64,
                  hasUnseenStory: true,
                  ringWidth: 3,
                  gapWidth: 3,
                ),
                if (selected)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFCFE3FF),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        LucideIcons.check,
                        size: 14,
                        color: Color(0xFF24508F),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 100),
              child: Text(
                account.handle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? AppColors.text : AppColors.text2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote(this.text, {this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.muted),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('ลองใหม่')),
        ],
      ),
    );
  }
}

class _PastelButton extends StatelessWidget {
  const _PastelButton({
    required this.label,
    required this.onTap,
    required this.height,
    required this.fontSize,
    this.radius = 8,
    this.horizontalPadding = 0,
    this.bold = false,
    this.leading,
  });

  final String label;
  final VoidCallback? onTap;
  final double height;
  final double fontSize;
  final double radius;
  final double horizontalPadding;
  final bool bold;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.btn,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.btnBorder, width: 1.5),
      ),
      child: Row(
        mainAxisSize: horizontalPadding > 0
            ? MainAxisSize.min
            : MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 8)],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.soft,
            ),
            child: Icon(icon, size: 24, color: AppColors.ink),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.text),
          ),
        ],
      ),
    );
  }
}

class _AppButton extends StatelessWidget {
  const _AppButton({
    required this.label,
    required this.background,
    required this.glyph,
    required this.onTap,
  });

  final String label;
  final BoxDecoration background;
  final Widget glyph;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        label: 'แชร์ไป $label',
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: background.copyWith(
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F000000),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: glyph,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: AppColors.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
