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

  /// catId → caretakerId ที่รับโอนสิทธิ์ ('__delete__' = ลบแมวไปพร้อมบัญชี)
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
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.soft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.lockKeyhole,
                size: 30,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isEn ? 'Sign in required' : 'ต้องเข้าสู่ระบบก่อน',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isEn
                  ? 'Please sign in to manage account deletion.'
                  : 'เข้าสู่ระบบเพื่อจัดการการลบบัญชีของคุณ',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 20),
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
                  padding: const EdgeInsets.symmetric(horizontal: 28),
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

  // ---------- ขั้นที่ 1: เตือน ----------
  Widget _buildWarning(bool isEn) {
    if (_loadStatus == _LoadStatus.loading) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _skeleton(height: 88, radius: 44, width: 88, center: true),
          const SizedBox(height: 16),
          _skeleton(height: 18, width: 200, center: true),
          const SizedBox(height: 8),
          _skeleton(height: 12, width: 160, center: true),
          const SizedBox(height: 20),
          _skeleton(height: 168),
          const SizedBox(height: 14),
          _skeleton(height: 140),
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
        const SizedBox(height: 4),
        const _CatIconBadge(
          badge: LucideIcons.triangleAlert,
          bg: AppColors.logoutBg,
          color: AppColors.danger,
        ),
        const SizedBox(height: 14),
        Text(
          isEn
              ? 'Deleting your account is permanent'
              : 'การลบบัญชีเป็นการกระทำถาวร',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isEn
              ? 'Please review the details before continuing'
              : 'โปรดอ่านรายละเอียดก่อนดำเนินการต่อ',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppColors.muted),
        ),
        const SizedBox(height: 18),
        _InfoCard(
          rows: [
            (
              LucideIcons.clock,
              isEn ? 'Kept for 30 days' : 'ข้อมูลถูกเก็บไว้ 30 วัน',
              isEn
                  ? 'Your profile and data are retained first'
                  : 'โปรไฟล์และข้อมูลทั้งหมดจะถูกเก็บไว้ก่อน',
            ),
            (
              LucideIcons.rotateCcw,
              isEn ? 'Restorable within 30 days' : 'กู้คืนได้ภายใน 30 วัน',
              isEn
                  ? 'Just sign in again to restore everything'
                  : 'เพียงเข้าสู่ระบบอีกครั้งก็กู้คืนบัญชีได้',
            ),
            (
              LucideIcons.ban,
              isEn ? 'No recovery afterwards' : 'พ้นกำหนดแล้วกู้คืนไม่ได้',
              isEn
                  ? 'Everything is permanently deleted'
                  : 'ข้อมูลทั้งหมดจะถูกลบถาวรโดยไม่ย้อนกลับได้',
            ),
          ],
        ),
        if (_cats.isNotEmpty) ...[
          const SizedBox(height: 18),
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
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              children: [
                for (var i = 0; i < _cats.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, indent: 62, endIndent: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        _CatThumb(source: _cats[i].imageSource),
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
                        _StatusPill(
                          label: _cats[i].mustResolve
                              ? (isEn
                                    ? '${_cats[i].coCaretakers.length} co-caretaker(s)'
                                    : 'มีผู้ดูแลร่วม ${_cats[i].coCaretakers.length} คน')
                              : (isEn
                                    ? 'Deleted with account'
                                    : 'ลบไปพร้อมบัญชี'),
                          isAlert: _cats[i].mustResolve,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_catsNeedingDecision.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              isEn
                  ? 'Cats with co-caretakers must be transferred or confirmed for deletion in the next step.'
                  : 'แมวที่มีผู้ดูแลร่วม ($catNames) ต้องเลือกโอนสิทธิ์หรือยืนยันลบในขั้นตอนถัดไป',
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppColors.muted,
              ),
            ),
          ],
        ] else ...[
          const SizedBox(height: 14),
          Text(
            isEn
                ? 'No pets are linked to this account.'
                : 'บัญชีนี้ไม่มีแมวที่ผูกไว้',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
        ],
        const SizedBox(height: 22),
        _PrimaryButton(
          label: isEn ? 'Continue' : 'ดำเนินการต่อ',
          color: AppColors.danger,
          onPressed: _goNext,
        ),
        const SizedBox(height: 10),
        _SecondaryButton(
          label: isEn ? 'Cancel' : 'ยกเลิก',
          onPressed: () => context.pop(),
        ),
      ],
    );
  }

  // ---------- ขั้นที่ 2: จัดการแมวที่มีผู้ดูแลร่วม ----------
  Widget _buildCaretakerStep(bool isEn) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        const _CatIconBadge(
          badge: LucideIcons.users,
          bg: AppColors.ownerPillBg,
          color: AppColors.ownerTeal,
        ),
        const SizedBox(height: 14),
        Text(
          isEn
              ? 'Decide what happens to your cats'
              : 'จัดการแมวของคุณก่อนลบบัญชี',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isEn
              ? 'Each cat with co-caretakers needs a new owner,\nor can be deleted together with your account.'
              : 'แมวที่มีผู้ดูแลร่วมแต่ละตัวต้องเลือกเจ้าของใหม่\nหรือยืนยันลบโปรไฟล์แมวไปพร้อมบัญชี',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            height: 1.5,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 18),
        for (final cat in _catsNeedingDecision)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                  child: Row(
                    children: [
                      _CatThumb(source: cat.imageSource, size: 44),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cat.catName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.text,
                              ),
                            ),
                            Text(
                              isEn
                                  ? '${cat.coCaretakers.length} co-caretaker(s)'
                                  : 'มีผู้ดูแลร่วม ${cat.coCaretakers.length} คน',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, indent: 14, endIndent: 14),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
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
                          subtitle: isEn
                              ? '${caretaker.name} becomes the new owner'
                              : '${caretaker.name} จะเป็นเจ้าของคนใหม่',
                          semanticLabel: isEn
                              ? 'Transfer ownership of ${cat.catName} to ${caretaker.name}'
                              : 'โอนสิทธิ์เจ้าของ${cat.catName}ให้${caretaker.name}',
                          onTap: () => setState(
                            () => _decisions[cat.catId] = caretaker.id,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Expanded(child: Divider(height: 1)),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Text(
                                isEn ? 'or' : 'หรือ',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider(height: 1)),
                          ],
                        ),
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
                        subtitle: isEn
                            ? 'The cat profile is removed permanently'
                            : 'โปรไฟล์แมวตัวนี้จะถูกลบถาวร',
                        semanticLabel: isEn
                            ? 'Delete ${cat.catName} with my account'
                            : 'ลบโปรไฟล์${cat.catName}ไปพร้อมบัญชี',
                        isDestructive: true,
                        onTap: () => setState(
                          () => _decisions[cat.catId] = '__delete__',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 6),
        _PrimaryButton(
          label: isEn ? 'Continue' : 'ดำเนินการต่อ',
          color: AppColors.danger,
          onPressed: _allDecided
              ? () => setState(() => _step = _DeleteStep.confirm)
              : null,
        ),
        if (!_allDecided) ...[
          const SizedBox(height: 6),
          Text(
            isEn
                ? 'Please choose an option for every cat'
                : 'เลือกให้ครบทุกตัวก่อนดำเนินการต่อ',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ],
        const SizedBox(height: 10),
        _SecondaryButton(
          label: isEn ? 'Back' : 'ย้อนกลับ',
          onPressed: () => setState(() => _step = _DeleteStep.warning),
        ),
      ],
    );
  }

  // ---------- ขั้นที่ 3: ยืนยันสุดท้าย ----------
  Widget _buildConfirmStep(bool isEn) {
    final transferred = _catsNeedingDecision
        .where((c) => _decisions[c.catId] != '__delete__')
        .length;
    final deletedCats = _cats
        .where((c) => _decisions[c.catId] == '__delete__')
        .map((c) => c.catName)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        const _CatIconBadge(
          badge: LucideIcons.circleAlert,
          bg: AppColors.logoutBg,
          color: AppColors.danger,
        ),
        const SizedBox(height: 14),
        Text(
          isEn ? 'Final confirmation' : 'ยืนยันการลบบัญชี',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isEn
              ? 'Please review the summary carefully'
              : 'ตรวจสอบสรุปรายการอีกครั้งก่อนยืนยัน',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppColors.muted),
        ),
        const SizedBox(height: 18),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            children: [
              _ConfirmSummaryRow(
                icon: LucideIcons.userX,
                label: isEn ? 'Your account and data' : 'บัญชีและข้อมูลทั้งหมด',
                value: isEn ? 'Deleted after 30 days' : 'ลบถาวรหลัง 30 วัน',
                isFirst: true,
              ),
              if (transferred > 0)
                _ConfirmSummaryRow(
                  icon: LucideIcons.users,
                  label: isEn
                      ? '$transferred cat(s) transferred'
                      : 'โอนสิทธิ์แมว $transferred ตัว',
                  value: isEn ? 'To chosen caretakers' : 'ให้ผู้ดูแลที่เลือก',
                ),
              if (deletedCats.isNotEmpty)
                _ConfirmSummaryRow(
                  icon: LucideIcons.cat,
                  label: isEn ? 'Deleted with account' : 'แมวที่ลบไปพร้อมบัญชี',
                  value: deletedCats.join(', '),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Semantics(
          button: true,
          label: isEn
              ? 'I understand the account will be permanently deleted after 30 days'
              : 'ข้าพเจ้าเข้าใจว่าบัญชีจะถูกลบถาวรหลัง 30 วัน',
          child: InkWell(
            onTap: () => setState(() => _acknowledged = !_acknowledged),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _acknowledged ? AppColors.ownerPillBg : AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _acknowledged
                      ? AppColors.ownerTealRing
                      : AppColors.line,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _acknowledged
                        ? LucideIcons.circleCheckBig
                        : LucideIcons.circle,
                    size: 22,
                    color: _acknowledged
                        ? AppColors.ownerTeal
                        : AppColors.unchecked,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isEn
                          ? 'I understand that my account will be permanently deleted after 30 days and cannot be restored afterwards.'
                          : 'ข้าพเจ้าเข้าใจว่าบัญชีจะถูกลบถาวรหลังผ่านไป 30 วัน และไม่สามารถกู้คืนได้หลังจากนั้น',
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.55,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        _PrimaryButton(
          label: _submitting
              ? (isEn ? 'Deleting...' : 'กำลังลบบัญชี...')
              : (isEn ? 'Delete my account' : 'ลบบัญชีของฉัน'),
          icon: LucideIcons.trash2,
          color: AppColors.danger,
          onPressed: _acknowledged && !_submitting
              ? () => _submitDeletion(isEn)
              : null,
        ),
        const SizedBox(height: 10),
        _SecondaryButton(
          label: isEn ? 'Back' : 'ย้อนกลับ',
          onPressed: _submitting
              ? null
              : () => setState(
                  () => _step = _catsNeedingDecision.isNotEmpty
                      ? _DeleteStep.resolveCaretakers
                      : _DeleteStep.warning,
                ),
        ),
      ],
    );
  }

  // ---------- ขั้นที่ 4: สำเร็จ ----------
  Widget _buildDoneStep(bool isEn) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _CatIconBadge(
              badge: LucideIcons.checkCheck,
              bg: AppColors.ownerPillBg,
              color: AppColors.ownerTeal,
              size: 84,
            ),
            const SizedBox(height: 16),
            Text(
              isEn ? 'Deletion request sent' : 'ส่งคำขอลบบัญชีแล้ว',
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isEn
                  ? 'We have received your request.\nYour data is kept safely for 30 days.'
                  : 'เราได้รับคำขอลบบัญชีของคุณแล้ว\nข้อมูลจะถูกเก็บไว้อย่างปลอดภัยเป็นเวลา 30 วัน',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.55,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.soft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(
                      LucideIcons.clock,
                      size: 18,
                      color: AppColors.ownerTeal,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEn ? 'Changed your mind?' : 'เปลี่ยนใจ?',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isEn
                              ? 'Sign in again within 30 days to restore everything.'
                              : 'เข้าสู่ระบบอีกครั้งภายใน 30 วันเพื่อกู้คืนบัญชีและข้อมูลทั้งหมด',
                          style: const TextStyle(
                            fontSize: 12.5,
                            height: 1.45,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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

  Widget _skeleton({
    required double height,
    double? width,
    double radius = 18,
    bool center = false,
  }) {
    final box = Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.soft,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
    return center ? Center(child: box) : box;
  }
}

// ---------- widgets ย่อย ----------

/// วงกลมไอคอนกลางจอของแต่ละขั้น
/// ไอคอนแมวกลม ๆ ตามสไตล์แอป พร้อม badge เล็กมุมขวาล่างบอกบริบทของแต่ละขั้น
class _CatIconBadge extends StatelessWidget {
  const _CatIconBadge({
    required this.badge,
    required this.bg,
    required this.color,
    this.size = 76,
  });

  final IconData badge;
  final Color bg;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final badgeSize = size * 0.36;
    return Center(
      child: SizedBox(
        width: size + 8,
        height: size + 8,
        child: Stack(
          children: [
            Center(
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                child: Icon(LucideIcons.cat, size: size * 0.46, color: color),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.line, width: 1.5),
                ),
                child: Icon(badge, size: badgeSize * 0.55, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// การ์ดอธิบายขั้นตอน แต่ละแถวเป็นไอคอน + หัวข้อ + คำอธิบาย
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});

  final List<(IconData, String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 62, endIndent: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.soft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(rows[i].$1, size: 18, color: AppColors.ink),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rows[i].$2,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          rows[i].$3,
                          style: const TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CatThumb extends StatelessWidget {
  const _CatThumb({required this.source, this.size = 40});

  final String? source;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (source != null) {
      return AppAvatar(source: source!, bg: 0xFFF6EFE6, size: size);
    }
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.soft,
      child: Icon(LucideIcons.cat, size: size * 0.45, color: AppColors.muted),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.isAlert});

  final String label;
  final bool isAlert;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isAlert ? AppColors.logoutBg : AppColors.soft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: isAlert ? AppColors.logoutText : AppColors.muted,
        ),
      ),
    );
  }
}

class _DecisionTile extends StatelessWidget {
  const _DecisionTile({
    required this.selected,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.semanticLabel,
    required this.onTap,
    this.isDestructive = false,
  });

  final bool selected;
  final Widget leading;
  final String title;
  final String subtitle;
  final String semanticLabel;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final accent = isDestructive ? AppColors.danger : AppColors.ownerTeal;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: const BoxConstraints(minHeight: 52),
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? (isDestructive ? AppColors.logoutBg : AppColors.ownerPillBg)
                : AppColors.page,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? (isDestructive
                        ? AppColors.logoutBorder
                        : AppColors.ownerTealRing)
                  : AppColors.line,
            ),
          ),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDestructive
                            ? AppColors.logoutText
                            : AppColors.text,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected ? LucideIcons.circleCheckBig : LucideIcons.circle,
                size: 20,
                color: selected ? accent : AppColors.unchecked,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmSummaryRow extends StatelessWidget {
  const _ConfirmSummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isFirst = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isFirst) const Divider(height: 1, indent: 14, endIndent: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: AppColors.ink),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.text2,
                  ),
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
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.color,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon ?? LucideIcons.arrowRight, size: 17),
        label: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          side: const BorderSide(color: AppColors.line2),
          shape: const StadiumBorder(),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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
