import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/config/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/error_view.dart';
import '../../domain/entities/treat_item.dart';
import '../../domain/entities/treat_recipient.dart';
import '../l10n/treats_l10n.dart';
import '../providers/treats_controller.dart';
import '../widgets/treats_pack_3d_viewer.dart';
import '../widgets/treats_qr_payment_view.dart';
import '../widgets/treats_recipient_sheet.dart';
import '../widgets/treats_skeleton.dart';
import '../widgets/treats_success_view.dart';

/// หน้าเลี้ยงขนมแมว (`/treats` และ `/treats?to=<id>`) — ตรงกับเว็บต้นแบบ www.แมว.live/treats
class TreatsPage extends ConsumerStatefulWidget {
  const TreatsPage({super.key, this.initialRecipientId});

  final String? initialRecipientId;

  @override
  ConsumerState<TreatsPage> createState() => _TreatsPageState();
}

class _TreatsPageState extends ConsumerState<TreatsPage> {
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _navigateBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEn = ref.watch(appLocaleProvider) == 'en';
    final provider = treatsControllerProvider(widget.initialRecipientId);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);

    if (state.status == TreatsStatus.ready &&
        state.step == TreatsStep.payment) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) controller.backToSelect();
        },
        child: Scaffold(
          backgroundColor: AppColors.page,
          body: TreatsQrPaymentView(
            totalPrice: state.totalPrice,
            totalCount: state.totalCount,
            isEn: isEn,
            onBack: controller.backToSelect,
            onPaid: controller.markPaid,
          ),
        ),
      );
    }

    if (state.status == TreatsStatus.ready &&
        state.step == TreatsStep.success) {
      final recipient = state.selectedRecipient;
      return Scaffold(
        backgroundColor: AppColors.page,
        body: TreatsSuccessView(
          recipientName: recipient?.name ?? '',
          totalCount: state.totalCount,
          openedFromPost: state.openedFromPost,
          isEn: isEn,
          onSendAnother: () {
            _noteController.clear();
            controller.resetForAnother();
          },
          onBack: _navigateBack,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.page,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  _TreatsHeader(
                    title: TreatsL10n.pageTitle(isEn),
                    backLabel: TreatsL10n.backLabel(isEn),
                    onBack: _navigateBack,
                  ),
                  Expanded(
                    child: switch (state.status) {
                      TreatsStatus.loading => const TreatsSkeleton(),
                      TreatsStatus.error => ErrorView(
                        title: TreatsL10n.loadError(isEn),
                        message:
                            state.errorMessage ??
                            TreatsL10n.emptySubtitle(isEn),
                        onRetry: controller.retry,
                      ),
                      TreatsStatus.empty => _EmptyTreatsView(
                        isEn: isEn,
                        onRetry: controller.retry,
                      ),
                      TreatsStatus.ready => _TreatsSelectBody(
                        state: state,
                        isEn: isEn,
                        noteController: _noteController,
                        onSelectRecipient: controller.selectRecipient,
                        onOpenAllRecipients: () => showTreatsRecipientSheet(
                          context,
                          recipients: state.recipients,
                          selectedId: state.selectedRecipientId,
                          isEn: isEn,
                          onSelect: controller.selectRecipient,
                        ),
                        onSelectTreat: controller.selectTreat,
                        onDecrementQty: controller.decrementQty,
                        onIncrementQty: controller.incrementQty,
                        onAddToCart: controller.addToCart,
                        onRemoveFromCart: controller.removeFromCart,
                        onNoteChanged: controller.updateNote,
                      ),
                    },
                  ),
                  if (state.status == TreatsStatus.ready)
                    _TreatsFooter(
                      totalCount: state.totalCount,
                      totalPrice: state.totalPrice,
                      recipientName: state.selectedRecipient?.name ?? '',
                      isEn: isEn,
                      onSubmit: controller.goToPayment,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TreatsHeader extends StatelessWidget {
  const _TreatsHeader({
    required this.title,
    required this.backLabel,
    required this.onBack,
  });

  final String title;
  final String backLabel;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            Semantics(
              button: true,
              label: backLabel,
              excludeSemantics: true,
              child: InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(14),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    LucideIcons.chevronLeft,
                    size: 24,
                    color: AppColors.text,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TreatsSelectBody extends StatelessWidget {
  const _TreatsSelectBody({
    required this.state,
    required this.isEn,
    required this.noteController,
    required this.onSelectRecipient,
    required this.onOpenAllRecipients,
    required this.onSelectTreat,
    required this.onDecrementQty,
    required this.onIncrementQty,
    required this.onAddToCart,
    required this.onRemoveFromCart,
    required this.onNoteChanged,
  });

  final TreatsState state;
  final bool isEn;
  final TextEditingController noteController;
  final ValueChanged<String> onSelectRecipient;
  final VoidCallback onOpenAllRecipients;
  final ValueChanged<String> onSelectTreat;
  final VoidCallback onDecrementQty;
  final VoidCallback onIncrementQty;
  final VoidCallback onAddToCart;
  final ValueChanged<String> onRemoveFromCart;
  final ValueChanged<String> onNoteChanged;

  @override
  Widget build(BuildContext context) {
    final recipient = state.selectedRecipient!;
    final treat = state.selectedTreat!;
    final visible = state.visibleRecipients;
    final remaining = state.recipients.length - visible.length;
    final cartItems = state.treats
        .where((t) => (state.cart[t.id] ?? 0) > 0)
        .toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                TreatsL10n.whoTitle(isEn),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final r in visible)
                    Expanded(
                      child: _RecipientTile(
                        recipient: r,
                        selected: r.id == state.selectedRecipientId,
                        onTap: () => onSelectRecipient(r.id),
                      ),
                    ),
                  if (remaining > 0)
                    Expanded(
                      child: _SeeAllTile(
                        remaining: remaining,
                        label: TreatsL10n.seeAll(isEn),
                        onTap: onOpenAllRecipients,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            TreatsL10n.pickTitle(isEn),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TreatsPack3dViewer(
          treat: treat,
          cartCount: state.totalCount,
          hopTrigger: state.hopTrigger,
          isEn: isEn,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEn ? treat.nameEn : treat.name,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isEn ? treat.sizeEn : treat.size,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.text2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '฿${treat.price}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (var i = 0; i < state.treats.length; i++) ...[
                    Expanded(
                      child: _TreatOptionCard(
                        treat: state.treats[i],
                        selected: state.treats[i].id == state.selectedTreatId,
                        qtyInCart: state.cart[state.treats[i].id] ?? 0,
                        isEn: isEn,
                        onTap: () => onSelectTreat(state.treats[i].id),
                      ),
                    ),
                    if (i < state.treats.length - 1) const SizedBox(width: 6),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _QtyButton(
                    icon: LucideIcons.minus,
                    label: TreatsL10n.decreaseQty(isEn),
                    enabled: state.stepperQty > 1,
                    onTap: onDecrementQty,
                  ),
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${state.stepperQty}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  _QtyButton(
                    icon: LucideIcons.plus,
                    label: TreatsL10n.increaseQty(isEn),
                    enabled: state.stepperQty < 9,
                    onTap: onIncrementQty,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: onAddToCart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.btn,
                          foregroundColor: AppColors.text,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(
                              color: AppColors.btnBorder,
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: Text(
                          TreatsL10n.addToCart(
                            isEn,
                            _formatInt(state.stepperQty * treat.price),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (cartItems.isNotEmpty) ...[
                const SizedBox(height: 10),
                for (var i = 0; i < cartItems.length; i++)
                  _CartItemRow(
                    treat: cartItems[i],
                    qty: state.cart[cartItems[i].id] ?? 0,
                    showTopDivider: i > 0,
                    isEn: isEn,
                    onRemove: () => onRemoveFromCart(cartItems[i].id),
                  ),
              ],
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.treatsWarmSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        LucideIcons.lock,
                        size: 16,
                        color: AppColors.text2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        TreatsL10n.privacyNotice(isEn, recipient.name),
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: AppColors.text2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                TreatsL10n.messageLabel(isEn, recipient.name),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteController,
                onChanged: onNoteChanged,
                maxLines: 2,
                maxLength: 120,
                style: const TextStyle(fontSize: 14.5, color: AppColors.text),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: AppColors.card,
                  hintText: TreatsL10n.messageHint(isEn),
                  hintStyle: const TextStyle(
                    fontSize: 14.5,
                    color: AppColors.muted,
                  ),
                  contentPadding: const EdgeInsets.all(12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.line2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.ink,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecipientTile extends StatelessWidget {
  const _RecipientTile({
    required this.recipient,
    required this.selected,
    required this.onTap,
  });

  final TreatRecipient recipient;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: recipient.name,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppColors.treatsInk : Colors.transparent,
                    width: 2.5,
                  ),
                ),
                child: AppAvatar(
                  source: recipient.avatarUrl,
                  bg: recipient.avatarBg,
                  size: 52,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                recipient.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected ? AppColors.text : AppColors.text2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeeAllTile extends StatelessWidget {
  const _SeeAllTile({
    required this.remaining,
    required this.label,
    required this.onTap,
  });

  final int remaining;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Column(
            children: [
              CustomPaint(
                painter: _DashedCirclePainter(),
                child: SizedBox(
                  width: 58,
                  height: 58,
                  child: Center(
                    child: Text(
                      '+$remaining',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.text2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1;
    canvas.drawCircle(center, radius, Paint()..color = AppColors.card);

    final stroke = Paint()
      ..color = AppColors.line2
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const dashes = 18;
    const step = (2 * 3.1415926535) / dashes;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * step,
        step * 0.55,
        false,
        stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TreatOptionCard extends StatelessWidget {
  const _TreatOptionCard({
    required this.treat,
    required this.selected,
    required this.qtyInCart,
    required this.isEn,
    required this.onTap,
  });

  final TreatItem treat;
  final bool selected;
  final int qtyInCart;
  final bool isEn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final short = isEn ? treat.shortNameEn : treat.shortName;
    final sub = isEn ? treat.subLabelEn : treat.subLabel;

    return Semantics(
      button: true,
      selected: selected,
      label: '$short $sub',
      excludeSemantics: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.treatsSelectedBg : AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected
                      ? AppColors.treatsSelectedBorder
                      : AppColors.line2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    short,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.text2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (qtyInCart > 0)
            Positioned(
              top: -6,
              right: -4,
              child: Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.treatsOrange,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$qtyInCart',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: enabled
                  ? AppColors.line2
                  : AppColors.line2.withValues(alpha: 0.45),
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: enabled
                ? AppColors.text
                : AppColors.text.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}

class _CartItemRow extends StatelessWidget {
  const _CartItemRow({
    required this.treat,
    required this.qty,
    required this.showTopDivider,
    required this.isEn,
    required this.onRemove,
  });

  final TreatItem treat;
  final int qty;
  final bool showTopDivider;
  final bool isEn;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final name = isEn ? treat.nameEn : treat.name;
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      decoration: showTopDivider
          ? const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.line)),
            )
          : null,
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                text: '$name ',
                style: const TextStyle(fontSize: 14, color: AppColors.text),
                children: [
                  TextSpan(
                    text: '× $qty',
                    style: const TextStyle(color: AppColors.text2),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '฿${_formatInt(qty * treat.price)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(width: 4),
          Semantics(
            button: true,
            label: TreatsL10n.removeItem(isEn, name),
            excludeSemantics: true,
            child: InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(999),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(LucideIcons.x, size: 16, color: AppColors.muted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TreatsFooter extends StatelessWidget {
  const _TreatsFooter({
    required this.totalCount,
    required this.totalPrice,
    required this.recipientName,
    required this.isEn,
    required this.onSubmit,
  });

  final int totalCount;
  final int totalPrice;
  final String recipientName;
  final bool isEn;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final enabled = totalCount > 0;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.page,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                TreatsL10n.footerSummary(isEn, totalCount),
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              Text(
                '฿${_formatInt(totalPrice)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: enabled ? onSubmit : null,
                icon: const Icon(LucideIcons.gift, size: 18),
                label: Text(
                  TreatsL10n.sendTreatsTo(isEn, recipientName),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.btn,
                  foregroundColor: AppColors.text,
                  disabledBackgroundColor: AppColors.btn.withValues(
                    alpha: 0.45,
                  ),
                  disabledForegroundColor: AppColors.text.withValues(
                    alpha: 0.45,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: enabled
                          ? AppColors.btnBorder
                          : AppColors.btnBorder.withValues(alpha: 0.45),
                      width: 1.5,
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

class _EmptyTreatsView extends StatelessWidget {
  const _EmptyTreatsView({required this.isEn, required this.onRetry});

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
            const Icon(LucideIcons.gift, size: 40, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(
              TreatsL10n.emptyTitle(isEn),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              TreatsL10n.emptySubtitle(isEn),
              style: const TextStyle(fontSize: 14, color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44),
                foregroundColor: AppColors.text,
                side: const BorderSide(color: AppColors.line2),
              ),
              child: Text(TreatsL10n.retry(isEn)),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatInt(int value) {
  final s = value.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}
