import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../domain/entities/my_cat_data.dart';
import 'sheet_chrome.dart';

const _ownerAvatarChoices = [
  'asset:assets/images/avatars/1494790108377-be9c29b29330.jpg',
  'asset:assets/images/avatars/1566616213894-2d4e1baee5d8.jpg',
  'asset:assets/images/avatars/1580489944761-15a19d654956.jpg',
  'asset:assets/images/avatars/1592194996308-7b43878e84a6.jpg',
  'asset:assets/images/avatars/1543852786-1cf6624b9987.jpg',
];

/// หน้า "แก้ไขโปรไฟล์" ของเจ้าของ (เต็มจอ Scaffold เพื่อให้พิมพ์บน iOS ได้ลื่นไม่ค้าง)
Future<void> showOwnerEditSheet(
  BuildContext context, {
  required OwnerProfile owner,
  required Future<bool> Function(OwnerProfile updated) onSave,
  bool isEn = false,
}) {
  return Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _OwnerEditPage(owner: owner, onSave: onSave, isEn: isEn),
    ),
  );
}

class _OwnerEditPage extends StatefulWidget {
  const _OwnerEditPage({
    required this.owner,
    required this.onSave,
    this.isEn = false,
  });

  final OwnerProfile owner;
  final Future<bool> Function(OwnerProfile updated) onSave;
  final bool isEn;

  @override
  State<_OwnerEditPage> createState() => _OwnerEditPageState();
}

