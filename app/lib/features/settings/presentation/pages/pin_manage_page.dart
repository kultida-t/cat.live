import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/config/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../auth/presentation/widgets/auth_l10n.dart';
import '../widgets/settings_l10n.dart';

enum _PinStep { verifyCurrent, create, done }

/// หน้าตั้ง/เปลี่ยนรหัส PIN (/settings/account/pin)
/// ยังไม่มี PIN → ขั้นเดียว (PIN ใหม่ + ยืนยัน) · มี PIN แล้ว → ยืนยัน PIN เดิม
/// ก่อนแล้วจึงตั้ง PIN ใหม่ ตามกติกาเปลี่ยนรหัสต้องรู้รหัสเดิม
class PinManagePage extends ConsumerStatefulWidget {
  const PinManagePage({super.key});

  @override
  ConsumerState<PinManagePage> createState() => _PinManagePageState();
}

class _PinManagePageState extends ConsumerState<PinManagePage> {
  final _currentPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  _PinStep? _step;
  bool? _hasPin;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _currentPinController.addListener(_refresh);
    _newPinController.addListener(_refresh);
    _confirmPinController.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _verifyCurrent(bool isEn) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final pin = _currentPinController.text.trim();
    if (pin.length != 6) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final ok = await ref
        .read(authControllerProvider.notifier)
        .verifyCurrentPin(pin);
    if (!mounted) return;
    setState(() {
      _submitting = false;
      if (ok) {
        _step = _PinStep.create;
      } else {
        _error = AuthL10n.pinWrongCurrentError(isEn);
      }
    });
  }

  Future<void> _saveNewPin(bool isEn) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final newPin = _newPinController.text.trim();
    final confirm = _confirmPinController.text.trim();
    if (newPin.length != 6 || confirm.length != 6) return;
    if (newPin != confirm) {
      setState(() => _error = AuthL10n.pinSetupMismatchError(isEn));
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final notifier = ref.read(authControllerProvider.notifier);
    final ok = _hasPin == true
        ? await notifier.changePinForCurrentAccount(
            currentPin: _currentPinController.text.trim(),
            newPin: newPin,
          )
        : await notifier.setPinForCurrentAccount(newPin);
    if (!mounted) return;
    setState(() {
      _submitting = false;
      if (ok) {
        _step = _PinStep.done;
      } else {
        _error = AuthL10n.pinSaveFailedError(isEn);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEn = ref.watch(appLocaleProvider) == 'en';
    final authState = ref.watch(authControllerProvider);
    final pinStatus = ref.watch(accountPinStatusProvider);
    final isGuest = authState.sessionResolved && authState.isGuest;
    final hasPhone = authState.session.user?.phone != null;

    // รู้สถานะ PIN จริงจาก storage แล้วค่อยเลือกขั้นแรก (ยังไม่รู้ → รอ skeleton)
    if (_hasPin == null && pinStatus.hasValue) {
      _hasPin = pinStatus.value;
      _step = _hasPin == true ? _PinStep.verifyCurrent : _PinStep.create;
    }
    final hasPin = _hasPin == true;

    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: Column(
          children: [
            _PinHeader(
              title: AuthL10n.pinManageTitle(hasPin, isEn),
              backLabel: SettingsL10n.backLabel(isEn),
              onBack: () =>
                  context.canPop() ? context.pop() : context.go('/settings'),
            ),
            Expanded(child: _buildBody(isEn, isGuest, hasPhone, hasPin)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool isEn, bool isGuest, bool hasPhone, bool hasPin) {
    if (isGuest || !hasPhone) {
      return _PinMessageCard(
        icon: LucideIcons.lockKeyhole,
        title: isEn ? 'Not available' : 'ใช้งานไม่ได้สำหรับบัญชีนี้',
        message: isGuest
            ? (isEn ? 'Please sign in first.' : 'เข้าสู่ระบบก่อนจัดการรหัส PIN')
            : AuthL10n.pinNoPhoneHint(isEn),
      );
    }
    return switch (_step) {
      null => const Center(child: CircularProgressIndicator()),
      _PinStep.done => _PinDoneView(hasPin: hasPin, isEn: isEn),
      _PinStep.verifyCurrent => _buildForm(
        isEn: isEn,
        fields: [
          _PinField(
            label: AuthL10n.pinCurrentLabel(isEn),
            hint: AuthL10n.pinCurrentHint(isEn),
            controller: _currentPinController,
          ),
        ],
        buttonLabel: AuthL10n.pinNextBtn(isEn),
        buttonEnabled:
            !_submitting && _currentPinController.text.trim().length == 6,
        onSubmit: () => _verifyCurrent(isEn),
      ),
      _PinStep.create => _buildForm(
        isEn: isEn,
        fields: [
          _PinField(
            label: AuthL10n.pinSetupNewLabel(isEn),
            controller: _newPinController,
          ),
          _PinField(
            label: AuthL10n.pinSetupConfirmLabel(isEn),
            controller: _confirmPinController,
          ),
        ],
        buttonLabel: AuthL10n.pinSetupSaveBtn(isEn),
        buttonEnabled:
            !_submitting &&
            _newPinController.text.trim().length == 6 &&
            _confirmPinController.text.trim().length == 6,
        onSubmit: () => _saveNewPin(isEn),
      ),
    };
  }

  Widget _buildForm({
    required bool isEn,
    required List<_PinField> fields,
    required String buttonLabel,
    required bool buttonEnabled,
    required VoidCallback onSubmit,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < fields.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                fields[i],
              ],
              if (_error != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.logoutBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.logoutBorder),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.logoutText,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Semantics(
                button: true,
                label: buttonLabel,
                child: FilledButton(
                  onPressed: buttonEnabled ? onSubmit : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.ownerTeal,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.line2,
                    disabledForegroundColor: AppColors.muted,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    buttonLabel,
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
      ],
    );
  }
}

/// ช่องกรอก PIN — ซ่อนตัวอักษร + แป้นตัวเลขตามกติกา
class _PinField extends StatelessWidget {
  const _PinField({required this.label, required this.controller, this.hint});

  final String label;
  final String? hint;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        if (hint != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              hint!,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ),
        const SizedBox(height: 8),
        Semantics(
          label: label,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: '••••••',
              counterText: '',
              prefixIcon: const Icon(LucideIcons.lockKeyhole, size: 18),
              filled: true,
              fillColor: AppColors.soft,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PinHeader extends StatelessWidget {
  const _PinHeader({
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

/// จอสำเร็จ — แจ้งสั้น ๆ แล้วให้กดเสร็จกลับหน้าบัญชี
class _PinDoneView extends StatelessWidget {
  const _PinDoneView({required this.hasPin, required this.isEn});

  final bool hasPin;
  final bool isEn;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
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
              AuthL10n.pinDoneTitle(hasPin, isEn),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              AuthL10n.pinDoneSubtitle(isEn),
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
              child: Semantics(
                button: true,
                label: AuthL10n.doneBtn(isEn),
                child: FilledButton(
                  onPressed: () => context.pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.ownerTeal,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                  ),
                  child: Text(
                    AuthL10n.doneBtn(isEn),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ตราแมว + ป้ายเล็กมุมล่างขวา — สไตล์เดียวกับจอสำเร็จของหน้าลบบัญชี
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
                decoration: BoxDecoration(
                  color: bg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.cat,
                  size: size * 0.46,
                  color: color,
                ),
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

/// การ์ดข้อความกลางจอสำหรับเคสเข้าไม่ได้ (guest / บัญชีไม่มีเบอร์)
class _PinMessageCard extends StatelessWidget {
  const _PinMessageCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
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
              child: Icon(icon, size: 30, color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
