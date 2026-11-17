import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/config/app_locale.dart';
import '../../../../core/router/auth_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/toast_pill.dart';
import '../../domain/entities/deletion_data.dart';
import '../providers/auth_controller.dart';
import '../widgets/auth_l10n.dart';

enum _DeleteStep { warning, resolveCaretakers, confirm, done }

enum _LoadStatus { loading, error, ready }

/// หน้าลบบัญชี (/settings/delete-account — AUTH-05)
/// flow 4 ขั้น: เตือน → จัดการแมวที่มีผู้ดูแลร่วม → ยืนยันสุดท้าย → สำเร็จ
class DeleteAccountPage extends ConsumerStatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  ConsumerState<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends ConsumerState<DeleteAccountPage>
    with ToastMixin {
  _DeleteStep _step = _DeleteStep.warning;
  _LoadStatus _loadStatus = _LoadStatus.loading;
  List<CatDeletionRequirement> _cats = const [];

  /// catId → caretakerId ที่รับโอนสิทธิ์ (null ใน map = ลบแมวไปพร้อมบัญชี)
  final Map<String, String?> _decisions = {};
  bool _acknowledged = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    disposeToast();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loadStatus = _LoadStatus.loading);
    try {
      final cats = await ref
          .read(authControllerProvider.notifier)
          .loadDeletionRequirements();
      if (!mounted) return;
      setState(() {
        _cats = cats;
        _loadStatus = _LoadStatus.ready;
        // แมวที่ไม่มีผู้ดูแลร่วมถูกลบพร้อมบัญชีอัตโนมัติ ไม่ต้องเลือก
        for (final cat in cats) {
          if (!cat.mustResolve) _decisions[cat.catId] = '__delete__';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadStatus = _LoadStatus.error);
    }
  }

  List<CatDeletionRequirement> get _catsNeedingDecision =>
      _cats.where((c) => c.mustResolve).toList();

  bool get _allDecided =>
      _catsNeedingDecision.every((c) => _decisions.containsKey(c.catId));

  Future<void> _submitDeletion(bool isEn) async {
    if (_submitting || !_acknowledged) return;
    setState(() => _submitting = true);
    final decisions = <String, String?>{
      for (final cat in _cats)
        cat.catId: _decisions[cat.catId] == '__delete__'
            ? null
            : _decisions[cat.catId],
    };
    final ok = await ref
        .read(authControllerProvider.notifier)
        .requestAccountDeletion(transferDecisions: decisions);
    if (!mounted) return;
    if (ok) {
      setState(() {
        _submitting = false;
        _step = _DeleteStep.done;
      });
    } else {
      setState(() => _submitting = false);
      showToast(
        isEn
            ? 'Could not delete the account. Please try again.'
            : 'ลบบัญชีไม่สำเร็จ กรุณาลองใหม่อีกครั้ง',
      );
    }
  }

  void _goNext() {
    if (_catsNeedingDecision.isNotEmpty) {
      setState(() => _step = _DeleteStep.resolveCaretakers);
    } else {
      setState(() => _step = _DeleteStep.confirm);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEn = ref.watch(appLocaleProvider) == 'en';
    final authState = ref.watch(authControllerProvider);
    // guest เข้าหน้านี้ไม่ได้ — แต่ขั้นสุดท้ายหลังลบสำเร็จ session กลายเป็น guest
    // ต้องให้จอสำเร็จแสดงต่อได้ จึงดักเฉพาะขั้นแรก
    final isGuest =
        authState.sessionResolved &&
        authState.isGuest &&
        _step == _DeleteStep.warning;

    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _DeleteHeader(
                  title: isEn ? 'Delete account' : 'ลบบัญชี',
                  backLabel: AuthL10n.backLabel(isEn),
                  onBack: () {
                    if (_step == _DeleteStep.done || !context.canPop()) {
                      context.go('/settings');
                    } else {
                      context.pop();
                    }
                  },
                ),
                Expanded(
                  child: isGuest
                      ? _buildGuestGate(isEn)
                      : switch (_step) {
                          _DeleteStep.warning => _buildWarning(isEn),
                          _DeleteStep.resolveCaretakers => _buildCaretakerStep(
                            isEn,
                          ),
                          _DeleteStep.confirm => _buildConfirmStep(isEn),
                          _DeleteStep.done => _buildDoneStep(isEn),
                        },
                ),
              ],
            ),
            if (toastMessage != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 24,
                child: IgnorePointer(
                  child: Center(child: ToastPill(message: toastMessage!)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestGate(bool isEn) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.lockKeyhole,
              size: 42,
              color: AppColors.muted,
            ),
            const SizedBox(height: 12),
            Text(
              isEn ? 'Sign in required' : 'ต้องเข้าสู่ระบบก่อน',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isEn
                  ? 'Please sign in to manage account deletion.'
                  : 'เข้าสู่ระบบเพื่อจัดการการลบบัญชีของคุณ',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: () => context.push(
                  loginLocation(returnTo: '/settings/delete-account'),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.ownerTeal,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                child: Text(
                  isEn ? 'Sign in' : 'เข้าสู่ระบบ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarning(bool isEn) {
    if (_loadStatus == _LoadStatus.loading) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _skeleton(height: 180),
          const SizedBox(height: 14),
          _skeleton(height: 14, width: 160),
          const SizedBox(height: 10),
          _skeleton(height: 90),
          const SizedBox(height: 14),
          _skeleton(height: 52),
        ],
      );
    }
    if (_loadStatus == _LoadStatus.error) {
      return ErrorView(
        title: isEn ? 'Something went wrong' : 'โหลดข้อมูลไม่สำเร็จ',
        message: isEn
            ? 'Please check your connection and try again.'
            : 'ตรวจสอบการเชื่อมต่อแล้วลองใหม่อีกครั้ง',
        onRetry: _load,
      );
    }

    final catNames = _catsNeedingDecision.map((c) => c.catName).join(', ');
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.logoutBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.logoutBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                LucideIcons.triangleAlert,
                size: 30,
                color: AppColors.danger,
              ),
              const SizedBox(height: 10),
              Text(
                isEn
                    ? 'Deleting your account is permanent'
                    : 'การลบบัญชีเป็นการกระทำถาวร',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.logoutText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isEn
                    ? 'Your profile, posts, and all saved data will be kept for 30 days, then permanently deleted. You can restore the account by signing in again within 30 days.'
                    : 'โปรไฟล์ โพสต์ และข้อมูลทั้งหมดจะถูกเก็บไว้ 30 วันก่อนลบถาวร — ล็อกอินใหม่ภายใน 30 วันเพื่อกู้คืนบัญชีได้',
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: AppColors.text2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (_cats.isNotEmpty) ...[
          Text(
            isEn ? 'Cats linked to your account' : 'แมวที่ผูกกับบัญชีของคุณ',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              children: [
                for (var i = 0; i < _cats.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  Row(
                    children: [
                      if (_cats[i].imageSource != null)
                        AppAvatar(
                          source: _cats[i].imageSource!,
                          bg: 0xFFF6EFE6,
                          size: 38,
                        )
                      else
                        const CircleAvatar(
                          radius: 19,
                          backgroundColor: AppColors.soft,
                          child: Icon(
                            LucideIcons.cat,
                            size: 18,
                            color: AppColors.muted,
                          ),
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _cats[i].catName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      Text(
                        _cats[i].mustResolve
                            ? (isEn
                                  ? 'Has co-caretakers'
                                  : 'มีผู้ดูแลร่วม ${_cats[i].coCaretakers.length} คน')
                            : (isEn
                                  ? 'Deleted with account'
                                  : 'ลบไปพร้อมบัญชี'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _cats[i].mustResolve
                              ? AppColors.danger
                              : AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          if (_catsNeedingDecision.isNotEmpty)
            Text(
              isEn
                  ? 'Cats with co-caretakers must be transferred or confirmed for deletion in the next step.'
                  : 'แมวที่มีผู้ดูแลร่วม ($catNames) ต้องเลือกโอนสิทธิ์หรือยืนยันลบในขั้นตอนถัดไป',
              style: const TextStyle(
                fontSize: 12,
                height: 1.45,
                color: AppColors.muted,
              ),
            ),
        ] else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              isEn
                  ? 'No pets are linked to this account.'
                  : 'บัญชีนี้ไม่มีแมวที่ผูกไว้',
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          ),
        const SizedBox(height: 20),
        SizedBox(
          height: 50,
          child: FilledButton(
            onPressed: _goNext,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
            child: Text(
              isEn ? 'Continue' : 'ดำเนินการต่อ',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 50,
          child: OutlinedButton(
            onPressed: () => context.pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.text,
              side: const BorderSide(color: AppColors.line2),
              shape: const StadiumBorder(),
            ),
            child: Text(
              isEn ? 'Cancel' : 'ยกเลิก',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCaretakerStep(bool isEn) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text(
          isEn
              ? 'Decide what happens to your cats'
              : 'จัดการแมวของคุณก่อนลบบัญชี',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isEn
              ? 'Each cat with co-caretakers needs a new owner, or you can delete the cat profile together with your account.'
              : 'แมวแต่ละตัวที่มีผู้ดูแลร่วมต้องเลือกเจ้าของใหม่ หรือยืนยันลบโปรไฟล์แมวไปพร้อมบัญชี',
          style: const TextStyle(
            fontSize: 13,
            height: 1.45,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 14),
        for (final cat in _catsNeedingDecision)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (cat.imageSource != null)
                      AppAvatar(
                        source: cat.imageSource!,
                        bg: 0xFFF6EFE6,
                        size: 40,
                      )
                    else
                      const CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.soft,
                        child: Icon(
                          LucideIcons.cat,
                          size: 20,
                          color: AppColors.muted,
                        ),
                      ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        cat.catName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (final caretaker in cat.coCaretakers)
                  _DecisionTile(
                    selected: _decisions[cat.catId] == caretaker.id,
                    leading: caretaker.avatarSource != null
                        ? AppAvatar(
                            source: caretaker.avatarSource!,
                            bg: 0xFFF6EFE6,
                            size: 30,
                          )
                        : const CircleAvatar(
                            radius: 15,
                            backgroundColor: AppColors.soft,
                            child: Icon(
                              LucideIcons.user,
                              size: 15,
                              color: AppColors.muted,
                            ),
                          ),
                    title: isEn
                        ? 'Transfer to ${caretaker.name}'
                        : 'โอนสิทธิ์เจ้าของให้ ${caretaker.name}',
                    semanticLabel: isEn
                        ? 'Transfer ownership of ${cat.catName} to ${caretaker.name}'
                        : 'โอนสิทธิ์เจ้าของ${cat.catName}ให้${caretaker.name}',
                    onTap: () =>
                        setState(() => _decisions[cat.catId] = caretaker.id),
                  ),
                _DecisionTile(
                  selected: _decisions[cat.catId] == '__delete__',
                  leading: const CircleAvatar(
                    radius: 15,
                    backgroundColor: AppColors.logoutBg,
                    child: Icon(
                      LucideIcons.trash2,
                      size: 15,
                      color: AppColors.danger,
                    ),
                  ),
                  title: isEn
                      ? 'Delete ${cat.catName} with my account'
                      : 'ลบโปรไฟล์${cat.catName}ไปพร้อมบัญชี',
                  semanticLabel: isEn
                      ? 'Delete ${cat.catName} with my account'
                      : 'ลบโปรไฟล์${cat.catName}ไปพร้อมบัญชี',
                  isDestructive: true,
                  onTap: () =>
                      setState(() => _decisions[cat.catId] = '__delete__'),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        SizedBox(
          height: 50,
          child: FilledButton(
            onPressed: _allDecided
                ? () => setState(() => _step = _DeleteStep.confirm)
                : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
            child: Text(
              isEn ? 'Continue' : 'ดำเนินการต่อ',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 50,
          child: OutlinedButton(
            onPressed: () => setState(() => _step = _DeleteStep.warning),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.text,
              side: const BorderSide(color: AppColors.line2),
              shape: const StadiumBorder(),
            ),
            child: Text(
              isEn ? 'Back' : 'ย้อนกลับ',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmStep(bool isEn) {
    final transferCount = _catsNeedingDecision
        .where((c) => _decisions[c.catId] != '__delete__')
        .length;
    final deletedCats = _cats
        .where((c) => _decisions[c.catId] == '__delete__')
        .map((c) => c.catName)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text(
          isEn ? 'Final confirmation' : 'ยืนยันการลบบัญชี',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _summaryRow(
                isEn ? 'Your account and data' : 'บัญชีและข้อมูลทั้งหมดของคุณ',
                isEn ? 'Deleted after 30 days' : 'ลบถาวรหลัง 30 วัน',
              ),
              if (transferCount > 0)
                _summaryRow(
                  isEn
                      ? '$transferCount cat(s) transferred'
                      : 'โอนสิทธิ์แมว $transferCount ตัว',
                  isEn ? 'To chosen caretakers' : 'ให้ผู้ดูแลที่เลือก',
                ),
              if (deletedCats.isNotEmpty)
                _summaryRow(
                  isEn ? 'Deleted with account' : 'แมวที่ลบไปพร้อมบัญชี',
                  deletedCats.join(', '),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        InkWell(
          onTap: () => setState(() => _acknowledged = !_acknowledged),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    _acknowledged
                        ? LucideIcons.squareCheckBig
                        : LucideIcons.square,
                    size: 24,
                    color: _acknowledged
                        ? AppColors.ownerTeal
                        : AppColors.muted,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isEn
                        ? 'I understand that my account will be permanently deleted after 30 days and this action cannot be undone afterwards.'
                        : 'ข้าพเจ้าเข้าใจว่าบัญชีจะถูกลบถาวรหลังผ่านไป 30 วัน และไม่สามารถกู้คืนได้หลังจากนั้น',
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.5,
                      color: AppColors.text,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 50,
          child: FilledButton.icon(
            onPressed: _acknowledged && !_submitting
                ? () => _submitDeletion(isEn)
                : null,
            icon: const Icon(LucideIcons.trash2, size: 17),
            label: Text(
              _submitting
                  ? (isEn ? 'Deleting...' : 'กำลังลบบัญชี...')
                  : (isEn ? 'Delete my account' : 'ลบบัญชีของฉัน'),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 50,
          child: OutlinedButton(
            onPressed: _submitting
                ? null
                : () => setState(
                    () => _step = _catsNeedingDecision.isNotEmpty
                        ? _DeleteStep.resolveCaretakers
                        : _DeleteStep.warning,
                  ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.text,
              side: const BorderSide(color: AppColors.line2),
              shape: const StadiumBorder(),
            ),
            child: Text(
              isEn ? 'Back' : 'ย้อนกลับ',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDoneStep(bool isEn) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.ownerPillBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.checkCheck,
                size: 34,
                color: AppColors.ownerTeal,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isEn ? 'Deletion request sent' : 'ส่งคำขอลบบัญชีแล้ว',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isEn
                  ? 'Your data will be kept for 30 days. Sign in again within that period to restore your account.'
                  : 'ข้อมูลจะถูกเก็บไว้ 30 วัน หากเปลี่ยนใจให้เข้าสู่ระบบอีกครั้งภายใน 30 วันเพื่อกู้คืนบัญชี',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () => context.go('/'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.ownerTeal,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  isEn ? 'Back to home' : 'กลับหน้าหลัก',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13.5, color: AppColors.text2),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeleton({required double height, double? width}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.soft,
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }
}

class _DecisionTile extends StatelessWidget {
  const _DecisionTile({
    required this.selected,
    required this.leading,
    required this.title,
    required this.semanticLabel,
    required this.onTap,
    this.isDestructive = false,
  });

  final bool selected;
  final Widget leading;
  final String title;
  final String semanticLabel;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.soft : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? (isDestructive ? AppColors.logoutBorder : AppColors.line2)
                  : AppColors.line,
            ),
          ),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDestructive ? AppColors.danger : AppColors.text,
                  ),
                ),
              ),
              Icon(
                selected ? LucideIcons.circleCheckBig : LucideIcons.circle,
                size: 20,
                color: selected
                    ? (isDestructive ? AppColors.danger : AppColors.ownerTeal)
                    : AppColors.unchecked,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteHeader extends StatelessWidget {
  const _DeleteHeader({
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
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 6),
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
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
