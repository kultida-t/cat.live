import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../domain/entities/messages_data.dart';
import '../providers/messages_controller.dart';
import 'messages_l10n.dart';

/// แผ่นล่าง "จัดการข้อความ" (ตัวกรองแสดงเฉพาะ + สวิตช์ตั้งค่า 3 ตัว)
Future<void> showManageMessagesSheet(
  BuildContext context, {
  required MessagesL10n l10n,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    barrierColor: AppColors.sheetBarrier,
    builder: (_) => _ManageMessagesSheet(l10n: l10n),
  );
}

class _ManageMessagesSheet extends ConsumerWidget {
  const _ManageMessagesSheet({required this.l10n});
  final MessagesL10n l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(messagesControllerProvider);
    final controller = ref.read(messagesControllerProvider.notifier);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        24 + MediaQuery.of(context).viewPadding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line2,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.manage,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: 'ปิด',
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(999),
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(LucideIcons.x, size: 22, color: AppColors.text),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.showOnly,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 6),
          _FilterRadioRow(
            label: l10n.filterUnread,
            selected: state.filter == MessagesFilter.unread,
            onTap: () => controller.toggleFilter(MessagesFilter.unread),
          ),
          _FilterRadioRow(
            label: l10n.filterUnanswered,
            selected: state.filter == MessagesFilter.unanswered,
            onTap: () => controller.toggleFilter(MessagesFilter.unanswered),
          ),
          _FilterRadioRow(
            label: l10n.filterPinned,
            selected: state.filter == MessagesFilter.pinned,
            onTap: () => controller.toggleFilter(MessagesFilter.pinned),
          ),
          _FilterRadioRow(
            label: l10n.filterMuted,
            selected: state.filter == MessagesFilter.muted,
            onTap: () => controller.toggleFilter(MessagesFilter.muted),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: AppColors.line),
          ),
          Text(
            l10n.settingsTitle,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 6),
          _SettingSwitchRow(
            title: l10n.allowRequests,
            subtitle: l10n.allowRequestsDesc,
            value: state.settings.allowRequests,
            onChanged: (v) => controller.updateSettings(
              state.settings.copyWith(allowRequests: v),
            ),
          ),
          _SettingSwitchRow(
            title: l10n.showReadReceipts,
            subtitle: l10n.showReadReceiptsDesc,
            value: state.settings.showReadReceipts,
            onChanged: (v) => controller.updateSettings(
              state.settings.copyWith(showReadReceipts: v),
            ),
          ),
          _SettingSwitchRow(
            title: l10n.showPreview,
            subtitle: l10n.showPreviewDesc,
            value: state.settings.showMessagePreview,
            onChanged: (v) => controller.updateSettings(
              state.settings.copyWith(showMessagePreview: v),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterRadioRow extends StatelessWidget {
  const _FilterRadioRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 46,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.text,
                ),
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.ink : Colors.transparent,
                border: Border.all(
                  color: selected ? AppColors.ink : AppColors.line2,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingSwitchRow extends StatelessWidget {
  const _SettingSwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: value,
            activeTrackColor: AppColors.ink,
            activeThumbColor: Colors.white,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// ผลลัพธ์จากแผ่นล่าง "ตัวเลือกแชท"
enum ThreadSheetAction { pin, toggleRead, mute, moveBox, block, delete }

/// แผ่นล่าง "ตัวเลือกแชท" เมื่อกดปุ่ม ···
Future<ThreadSheetAction?> showThreadOptionsSheet(
  BuildContext context, {
  required ChatThread thread,
  required MessagesL10n l10n,
}) {
  return showModalBottomSheet<ThreadSheetAction>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.sheetBarrier,
    builder: (ctx) => Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.of(ctx).viewPadding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.line2,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  thread.peer.handle,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: 'ปิด',
                child: InkWell(
                  onTap: () => Navigator.of(ctx).pop(),
                  borderRadius: BorderRadius.circular(999),
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(LucideIcons.x, size: 22, color: AppColors.text),
                  ),
                ),
              ),
            ],
          ),
          _OptionRow(
            icon: LucideIcons.pin,
            label: thread.isPinned ? l10n.unpinTop : l10n.pinTop,
            onTap: () => Navigator.of(ctx).pop(ThreadSheetAction.pin),
          ),
          _OptionRow(
            icon: LucideIcons.mail,
            label: thread.isUnread ? l10n.markRead : l10n.markUnread,
            onTap: () => Navigator.of(ctx).pop(ThreadSheetAction.toggleRead),
          ),
          _OptionRow(
            icon: thread.isMuted ? LucideIcons.bell : LucideIcons.bellOff,
            label: thread.isMuted ? l10n.unmuteChat : l10n.muteChat,
            onTap: () => Navigator.of(ctx).pop(ThreadSheetAction.mute),
          ),
          _OptionRow(
            icon: LucideIcons.folderInput,
            label: thread.box == MessagesBoxTab.general
                ? l10n.moveToPrimary
                : l10n.moveToGeneral,
            onTap: () => Navigator.of(ctx).pop(ThreadSheetAction.moveBox),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Divider(height: 1, color: AppColors.line),
          ),
          _OptionRow(
            icon: LucideIcons.ban,
            label: l10n.block,
            isDanger: true,
            onTap: () => Navigator.of(ctx).pop(ThreadSheetAction.block),
          ),
          _OptionRow(
            icon: LucideIcons.trash2,
            label: l10n.deleteChat,
            isDanger: true,
            onTap: () => Navigator.of(ctx).pop(ThreadSheetAction.delete),
          ),
        ],
      ),
    ),
  );
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDanger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? AppColors.danger : AppColors.text;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// แผ่นล่างยืนยัน "บล็อก" หรือ "ลบแชท" ตรงตามเว็บตัวอย่าง
Future<bool> showDangerConfirmSheet(
  BuildContext context, {
  required String title,
  required String description,
  required String cancelLabel,
  required String confirmLabel,
}) async {
  final res = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.sheetBarrier,
    builder: (ctx) => Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        24 + MediaQuery.of(ctx).viewPadding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line2,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: 'ปิด',
                child: InkWell(
                  onTap: () => Navigator.of(ctx).pop(false),
                  borderRadius: BorderRadius.circular(999),
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(LucideIcons.x, size: 22, color: AppColors.text),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14.5,
              height: 1.45,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.page,
                      foregroundColor: AppColors.text,
                      side: const BorderSide(color: AppColors.line2),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      cancelLabel,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      confirmLabel,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  return res ?? false;
}

/// แผ่นล่าง "ข้อความใหม่" — เลือกเพื่อนเพื่อเริ่มหรือเปิดห้องแชท
Future<ChatUser?> showNewMessageSheet(
  BuildContext context, {
  required List<ChatUser> contacts,
  required MessagesL10n l10n,
}) {
  return showModalBottomSheet<ChatUser>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    barrierColor: AppColors.sheetBarrier,
    builder: (ctx) => Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(ctx).size.height * 0.72,
      ),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        16 + MediaQuery.of(ctx).viewPadding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.line2,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.chooseRecipient,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: 'ปิด',
                child: InkWell(
                  onTap: () => Navigator.of(ctx).pop(),
                  borderRadius: BorderRadius.circular(999),
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(LucideIcons.x, size: 22, color: AppColors.text),
                  ),
                ),
              ),
            ],
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: contacts.length,
              itemBuilder: (_, i) {
                final user = contacts[i];
                return InkWell(
                  onTap: () => Navigator.of(ctx).pop(user),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        AppAvatar(
                          source: user.avatarSource,
                          bg: user.avatarBg,
                          size: 46,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.handle,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.text,
                                ),
                              ),
                              Text(
                                user.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          LucideIcons.chevronRight,
                          size: 18,
                          color: AppColors.muted,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

/// แผ่นล่าง "แก้ไขโน้ตของคุณ"
Future<String?> showEditNoteSheet(
  BuildContext context, {
  required String initialNote,
  required MessagesL10n l10n,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    barrierColor: AppColors.sheetBarrier,
    builder: (ctx) => _EditNoteSheet(initialNote: initialNote, l10n: l10n),
  );
}

class _EditNoteSheet extends StatefulWidget {
  const _EditNoteSheet({required this.initialNote, required this.l10n});
  final String initialNote;
  final MessagesL10n l10n;

  @override
  State<_EditNoteSheet> createState() => _EditNoteSheetState();
}

class _EditNoteSheetState extends State<_EditNoteSheet> {
  late final TextEditingController _ctrl = TextEditingController(
    text: widget.initialNote,
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + bottomInset + MediaQuery.of(context).viewPadding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.line2,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.l10n.editNoteTitle,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(_ctrl.text),
                child: Text(
                  widget.l10n.save,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _ctrl,
            maxLength: 60,
            autofocus: true,
            decoration: InputDecoration(
              hintText: widget.l10n.noteHint,
              filled: true,
              fillColor: AppColors.soft,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