class _OwnerEditPageState extends State<_OwnerEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _districtCtrl;
  late final TextEditingController _accountNoCtrl;
  late final TextEditingController _accountNameCtrl;
  late final TextEditingController _treatAddressCtrl;

  late String _avatar;
  late OwnerPrivacySettings _privacy;
  late OwnerNotificationSettings _notifications;
  late DonationMethod _donationMethod;
  bool _showTreatAddress = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final o = widget.owner;
    _nameCtrl = TextEditingController(text: o.displayName);
    _bioCtrl = TextEditingController(text: o.bio);
    _districtCtrl = TextEditingController(text: o.district);
    _accountNoCtrl = TextEditingController(
      text: o.donationAccount.accountNumber,
    );
    _accountNameCtrl = TextEditingController(
      text: o.donationAccount.accountName,
    );
    _treatAddressCtrl = TextEditingController(text: o.treatAddress);
    _avatar = o.avatarSource;
    _privacy = o.privacy;
    _notifications = o.notifications;
    _donationMethod = o.donationAccount.method;
    _showTreatAddress = o.treatAddress.isNotEmpty;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _districtCtrl.dispose();
    _accountNoCtrl.dispose();
    _accountNameCtrl.dispose();
    _treatAddressCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final next = widget.owner.copyWith(
      avatarSource: _avatar,
      displayName: _nameCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
      district: _districtCtrl.text.trim(),
      privacy: _privacy,
      notifications: _notifications,
      donationAccount: OwnerDonationAccount(
        method: _donationMethod,
        accountNumber: _accountNoCtrl.text.trim(),
        accountName: _accountNameCtrl.text.trim(),
      ),
      treatAddress: _treatAddressCtrl.text.trim(),
    );
    final ok = await widget.onSave(next);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEn = widget.isEn;
    return Scaffold(
      backgroundColor: AppColors.card,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        leading: Semantics(
          button: true,
          label: isEn ? 'Close' : 'ปิด',
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(LucideIcons.x, size: 20),
          ),
        ),
        title: Text(
          isEn ? 'Edit profile' : 'แก้ไขโปรไฟล์',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saving ? null : _submit,
            child: Text(
              isEn ? 'Save' : 'บันทึก',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _saving ? AppColors.muted : AppColors.ownerTeal,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEn ? 'Profile photo' : 'รูปโปรไฟล์',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 58,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _ownerAvatarChoices.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (_, i) {
                        final src = _ownerAvatarChoices[i];
                        final selected = src == _avatar;
                        return Semantics(
                          button: true,
                          selected: selected,
                          label: isEn
                              ? 'Select profile photo ${i + 1}'
                              : 'เลือกรูปโปรไฟล์ที่ ${i + 1}',
                          child: InkWell(
                            onTap: () => setState(() => _avatar = src),
                            customBorder: const CircleBorder(),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected
                                      ? AppColors.ownerTealRing
                                      : AppColors.line,
                                  width: selected ? 2.5 : 1,
                                ),
                              ),
                              child: AppAvatar(
                                source: src,
                                bg: widget.owner.avatarBg,
                                size: 50,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  _OwnerTextField(
                    label: isEn ? 'Display name *' : 'ชื่อที่แสดง *',
                    controller: _nameCtrl,
                    validator: (v) {
                      final text = v?.trim() ?? '';
                      if (text.isEmpty) {
                        return isEn
                            ? 'Please enter display name'
                            : 'กรุณาระบุชื่อที่แสดง';
                      }
                      if (text.length > 40) {
                        return isEn
                            ? 'Display name up to 40 characters'
                            : 'ชื่อยาวได้ไม่เกิน 40 ตัวอักษร';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _bioCtrl,
                    builder: (_, val, _) => _OwnerTextField(
                      label: isEn
                          ? 'Bio (${val.text.length}/80)'
                          : 'แนะนำตัว (${val.text.length}/80)',
                      controller: _bioCtrl,
                      maxLength: 80,
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _OwnerTextField(
                    label: isEn ? 'Neighborhood' : 'ย่านที่อยู่',
                    controller: _districtCtrl,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isEn ? 'Privacy' : 'ความเป็นส่วนตัว',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedChoiceRow<ProfileVisibility>(
                    options: [
                      (
                        value: ProfileVisibility.everyone,
                        label: isEn ? 'Everyone' : 'ทุกคน',
                      ),
                      (
                        value: ProfileVisibility.followersOnly,
                        label: isEn ? 'Followers only' : 'เฉพาะผู้ติดตาม',
                      ),
                    ],
                    selected: _privacy.visibility,
                    onChanged: (v) => setState(
                      () => _privacy = _privacy.copyWith(visibility: v),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _SwitchBox(
                    children: [
                      SwitchListTile.adaptive(
                        title: Text(isEn ? 'Show my cats' : 'แสดงแมวของฉัน'),
                        value: _privacy.showMyCats,
                        activeTrackColor: AppColors.ownerTealRing,
                        onChanged: (v) => setState(
                          () => _privacy = _privacy.copyWith(showMyCats: v),
                        ),
                      ),
                      const Divider(height: 1, color: AppColors.line),
                      SwitchListTile.adaptive(
                        title: Text(
                          isEn ? 'Show neighborhood' : 'แสดงย่านที่อยู่',
                        ),
                        value: _privacy.showDistrict,
                        activeTrackColor: AppColors.ownerTealRing,
                        onChanged: (v) => setState(
                          () => _privacy = _privacy.copyWith(showDistrict: v),
                        ),
                      ),
                      const Divider(height: 1, color: AppColors.line),
                      SwitchListTile.adaptive(
                        title: Text(
                          isEn ? 'Allow messages' : 'รับข้อความจากคนอื่น',
                        ),
                        value: _privacy.allowMessages,
                        activeTrackColor: AppColors.ownerTealRing,
                        onChanged: (v) => setState(
                          () => _privacy = _privacy.copyWith(allowMessages: v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isEn ? 'Donation account' : 'บัญชีรับเงินบริจาค',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedChoiceRow<DonationMethod>(
                    options: [
                      (
                        value: DonationMethod.promptPay,
                        label: isEn ? 'PromptPay' : 'พร้อมเพย์',
                      ),
                      (
                        value: DonationMethod.bankAccount,
                        label: isEn ? 'Bank account' : 'บัญชีธนาคาร',
                      ),
                    ],
                    selected: _donationMethod,
                    onChanged: (v) => setState(() => _donationMethod = v),
                  ),
                  const SizedBox(height: 10),
                  _OwnerTextField(
                    label: _donationMethod == DonationMethod.promptPay
                        ? (isEn
                              ? 'PromptPay ID / Account no.'
                              : 'เบอร์พร้อมเพย์ / เลขบัญชี')
                        : (isEn ? 'Bank account number' : 'เลขที่บัญชีธนาคาร'),
                    controller: _accountNoCtrl,
                  ),
                  const SizedBox(height: 10),
                  _OwnerTextField(
                    label: isEn ? 'Account name' : 'ชื่อบัญชี',
                    controller: _accountNameCtrl,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isEn ? 'Cat treat shipping address' : 'ที่อยู่รับขนมแมว',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Material(
                    color: AppColors.page,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: AppColors.line),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        ListTile(
                          onTap: () => setState(
                            () => _showTreatAddress = !_showTreatAddress,
                          ),
                          leading: const Icon(
                            LucideIcons.lock,
                            size: 18,
                            color: AppColors.ink,
                          ),
                          title: Text(
                            _treatAddressCtrl.text.trim().isEmpty
                                ? (isEn
                                      ? 'No address set · add so others can send treats'
                                      : 'ยังไม่ได้ตั้งที่อยู่ เพิ่มเพื่อให้คนอื่นเลี้ยงขนมแมวของคุณได้')
                                : (isEn
                                      ? 'Address saved (hidden from senders)'
                                      : 'ตั้งค่าที่อยู่แล้ว (ซ่อนจากผู้ส่งขนม)'),
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text,
                            ),
                          ),
                          trailing: Icon(
                            _showTreatAddress
                                ? LucideIcons.chevronUp
                                : LucideIcons.chevronDown,
                            size: 18,
                          ),
                        ),
                        if (_showTreatAddress)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _treatAddressCtrl,
                                  maxLines: 3,
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  smartDashesType: SmartDashesType.disabled,
                                  smartQuotesType: SmartQuotesType.disabled,
                                  decoration: InputDecoration(
                                    hintText: isEn
                                        ? 'Enter delivery address (kept private)'
                                        : 'กรอกที่อยู่จัดส่งขนมแมว (เก็บเป็นความลับ)',
                                    filled: true,
                                    fillColor: AppColors.card,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppColors.line2,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  isEn
                                      ? 'Only you and shipping couriers see this · senders never see your real address'
                                      : 'ข้อมูลนี้เห็นเฉพาะคุณและระบบจัดส่ง · คนที่เลี้ยงขนมจะไม่เห็นที่อยู่จริงของคุณ',
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
                  const SizedBox(height: 16),
                  Text(
                    isEn ? 'Verification' : 'ยืนยันตัวตน',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _SwitchBox(
                    children: [
                      ListTile(
                        leading: const Icon(
                          LucideIcons.checkCircle2,
                          color: AppColors.statusSafe,
                          size: 18,
                        ),
                        title: Text(isEn ? 'Phone number' : 'เบอร์โทรศัพท์'),
                        trailing: Text(
                          widget.owner.isPhoneVerified
                              ? (isEn ? 'OTP verified' : 'ยืนยันด้วย OTP แล้ว')
                              : (isEn ? 'Not verified' : 'ยังไม่ยืนยัน'),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.statusSafe,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Divider(height: 1, color: AppColors.line),
                      ListTile(
                        leading: const Icon(
                          LucideIcons.checkCircle2,
                          color: AppColors.statusSafe,
                          size: 18,
                        ),
                        title: Text(isEn ? 'National ID card' : 'บัตรประชาชน'),
                        trailing: Text(
                          widget.owner.isIdVerified
                              ? (isEn ? 'Verified' : 'ยืนยันแล้ว')
                              : (isEn ? 'Not verified' : 'ยังไม่ยืนยัน'),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.statusSafe,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isEn ? 'Notifications' : 'การแจ้งเตือน',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _SwitchBox(
                    children: [
                      SwitchListTile.adaptive(
                        title: Text(
                          isEn
                              ? 'Lost / found cats nearby'
                              : 'แมวหาย/พบแมวใกล้ฉัน',
                        ),
                        value: _notifications.nearbyAlerts,
                        activeTrackColor: AppColors.ownerTealRing,
                        onChanged: (v) => setState(
                          () => _notifications = _notifications.copyWith(
                            nearbyAlerts: v,
                          ),
                        ),
                      ),
                      const Divider(height: 1, color: AppColors.line),
                      SwitchListTile.adaptive(
                        title: Text(
                          isEn ? 'Cat care reminders' : 'เตือนการดูแลแมว',
                        ),
                        value: _notifications.careReminders,
                        activeTrackColor: AppColors.ownerTealRing,
                        onChanged: (v) => setState(
                          () => _notifications = _notifications.copyWith(
                            careReminders: v,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      isEn
                          ? '@${widget.owner.handle} · Primary handle cannot be changed'
                          : '@${widget.owner.handle} · บัญชีหลักเปลี่ยนชื่อผู้ใช้ไม่ได้',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
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

class _OwnerTextField extends StatelessWidget {
  const _OwnerTextField({
    required this.label,
    required this.controller,
    this.validator,
    this.maxLength,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;
  final int? maxLength;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLength: maxLength,
          maxLines: maxLines,
          autocorrect: false,
          enableSuggestions: false,
          smartDashesType: SmartDashesType.disabled,
          smartQuotesType: SmartQuotesType.disabled,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.page,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.line2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.line2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.ownerTealRing,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SwitchBox extends StatelessWidget {
  const _SwitchBox({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.page,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}
