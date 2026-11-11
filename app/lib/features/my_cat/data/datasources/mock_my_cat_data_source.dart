import '../../domain/entities/my_cat_data.dart';
import '../models/my_cat_models.dart';
import 'my_cat_remote_data_source.dart';

/// ข้อมูลจำลองหน้าแมวและฉัน — ตรงตามหน้าเว็บจริง www.แมว.live
class MockMyCatDataSource implements MyCatRemoteDataSource {
  MockMyCatDataSource({this.delay = const Duration(milliseconds: 180)})
    : _bundle = _initialBundle();

  final Duration delay;
  MyCatBundle _bundle;
  int _nextCatSeq = 189;
  int _nextPhotoSeq = 100;

  static MyCatBundle _initialBundle() {
    const sharedCareTasks = [
      CareTaskItem(
        id: 'care-food',
        title: 'อาหาร',
        subtitle: 'เสร็จแล้ว · แม่ · 07:30',
        isDone: true,
      ),
      CareTaskItem(
        id: 'care-water',
        title: 'น้ำ',
        subtitle: 'เสร็จแล้ว · พี่สาว · 08:10',
        isDone: true,
      ),
      CareTaskItem(
        id: 'care-litter',
        title: 'ทราย',
        subtitle: 'ตักทราย · ครั้งล่าสุดเมื่อวาน 21:00',
        isDone: false,
      ),
      CareTaskItem(
        id: 'care-meds',
        title: 'ยา',
        subtitle: 'ยาหยอดตา 1 หยด · 20:00',
        isDone: false,
      ),
      CareTaskItem(
        id: 'care-weight',
        title: 'น้ำหนัก',
        subtitle: 'ชั่งสัปดาห์ละครั้ง · ครั้งล่าสุด 4.1 กก.',
        isDone: false,
      ),
    ];

    const sharedHighlights = [
      CatHealthHighlight(
        id: 'h-1',
        title: 'วัคซีนรวม (เข็มกระตุ้น)',
        dateLabel: 'ครบกำหนด 7 พ.ย. 2569',
        isAlert: true,
      ),
      CatHealthHighlight(
        id: 'h-2',
        title: 'อาเจียน 2 ครั้ง · บันทึกจาก Cat AI',
        dateLabel: '26 ต.ค. 2569',
      ),
      CatHealthHighlight(
        id: 'h-3',
        title: 'ถ่ายพยาธิ',
        dateLabel: '2 ต.ค. 2569',
      ),
      CatHealthHighlight(
        id: 'h-4',
        title: 'ตรวจสุขภาพประจำปี',
        dateLabel: '15 ส.ค. 2569',
      ),
    ];

    const sharedCaregivers = [
      CatCaregiver(
        id: 'cg-mom',
        name: 'แม่',
        roleLabel: 'ผู้ดูแลหลัก',
        avatarSource:
            'asset:assets/images/avatars/1566616213894-2d4e1baee5d8.jpg',
        avatarBg: 0xFFFCE7D6,
      ),
      CatCaregiver(
        id: 'cg-sis',
        name: 'พี่สาว',
        roleLabel: 'ผู้ดูแล',
        avatarSource:
            'asset:assets/images/avatars/1580489944761-15a19d654956.jpg',
        avatarBg: 0xFFFFEEF3,
      ),
      CatCaregiver(
        id: 'cg-me',
        name: 'ฉัน',
        roleLabel: 'เจ้าของบัญชี',
        avatarSource:
            'asset:assets/images/avatars/1494790108377-be9c29b29330.jpg',
        avatarBg: 0xFFFFE89A,
      ),
    ];

    const maliPhotos = [
      CatPhotoItem(
        id: 'mali-p1',
        imageSource: 'asset:assets/images/hero/mali.jpg',
        caption: 'มะลินั่งรับลมเช้าที่ระเบียง วันนี้อารมณ์ดีเป็นพิเศษ',
        relativeTime: '2 วันที่แล้ว',
        likeCount: 48,
        commentCount: 5,
        shareCount: 2,
      ),
      CatPhotoItem(
        id: 'mali-p2',
        imageSource: 'asset:assets/images/my_cat/mali-2.jpg',
        caption: 'ช่วงบ่ายขดตัวบนเบาะอุ่น ๆ ไม่ยอมลุกเลย',
        relativeTime: '5 วันที่แล้ว',
        likeCount: 63,
        commentCount: 9,
        shareCount: 3,
      ),
      CatPhotoItem(
        id: 'mali-p3',
        imageSource: 'asset:assets/images/my_cat/mali-3.jpg',
        caption: 'รอแม่เทขนมเลียหลังกลับจากหาหมอ',
        relativeTime: '1 สัปดาห์ที่แล้ว',
        likeCount: 37,
        commentCount: 3,
        shareCount: 1,
      ),
      CatPhotoItem(
        id: 'mali-p4',
        imageSource: 'asset:assets/images/my_cat/mali-4.jpg',
        caption: 'ตาแป๋วทุกทีเวลาเปิดซองอาหารเปียก',
        relativeTime: '2 สัปดาห์ที่แล้ว',
        likeCount: 71,
        commentCount: 12,
        shareCount: 3,
      ),
      CatPhotoItem(
        id: 'mali-p5',
        imageSource: 'asset:assets/images/my_cat/mali-5.jpg',
        caption: 'ซ้อมปีนคอนโดแมวชั้นบนสุด',
        relativeTime: '3 สัปดาห์ที่แล้ว',
        likeCount: 55,
        commentCount: 4,
        shareCount: 2,
      ),
      CatPhotoItem(
        id: 'mali-p6',
        imageSource: 'asset:assets/images/my_cat/mali-6.jpg',
        caption: 'รูปประจำตัวตอนเพิ่งพามะลิมาอยู่บ้านใหม่',
        relativeTime: '1 เดือนที่แล้ว',
        likeCount: 89,
        commentCount: 15,
        shareCount: 4,
      ),
    ];

    const somjeedPhotos = [
      CatPhotoItem(
        id: 'som-p1',
        imageSource: 'asset:assets/images/hero/somjeed.jpg',
        caption: 'ส้มจี๊ดขอกินมื้อสายเพิ่มอีกครึ่งช้อน',
        relativeTime: '1 วันที่แล้ว',
        likeCount: 48,
        commentCount: 5,
        shareCount: 2,
      ),
      CatPhotoItem(
        id: 'som-p2',
        imageSource: 'asset:assets/images/posts/1759588032622-1388cf9505ad.jpg',
        caption: 'หลับคาตักระหว่างทำงานตลอด',
        relativeTime: '4 วันที่แล้ว',
        likeCount: 63,
        commentCount: 9,
        shareCount: 3,
      ),
      CatPhotoItem(
        id: 'som-p3',
        imageSource: 'asset:assets/images/posts/1571566882372-1598d88abd90.jpg',
        caption: 'วิ่งเล่นหลังฝนหยุดที่หน้าบ้าน',
        relativeTime: '1 สัปดาห์ที่แล้ว',
        likeCount: 37,
        commentCount: 3,
        shareCount: 1,
      ),
      CatPhotoItem(
        id: 'som-p4',
        imageSource: 'asset:assets/images/posts/1765714714461-174be7eaad85.jpg',
        caption: 'สวมปลอกคอใหม่อวดเพื่อนบ้าน',
        relativeTime: '2 สัปดาห์ที่แล้ว',
        likeCount: 71,
        commentCount: 12,
        shareCount: 3,
      ),
      CatPhotoItem(
        id: 'som-p5',
        imageSource: 'asset:assets/images/posts/1511044568932-338cba0ad803.jpg',
        caption: 'ย้อนดูรูปตอนส้มจี๊ดยังตัวจิ๋ว',
        relativeTime: '3 สัปดาห์ที่แล้ว',
        likeCount: 55,
        commentCount: 4,
        shareCount: 2,
      ),
      CatPhotoItem(
        id: 'som-p6',
        imageSource: 'asset:assets/images/my_cat/som-6.jpg',
        caption: 'นอนอาบแดดริมหน้าต่างตอนเย็น',
        relativeTime: '1 เดือนที่แล้ว',
        likeCount: 89,
        commentCount: 15,
        shareCount: 4,
      ),
    ];

    const thuadamPhotos = [
      CatPhotoItem(
        id: 'thua-p1',
        imageSource: 'asset:assets/images/hero/thuadam.jpg',
        caption: 'พี่ใหญ่ถั่วดำเฝ้าประตูบ้านทุกเช้า',
        relativeTime: '3 วันที่แล้ว',
        likeCount: 48,
        commentCount: 5,
        shareCount: 2,
      ),
      CatPhotoItem(
        id: 'thua-p2',
        imageSource: 'asset:assets/images/posts/1514888286974-6c03e2ca1dba.jpg',
        caption: 'สายตาดุแต่จริง ๆ ขี้อ้อนที่สุดในบ้าน',
        relativeTime: '6 วันที่แล้ว',
        likeCount: 63,
        commentCount: 9,
        shareCount: 3,
      ),
      CatPhotoItem(
        id: 'thua-p3',
        imageSource: 'asset:assets/images/my_cat/thua-3.jpg',
        caption: 'พึ่งตื่นจากงีบบ่าย 3 ชั่วโมง',
        relativeTime: '1 สัปดาห์ที่แล้ว',
        likeCount: 37,
        commentCount: 3,
        shareCount: 1,
      ),
      CatPhotoItem(
        id: 'thua-p4',
        imageSource: 'asset:assets/images/my_cat/thua-4.jpg',
        caption: 'ตรวจสุขภาพประจำปีผ่านฉลุย',
        relativeTime: '2 สัปดาห์ที่แล้ว',
        likeCount: 71,
        commentCount: 12,
        shareCount: 3,
      ),
      CatPhotoItem(
        id: 'thua-p5',
        imageSource: 'asset:assets/images/posts/1478098711619-5ab0b478d6e6.jpg',
        caption: 'นั่งดูนกกับน้อง ๆ ในบ้าน',
        relativeTime: '3 สัปดาห์ที่แล้ว',
        likeCount: 55,
        commentCount: 4,
        shareCount: 2,
      ),
      CatPhotoItem(
        id: 'thua-p6',
        imageSource: 'asset:assets/images/my_cat/thua-6.jpg',
        caption: 'รูปคู่โปรดของพี่ใหญ่',
        relativeTime: '1 เดือนที่แล้ว',
        likeCount: 89,
        commentCount: 15,
        shareCount: 4,
      ),
    ];

    const owner = OwnerProfile(
      id: 'me',
      handle: 'jutamas.lk',
      displayName: 'จุฑามาศ ลูกแก้ว',
      bio: 'ทาสแมว 3 ตัว รักการช่วยแมวจร',
      district: 'บางซื่อ กรุงเทพฯ',
      memberSince: 'มี.ค. 2023',
      avatarSource:
          'asset:assets/images/avatars/1494790108377-be9c29b29330.jpg',
      avatarBg: 0xFFFFE89A,
      followerCount: 12,
      helpedCount: 2,
      unreadMessagesCount: 3,
      isPhoneVerified: true,
      isIdVerified: true,
      donationAccount: OwnerDonationAccount(
        method: DonationMethod.promptPay,
        accountNumber: '0891235678',
        accountName: 'จุฑามาศ ลูกแก้ว',
      ),
      treatAddress: '',
      privacy: OwnerPrivacySettings(
        visibility: ProfileVisibility.everyone,
        showMyCats: true,
        showDistrict: true,
        allowMessages: true,
      ),
      notifications: OwnerNotificationSettings(
        pushEnabled: true,
        quietHoursEnabled: true,
        nearbyAlerts: true,
        careReminders: true,
        locale: 'th',
      ),
    );

    return const MyCatBundle(
      owner: owner,
      cats: [
        CatProfile(
          id: 'cat-mali',
          publicId: 'MAW000123',
          name: 'มะลิ',
          breed: 'วิเชียรมาศ',
          gender: CatGender.female,
          neutered: true,
          ageLabel: '3 ปี',
          weightKg: 4.1,
          recordCount: 12,
          adoptedYear: 2023,
          avatarSource: 'asset:assets/images/hero/mali.jpg',
          avatarBg: 0xFFFFF1E6,
          healthBadge: CatHealthBadge.watch,
          trackerStatus: CatTrackerStatus.safe,
          trackerLabel: 'อยู่ในเขตปลอดภัย',
          photos: maliPhotos,
          careTasks: sharedCareTasks,
          healthReminderTitle: 'วัคซีนรวมครบกำหนดใน 12 วัน',
          healthReminderSubtitle: '7 พ.ย. 2569 · ตั้งเตือนล่วงหน้า 3 วัน',
          healthHighlights: sharedHighlights,
          caregivers: sharedCaregivers,
        ),
        CatProfile(
          id: 'cat-somjeed',
          publicId: 'MAW000124',
          name: 'ส้มจี๊ด',
          breed: 'ไทยสีส้ม',
          gender: CatGender.male,
          neutered: true,
          ageLabel: '1 ปี',
          weightKg: 4.8,
          recordCount: 7,
          adoptedYear: 2025,
          avatarSource: 'asset:assets/images/hero/somjeed.jpg',
          avatarBg: 0xFFFFF1C9,
          healthBadge: CatHealthBadge.good,
          trackerStatus: CatTrackerStatus.outOfZone,
          trackerLabel: 'ออกนอกเขตปลอดภัย',
          photos: somjeedPhotos,
          careTasks: sharedCareTasks,
          healthReminderTitle: 'วัคซีนรวมครบกำหนดใน 12 วัน',
          healthReminderSubtitle: '7 พ.ย. 2569 · ตั้งเตือนล่วงหน้า 3 วัน',
          healthHighlights: sharedHighlights,
          caregivers: sharedCaregivers,
        ),
        CatProfile(
          id: 'cat-thuadam',
          publicId: 'MAW000188',
          name: 'ถั่วดำ',
          breed: 'ดำปลอด',
          gender: CatGender.male,
          neutered: false,
          ageLabel: '6 ปี',
          weightKg: 5.2,
          recordCount: 21,
          adoptedYear: 2020,
          avatarSource: 'asset:assets/images/hero/thuadam.jpg',
          avatarBg: 0xFFEAF3FF,
          healthBadge: CatHealthBadge.good,
          trackerStatus: CatTrackerStatus.noCollar,
          trackerLabel: 'ยังไม่มีปลอกคอ',
          photos: thuadamPhotos,
          careTasks: sharedCareTasks,
          healthReminderTitle: 'วัคซีนรวมครบกำหนดใน 12 วัน',
          healthReminderSubtitle: '7 พ.ย. 2569 · ตั้งเตือนล่วงหน้า 3 วัน',
          healthHighlights: sharedHighlights,
          caregivers: sharedCaregivers,
        ),
      ],
    );
  }

