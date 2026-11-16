import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/config/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../messages/domain/entities/messages_data.dart';
import '../../../messages/presentation/providers/messages_controller.dart';

/// หน้ารายละเอียดและประวัติขนมแมวที่ได้รับ (/notifications/treats)
/// เปิดจากแจ้งเตือน "ส่งขนมแมวเลีย" — กด < กลับหน้าการแจ้งเตือนได้ทันที
class ReceivedTreatsPage extends ConsumerWidget {
  const ReceivedTreatsPage({super.key});

  Future<void> _openDirectChat(
    BuildContext context,
    WidgetRef ref,
    _ReceivedTreatRecord record,
  ) async {
    final peer = ChatUser(
      id: record.senderId,
      handle: record.senderHandle.replaceFirst('@', ''),
      name: record.senderName,
      avatarSource: record.senderAvatar,
      avatarBg: record.senderBg,
    );
    final thread = await ref
        .read(messagesControllerProvider.notifier)
        .openOrCreateForPeer(peer);
    if (!context.mounted) return;
    context.push('/messages/${thread.id}');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEn = ref.watch(appLocaleProvider) == 'en';
    final latest = _mockHistory.first;
    final previous = _mockHistory.skip(1).toList();

    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: Column(
          children: [
            _Header(isEn: isEn, onBack: () => context.pop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                children: [
                  _FeaturedTreatCard(
                    record: latest,
                    isEn: isEn,
                    onThankYou: () => _openDirectChat(context, ref, latest),
                    onSendBack: () => context.push(
                      '/treats?to=${Uri.encodeQueryComponent(latest.senderId)}',
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    isEn ? 'Received treats history' : 'ประวัติขนมที่ได้รับ',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final item in previous) ...[
                    _HistoryCard(record: item, isEn: isEn),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isEn, required this.onBack});

  final bool isEn;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 12, 8),
      decoration: const BoxDecoration(
        color: AppColors.page,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: isEn ? 'Back' : 'ย้อนกลับ',
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
          Expanded(
            child: Text(
              isEn ? 'Received Treats' : 'ขนมที่ได้รับ',
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedTreatCard extends StatelessWidget {
  const _FeaturedTreatCard({
    required this.record,
    required this.isEn,
    required this.onThankYou,
    required this.onSendBack,
  });

  final _ReceivedTreatRecord record;
  final bool isEn;
  final VoidCallback onThankYou;
  final VoidCallback onSendBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.heroStart, AppColors.card],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.btnBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(
                source: record.senderAvatar,
                bg: record.senderBg,
                size: 48,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${record.senderName} (${record.senderHandle})',
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isEn ? record.timeEn : record.timeTh,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.btn,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.btnBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.gift,
                      size: 14,
                      color: AppColors.ink,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isEn ? 'New' : 'ล่าสุด',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEn
                      ? '${record.itemEn} · For ${record.catNameEn}'
                      : '${record.itemTh} · ส่งให้น้อง${record.catNameTh}',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isEn ? record.noteEn : record.noteTh,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: AppColors.text2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 6,
                child: FilledButton(
                  onPressed: onThankYou,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    backgroundColor: AppColors.btn,
                    foregroundColor: AppColors.ink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.btnBorder),
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.messageCircleHeart, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          isEn ? 'Say thanks' : 'ส่งข้อความขอบคุณ',
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 4,
                child: OutlinedButton(
                  onPressed: onSendBack,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    backgroundColor: AppColors.card,
                    foregroundColor: AppColors.text,
                    side: const BorderSide(color: AppColors.line2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.gift, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          isEn ? 'Send back' : 'ส่งขนมกลับ',
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.record, required this.isEn});

  final _ReceivedTreatRecord record;
  final bool isEn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppAvatar(source: record.senderAvatar, bg: record.senderBg, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEn
                      ? '${record.senderName} sent ${record.itemEn} to ${record.catNameEn}'
                      : '${record.senderName} ส่ง${record.itemTh} ให้น้อง${record.catNameTh}',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEn ? record.noteEn : record.noteTh,
                  style: const TextStyle(fontSize: 13, color: AppColors.text2),
                ),
                const SizedBox(height: 4),
                Text(
                  isEn ? record.timeEn : record.timeTh,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceivedTreatRecord {
  const _ReceivedTreatRecord({
    required this.senderId,
    required this.senderName,
    required this.senderHandle,
    required this.senderAvatar,
    required this.senderBg,
    required this.itemTh,
    required this.itemEn,
    required this.catNameTh,
    required this.catNameEn,
    required this.noteTh,
    required this.noteEn,
    required this.timeTh,
    required this.timeEn,
  });

  final String senderId;
  final String senderName;
  final String senderHandle;
  final String senderAvatar;
  final int senderBg;
  final String itemTh;
  final String itemEn;
  final String catNameTh;
  final String catNameEn;
  final String noteTh;
  final String noteEn;
  final String timeTh;
  final String timeEn;
}

const _mockHistory = [
  _ReceivedTreatRecord(
    senderId: 'guy',
    senderName: 'กาย · แมวสูงวัย',
    senderHandle: '@guy.oldcat',
    senderAvatar: 'asset:assets/images/avatars/1574158622682-e40e69881006.jpg',
    senderBg: 0xFFDCEBFF,
    itemTh: 'ขนมแมวเลีย 1 แพ็ก',
    itemEn: '1 pack of creamy treats',
    catNameTh: 'มะลิ',
    catNameEn: 'Mali',
    noteTh: '“ขอให้น้องมะลิแข็งแรงนะ”',
    noteEn: '“Stay healthy, Mali!”',
    timeTh: '22 นาทีที่แล้ว',
    timeEn: '22m ago',
  ),
  _ReceivedTreatRecord(
    senderId: 'noon',
    senderName: 'นุ่น & โมจิ',
    senderHandle: '@noon.mochi',
    senderAvatar: 'asset:assets/images/avatars/1592194996308-7b43878e84a6.jpg',
    senderBg: 0xFFFCE7D6,
    itemTh: 'ขนมฟรีซดราย 1 กระปุก',
    itemEn: '1 jar of freeze-dried treats',
    catNameTh: 'ส้มจี๊ด',
    catNameEn: 'Somjeed',
    noteTh: '“รางวัลเด็กดีกินน้ำเก่ง”',
    noteEn: '“Reward for drinking lots of water!”',
    timeTh: '3 วันที่แล้ว',
    timeEn: '3d ago',
  ),
  _ReceivedTreatRecord(
    senderId: 'muk',
    senderName: 'มุก อารีย์',
    senderHandle: '@muk.ari',
    senderAvatar: 'asset:assets/images/avatars/1787404200329-78b2aaee13c1.jpg',
    senderBg: 0xFFD5F0EB,
    itemTh: 'กล่องรวมขนมแมว 1 กล่อง',
    itemEn: '1 assorted treat box',
    catNameTh: 'ถั่วดำ',
    catNameEn: 'Thoadam',
    noteTh: '“เอ็นดูความอ้อนของถั่วดำมากค่ะ”',
    noteEn: '“Love how affectionate Thoadam is!”',
    timeTh: '1 สัปดาห์ที่แล้ว',
    timeEn: '1w ago',
  ),
];
