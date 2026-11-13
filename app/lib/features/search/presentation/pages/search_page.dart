import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide SearchController;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/config/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/error_view.dart';
import '../../domain/entities/search_account.dart';
import '../../domain/entities/search_category.dart';
import '../../domain/entities/search_post.dart';
import '../l10n/search_l10n.dart';
import '../providers/search_controller.dart';
import '../widgets/search_header.dart';
import '../widgets/search_post_card.dart';
import '../widgets/search_skeleton.dart';

/// หน้าค้นหา (/search) — ตรงตามเว็บต้นแบบ www.แมว.live/search
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _applyKeyword(String keyword) {
    _textController.value = TextEditingValue(
      text: keyword,
      selection: TextSelection.collapsed(offset: keyword.length),
    );
    ref.read(searchControllerProvider.notifier).setQuery(keyword);
  }

  void _clearKeyword() {
    _textController.clear();
    ref.read(searchControllerProvider.notifier).clearQuery();
  }

  void _dismissKeyboard() {
    if (_focusNode.hasFocus) {
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(appLocaleProvider);
    final l10n = SearchL10n(locale);
    final state = ref.watch(searchControllerProvider);
    final controller = ref.read(searchControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.page,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _dismissKeyboard,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              SearchHeader(
                controller: _textController,
                focusNode: _focusNode,
                l10n: l10n,
                hasQuery: state.query.isNotEmpty,
                onBack: () {
                  _dismissKeyboard();
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/');
                  }
                },
                onChanged: controller.setQuery,
                onClear: _clearKeyword,
              ),
              Expanded(child: _buildBody(context, state, controller, l10n)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    SearchState state,
    SearchController controller,
    SearchL10n l10n,
  ) {
    if (state.isLoading && state.data == null) {
      return const SearchSkeleton();
    }
    if (state.failure != null && state.data == null) {
      return ErrorView(
        message: state.failure!.message,
        onRetry: controller.load,
      );
    }

    final data = state.data;
    if (data == null) {
      return const SearchSkeleton();
    }

    final accounts = state.filteredAccounts;
    final posts = state.filteredPosts;

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
      children: [
        _CategoryRow(
          selected: state.selectedCategory,
          l10n: l10n,
          onSelect: (category) {
            _dismissKeyboard();
            controller.selectCategory(category);
          },
        ),
        if (state.isDefaultView && data.trendingKeywords.isNotEmpty) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.trendingTitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final keyword in data.trendingKeywords)
                      _TrendingChip(
                        keyword: keyword,
                        onTap: () {
                          _dismissKeyboard();
                          _applyKeyword(keyword);
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
        if (accounts.isNotEmpty) ...[
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.accountsTitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                for (final account in accounts) _AccountRow(account: account),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.isDefaultView
                    ? l10n.recommendedPosts
                    : l10n.postsCount(posts.length),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 10),
              if (posts.isEmpty)
                _EmptySearchResult(
                  trimmedQuery: state.query.trim(),
                  l10n: l10n,
                  onAskCatAi: () {
                    _dismissKeyboard();
                    context.go('/cat-ai');
                  },
                )
              else
                _PostsList(
                  posts: posts,
                  l10n: l10n,
                  onTapPost: (post) {
                    _dismissKeyboard();
                    context.push('/p/${post.id}');
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryRow extends StatefulWidget {
  const _CategoryRow({
    required this.selected,
    required this.l10n,
    required this.onSelect,
  });

  final SearchCategory selected;
  final SearchL10n l10n;
  final ValueChanged<SearchCategory> onSelect;

  @override
  State<_CategoryRow> createState() => _CategoryRowState();
}

class _CategoryRowState extends State<_CategoryRow> {
  final _scrollController = ScrollController();
  final _keys = {for (final c in SearchCategory.values) c: GlobalKey()};
  bool _canScrollLeft = false;
  bool _canScrollRight = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateFades);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateFades());
  }

  @override
  void didUpdateWidget(covariant _CategoryRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _keys[widget.selected]?.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            alignment: 0.5,
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateFades);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateFades() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final left = pos.pixels > 4;
    final right = pos.pixels < pos.maxScrollExtent - 4;
    if (left != _canScrollLeft || right != _canScrollRight) {
      setState(() {
        _canScrollLeft = left;
        _canScrollRight = right;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ShaderMask(
        shaderCallback: (bounds) {
          final leftColor = _canScrollLeft ? Colors.transparent : Colors.white;
          final rightColor = _canScrollRight
              ? Colors.transparent
              : Colors.white;
          return LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [leftColor, Colors.white, Colors.white, rightColor],
            stops: const [0.0, 0.06, 0.88, 1.0],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: ListView.separated(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: SearchCategory.values.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final category = SearchCategory.values[index];
            final isSelected = category == widget.selected;
            final label = widget.l10n.categoryLabel(category);
            return KeyedSubtree(
              key: _keys[category],
              child: Semantics(
                button: true,
                selected: isSelected,
                label: label,
                excludeSemantics: true,
                child: InkWell(
                  onTap: () => widget.onSelect(category),
                  borderRadius: BorderRadius.circular(999),
                  child: Center(
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.ink : AppColors.card,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isSelected ? AppColors.ink : AppColors.line,
                        ),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppColors.text2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TrendingChip extends StatelessWidget {
  const _TrendingChip({required this.keyword, required this.onTap});

  final String keyword;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: keyword,
      excludeSemantics: true,
      child: Material(
        color: AppColors.soft,
        borderRadius: BorderRadius.circular(999),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  LucideIcons.search,
                  size: 14,
                  color: AppColors.muted,
                ),
                const SizedBox(width: 6),
                Text(
                  keyword,
                  style: const TextStyle(fontSize: 14, color: AppColors.text),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.account});

  final SearchAccount account;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          AppAvatar(source: account.avatarUrl, bg: account.avatarBg, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  '@${account.handle}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PostsList extends StatelessWidget {
  const _PostsList({
    required this.posts,
    required this.l10n,
    required this.onTapPost,
  });

  final List<SearchPost> posts;
  final SearchL10n l10n;
  final ValueChanged<SearchPost> onTapPost;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < posts.length; i++) ...[
          SearchPostCard(
            post: posts[i],
            l10n: l10n,
            onTap: () => onTapPost(posts[i]),
          ),
          if (i < posts.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _EmptySearchResult extends StatefulWidget {
  const _EmptySearchResult({
    required this.trimmedQuery,
    required this.l10n,
    required this.onAskCatAi,
  });

  final String trimmedQuery;
  final SearchL10n l10n;
  final VoidCallback onAskCatAi;

  @override
  State<_EmptySearchResult> createState() => _EmptySearchResultState();
}

class _EmptySearchResultState extends State<_EmptySearchResult> {
  late final TapGestureRecognizer _tapRecognizer;

  @override
  void initState() {
    super.initState();
    _tapRecognizer = TapGestureRecognizer()..onTap = widget.onAskCatAi;
  }

  @override
  void didUpdateWidget(covariant _EmptySearchResult oldWidget) {
    super.didUpdateWidget(oldWidget);
    _tapRecognizer.onTap = widget.onAskCatAi;
  }

  @override
  void dispose() {
    _tapRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text.rich(
          TextSpan(
            style: const TextStyle(fontSize: 14, color: AppColors.muted),
            children: [
              TextSpan(text: widget.l10n.emptyPrefix(widget.trimmedQuery)),
              TextSpan(
                text: widget.l10n.askCatAi,
                recognizer: _tapRecognizer,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