  @override
  Future<MyCatBundleModel> fetchBundle() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    return MyCatBundleModel(
      owner: OwnerProfileModel(entity: _bundle.owner),
      cats: _bundle.cats.map((c) => CatProfileModel(entity: c)).toList(),
    );
  }

  @override
  Future<void> toggleCareTask({
    required String catId,
    required String taskId,
    required bool isDone,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 60));
    _bundle = _bundle.copyWith(
      cats: _bundle.cats.map((cat) {
        if (cat.id != catId) return cat;
        return cat.copyWith(
          careTasks: cat.careTasks
              .map((t) => t.id == taskId ? t.copyWith(isDone: isDone) : t)
              .toList(),
        );
      }).toList(),
    );
  }

  @override
  Future<CatProfileModel> updateCatProfile(CatProfile cat) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    _bundle = _bundle.copyWith(
      cats: _bundle.cats.map((c) => c.id == cat.id ? cat : c).toList(),
    );
    return CatProfileModel(entity: cat);
  }

  @override
  Future<CatProfileModel> addCatProfile(CatProfile newCat) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final publicId = 'MAW000${_nextCatSeq++}';
    final created = newCat.copyWith(
      id: 'cat-$publicId',
      publicId: publicId,
      careTasks: _bundle.cats.isNotEmpty
          ? _bundle.cats.first.careTasks
                .map((t) => t.copyWith(isDone: false))
                .toList()
          : const [
              CareTaskItem(
                id: 'care-food',
                title: 'อาหาร',
                subtitle: 'รอให้อาหารเช้า',
                isDone: false,
              ),
              CareTaskItem(
                id: 'care-water',
                title: 'น้ำ',
                subtitle: 'เปลี่ยนน้ำสะอาดประจำวัน',
                isDone: false,
              ),
            ],
      caregivers: _bundle.cats.isNotEmpty
          ? _bundle.cats.first.caregivers
          : const [],
    );
    _bundle = _bundle.copyWith(cats: [..._bundle.cats, created]);
    return CatProfileModel(entity: created);
  }

  @override
  Future<OwnerProfileModel> updateOwnerProfile(OwnerProfile owner) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    _bundle = _bundle.copyWith(owner: owner);
    return OwnerProfileModel(entity: owner);
  }

  @override
  Future<CatPhotoItem> addCatPhoto({
    required String catId,
    required String imageSource,
    required String caption,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    final item = CatPhotoItem(
      id: 'photo-${_nextPhotoSeq++}',
      imageSource: imageSource,
      caption: caption,
      relativeTime: 'เมื่อสักครู่',
    );
    _bundle = _bundle.copyWith(
      cats: _bundle.cats.map((cat) {
        if (cat.id != catId) return cat;
        return cat.copyWith(photos: [item, ...cat.photos]);
      }).toList(),
    );
    return item;
  }
}
