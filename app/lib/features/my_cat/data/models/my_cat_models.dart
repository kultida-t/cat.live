import '../../domain/entities/my_cat_data.dart';

/// โมเดล JSON ของข้อมูลหน้าแมวและฉัน (รองรับสคีมา Backend Phase 1)
class MyCatBundleModel {
  const MyCatBundleModel({required this.owner, required this.cats});

  factory MyCatBundleModel.fromJson(Map<String, dynamic> json) {
    return MyCatBundleModel(
      owner: OwnerProfileModel.fromJson(
        Map<String, dynamic>.from(json['owner'] as Map),
      ),
      cats: (json['cats'] as List)
          .map(
            (e) =>
                CatProfileModel.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
    );
  }

  final OwnerProfileModel owner;
  final List<CatProfileModel> cats;

  MyCatBundle toEntity() => MyCatBundle(
    owner: owner.toEntity(),
    cats: cats.map((e) => e.toEntity()).toList(),
  );
}

class OwnerProfileModel {
  const OwnerProfileModel({required this.entity});

  factory OwnerProfileModel.fromJson(Map<String, dynamic> json) {
    final priv = Map<String, dynamic>.from(
      (json['user_private'] as Map?) ?? const {},
    );
    final privacyJson = Map<String, dynamic>.from(
      (json['privacy'] as Map?) ?? const {},
    );
    final notifJson = Map<String, dynamic>.from(
      (json['notifications'] as Map?) ?? const {},
    );
    final donationJson = Map<String, dynamic>.from(
      (priv['donation_account'] as Map?) ?? const {},
    );

    return OwnerProfileModel(
      entity: OwnerProfile(
        id: json['id'] as String? ?? 'me',
        handle: json['username'] as String? ?? 'jutamas.lk',
        displayName: json['display_name'] as String? ?? '',
        bio: json['bio'] as String? ?? '',
        district: json['district'] as String? ?? '',
        memberSince: json['member_since'] as String? ?? '',
        avatarSource: json['avatar_url'] as String? ?? '',
        avatarBg: json['avatar_bg'] as int? ?? 0xFFFFE89A,
        followerCount: json['follower_count'] as int? ?? 0,
        helpedCount: json['helped_count'] as int? ?? 0,
        unreadMessagesCount: json['unread_messages_count'] as int? ?? 0,
        isPhoneVerified: priv['phone_verified'] as bool? ?? false,
        isIdVerified: priv['id_verified'] as bool? ?? false,
        donationAccount: OwnerDonationAccount(
          method: donationJson['method'] == 'bank'
              ? DonationMethod.bankAccount
              : DonationMethod.promptPay,
          accountNumber: donationJson['account_number'] as String? ?? '',
          accountName: donationJson['account_name'] as String? ?? '',
        ),
        treatAddress: priv['treat_address'] as String? ?? '',
        privacy: OwnerPrivacySettings(
          visibility: privacyJson['visibility'] == 'followers'
              ? ProfileVisibility.followersOnly
              : ProfileVisibility.everyone,
          showMyCats: privacyJson['show_my_cats'] as bool? ?? true,
          showDistrict: privacyJson['show_district'] as bool? ?? true,
          allowMessages: privacyJson['allow_messages'] as bool? ?? true,
        ),
        notifications: OwnerNotificationSettings(
          pushEnabled: notifJson['push_enabled'] as bool? ?? true,
          quietHoursEnabled: notifJson['quiet_hours_enabled'] as bool? ?? true,
          nearbyAlerts: notifJson['nearby_alerts'] as bool? ?? true,
          careReminders: notifJson['care_reminders'] as bool? ?? true,
          locale: json['locale'] as String? ?? 'th',
        ),
      ),
    );
  }

  final OwnerProfile entity;

  OwnerProfile toEntity() => entity;

  static Map<String, dynamic> toJson(OwnerProfile o) => {
    'id': o.id,
    'username': o.handle,
    'display_name': o.displayName,
    'bio': o.bio,
    'district': o.district,
    'member_since': o.memberSince,
    'avatar_url': o.avatarSource,
    'avatar_bg': o.avatarBg,
    'follower_count': o.followerCount,
    'helped_count': o.helpedCount,
    'unread_messages_count': o.unreadMessagesCount,
    'locale': o.notifications.locale,
    'user_private': {
      'phone_verified': o.isPhoneVerified,
      'id_verified': o.isIdVerified,
      'treat_address': o.treatAddress,
      'donation_account': {
        'method': o.donationAccount.method == DonationMethod.bankAccount
            ? 'bank'
            : 'promptpay',
        'account_number': o.donationAccount.accountNumber,
        'account_name': o.donationAccount.accountName,
      },
    },
    'privacy': {
      'visibility': o.privacy.visibility == ProfileVisibility.followersOnly
          ? 'followers'
          : 'everyone',
      'show_my_cats': o.privacy.showMyCats,
      'show_district': o.privacy.showDistrict,
      'allow_messages': o.privacy.allowMessages,
    },
    'notifications': {
      'push_enabled': o.notifications.pushEnabled,
      'quiet_hours_enabled': o.notifications.quietHoursEnabled,
      'nearby_alerts': o.notifications.nearbyAlerts,
      'care_reminders': o.notifications.careReminders,
    },
  };
}

class CatProfileModel {
  const CatProfileModel({required this.entity});

