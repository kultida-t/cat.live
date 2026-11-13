import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/config/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/toast_pill.dart';
import '../../../shell/presentation/main_shell.dart';
import '../../domain/entities/cat_ai_data.dart';
import '../providers/cat_ai_controller.dart';
import '../widgets/cat_ai_add_menu_sheet.dart';
import '../widgets/cat_ai_header.dart';
import '../widgets/cat_ai_hero.dart';
import '../widgets/cat_ai_input_bar.dart';
import '../widgets/cat_ai_l10n.dart';
import '../widgets/cat_ai_record_card.dart';
import '../widgets/cat_ai_settings_sheet.dart';
import 'cat_voice_call_page.dart';

/// หน้า Cat AI (/cat-ai) — ถามอาการและการดูแลแมว (ตอนนี้เป็นข้อมูลตัวอย่าง)
class CatAiPage extends ConsumerStatefulWidget {
  const CatAiPage({super.key});

  @override
  ConsumerState<CatAiPage> createState() => _CatAiPageState();
}

class _CatAiPageState extends ConsumerState<CatAiPage> with ToastMixin {
  final TextEditingController _input = TextEditingController();

  /// เมนู + กำลังเปิดอยู่หรือไม่ (เปิดแล้วปุ่ม + กลายเป็นกากบาท)
  bool _menuOpen = false;

  /// รูปที่แนบไว้รอส่ง ผู้ใช้พิมพ์บอกจุดที่อยากให้ดูก่อนกดส่งได้
  Uint8List? _pendingImage;

  @override
  void initState() {
    super.initState();
    _input.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    disposeToast();
    _input.dispose();
    super.dispose();
  }

  /// ส่งข้อความจากช่องพิมพ์ พร้อมรูปที่แนบไว้ (ถ้ามี) ล้างช่องและแถบรูปทันทีเหมือนเว็บจริง
  /// ถ้าส่งไม่สำเร็จจึงคืนข้อความและรูปกลับมาให้ผู้ใช้ส่งใหม่ได้
  Future<void> _submitInput(bool isEn) async {
    final text = _input.text;
    final image = _pendingImage;
    if (ref.read(catAiControllerProvider).isSending) return;
    _input.clear();
    setState(() => _pendingImage = null);
    final ok = await ref
        .read(catAiControllerProvider.notifier)
        .send(text, image: image);
    if (!mounted || ok) return;
    _input.text = text;
    setState(() => _pendingImage = image);
    showToast(CatAiL10n.sendFailed(isEn));
  }

  /// ส่งคำถามลัดหรือเรื่องที่ถามบ่อยทันที โดยไม่กระทบช่องพิมพ์และรูปที่แนบไว้
  Future<void> _sendQuestion(String text, bool isEn) async {
    if (ref.read(catAiControllerProvider).isSending) return;
    final ok = await ref.read(catAiControllerProvider.notifier).send(text);
    if (!mounted || ok) return;
    showToast(CatAiL10n.sendFailed(isEn));
  }

  void _attach(Uint8List bytes) {
    setState(() {
      _pendingImage = bytes;
      _menuOpen = false;
    });
  }

