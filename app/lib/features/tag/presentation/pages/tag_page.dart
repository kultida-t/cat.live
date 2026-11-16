import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/config/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/toast_pill.dart';
import '../../domain/entities/tag_product_data.dart';
import '../l10n/tag_l10n.dart';
import '../providers/tag_controller.dart';
import '../widgets/tag_sections_features.dart';
import '../widgets/tag_sections_top.dart';
import '../widgets/tag_skeleton.dart';

/// หน้า แมว.live Tag (/tag) — ระดับ UI Mock ตรงตามเว็บต้นแบบ www.แมว.live/tag
class TagPage extends ConsumerStatefulWidget {
  const TagPage({super.key});

  @override
  ConsumerState<TagPage> createState() => _TagPageState();
}

class _TagPageState extends ConsumerState<TagPage> with ToastMixin {
  @override
  void dispose() {
    disposeToast();
    super.dispose();
  }

  void _handlePlaySound(bool isEn) {
    ref.read(tagControllerProvider.notifier).triggerSoundPing();
    showToast(TagL10n.soundPlayingToast(isEn));
  }

  void _handleToggleFlashlight(bool isEn) {
    final controller = ref.read(tagControllerProvider.notifier);
    final nextOn = !ref.read(tagControllerProvider).isFlashlightOn;
    controller.toggleFlashlight();
    showToast(
      nextOn ? TagL10n.flashlightOnToast(isEn) : TagL10n.flashlightOffToast(isEn),
    );
  }

  void _showOrderSummarySheet(
    BuildContext context,
    TagState state,
    bool isEn,
  ) {
    final data = state.data;
    final tagColor = state.selectedTagColor;
    final collarColor = state.selectedCollarColor;
    if (data == null || tagColor == null || collarColor == null) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.line2,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  TagL10n.orderSheetTitle(isEn),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.tagTextDark,
                  ),
                ),
                const SizedBox(height: 14),
                _SelectionRow(
                  label: TagL10n.orderSheetTagLabel(isEn),
                  option: tagColor,
                  isEn: isEn,
                ),
                const SizedBox(height: 10),
                _SelectionRow(
                  label: TagL10n.orderSheetCollarLabel(isEn),
                  option: collarColor,
                  isEn: isEn,
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.tagCardMintSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    TagL10n.orderSheetNote(isEn),
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.tagTeal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(sheetCtx).pop(),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: AppColors.tagTeal,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    TagL10n.close(isEn),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tagControllerProvider);
    final controller = ref.read(tagControllerProvider.notifier);
    final isEn = ref.watch(appLocaleProvider) == 'en';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.25, 0.65, 1.0],
            colors: [
              AppColors.tagBgTop,
              AppColors.tagBgTop,
              AppColors.tagBgMid,
              AppColors.tagBgBottom,
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Column(
                children: [
                  _TagHeader(
                    isEn: isEn,
                    onBack: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/');
                      }
                    },
                  ),
                  Expanded(
                    child: switch (state.status) {
                      TagStatus.loading => const TagSkeleton(),
                      TagStatus.error => ErrorView(
                        title: TagL10n.loadError(isEn),
                        message:
                            state.errorMessage ?? TagL10n.emptySubtitle(isEn),
                        onRetry: controller.retry,
                      ),
                      TagStatus.empty => _EmptyTagCard(
                        isEn: isEn,
                        onRetry: controller.retry,
                      ),
                      TagStatus.ready => _buildReadyBody(state, controller, isEn),
                    },
                  ),
                ],
              ),
              if (state.status == TagStatus.ready && state.data != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _BottomBuyBar(
                    priceThb: state.data!.priceThb,
                    isEn: isEn,
                    onBuyTap: () =>
                        _showOrderSummarySheet(context, state, isEn),
                  ),
                ),
              if (toastMessage != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 92,
                  child: IgnorePointer(
                    child: Center(child: ToastPill(message: toastMessage!)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadyBody(
    TagState state,
    TagController controller,
    bool isEn,
  ) {
    final data = state.data!;
    final tagColor = state.selectedTagColor!;
    final collarColor = state.selectedCollarColor!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 116),
      children: [
        TagSectionsTop(
          data: data,
          selectedTagColor: tagColor,
          selectedCollarColor: collarColor,
          isEn: isEn,
          onSelectTagColor: controller.selectTagColor,
          onSelectCollarColor: controller.selectCollarColor,
        ),
        const SizedBox(height: 68),
        TagSectionsFeatures(
          data: data,
          isEn: isEn,
          soundTrigger: state.soundTrigger,
          isFlashlightOn: state.isFlashlightOn,
          onPlaySound: () => _handlePlaySound(isEn),
          onToggleFlashlight: () => _handleToggleFlashlight(isEn),
        ),
      ],
    );
  }
}

class _TagHeader extends StatelessWidget {
  const _TagHeader({required this.isEn, required this.onBack});

  final bool isEn;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.tagBgTop,
      padding: const EdgeInsets.fromLTRB(8, 6, 16, 4),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: TagL10n.backLabel(isEn),
            excludeSemantics: true,
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(12),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  LucideIcons.chevronLeft,
                  size: 24,
                  color: AppColors.tagTextDark,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            TagL10n.pageTitle(isEn),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.tagTextDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBuyBar extends StatelessWidget {
  const _BottomBuyBar({
    required this.priceThb,
    required this.isEn,
    required this.onBuyTap,
  });

  final int priceThb;
  final bool isEn;
  final VoidCallback onBuyTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.tagBgBottom.withValues(alpha: 0.0),
            AppColors.tagBgBottom.withValues(alpha: 0.90),
            AppColors.tagBgBottom,
          ],
        ),
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                TagL10n.fromLabel(isEn),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.tagTextMuted,
                ),
              ),
              Text(
                '฿$priceThb',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.tagTextDark,
                ),
              ),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Semantics(
              button: true,
              label: TagL10n.buyNow(isEn),
              excludeSemantics: true,
              child: InkWell(
                onTap: onBuyTap,
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppColors.tagTealLight, AppColors.tagTeal],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.tagTealDeep.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      TagL10n.buyNow(isEn),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
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

class _SelectionRow extends StatelessWidget {
  const _SelectionRow({
    required this.label,
    required this.option,
    required this.isEn,
  });

  final String label;
  final TagColorOption option;
  final bool isEn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.tagBgTop,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.tagBorder),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.tagTextMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Color(option.colorValue),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.line2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isEn ? option.nameEn : option.nameTh,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.tagTextDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTagCard extends StatelessWidget {
  const _EmptyTagCard({required this.isEn, required this.onRetry});

  final bool isEn;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.tag,
              size: 40,
              color: AppColors.tagTextMuted,
            ),
            const SizedBox(height: 12),
            Text(
              TagL10n.emptyTitle(isEn),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.tagTextDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              TagL10n.emptySubtitle(isEn),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.tagTextMuted,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 44),
                backgroundColor: AppColors.tagTeal,
                foregroundColor: Colors.white,
              ),
              child: Text(TagL10n.retry(isEn)),
            ),
          ],
        ),
      ),
    );
  }
}