  factory CatProfileModel.fromJson(Map<String, dynamic> json) {
    final photos = ((json['photos'] as List?) ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .map(
          (p) => CatPhotoItem(
            id: p['id'] as String,
            imageSource: p['image_url'] as String,
            caption: p['caption'] as String? ?? '',
            relativeTime: p['relative_time'] as String? ?? 'เมื่อสักครู่',
            likeCount: p['like_count'] as int? ?? 0,
            commentCount: p['comment_count'] as int? ?? 0,
            repostCount: p['repost_count'] as int? ?? 0,
            shareCount: p['share_count'] as int? ?? 0,
            isLiked: p['is_liked'] as bool? ?? false,
            isReposted: p['is_reposted'] as bool? ?? false,
            isSaved: p['is_saved'] as bool? ?? false,
          ),
        )
        .toList();

    final careTasks = ((json['care_tasks'] as List?) ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .map(
          (t) => CareTaskItem(
            id: t['id'] as String,
            title: t['title'] as String,
            subtitle: t['subtitle'] as String? ?? '',
            isDone: t['is_done'] as bool? ?? false,
          ),
        )
        .toList();

    final highlights = ((json['health_highlights'] as List?) ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .map(
          (h) => CatHealthHighlight(
            id: h['id'] as String,
            title: h['title'] as String,
            dateLabel: h['date_label'] as String? ?? '',
            isAlert: h['is_alert'] as bool? ?? false,
          ),
        )
        .toList();

    final caregivers = ((json['caregivers'] as List?) ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .map(
          (c) => CatCaregiver(
            id: c['id'] as String,
            name: c['name'] as String,
            roleLabel: c['role_label'] as String,
            avatarSource: c['avatar_url'] as String,
            avatarBg: c['avatar_bg'] as int? ?? 0xFFFFF1E6,
          ),
        )
        .toList();

    return CatProfileModel(
      entity: CatProfile(
        id: json['id'] as String,
        publicId: json['public_id'] as String,
        name: json['name'] as String,
        breed: json['breed'] as String? ?? '',
        gender: json['sex'] == 'male' ? CatGender.male : CatGender.female,
        neutered: json['neutered'] as bool? ?? false,
        ageLabel: json['age_label'] as String? ?? '',
        weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 0.0,
        recordCount: json['record_count'] as int? ?? 0,
        adoptedYear: json['adopted_year'] as int? ?? 2024,
        avatarSource: json['avatar_url'] as String? ?? '',
        avatarBg: json['avatar_bg'] as int? ?? 0xFFFFF1E6,
        healthBadge: _parseHealthBadge(json['health_badge'] as String?),
        trackerStatus: _parseTrackerStatus(json['tracker_status'] as String?),
        trackerLabel: json['tracker_label'] as String? ?? 'ยังไม่มีปลอกคอ',
        photos: photos,
        careTasks: careTasks,
        healthReminderTitle: json['health_reminder_title'] as String? ?? '',
        healthReminderSubtitle:
            json['health_reminder_subtitle'] as String? ?? '',
        healthHighlights: highlights,
        caregivers: caregivers,
      ),
    );
  }

  final CatProfile entity;

  CatProfile toEntity() => entity;

  static CatHealthBadge _parseHealthBadge(String? raw) {
    return switch (raw) {
      'good' => CatHealthBadge.good,
      'poor' => CatHealthBadge.poor,
      _ => CatHealthBadge.watch,
    };
  }

  static CatTrackerStatus _parseTrackerStatus(String? raw) {
    return switch (raw) {
      'safe' => CatTrackerStatus.safe,
      'out_of_zone' => CatTrackerStatus.outOfZone,
      _ => CatTrackerStatus.noCollar,
    };
  }

  static Map<String, dynamic> toJson(CatProfile c) => {
    'id': c.id,
    'public_id': c.publicId,
    'name': c.name,
    'breed': c.breed,
    'sex': c.gender == CatGender.male ? 'male' : 'female',
    'neutered': c.neutered,
    'age_label': c.ageLabel,
    'weight_kg': c.weightKg,
    'record_count': c.recordCount,
    'adopted_year': c.adoptedYear,
    'avatar_url': c.avatarSource,
    'avatar_bg': c.avatarBg,
    'health_badge': switch (c.healthBadge) {
      CatHealthBadge.good => 'good',
      CatHealthBadge.watch => 'watch',
      CatHealthBadge.poor => 'poor',
    },
    'tracker_status': switch (c.trackerStatus) {
      CatTrackerStatus.safe => 'safe',
      CatTrackerStatus.outOfZone => 'out_of_zone',
      CatTrackerStatus.noCollar => 'no_collar',
    },
    'tracker_label': c.trackerLabel,
  };
}