  Future<void> _pickImage(ImageSource source, bool isEn) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;
      _attach(await picked.readAsBytes());
    } catch (_) {
      if (mounted) showToast(CatAiL10n.imagePickFailed(isEn));
    }
  }

  void _toggleMenu() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _menuOpen = !_menuOpen);
  }

  void _closeMenu() {
    if (_menuOpen) setState(() => _menuOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(catAiControllerProvider);
    final ctrl = ref.read(catAiControllerProvider.notifier);
    final isEn = ref.watch(appLocaleProvider) == 'en';
    final cat = state.selectedCat;
    final hasCat =
        !state.isLoading && state.errorMessage == null && cat != null;
    // ว่างเปล่า = ยังไม่มีข้อความ ไม่ได้พิมพ์ และไม่ได้แนบรูป
    final idle =
        state.messages.isEmpty &&
        _input.text.trim().isEmpty &&
        _pendingImage == null;
    // คำถามลัดแสดงเฉพาะตอนยังไม่เริ่มแชท และไม่ได้กำลังส่งข้อความอยู่
    final showQuickQuestions =
        _input.text.trim().isEmpty &&
        _pendingImage == null &&
        !_menuOpen &&
        state.messages.isEmpty &&
        !state.isSending;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: DecoratedBox(
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
                  Expanded(
                    child: Stack(
                      children: [
                        AnimatedSwitcher(
                          duration: _kFade,
                          layoutBuilder: (current, previous) => Stack(
                            fit: StackFit.expand,
                            children: [...previous, ?current],
                          ),
                          child: KeyedSubtree(
                            key: ValueKey(_bodyKind(state, idle)),
                            child: _buildBody(state, ctrl, isEn, idle),
                          ),
                        ),
                        if (_menuOpen)
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _closeMenu,
                            ),
                          ),
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 10,
                          child: IgnorePointer(
                            ignoring: !_menuOpen,
                            child: _Reveal(
                              show: _menuOpen,
                              animateSize: false,
                              child: CatAiAddMenu(
                                isEn: isEn,
                                onPickImage: (source) {
                                  _closeMenu();
                                  _pickImage(source, isEn);
                                },
                                onFaceCheck: () {
                                  _closeMenu();
                                  context.push('/cat-ai/face-check');
                                },
                                onQuestion: (q) {
                                  _closeMenu();
                                  _sendQuestion(q, isEn);
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _Reveal(
                    show: hasCat && showQuickQuestions,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: CatAiQuickQuestions(
                        questions: cat?.quickQuestions ?? const [],
                        isEn: isEn,
                        onSelect: (q) => _sendQuestion(
                          isEn ? q.questionEn : q.questionTh,
                          isEn,
                        ),
                      ),
                    ),
                  ),
                  _Reveal(
                    show: hasCat && _pendingImage != null,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: _pendingImage == null
                          ? const SizedBox.shrink()
                          : CatAiAttachmentPreview(
                              bytes: _pendingImage!,
                              hint: CatAiL10n.attachmentHint(isEn),
                              removeLabel: CatAiL10n.removeAttachmentLabel(
                                isEn,
                              ),
                              onRemove: () =>
                                  setState(() => _pendingImage = null),
                            ),
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
                        hasAttachment: _pendingImage != null,
                        isMenuOpen: _menuOpen,
                        onSubmit: () => _submitInput(isEn),
                        onAdd: _toggleMenu,
                        onFaceCheck: () => context.push('/cat-ai/face-check'),
                        onVoiceInput: () =>
                            showToast(CatAiL10n.voiceNotReady(isEn)),
                        onVetCall: () => showCatVoiceCallPage(
                          context,
                          catName: cat.name,
                          catPhoto: cat.avatarAsset,
                          isEn: isEn,
                        ),
                      ),
                    ),
                  // ซ่อนข้อความแต่ยังกินพื้นที่เดิม เพื่อให้ระยะห่างกับเมนูล่างไม่เปลี่ยน
                  AnimatedOpacity(
                    opacity: idle ? 1 : 0,
                    duration: _kFade,
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
      ),
    );
  }

  String _bodyKind(CatAiState s, bool idle) {
    if (s.isLoading) return 'loading';
    if (s.errorMessage != null) return 'error';
    if (s.selectedCat == null) return 'empty';
    return s.messages.isEmpty && idle ? 'idle' : 'chat';
  }

  Widget _buildBody(
    CatAiState state,
    CatAiController ctrl,
    bool isEn,
    bool idle,
  ) {
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
    if (state.messages.isEmpty && idle) {
      // เลื่อนได้เมื่อคีย์บอร์ดขึ้นทำให้พื้นที่เหลือน้อยกว่าขนาดไมค์ จะได้ไม่ล้น
      return LayoutBuilder(
        builder: (_, constraints) => SingleChildScrollView(
          child: SizedBox(
            height: constraints.maxHeight < 240 ? 240 : constraints.maxHeight,
            child: Center(
              child: CatAiHero(
                isEn: isEn,
                onTap: () => showToast(CatAiL10n.voiceNotReady(isEn)),
              ),
            ),
          ),
        ),
      );
    }
    final catId = state.selectedCat?.id ?? '';
    return _ChatList(
      messages: state.messages,
      isSending: state.isSending,
      isEn: isEn,
      onFeedback: () => showToast(CatAiL10n.feedbackThanks(isEn)),
      onConfirmRecord: (m) => ctrl.confirmRecord(catId, m),
      onEditRecord: (m) async {
        final text = await showCatAiRecordEditSheet(
          context,
          initial: m.record!.details,
          isEn: isEn,
        );
        if (text != null) ctrl.editRecordDetails(catId, m, text);
      },
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
    required this.onConfirmRecord,
    required this.onEditRecord,
  });

  final List<CatAiMessage> messages;
  final bool isSending;
  final bool isEn;
  final VoidCallback onFeedback;
  final ValueChanged<CatAiMessage> onConfirmRecord;
  final ValueChanged<CatAiMessage> onEditRecord;

  @override
  Widget build(BuildContext context) {
    // ข้อความล่าสุดอยู่ล่างสุด จึงจัดลำดับกลับด้านแล้วใช้ reverse
    final count = messages.length + (isSending ? 1 : 0);
    // การ์ดคำเตือนอยู่บนสุดของแชทเสมอ (ไม่เลื่อนตามข้อความ) เหมือนเว็บจริง
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: _DisclaimerCard(isEn: isEn),
        ),
        Expanded(
          // ไล่เฟดขอบบน-ล่างของรายการ ให้ข้อความค่อย ๆ จางหายใต้ป้ายเตือนและช่องพิมพ์
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (rect) {
              final f = rect.height <= 0 ? 0.0 : 28 / rect.height;
              return LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: const [
                  Colors.transparent,
                  Colors.black,
                  Colors.black,
                  Colors.transparent,
                ],
                stops: [0, f, 1 - f, 1],
              ).createShader(rect);
            },
            child: ListView.builder(
              reverse: true,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
              itemCount: count,
              itemBuilder: (_, i) {
                if (isSending && i == 0) {
                  return const _TypingBubble();
                }
                final msg =
                    messages[messages.length - 1 - (isSending ? i - 1 : i)];
                return _Bubble(
                  message: msg,
                  isEn: isEn,
                  animateIn: i < 2,
                  onFeedback: onFeedback,
                  onConfirmRecord: onConfirmRecord,
                  onEditRecord: onEditRecord,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// แถบจุด 3 จุดเด้งสลับจังหวะระหว่างรอ Cat AI ตอบ (ตรงกับเว็บจริง)
class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.line),
            ),
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, _) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    Transform.translate(
                      offset: Offset(
                        0,
                        reduce
                            ? 0
                            : -3.5 *
                                  math.max(
                                    0.0,
                                    math.sin(
                                      (_ctrl.value * 2 * math.pi) - (i * 0.8),
                                    ),
                                  ),
                      ),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.ink,
                          shape: BoxShape.circle,
                        ),
                      ),
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

/// ระยะเวลาแอนิเมชันเฟด/ขยายของส่วนต่าง ๆ ในหน้า Cat AI
const _kFade = Duration(milliseconds: 220);

/// แสดง/ซ่อนส่วนที่อยู่เหนือช่องพิมพ์ (คำถามลัด แถบรูป) แบบเฟดและขยายค่อย ๆ แทนการโผล่ทันที
class _Reveal extends StatefulWidget {
  const _Reveal({
    required this.show,
    required this.child,
    this.animateSize = true,
  });

  final bool show;
  final Widget child;

  /// true = พื้นที่ขยาย/หดค่อย ๆ (ส่วนในคอลัมน์) / false = เฟดและเลื่อนเล็กน้อย (เมนูลอย)
  final bool animateSize;

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> {
  /// เปลี่ยนทุกครั้งที่สลับแสดง/ซ่อน เพื่อให้ key ไม่ซ้ำกับตัวที่กำลังเฟดออก
  int _generation = 0;

  @override
  void didUpdateWidget(_Reveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.show != widget.show) _generation++;
  }

  @override
  Widget build(BuildContext context) {
    final switcher = AnimatedSwitcher(
      duration: _kFade,
      transitionBuilder: (child, anim) {
        final faded = FadeTransition(opacity: anim, child: child);
        if (widget.animateSize) return faded;
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(anim),
          child: faded,
        );
      },
      child: widget.show
          ? KeyedSubtree(key: ValueKey('on$_generation'), child: widget.child)
          : SizedBox(key: ValueKey('off$_generation'), width: double.infinity),
    );
    if (!widget.animateSize) return switcher;
    return AnimatedSize(
      duration: _kFade,
      curve: Curves.easeOut,
      alignment: Alignment.bottomCenter,
      child: switcher,
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
  const _Bubble({
    required this.message,
    required this.isEn,
    required this.onFeedback,
    required this.onConfirmRecord,
    required this.onEditRecord,
    this.animateIn = false,
  });

  final CatAiMessage message;
  final bool isEn;
  final bool animateIn;
  final VoidCallback onFeedback;
  final ValueChanged<CatAiMessage> onConfirmRecord;
  final ValueChanged<CatAiMessage> onEditRecord;

  @override
  Widget build(BuildContext context) {
    final bubble = _buildBubble(context);
    if (!animateIn) return bubble;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: _kFade,
      curve: Curves.easeOut,
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - t)),
          child: child,
        ),
      ),
      child: bubble,
    );
  }

  Widget _buildBubble(BuildContext context) {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.imageBytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    message.imageBytes!,
                    width: 200,
                    cacheWidth: 600,
                    fit: BoxFit.cover,
                    semanticLabel: 'รูปที่แนบ',
                  ),
                ),
              if (message.text.isNotEmpty)
                Text(
                  message.text,
                  style: const TextStyle(fontSize: 14.5, color: AppColors.ink),
                ),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
                      if (message.level != null)
                        CatAiLevelBadge(level: message.level!, isEn: isEn),
                      Text(
                        message.text,
                        style: const TextStyle(
                          fontSize: 14.5,
                          height: 1.5,
                          color: AppColors.text,
                        ),
                      ),
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
                  ),
                ),
              ),
            ],
          ),
          if (message.record != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 8, 0, 0),
              child: CatAiRecordCard(
                record: message.record!,
                isEn: isEn,
                onEdit: () => onEditRecord(message),
                onConfirm: () => onConfirmRecord(message),
                onViewHistory: () => context.push('/my-cat/health'),
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
