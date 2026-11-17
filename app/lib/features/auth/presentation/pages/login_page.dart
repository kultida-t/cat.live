import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/config/app_locale.dart';
import '../../../../core/config/pet_species_config.dart';
import '../../../../core/router/auth_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/social_brand_icons.dart';
import '../../../../core/widgets/toast_pill.dart';
import '../../domain/entities/auth_data.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth_rules.dart';
import '../providers/auth_controller.dart';
import '../widgets/auth_l10n.dart';
import '../widgets/pending_deletion_sheet.dart';

/// หน้าเข้าสู่ระบบ สมัครสมาชิก และ Guest Mode (/login — AUTH-01..04, PDPA-03)
/// `returnTo` = ปลายทางหลังล็อกอินสำเร็จ (AUTH-02), `initialRegister` = เปิดแท็บสมัครเลย
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key, this.returnTo, this.initialRegister = false});

  final String? returnTo;
  final bool initialRegister;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> with ToastMixin {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  late bool _isRegisterMode = widget.initialRegister;
  bool _useOtpInSignIn = false;
  int _selectedBirthYear = 1995;
  bool _guardianConsent = false;
  bool _pdpaAccepted = false;
  String? _validationError;

  /// ขั้นตั้ง PIN หลังยืนยัน OTP ผ่าน — แสดงเมื่อบัญชีนี้ยังไม่มี PIN บนเครื่อง
  bool _pinSetupPhase = false;
  bool? _accountHasPin;
  String? _pinSetupError;
  int _prevPhoneLen = 0;
  int _prevPinLen = 0;
  int _prevOtpLen = 0;
  bool _prevBothPinsDone = false;
  bool _obscurePin = true;
  bool _obscureNewPin = true;
  bool _obscureConfirmPin = true;

  @override
  void initState() {
    super.initState();
    // ปิดคีย์แพ็ดเฉพาะตอน "พิมพ์จนครบจำนวนหลัก" เท่านั้น — เก็บความยาวล่าสุดไว้เทียบ
    // ไม่งั้นตอนลบ/แก้ตัวเลขที่ยังอยู่ที่จำนวนครบคีย์แพ็ดจะหุบกลางทาง
    _phoneController.addListener(() {
      final len = _phoneController.text.length;
      if (len == 10 && _prevPhoneLen < 10) {
        FocusManager.instance.primaryFocus?.unfocus();
      }
      _prevPhoneLen = len;
      setState(() {});
    });
    _pinController.addListener(() {
      final len = _pinController.text.length;
      if (len == 6 && _prevPinLen < 6) {
        FocusManager.instance.primaryFocus?.unfocus();
      }
      _prevPinLen = len;
      setState(() {});
    });
    _otpController.addListener(() {
      final len = _otpController.text.length;
      if (len == 6 && _prevOtpLen < 6) {
        FocusManager.instance.primaryFocus?.unfocus();
      }
      _prevOtpLen = len;
      setState(() {});
    });
    void dismissWhenBothPinsDone() {
      final bothDone =
          _newPinController.text.length == 6 &&
          _confirmPinController.text.length == 6;
      if (bothDone && !_prevBothPinsDone) {
        FocusManager.instance.primaryFocus?.unfocus();
      }
      _prevBothPinsDone = bothDone;
      setState(() {});
    }

    _newPinController.addListener(dismissWhenBothPinsDone);
    _confirmPinController.addListener(dismissWhenBothPinsDone);
  }

  /// ปลายทางหลังล็อกอิน/สมัครสำเร็จ — ค่าเริ่มต้นคือหน้าแรก (AUTH-02)
  String get _afterAuthTarget => sanitizeAuthReturnTo(widget.returnTo) ?? '/';

  void _goAfterAuth() {
    if (mounted) context.go(_afterAuthTarget);
  }

  /// เรียกหลังล็อกอิน/สมัครสำเร็จ — ถ้าบัญชีค้างลบ (AUTH-05) ให้เปิดชีตเลือก
  /// กู้คืน/ลบต่อก่อน ไม่เช่นนั้นจึงแจ้งเตือนแล้วพาไปปลายทางเดิม
  Future<void> _finishAfterSignIn(bool isEn) async {
    final authState = ref.read(authControllerProvider);
    if (authState.isPendingDeletion) {
      final scheduledAt = authState.session.deletionScheduledAt;
      final deadline = scheduledAt?.add(const Duration(days: 30));
      final daysRemaining = deadline == null
          ? 30
          : deadline.difference(DateTime.now()).inDays;
      final restored = await showPendingDeletionSheet(
        context,
        daysRemaining: daysRemaining,
      );
      if (!mounted) return;
      if (restored == true) {
        showToast(isEn ? 'Account restored' : 'กู้คืนบัญชีเรียบร้อยแล้ว');
        _goAfterAuth();
      } else if (restored == false) {
        showToast(
          isEn
              ? 'Account will be permanently deleted'
              : 'บัญชีจะถูกลบถาวรตามกำหนด',
        );
        context.go('/');
      }
      // restored == null → ผู้ใช้ปิดชีตไป ค้างอยู่หน้าล็อกอินเดิม
      return;
    }
    showToast(isEn ? 'Signed in successfully' : 'เข้าสู่ระบบสำเร็จแล้ว');
    _goAfterAuth();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _pinController.dispose();
    _otpController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    disposeToast();
    super.dispose();
  }

  List<int> _birthYearOptions() {
    final currentYear = DateTime.now().year;
    return List<int>.generate(75, (index) => currentYear - 8 - index);
  }

  AgeEligibility get _ageEligibility => AuthRules.evaluateAge(
    birthYear: _selectedBirthYear,
    currentYear: DateTime.now().year,
  );

  bool get _canProceedAuth {
    if (!_isRegisterMode) return true;
    if (_ageEligibility == AgeEligibility.under13Blocked) return false;
    if (_ageEligibility == AgeEligibility.minorNeedsGuardianConsent &&
        !_guardianConsent) {
      return false;
    }
    return _pdpaAccepted;
  }

  bool get _canRequestOtp =>
      _canProceedAuth && AuthRules.isValidThaiPhone(_phoneController.text);

  bool get _canSignInWithPin =>
      AuthRules.isValidThaiPhone(_phoneController.text) &&
      _pinController.text.trim().length == 6;

  Future<void> _handleSignInWithPin(bool isEn) async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_canSignInWithPin) return;
    final failure = await ref
        .read(authControllerProvider.notifier)
        .signInWithPin(
          phone: _phoneController.text.trim(),
          pin: _pinController.text.trim(),
        );
    if (!mounted) return;
    if (failure == null) {
      setState(() => _validationError = null);
      await _finishAfterSignIn(isEn);
      return;
    }
    setState(
      () => _validationError = failure == PinSignInFailure.noPinForPhone
          ? AuthL10n.noPinForPhoneError(isEn)
          : AuthL10n.invalidPinError(isEn),
    );
  }

  bool _validateCompliance(bool isEn) {
    if (!_isRegisterMode) {
      setState(() => _validationError = null);
      return true;
    }
    if (_ageEligibility == AgeEligibility.under13Blocked) {
      setState(() => _validationError = AuthL10n.birthYearUnder13Error(isEn));
      return false;
    }
    if (_ageEligibility == AgeEligibility.minorNeedsGuardianConsent &&
        !_guardianConsent) {
      setState(
        () => _validationError = AuthL10n.guardianConsentRequiredError(isEn),
      );
      return false;
    }
    if (!_pdpaAccepted) {
      setState(() => _validationError = AuthL10n.pdpaRequiredError(isEn));
      return false;
    }
    setState(() => _validationError = null);
    return true;
  }

  Future<void> _openBirthYearPicker(bool isEn) async {
    final years = _birthYearOptions();
    var tempIndex = years.indexOf(_selectedBirthYear);
    if (tempIndex < 0) tempIndex = 0;

    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: 300,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(
                        AuthL10n.pickerCancel(isEn),
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ),
                    Text(
                      AuthL10n.pickerTitle(isEn),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(years[tempIndex]),
                      child: Text(
                        AuthL10n.pickerDone(isEn),
                        style: const TextStyle(
                          color: AppColors.ownerTeal,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.line),
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(
                    initialItem: tempIndex,
                  ),
                  itemExtent: 42,
                  onSelectedItemChanged: (idx) => tempIndex = idx,
                  children: years
                      .map(
                        (y) => Center(
                          child: Text(
                            isEn ? '$y' : '$y (พ.ศ. ${y + 543})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedBirthYear = picked;
        _validationError = null;
      });
    }
  }

  Future<void> _openPdpaDetailsSheet(
    PetSpeciesConfig species,
    bool isEn,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.45,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollCtrl) => SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        AuthL10n.pdpaSheetTitle(isEn),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(LucideIcons.x, size: 20),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.line),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                  children: [
                    _PdpaDetailSection(
                      title: isEn
                          ? '1. Data We Collect'
                          : '1. ข้อมูลส่วนบุคคลที่จัดเก็บ',
                      body: isEn
                          ? 'Phone number / OAuth profile, birth year for age verification, ${species.petNoun(true).toLowerCase()} profiles, and health logs you choose to save.'
                          : 'เบอร์โทรศัพท์หรือข้อมูลบัญชี Apple/Google/LINE, ปีเกิดเพื่อตรวจเกณฑ์อายุ, และข้อมูล${species.petNoun(false)}/สมุดสุขภาพที่คุณบันทึก',
                    ),
                    _PdpaDetailSection(
                      title: isEn
                          ? '2. Purpose & AI Policy'
                          : '2. วัตถุประสงค์และนโยบาย AI',
                      body: isEn
                          ? 'Used solely for account authentication, missing-pet alerts, and health tracking. AI conversations are never used for model training without explicit opt-in.'
                          : 'ใช้เพื่อยืนยันตัวตน แจ้งเตือนสัตว์เลี้ยงหาย และบันทึกสุขภาพเท่านั้น — ไม่นำข้อมูลไปฝึกโมเดล AI หากไม่ได้รับความยินยอมแยกต่างหาก',
                    ),
                    _PdpaDetailSection(
                      title: isEn
                          ? '3. Age Compliance (PDPA-03)'
                          : '3. เงื่อนไขด้านอายุ (PDPA-03)',
                      body: isEn
                          ? 'Users under 13 cannot register. Users aged 13–19 require parental/guardian consent before using paid features.'
                          : 'ผู้ใช้อายุต่ำกว่า 13 ปีไม่สามารถสมัครใช้งานได้ ผู้ใช้อายุ 13–19 ปีต้องได้รับความยินยอมจากผู้ปกครอง',
                    ),
                    _PdpaDetailSection(
                      title: isEn
                          ? '4. Your Rights (Export & Delete)'
                          : '4. สิทธิ์ของเจ้าของข้อมูล',
                      body: isEn
                          ? 'You can withdraw consent, export your data (JSON + PDF), or request account deletion anytime in Settings.'
                          : 'คุณสามารถถอนความยินยอม ขอสำเนาข้อมูล (JSON + PDF) หรือขอลบบัญชีถาวรได้ทุกเมื่อในหน้าตั้งค่า',
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      setState(() => _pdpaAccepted = true);
                      Navigator.of(ctx).pop();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.ownerTeal,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: Text(
                      isEn ? 'Accept & Close' : 'ยอมรับและปิดหน้าต่าง',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleRequestOtp(bool isEn) async {
    if (!_validateCompliance(isEn)) return;
    final phone = _phoneController.text.trim();
    if (!AuthRules.isValidThaiPhone(phone)) {
      setState(() => _validationError = AuthL10n.invalidPhoneError(isEn));
      return;
    }
    final ok = await ref
        .read(authControllerProvider.notifier)
        .requestOtp(phone);
    if (!ok || !mounted) return;
    // จำไว้เลยว่าเบอร์นี้มี PIN บนเครื่องหรือยัง เพื่อตัดสินขั้นตั้ง PIN
    // ทันทีหลังยืนยัน OTP ผ่านโดยไม่ต้องรอ query ซ้ำ
    _accountHasPin = await ref
        .read(authControllerProvider.notifier)
        .hasPinForPhone(phone);
    if (mounted) {
      showToast(
        isEn ? 'OTP sent (Mock: 123456)' : 'ส่งรหัส OTP แล้ว (ทดสอบ: 123456)',
      );
    }
  }

  bool get _canVerifyOtp => _otpController.text.trim().length == 6;

  Future<void> _handleVerifyOtp(bool isEn) async {
    if (!_validateCompliance(isEn)) return;
    final code = _otpController.text.trim();
    if (code.length != 6) return;
    final ok = await ref
        .read(authControllerProvider.notifier)
        .verifyOtp(
          code: code,
          birthYear: _selectedBirthYear,
          guardianConsentGranted: _guardianConsent,
          displayName: _isRegisterMode ? _nameController.text.trim() : null,
        );
    if (!ok || !mounted) return;
    // บัญชีนี้ยังไม่มี PIN บนเครื่อง (สมัครใหม่ / เครื่องใหม่ / ลืม PIN)
    // → เสนอขั้นตั้ง PIN ก่อนเข้าแอป ข้ามได้ด้วย "ไว้ทีหลัง"
    if (!ref.read(authControllerProvider).isPendingDeletion &&
        _accountHasPin != true) {
      setState(() => _pinSetupPhase = true);
      return;
    }
    await _finishAfterSignIn(isEn);
  }

  bool get _canSavePinSetup =>
      _newPinController.text.trim().length == 6 &&
      _confirmPinController.text.trim().length == 6;

  Future<void> _handleSavePinSetup(bool isEn) async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_canSavePinSetup) return;
    if (_newPinController.text.trim() != _confirmPinController.text.trim()) {
      setState(() => _pinSetupError = AuthL10n.pinSetupMismatchError(isEn));
      return;
    }
    final ok = await ref
        .read(authControllerProvider.notifier)
        .setPinForCurrentAccount(_newPinController.text.trim());
    if (!mounted) return;
    if (!ok) {
      setState(() => _pinSetupError = AuthL10n.pinSaveFailedError(isEn));
      return;
    }
    showToast(isEn ? 'PIN set successfully' : 'ตั้งรหัส PIN เรียบร้อยแล้ว');
    _goAfterAuth();
  }

  Future<void> _skipPinSetup(bool isEn) async {
    setState(() => _pinSetupPhase = false);
    await _finishAfterSignIn(isEn);
  }

  Future<void> _handleSocialLogin(AuthMethod method, bool isEn) async {
    if (!_validateCompliance(isEn)) return;
    final ok = await ref
        .read(authControllerProvider.notifier)
        .signInWithProvider(
          method: method,
          birthYear: _selectedBirthYear,
          guardianConsentGranted: _guardianConsent,
          displayName: _isRegisterMode ? _nameController.text.trim() : null,
        );
    if (ok && mounted) {
      await _finishAfterSignIn(isEn);
    }
  }

  Future<void> _handleGuestMode(bool isEn) async {
    await ref.read(authControllerProvider.notifier).continueAsGuest();
    if (mounted) {
      _goAfterAuth();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isEn = ref.watch(appLocaleProvider) == 'en';
    final species = ref.watch(petSpeciesConfigProvider);
    final challenge = authState.otpChallenge;

    // ล็อกอินอยู่แล้วไม่ควรเห็นหน้านี้ (เช่น กด deep link /login มาตรง ๆ)
    // รอให้อ่าน session จาก storage เสร็จก่อนค่อยตัดสินใจเด้งกลับปลายทาง
    // ยกเว้น session ค้างลบ (AUTH-05) — ต้องอยู่หน้านี้เพื่อให้ชีตกู้คืนแสดงได้
    if (authState.sessionResolved &&
        authState.isAuthenticated &&
        !authState.isPendingDeletion &&
        !_pinSetupPhase) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(_afterAuthTarget);
      });
      return const Scaffold(
        backgroundColor: AppColors.page,
        body: SizedBox.shrink(),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.page,
        body: GestureDetector(
          // แตะพื้นว่างนอกช่องกรอก → ปิดคีย์แพ็ด/เลิกโฟกัส
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    if (challenge != null)
                      _OtpTopBar(
                        title: AuthL10n.otpTitle(isEn),
                        backLabel: AuthL10n.backLabel(isEn),
                        onBack: () => ref
                            .read(authControllerProvider.notifier)
                            .clearOtpChallenge(),
                      )
                    else if (_pinSetupPhase)
                      _OtpTopBar(
                        title: AuthL10n.pinSetupTitle(isEn),
                        backLabel: AuthL10n.backLabel(isEn),
                        onBack: () => _skipPinSetup(isEn),
                      ),
                    Expanded(
                      child: ListView(
                        key: ValueKey(
                          challenge == null ? 'login-list' : 'otp-list',
                        ),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.fromLTRB(
                          20,
                          challenge == null ? 24 : 8,
                          20,
                          32,
                        ),
                        children: [
                          Center(
                            child: Image.asset(
                              'assets/brand/maew-logo.png',
                              width: 132,
                              height: 38,
                              semanticLabel: species.brandName(isEn),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            challenge != null
                                ? AuthL10n.otpTitle(isEn)
                                : (_pinSetupPhase
                                      ? AuthL10n.pinSetupTitle(isEn)
                                      : AuthL10n.headline(species, isEn)),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            challenge != null
                                ? AuthL10n.otpSubtitle(
                                    AuthRules.maskThaiPhone(
                                      challenge.phoneNumber,
                                    ),
                                    challenge.refCode,
                                    isEn,
                                  )
                                : (_pinSetupPhase
                                      ? AuthL10n.pinSetupSubtitle(isEn)
                                      : AuthL10n.subheadline(species, isEn)),
                            textAlign: TextAlign.center,
                            maxLines: challenge == null ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (_pinSetupPhase)
                            _buildPinSetupCard(authState: authState, isEn: isEn)
                          else if (challenge == null) ...[
                            _AuthModeTabs(
                              isRegisterMode: _isRegisterMode,
                              signInLabel: AuthL10n.tabSignIn(isEn),
                              registerLabel: AuthL10n.tabRegister(isEn),
                              onChanged: (register) => setState(() {
                                _isRegisterMode = register;
                                _useOtpInSignIn = false;
                                _validationError = null;
                              }),
                            ),
                            const SizedBox(height: 14),
                            _buildLoginMethodsCard(
                              authState: authState,
                              species: species,
                              isEn: isEn,
                            ),
                          ] else
                            _buildOtpVerifyCard(
                              authState: authState,
                              challenge: challenge,
                              isEn: isEn,
                            ),
                          const SizedBox(height: 18),
                          OutlinedButton.icon(
                            onPressed: authState.isSubmitting
                                ? null
                                : () => _handleGuestMode(isEn),
                            icon: const Icon(LucideIcons.compass, size: 17),
                            label: Text(
                              AuthL10n.guestBtn(isEn),
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: AppColors.card,
                              foregroundColor: AppColors.text,
                              side: const BorderSide(color: AppColors.line2),
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AuthL10n.guestHint(isEn),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
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
        ),
      ),
    );
  }

  Widget _buildLoginMethodsCard({
    required AuthState authState,
    required PetSpeciesConfig species,
    required bool isEn,
  }) {
    final eligibility = _ageEligibility;
    final isUnder13 =
        _isRegisterMode && eligibility == AgeEligibility.under13Blocked;
    final isMinor =
        _isRegisterMode &&
        eligibility == AgeEligibility.minorNeedsGuardianConsent;
    final canSocial = !authState.isSubmitting && _canProceedAuth;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isRegisterMode) ...[
            Text(
              AuthL10n.displayNameLabel(isEn),
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.text2,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: AuthL10n.displayNameHint(isEn),
                prefixIcon: const Icon(LucideIcons.user, size: 18),
                filled: true,
                fillColor: AppColors.soft,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              AuthL10n.birthYearLabel(isEn),
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.text2,
              ),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: () => _openBirthYearPicker(isEn),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.soft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.calendar,
                      size: 18,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isEn
                            ? '$_selectedBirthYear'
                            : '$_selectedBirthYear (พ.ศ. ${_selectedBirthYear + 543})',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    const Icon(
                      LucideIcons.chevronDown,
                      size: 18,
                      color: AppColors.muted,
                    ),
                  ],
                ),
              ),
            ),
            if (isUnder13) ...[
              const SizedBox(height: 12),
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
                  AuthL10n.birthYearUnder13Error(isEn),
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.logoutText,
                  ),
                ),
              ),
            ],
            if (isMinor) ...[
              const SizedBox(height: 10),
              _ConsentCheckboxRow(
                value: _guardianConsent,
                label: AuthL10n.guardianConsentLabel(isEn),
                onChanged: (val) => setState(() {
                  _guardianConsent = val;
                  _validationError = null;
                }),
              ),
            ],
            const SizedBox(height: 10),
            _PdpaConsentInlineRow(
              value: _pdpaAccepted,
              termsText: AuthL10n.pdpaTermsLabel(isEn),
              readMoreText: AuthL10n.pdpaReadMore(isEn),
              onChanged: (val) => setState(() {
                _pdpaAccepted = val;
                _validationError = null;
              }),
              onReadMore: () => _openPdpaDetailsSheet(species, isEn),
            ),
            if (_validationError != null && !isUnder13) ...[
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
                  _validationError!,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.logoutText,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
          Text(
            AuthL10n.phoneLabel(isEn),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneController,
            enabled: !isUnder13,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: AuthL10n.phoneHint(isEn),
              counterText: '',
              prefixIcon: const Icon(LucideIcons.smartphone, size: 18),
              filled: true,
              fillColor: AppColors.soft,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (!_isRegisterMode && !_useOtpInSignIn) ...[
            const SizedBox(height: 12),
            Text(
              AuthL10n.pinLabel(isEn),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: _obscurePin,
              maxLength: 6,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: '••••••',
                counterText: '',
                prefixIcon: const Icon(LucideIcons.lockKeyhole, size: 18),
                suffixIcon: IconButton(
                  tooltip: _obscurePin
                      ? AuthL10n.showPinLabel(isEn)
                      : AuthL10n.hidePinLabel(isEn),
                  icon: Icon(
                    _obscurePin ? LucideIcons.eye : LucideIcons.eyeOff,
                    size: 18,
                    color: AppColors.muted,
                  ),
                  onPressed: () => setState(() => _obscurePin = !_obscurePin),
                ),
                filled: true,
                fillColor: AppColors.soft,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (_validationError != null) ...[
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
                  _validationError!,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.logoutText,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: authState.isSubmitting || !_canSignInWithPin
                  ? null
                  : () => _handleSignInWithPin(isEn),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.ownerTeal,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.line2,
                disabledForegroundColor: AppColors.muted,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                AuthL10n.signInWithPinBtn(isEn),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: authState.isSubmitting
                  ? null
                  : () => _handleSocialLogin(AuthMethod.phoneOtp, isEn),
              icon: const Icon(LucideIcons.scanFace, size: 18),
              label: Text(
                AuthL10n.biometricBtn(isEn),
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.ownerTeal,
                side: const BorderSide(color: AppColors.ownerTealBorder),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            TextButton(
              onPressed: () => setState(() {
                _useOtpInSignIn = true;
                _validationError = null;
              }),
              child: Text(
                AuthL10n.switchDeviceOtpLink(isEn),
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            FilledButton(
              onPressed: authState.isSubmitting || !_canRequestOtp
                  ? null
                  : () => _handleRequestOtp(isEn),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.ownerTeal,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.line2,
                disabledForegroundColor: AppColors.muted,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                AuthL10n.requestOtpBtn(isEn),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (!_isRegisterMode && _useOtpInSignIn)
              TextButton(
                onPressed: () => setState(() {
                  _useOtpInSignIn = false;
                  _validationError = null;
                }),
                child: Text(
                  isEn ? 'Back to PIN sign-in' : 'กลับไปเข้าสู่ระบบด้วย PIN',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
              ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(child: Divider(color: AppColors.line)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  AuthL10n.orDivider(isEn),
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ),
              const Expanded(child: Divider(color: AppColors.line)),
            ],
          ),
          const SizedBox(height: 16),
          _SocialBrandButton(
            icon: const Icon(Icons.apple, size: 20, color: Colors.white),
            label: AuthL10n.appleBtn(isEn),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.line2,
            disabledForegroundColor: AppColors.muted,
            onPressed: canSocial
                ? () => _handleSocialLogin(AuthMethod.apple, isEn)
                : null,
          ),
          const SizedBox(height: 10),
          _SocialBrandButton(
            icon: Opacity(
              opacity: canSocial ? 1.0 : 0.45,
              child: const GoogleLogoIcon(size: 19),
            ),
            label: AuthL10n.googleBtn(isEn),
            backgroundColor: Colors.white,
            foregroundColor: AppColors.text,
            borderColor: canSocial ? AppColors.line2 : AppColors.line,
            disabledBackgroundColor: Colors.white,
            disabledForegroundColor: AppColors.muted,
            onPressed: canSocial
                ? () => _handleSocialLogin(AuthMethod.google, isEn)
                : null,
          ),
          const SizedBox(height: 10),
          _SocialBrandButton(
            icon: Opacity(
              opacity: canSocial ? 1.0 : 0.45,
              child: const LineLogoIcon(size: 20),
            ),
            label: AuthL10n.lineBtn(isEn),
            backgroundColor: AppColors.brandLine,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.line2,
            disabledForegroundColor: AppColors.muted,
            onPressed: canSocial
                ? () => _handleSocialLogin(AuthMethod.line, isEn)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildOtpVerifyCard({
    required AuthState authState,
    required OtpChallenge challenge,
    required bool isEn,
  }) {
    final now = DateTime.now();
    final resendCooldown = challenge.secondsUntilResend(now);
    final expirySeconds = challenge.secondsUntilExpiry(now);
    final unlockSeconds = challenge.secondsUntilUnlock(now);
    final expiryMin = (expirySeconds ~/ 60).toString().padLeft(2, '0');
    final expirySec = (expirySeconds % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isEn ? 'Enter 6-digit code' : 'กรอกรหัส 6 หลัก',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              Text(
                isEn
                    ? 'Expires in $expiryMin:$expirySec'
                    : 'หมดอายุใน $expiryMin:$expirySec',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: 10,
              color: AppColors.text,
            ),
            decoration: InputDecoration(
              hintText: '••••••',
              hintStyle: const TextStyle(
                fontSize: 24,
                letterSpacing: 10,
                color: AppColors.unchecked,
              ),
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              filled: true,
              fillColor: AppColors.soft,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (authState.errorCode != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.logoutBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.logoutBorder),
              ),
              child: Text(
                AuthL10n.otpErrorText(
                  authState.errorCode!,
                  challenge.remainingAttempts,
                  unlockSeconds,
                  isEn,
                ),
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.logoutText,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          FilledButton(
            onPressed: authState.isSubmitting || !_canVerifyOtp
                ? null
                : () => _handleVerifyOtp(isEn),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.ownerTeal,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.line2,
              disabledForegroundColor: AppColors.muted,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              AuthL10n.verifyOtpBtn(isEn),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: resendCooldown > 0 || authState.isSubmitting
                    ? null
                    : () => ref
                          .read(authControllerProvider.notifier)
                          .requestOtp(challenge.phoneNumber),
                child: Text(
                  AuthL10n.resendOtpBtn(resendCooldown, isEn),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                onPressed: () {
                  _otpController.clear();
                  ref.read(authControllerProvider.notifier).clearOtpChallenge();
                },
                child: Text(
                  AuthL10n.changePhoneBtn(isEn),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// การ์ดขั้นตั้ง PIN — แสดงหลังยืนยัน OTP ผ่านเมื่อบัญชียังไม่มี PIN
  /// บนเครื่องนี้ (สมัครใหม่ / เครื่องใหม่ / ลืม PIN) ข้ามได้ด้วย "ไว้ทีหลัง"
  Widget _buildPinSetupCard({
    required AuthState authState,
    required bool isEn,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AuthL10n.pinSetupNewLabel(isEn),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            label: AuthL10n.pinSetupNewLabel(isEn),
            child: TextField(
              controller: _newPinController,
              keyboardType: TextInputType.number,
              obscureText: _obscureNewPin,
              maxLength: 6,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                hintText: '••••••',
                counterText: '',
                prefixIcon: const Icon(LucideIcons.lockKeyhole, size: 18),
                suffixIcon: IconButton(
                  tooltip: _obscureNewPin
                      ? AuthL10n.showPinLabel(isEn)
                      : AuthL10n.hidePinLabel(isEn),
                  icon: Icon(
                    _obscureNewPin ? LucideIcons.eye : LucideIcons.eyeOff,
                    size: 18,
                    color: AppColors.muted,
                  ),
                  onPressed: () =>
                      setState(() => _obscureNewPin = !_obscureNewPin),
                ),
                filled: true,
                fillColor: AppColors.soft,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AuthL10n.pinSetupConfirmLabel(isEn),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            label: AuthL10n.pinSetupConfirmLabel(isEn),
            child: TextField(
              controller: _confirmPinController,
              keyboardType: TextInputType.number,
              obscureText: _obscureConfirmPin,
              maxLength: 6,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: '••••••',
                counterText: '',
                prefixIcon: const Icon(LucideIcons.lockKeyhole, size: 18),
                suffixIcon: IconButton(
                  tooltip: _obscureConfirmPin
                      ? AuthL10n.showPinLabel(isEn)
                      : AuthL10n.hidePinLabel(isEn),
                  icon: Icon(
                    _obscureConfirmPin ? LucideIcons.eye : LucideIcons.eyeOff,
                    size: 18,
                    color: AppColors.muted,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirmPin = !_obscureConfirmPin),
                ),
                filled: true,
                fillColor: AppColors.soft,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (_pinSetupError != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.logoutBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.logoutBorder),
              ),
              child: Text(
                _pinSetupError!,
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
            label: AuthL10n.pinSetupSaveBtn(isEn),
            child: FilledButton(
              onPressed: authState.isSubmitting || !_canSavePinSetup
                  ? null
                  : () => _handleSavePinSetup(isEn),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.ownerTeal,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.line2,
                disabledForegroundColor: AppColors.muted,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                AuthL10n.pinSetupSaveBtn(isEn),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Semantics(
            button: true,
            label: AuthL10n.pinSetupLaterBtn(isEn),
            child: TextButton(
              onPressed: authState.isSubmitting
                  ? null
                  : () => _skipPinSetup(isEn),
              child: Text(
                AuthL10n.pinSetupLaterBtn(isEn),
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthModeTabs extends StatelessWidget {
  const _AuthModeTabs({
    required this.isRegisterMode,
    required this.signInLabel,
    required this.registerLabel,
    required this.onChanged,
  });

  final bool isRegisterMode;
  final String signInLabel;
  final String registerLabel;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.soft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeTabButton(
              label: signInLabel,
              selected: !isRegisterMode,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _ModeTabButton(
              label: registerLabel,
              selected: isRegisterMode,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeTabButton extends StatelessWidget {
  const _ModeTabButton({
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.card : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? AppColors.text : AppColors.muted,
          ),
        ),
      ),
    );
  }
}

class _PdpaConsentInlineRow extends StatefulWidget {
  const _PdpaConsentInlineRow({
    required this.value,
    required this.termsText,
    required this.readMoreText,
    required this.onChanged,
    required this.onReadMore,
  });

  final bool value;
  final String termsText;
  final String readMoreText;
  final ValueChanged<bool> onChanged;
  final VoidCallback onReadMore;

  @override
  State<_PdpaConsentInlineRow> createState() => _PdpaConsentInlineRowState();
}

class _PdpaConsentInlineRowState extends State<_PdpaConsentInlineRow> {
  late final TapGestureRecognizer _readMoreRecognizer;

  @override
  void initState() {
    super.initState();
    _readMoreRecognizer = TapGestureRecognizer()..onTap = widget.onReadMore;
  }

  @override
  void dispose() {
    _readMoreRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: widget.value,
          activeColor: AppColors.ownerTeal,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          onChanged: (next) => widget.onChanged(next ?? false),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text.rich(
              TextSpan(
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.text,
                  height: 1.45,
                ),
                children: [
                  TextSpan(text: '${widget.termsText} '),
                  TextSpan(
                    text: widget.readMoreText,
                    recognizer: _readMoreRecognizer,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ownerTeal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PdpaDetailSection extends StatelessWidget {
  const _PdpaDetailSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.muted,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsentCheckboxRow extends StatelessWidget {
  const _ConsentCheckboxRow({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Checkbox(
              value: value,
              activeColor: AppColors.ownerTeal,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: (next) => onChanged(next ?? false),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 12.5, color: AppColors.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialBrandButton extends StatelessWidget {
  const _SocialBrandButton({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.disabledBackgroundColor,
    required this.disabledForegroundColor,
    this.borderColor,
    this.onPressed,
  });

  final Widget icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color disabledBackgroundColor;
  final Color disabledForegroundColor;
  final Color? borderColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final fg = enabled ? foregroundColor : disabledForegroundColor;
    final bg = enabled ? backgroundColor : disabledBackgroundColor;

    return Material(
      color: bg,
      shape: StadiumBorder(
        side: borderColor != null
            ? BorderSide(color: borderColor!)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onPressed,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          child: Center(
            child: SizedBox(
              width: 224,
              child: Row(
                children: [
                  SizedBox(width: 22, child: Center(child: icon)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: fg,
                      ),
                    ),
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

class _OtpTopBar extends StatelessWidget {
  const _OtpTopBar({
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
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 4),
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
                width: 40,
                height: 40,
                child: Icon(
                  LucideIcons.chevronLeft,
                  size: 22,
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
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}
