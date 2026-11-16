import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/config/app_locale.dart';
import '../../../../core/config/pet_species_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/toast_pill.dart';
import '../../domain/entities/auth_data.dart';
import '../../domain/usecases/auth_rules.dart';
import '../providers/auth_controller.dart';
import '../widgets/auth_l10n.dart';

/// หน้าเข้าสู่ระบบและ Guest Mode (/login — AUTH-01..04, PDPA-03)
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> with ToastMixin {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  int _selectedBirthYear = 1995;
  bool _guardianConsent = false;
  bool _pdpaAccepted = true;
  String? _validationError;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    disposeToast();
    super.dispose();
  }

  List<int> _birthYearOptions() {
    final currentYear = DateTime.now().year;
    return List<int>.generate(70, (index) => currentYear - 8 - index);
  }

  bool _validateCompliance(bool isEn) {
    if (!_pdpaAccepted) {
      setState(() => _validationError = AuthL10n.pdpaRequiredError(isEn));
      return false;
    }
    final eligibility = AuthRules.evaluateAge(
      birthYear: _selectedBirthYear,
      currentYear: DateTime.now().year,
    );
    if (eligibility == AgeEligibility.under13Blocked) {
      setState(() => _validationError = AuthL10n.birthYearUnder13Error(isEn));
      return false;
    }
    if (eligibility == AgeEligibility.minorNeedsGuardianConsent &&
        !_guardianConsent) {
      setState(
        () => _validationError = AuthL10n.guardianConsentRequiredError(isEn),
      );
      return false;
    }
    setState(() => _validationError = null);
    return true;
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
    if (ok && mounted) {
      showToast(
        isEn ? 'OTP sent (Mock: 123456)' : 'ส่งรหัส OTP แล้ว (ทดสอบ: 123456)',
      );
    }
  }

  Future<void> _handleVerifyOtp(bool isEn) async {
    if (!_validateCompliance(isEn)) return;
    final code = _otpController.text.trim();
    final ok = await ref
        .read(authControllerProvider.notifier)
        .verifyOtp(
          code: code,
          birthYear: _selectedBirthYear,
          guardianConsentGranted: _guardianConsent,
        );
    if (ok && mounted) {
      showToast(isEn ? 'Signed in successfully' : 'เข้าสู่ระบบสำเร็จแล้ว');
      context.go('/');
    }
  }

  Future<void> _handleSocialLogin(AuthMethod method, bool isEn) async {
    if (!_validateCompliance(isEn)) return;
    final ok = await ref
        .read(authControllerProvider.notifier)
        .signInWithProvider(
          method: method,
          birthYear: _selectedBirthYear,
          guardianConsentGranted: _guardianConsent,
        );
    if (ok && mounted) {
      showToast(isEn ? 'Signed in successfully' : 'เข้าสู่ระบบสำเร็จแล้ว');
      context.go('/');
    }
  }

  Future<void> _handleGuestMode(bool isEn) async {
    await ref.read(authControllerProvider.notifier).continueAsGuest();
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isEn = ref.watch(appLocaleProvider) == 'en';
    final species = ref.watch(petSpeciesConfigProvider);
    final challenge = authState.otpChallenge;

    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _TopBar(
                  title: challenge == null
                      ? AuthL10n.pageTitle(isEn)
                      : AuthL10n.otpTitle(isEn),
                  backLabel: AuthL10n.backLabel(isEn),
                  onBack: () {
                    if (challenge != null) {
                      ref
                          .read(authControllerProvider.notifier)
                          .clearOtpChallenge();
                    } else if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/');
                    }
                  },
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
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
                        challenge == null
                            ? AuthL10n.headline(species, isEn)
                            : AuthL10n.otpTitle(isEn),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        challenge == null
                            ? AuthL10n.subheadline(species, isEn)
                            : AuthL10n.otpSubtitle(
                                AuthRules.maskThaiPhone(challenge.phoneNumber),
                                challenge.refCode,
                                isEn,
                              ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AppColors.muted,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (challenge == null)
                        _buildLoginMethodsCard(
                          authState: authState,
                          isEn: isEn,
                        )
                      else
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
                          height: 1.35,
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
    );
  }

  Widget _buildLoginMethodsCard({
    required AuthState authState,
    required bool isEn,
  }) {
    final eligibility = AuthRules.evaluateAge(
      birthYear: _selectedBirthYear,
      currentYear: DateTime.now().year,
    );
    final isMinor = eligibility == AgeEligibility.minorNeedsGuardianConsent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AuthL10n.birthYearLabel(isEn),
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.text2,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<int>(
            initialValue: _selectedBirthYear,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.soft,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            items: _birthYearOptions()
                .map(
                  (y) => DropdownMenuItem(
                    value: y,
                    child: Text(
                      isEn ? '$y' : '$y (พ.ศ. ${y + 543})',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                )
                .toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedBirthYear = val;
                  _validationError = null;
                });
              }
            },
          ),
          if (isMinor) ...[
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _guardianConsent,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.ownerTeal,
              title: Text(
                AuthL10n.guardianConsentLabel(isEn),
                style: const TextStyle(fontSize: 12.5, color: AppColors.text),
              ),
              onChanged: (val) =>
                  setState(() => _guardianConsent = val ?? false),
            ),
          ],
          CheckboxListTile(
            value: _pdpaAccepted,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppColors.ownerTeal,
            title: Text(
              AuthL10n.pdpaTermsLabel(isEn),
              style: const TextStyle(fontSize: 12.5, color: AppColors.text),
            ),
            onChanged: (val) => setState(() => _pdpaAccepted = val ?? false),
          ),
          if (_validationError != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
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
            const SizedBox(height: 10),
          ],
          Text(
            AuthL10n.phoneLabel(isEn),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: AuthL10n.phoneHint(isEn),
              prefixIcon: const Icon(LucideIcons.smartphone, size: 18),
              filled: true,
              fillColor: AppColors.soft,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: authState.isSubmitting
                ? null
                : () => _handleRequestOtp(isEn),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.ownerTeal,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              AuthL10n.requestOtpBtn(isEn),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(child: Divider(color: AppColors.line)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  AuthL10n.orDivider(isEn),
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ),
              const Expanded(child: Divider(color: AppColors.line)),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: authState.isSubmitting
                ? null
                : () => _handleSocialLogin(AuthMethod.apple, isEn),
            icon: const Icon(Icons.apple, size: 20),
            label: Text(
              AuthL10n.appleBtn(isEn),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: authState.isSubmitting
                ? null
                : () => _handleSocialLogin(AuthMethod.google, isEn),
            icon: const Text(
              'G',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF4285F4),
              ),
            ),
            label: Text(
              AuthL10n.googleBtn(isEn),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.text,
              side: const BorderSide(color: AppColors.line2),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: authState.isSubmitting
                ? null
                : () => _handleSocialLogin(AuthMethod.line, isEn),
            icon: const Icon(LucideIcons.messageCircle, size: 18),
            label: Text(
              AuthL10n.lineBtn(isEn),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandLine,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.ownerPillBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    AuthL10n.otpMockHelper(isEn),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ownerTeal,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _otpController.text = AuthRules.mockValidOtp;
                  },
                  child: Text(
                    AuthL10n.fillMockOtp(isEn),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 6,
            ),
            decoration: InputDecoration(
              hintText: AuthL10n.otpInputHint(isEn),
              counterText: '$expiryMin:$expirySec',
              filled: true,
              fillColor: AppColors.soft,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (authState.errorCode != null) ...[
            const SizedBox(height: 6),
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
          const SizedBox(height: 12),
          FilledButton(
            onPressed: authState.isSubmitting
                ? null
                : () => _handleVerifyOtp(isEn),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.ownerTeal,
              foregroundColor: Colors.white,
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
                  ref
                      .read(authControllerProvider.notifier)
                      .clearOtpChallenge();
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
}

class _TopBar extends StatelessWidget {
  const _TopBar({
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
