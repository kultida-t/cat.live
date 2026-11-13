import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/config/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/toast_pill.dart';
import '../../../shell/presentation/main_shell.dart';
import '../../domain/entities/cat_ai_data.dart';
import '../providers/cat_ai_controller.dart';
import '../widgets/cat_ai_header.dart';
import '../widgets/cat_ai_hero.dart';
import '../widgets/cat_ai_input_bar.dart';
import '../widgets/cat_ai_l10n.dart';
import '../widgets/cat_ai_settings_sheet.dart';

/// หน้า Cat AI (/cat-ai) — ถามอาการและการดูแลแมว (ตอนนี้เป็นข้อมูลตัวอย่าง)
class CatAiPage extends ConsumerStatefulWidget {
  const CatAiPage({super.key});

  @override
  ConsumerState<CatAiPage> createState() => _CatAiPageState();
}

class _CatAiPageState extends ConsumerState<CatAiPage> with ToastMixin {
  final TextEditingController _input = TextEditingController();

  @override
  void dispose() {
    disposeToast();
    _input.dispose();
    super.dispose();
  }

  Future<void> _send(String text, bool isEn) async {
    if (ref.read(catAiControllerProvider).isSending) return;
    final ok = await ref.read(catAiControllerProvider.notifier).send(text);
    if (!mounted) return;
    if (ok) {
      _input.clear();
    } else {
      showToast(CatAiL10n.sendFailed(isEn));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(catAiControllerProvider);
    final ctrl = ref.read(catAiControllerProvider.notifier);
    final isEn = ref.watch(appLocaleProvider) == 'en';
    final cat = state.selectedCat;
    final hasCat =
        !state.isLoading && state.errorMessage == null && cat != null;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0, 0.38, 0.72, 1],
          colors: [
            AppColors.page,
            AppColors.page,
            AppColors.catAiGradientMid,
            AppColors.catAiGradientEnd,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                CatAiHeader(
                  cat: hasCat ? cat : null,
                  isEn: isEn,
                  onOpenSettings: () => showCatAiSettingsSheet(context, isEn),
                  onCycleCat: ctrl.nextCat,
                  onEditCat: () => context.push('/cat-profile'),
                  onOpenMyCat: () => goToShellTab(context, ref, 5),
                ),
                Expanded(child: _buildBody(state, ctrl, isEn)),
                if (hasCat)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: CatAiQuickQuestions(
                      questions: cat.quickQuestions,
                      isEn: isEn,
                      onSelect: (q) =>
                          _send(isEn ? q.questionEn : q.questionTh, isEn),
                    ),
                  ),
                if (hasCat)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: CatAiInputBar(
                      controller: _input,
                      catName: cat.name,
                      isEn: isEn,
                      isSending: state.isSending,
                      hasMessages: state.messages.isNotEmpty,
                      onSubmit: (text) => _send(text, isEn),
                      onAdd: () => showToast(CatAiL10n.comingSoon(isEn)),
                      onFaceCheck: () => showToast(CatAiL10n.comingSoon(isEn)),
                      onVoiceInput: () =>
                          showToast(CatAiL10n.voiceNotReady(isEn)),
                      onVetCall: () => showToast(CatAiL10n.comingSoon(isEn)),
                    ),
                  ),
                // ซ่อนข้อความแต่ยังกินพื้นที่เดิม เพื่อให้ระยะห่างกับเมนูล่างไม่เปลี่ยน
                Visibility(
                  visible: state.messages.isEmpty,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      CatAiL10n.disclaimer(isEn),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (toastMessage != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 78,
                child: Center(child: ToastPill(message: toastMessage!)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(CatAiState state, CatAiController ctrl, bool isEn) {
    if (state.isLoading) return const _CatAiSkeleton();
    if (state.errorMessage != null) {
      return ErrorView(
        title: CatAiL10n.errorTitle(isEn),
        message: CatAiL10n.errorMessage(isEn),
        actionLabel: CatAiL10n.retry(isEn),
        onRetry: ctrl.load,
      );
    }
    if (state.selectedCat == null) return _EmptyCat(isEn: isEn);
    if (state.messages.isEmpty) {
      return Center(
        child: CatAiHero(
          isEn: isEn,
          onTap: () => showToast(CatAiL10n.voiceNotReady(isEn)),
        ),
      );
    }
    return _ChatList(
      messages: state.messages,
      isSending: state.isSending,
      isEn: isEn,
      onFeedback: () => showToast(CatAiL10n.feedbackThanks(isEn)),
    );
  }
}

class _CatAiSkeleton extends StatelessWidget {
  const _CatAiSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.soft,
          shape: BoxShape.circle,
        ),
        child: SizedBox(width: 200, height: 200),
      ),
    );
  }
}

class _EmptyCat extends StatelessWidget {
  const _EmptyCat({required this.isEn});

  final bool isEn;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.cat, size: 48, color: AppColors.muted),
            const SizedBox(height: 16),
            Text(
              CatAiL10n.emptyTitle(isEn),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              CatAiL10n.emptyMessage(isEn),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatList extends StatelessWidget {
  const _ChatList({
    required this.messages,
    required this.isSending,
    required this.isEn,
    required this.onFeedback,
  });

  final List<CatAiMessage> messages;
  final bool isSending;
  final bool isEn;
  final VoidCallback onFeedback;

  @override
  Widget build(BuildContext context) {
    // ข้อความล่าสุดอยู่ล่างสุด จึงจัดลำดับกลับด้านแล้วใช้ reverse
    final items = [
      if (isSending) const CatAiMessage(text: '…', isFromUser: false),
      ...messages.reversed,
    ];
    final itemCount = items.length + 1;
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      itemCount: itemCount,
      itemBuilder: (_, i) {
        if (i == itemCount - 1) return _DisclaimerCard(isEn: isEn);
        return _Bubble(message: items[i], onFeedback: onFeedback);
      },
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard({required this.isEn});

  final bool isEn;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.soft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.info, size: 16, color: AppColors.text2),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              CatAiL10n.cannotDiagnoseNote(isEn),
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: AppColors.text2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.onFeedback});

  final CatAiMessage message;
  final VoidCallback onFeedback;

  @override
  Widget build(BuildContext context) {
    if (message.isFromUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          constraints: const BoxConstraints(maxWidth: 280),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.btn,
            border: Border.all(color: AppColors.btnBorder),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(10),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
          ),
          child: Text(
            message.text,
            style: const TextStyle(fontSize: 14.5, color: AppColors.ink),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.btn,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.sparkles,
              size: 16,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 280),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              decoration: BoxDecoration(
                color: AppColors.card,
                border: Border.all(color: AppColors.line),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: const TextStyle(
                      fontSize: 14.5,
                      height: 1.5,
                      color: AppColors.text,
                    ),
                  ),
                  if (message.text != '…') ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _FeedbackButton(
                          icon: LucideIcons.thumbsUp,
                          onTap: onFeedback,
                        ),
                        _FeedbackButton(
                          icon: LucideIcons.thumbsDown,
                          onTap: onFeedback,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackButton extends StatelessWidget {
  const _FeedbackButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 36,
        height: 32,
        child: Icon(icon, size: 16, color: AppColors.muted),
      ),
    );
  }
}
