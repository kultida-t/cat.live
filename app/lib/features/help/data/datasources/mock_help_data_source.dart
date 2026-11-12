import '../../domain/entities/help_data.dart';
import 'help_remote_data_source.dart';

/// ข้อมูลจำลองหน้าช่วยเหลือ (/help) — เทียบตรงจากหน้าเว็บจริง www.แมว.live/help
class MockHelpDataSource implements HelpRemoteDataSource {
  MockHelpDataSource({this.delay = const Duration(milliseconds: 160)})
    : _snapshot = _buildInitialSnapshot();

  final Duration delay;
  HelpSnapshot _snapshot;
  int _nextSeq = 100;

  @override
  Future<HelpSnapshot> fetchHelpData() async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    return _snapshot;
  }

  @override
  Future<HelpPost> createHelpPost(CreateHelpPostInput input) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
    _nextSeq += 1;
    final id = 'help-post-$_nextSeq';
    final displayTitle = (input.catName != null && input.catName!.trim().isNotEmpty)
        ? '${input.catName!.trim()} · ${input.title.trim()}'
        : input.title.trim();
    final timeText = (input.timeLabel != null && input.timeLabel!.trim().isNotEmpty)
        ? input.timeLabel!.trim()
        : 'เมื่อสักครู่';
    final timeEnText = (input.timeLabel != null && input.timeLabel!.trim().isNotEmpty)
        ? input.timeLabel!.trim()
        : 'Just now';

    final newPost = HelpPost(
      id: id,
      titleTh: displayTitle,
      titleEn: displayTitle,
      category: input.category,
      imageAsset: input.imageAsset,
      imageFilePath: input.imageFilePath,
      locationTh: input.location.trim(),
      locationEn: input.location.trim(),
      distanceKm: 0.3,
      timeAgoTh: timeText,
      timeAgoEn: timeEnText,
      summaryTh: input.summary.trim(),
      summaryEn: input.summary.trim(),
      detailTraitsTh: input.summary.trim(),
      detailTraitsEn: input.summary.trim(),
      secretMarkTh: input.secretMark?.trim().isNotEmpty == true
          ? input.secretMark!.trim()
          : null,
      secretMarkEn: input.secretMark?.trim().isNotEmpty == true
          ? input.secretMark!.trim()
          : null,
      contactInfoTh: input.allowsChatClues
          ? 'เปิดรับเบาะแสผ่านแชต แมว.live ทันที'
          : 'ติดต่อผ่านโทรศัพท์เจ้าของประกาศ',
      contactInfoEn: input.allowsChatClues
          ? 'Accepting clues via Cat.live chat immediately'
          : 'Contact post owner by phone',
      donation: input.enableDonation && input.targetBaht > 0
          ? DonationInfo(
              raisedBaht: 0,
              targetBaht: input.targetBaht,
              purposeTh: input.donationPurpose?.trim().isNotEmpty == true
                  ? input.donationPurpose!.trim()
                  : 'ค่ารักษาและดูแลแมว',
              purposeEn: input.donationPurpose?.trim().isNotEmpty == true
                  ? input.donationPurpose!.trim()
                  : 'Treatment and cat care',
            )
          : null,
      isMine: true,
      allowsChatClues: input.allowsChatClues,
      ownerNameTh: 'ตัวฉัน',
      ownerNameEn: 'Me',
    );

    _snapshot = _snapshot.copyWith(posts: [newPost, ..._snapshot.posts]);
    return newPost;
  }

  @override
  Future<void> sendClue(String postId) async {
    _snapshot = _snapshot.copyWith(
      posts: _snapshot.posts
          .map((p) => p.id == postId ? p.copyWith(clueSent: true) : p)
          .toList(),
    );
  }

  @override
  Future<void> updatePostStatus(String postId, HelpPostStatus status) async {
    _snapshot = _snapshot.copyWith(
      posts: _snapshot.posts
          .map((p) => p.id == postId ? p.copyWith(status: status) : p)
          .toList(),
    );
  }

  @override
  Future<void> setDonationClosed(String postId, bool isClosed) async {
    _snapshot = _snapshot.copyWith(
      posts: _snapshot.posts
          .map(
            (p) => p.id == postId && p.donation != null
                ? p.copyWith(donation: p.donation!.copyWith(isClosed: isClosed))
                : p,
          )
          .toList(),
    );
  }

  @override
  Future<void> updatePostContent(
    String postId, {
    required String title,
    required String summary,
    required String location,
  }) async {
    _snapshot = _snapshot.copyWith(
      posts: _snapshot.posts
          .map(
            (p) => p.id == postId
                ? p.copyWith(
                    titleTh: title,
                    titleEn: title,
                    summaryTh: summary,
                    summaryEn: summary,
                    locationTh: location,
                    locationEn: location,
                  )
                : p,
          )
          .toList(),
    );
  }

  static HelpSnapshot _buildInitialSnapshot() {
    return const HelpSnapshot(
      posts: [
        HelpPost(
          id: 'post-mochi',
          titleTh: 'โมจิ',
          titleEn: 'Mochi',
          category: HelpCategory.lost,
          imageAsset: 'assets/images/help/mochi.jpg',
          locationTh: 'อารีย์ ซอย 4',
          locationEn: 'Ari Soi 4',
          distanceKm: 1.2,
          timeAgoTh: 'หายเมื่อ 2 ชม. ที่แล้ว',
          timeAgoEn: 'Lost 2h ago',
          rewardTh: 'สินน้ำใจ ฿5,000',
          rewardEn: 'Reward ฿5,000',
          summaryTh: 'ปลอกคอสีแดง กระดิ่งทอง มีแต้มสีน้ำตาลที่หูขวา',
          summaryEn: 'Red collar with gold bell, brown spot on right ear',
          detailTraitsTh: 'เพศผู้ ทำหมันแล้ว ขี้อ้อนแต่ตกใจเสียงดัง น่าจะหลบใต้รถหรือพุ่มไม้',
          detailTraitsEn: 'Neutered male, friendly but shy around loud noises. May hide under cars.',
          secretMarkTh: 'จุดสังเกตลับ: มีปานสีเข้มใต้ฝ่าเท้าหน้าซ้าย',
          secretMarkEn: 'Secret mark: Dark birthmark under front left paw',
          contactInfoTh: 'ติดต่อ คุณมิ้นท์ · แชต แมว.live หรือ 089-xxx-4412',
          contactInfoEn: 'Contact Mint · Cat.live chat or 089-xxx-4412',
          postedBy: 'mint.ari',
          ownerNameTh: 'คุณมิ้นท์',
          ownerNameEn: 'Mint',
        ),
        HelpPost(
          id: 'post-luna',
          titleTh: 'ลูน่า',
          titleEn: 'Luna',
          category: HelpCategory.lost,
          imageAsset: 'assets/images/help/luna.jpg',
          locationTh: 'สะพานควาย',
          locationEn: 'Saphan Khwai',
          distanceKm: 2.1,
          timeAgoTh: 'หายเมื่อ 1 วันที่แล้ว',
          timeAgoEn: 'Lost 1d ago',
          rewardTh: 'สินน้ำใจ ฿3,000',
          rewardEn: 'Reward ฿3,000',
          summaryTh: 'แมวลายสลิดตาสีเหลือง ไม่สวมปลอกคอ ชอบขึ้นไปนอนบนหลังคารถ',
          summaryEn: 'Tabby cat with amber eyes, no collar, likes sleeping on car roofs',
          detailTraitsTh: 'อายุ 2 ปี หางยาวปลายงอเล็กน้อย เรียกชื่อลูน่าแล้วหัน',
          detailTraitsEn: '2 years old, long tail with slight kink at the tip. Responds to Luna.',
          secretMarkTh: 'จุดสังเกตลับ: ฟันเขี้ยวล่างขวาบิ่นเล็กน้อย',
          secretMarkEn: 'Secret mark: Slightly chipped lower right canine tooth',
          contactInfoTh: 'ติดต่อ คุณปาล์ม · แชต แมว.live',
          contactInfoEn: 'Contact Palm · Cat.live chat',
          postedBy: 'palm.skw',
          ownerNameTh: 'คุณปาล์ม',
          ownerNameEn: 'Palm',
        ),
        HelpPost(
          id: 'post-leo',
          titleTh: 'ลีโอ',
          titleEn: 'Leo',
          category: HelpCategory.lost,
          imageAsset: 'assets/images/help/leo.jpg',
          locationTh: 'พญาไท',
          locationEn: 'Phaya Thai',
          distanceKm: 3.8,
          timeAgoTh: 'หายเมื่อ 3 วันที่แล้ว',
          timeAgoEn: 'Lost 3d ago',
          rewardTh: 'มีสินน้ำใจ',
          rewardEn: 'Reward offered',
          summaryTh: 'แมวส้มอ้วน ขนฟู ปลอกคอผ้าสีเขียวอ่อน หลุดออกจากคอนโดชั้น 1',
          summaryEn: 'Chubby fluffy ginger cat, light green fabric collar, slipped out from condo 1F',
          detailTraitsTh: 'หนัก 5.8 กก. เชื่องกับคนแปลกหน้า ชอบกินขนมแมวเลีย',
          detailTraitsEn: '5.8 kg, friendly with strangers, loves creamy cat treats.',
          secretMarkTh: 'จุดสังเกตลับ: มีรอยบากเล็กๆ ที่ใบหูซ้าย',
          secretMarkEn: 'Secret mark: Small notch on left ear tip',
          contactInfoTh: 'ติดต่อ คุณต้น · แชต แมว.live',
          contactInfoEn: 'Contact Ton · Cat.live chat',
          postedBy: 'ton.phayathai',
          ownerNameTh: 'คุณต้น',
          ownerNameEn: 'Ton',
        ),
        HelpPost(
          id: 'post-tabby',
          titleTh: 'สลิดเทา',
          titleEn: 'Grey Tabby',
          category: HelpCategory.found,
          imageAsset: 'assets/images/help/tabby.jpg',
          locationTh: 'หลังเซเว่นประดิพัทธ์',
          locationEn: 'Behind 7-Eleven Pradiphat',
          distanceKm: 0.8,
          timeAgoTh: 'พบเมื่อ 3 ชม. ที่แล้ว',
          timeAgoEn: 'Found 3h ago',
          summaryTh: 'เชื่องมาก เดินตามคน ขนสะอาด น่าจะเป็นแมวหลุดจากบ้าน',
          summaryEn: 'Very tame, follows people, clean coat. Likely an escaped house cat.',
          detailTraitsTh: 'ตอนนี้ฝากดูแลชั่วคราวในกรงที่ร้านกาแฟปากซอย ปลอดภัยดี กินอาหารเม็ดได้',
          detailTraitsEn: 'Currently kept safely at a nearby cafe. Eating dry food well.',
          contactInfoTh: 'ผู้พบ: คุณฝน · เปิดรับแชตตรวจสอบเจ้าของ',
          contactInfoEn: 'Finder: Fon · Open for owner verification chat',
          postedBy: 'fon.pradiphat',
          ownerNameTh: 'คุณฝน',
          ownerNameEn: 'Fon',
        ),
        HelpPost(
          id: 'post-calico',
          titleTh: 'สามสีตัวเล็ก',
          titleEn: 'Little Calico',
          category: HelpCategory.found,
          imageAsset: 'assets/images/help/calico.jpg',
          locationTh: 'ใต้สะพานลอยอนุสาวรีย์ฯ',
          locationEn: 'Under Victory Monument overpass',
          distanceKm: 2.5,
          timeAgoTh: 'พบเมื่อ 26 ต.ค. 07:15',
          timeAgoEn: 'Found Oct 26, 07:15',
          summaryTh: 'ลูกแมวสามสีอายุประมาณ 4 เดือน มีกระดิ่งสีชมพูติดตัว',
          summaryEn: '4-month-old calico kitten wearing a pink bell collar',
          detailTraitsTh: 'กลัวเสียงรถเลยพามาพักที่บ้านก่อน ใครเป็นเจ้าของทักมาดูรูปเพิ่มได้เลย',
          detailTraitsEn: 'Scared of traffic, brought indoors for safety. Contact to verify.',
          contactInfoTh: 'ผู้พบ: คุณบีม · แชต แมว.live',
          contactInfoEn: 'Finder: Beam · Cat.live chat',
          postedBy: 'beam.victory',
          ownerNameTh: 'คุณบีม',
          ownerNameEn: 'Beam',
        ),
        HelpPost(
          id: 'post-injured',
          titleTh: 'แมวจรขาหัก',
          titleEn: 'Stray cat with broken leg',
          shortNameTh: 'แมวจรขาหัก',
          shortNameEn: 'Stray cat',
          category: HelpCategory.helpRequest,
          imageAsset: 'assets/images/help/injured.jpg',
          locationTh: 'ซอยอินทามระ 29',
          locationEn: 'Soi Inthamara 29',
          distanceKm: 1.7,
          timeAgoTh: 'โพสต์เมื่อ 4 ชม.',
          timeAgoEn: 'Posted 4h ago',
          summaryTh: 'ถูกรถเฉี่ยวหน้าปากซอย นำส่งคลินิกแล้ว หมอประเมินต้องผ่าตัดดามเหล็ก',
          summaryEn: 'Hit by a motorbike, admitted to clinic. Vet estimates bone pinning surgery.',
          detailTraitsTh: 'มีใบประเมินค่ารักษาจากคลินิกสัตวแพทย์แนบไว้เรียบร้อย อัปเดตอาการทุกวัน',
          detailTraitsEn: 'Vet cost estimate attached. Daily recovery updates posted.',
          contactInfoTh: 'ผู้ดูแลเคส: คุณแอน · คลินิกรักษ์แมวอินทามระ',
          contactInfoEn: 'Case lead: Ann · Rak Maew Clinic Inthamara',
          isUrgent: true,
          postedBy: 'ann.rakmaew',
          donation: DonationInfo(
            raisedBaht: 3200,
            targetBaht: 5000,
            purposeTh: 'ค่าผ่าตัดและยา',
            purposeEn: 'Surgery & medication',
            donorCount: 5,
            supportersTextTh: 'ผู้ใจดีที่ช่วย "แมวจรขาหัก": maew.vetno...',
            supportersTextEn: 'Supporters for "Stray cat": maew.vetno...',
            donorAvatars: [
              'assets/images/avatars/1494790108377-be9c29b29330.jpg',
              'assets/images/avatars/1503777119540-ce54b422baff.jpg',
              'assets/images/avatars/1511044568932-338cba0ad803.jpg',
            ],
          ),
          ownerNameTh: 'คุณแอน',
          ownerNameEn: 'Ann',
        ),
        HelpPost(
          id: 'post-kittens',
          titleTh: 'ลูกแมว 3 ตัวถูกทิ้ง',
          titleEn: '3 abandoned kittens',
          shortNameTh: 'ลูกแมว 3 ตัว',
          shortNameEn: '3 kittens',
          category: HelpCategory.helpRequest,
          imageAsset: 'assets/images/help/kittens.jpg',
          locationTh: 'วัดไผ่ตัน สะพานควาย',
          locationEn: 'Wat Phai Tan, Saphan Khwai',
          distanceKm: 1.4,
          timeAgoTh: 'โพสต์เมื่อ 6 ชม.',
          timeAgoEn: 'Posted 6h ago',
          summaryTh: 'ลูกแมวอายุ ~3 สัปดาห์ ยังไม่หย่านม ต้องการนมแพะและคนช่วยป้อนชั่วคราว',
          summaryEn: '~3-week-old kittens needing goat milk and temporary bottle-feeding foster',
          detailTraitsTh: 'แข็งแรงดีทั้ง 3 ตัว ร้องเก่ง อยากได้คนรับช่วยดูแลระยะสั้น 2-3 สัปดาห์',
          detailTraitsEn: 'All 3 are healthy and vocal. Looking for 2-3 weeks temporary foster.',
          contactInfoTh: 'ติดต่อ คุณเจ · แชต แมว.live',
          contactInfoEn: 'Contact Jay · Cat.live chat',
          isUrgent: true,
          postedBy: 'jay.phaitan',
          ownerNameTh: 'คุณเจ',
          ownerNameEn: 'Jay',
        ),
        HelpPost(
          id: 'post-adoption-1',
          titleTh: 'น้องทองหยิบ · หาบ้านถาวร',
          titleEn: 'Thongyib · Looking for forever home',
          category: HelpCategory.adoption,
          imageAsset: 'assets/images/help/mochi.jpg',
          locationTh: 'จตุจักร',
          locationEn: 'Chatuchak',
          distanceKm: 2.9,
          timeAgoTh: 'ประกาศเมื่อ 20 ต.ค.',
          timeAgoEn: 'Posted Oct 20',
          summaryTh: 'ทำหมัน + วัคซีนครบ 2 เข็มแล้ว นิสัยเรียบร้อย ชอบนอนตัก',
          summaryEn: 'Neutered + 2 vaccines done. Calm personality, loves lap naps.',
          detailTraitsTh: 'อายุ 1 ปี เข้ากับแมวตัวอื่นได้ดี ยินดีส่งถึงบ้านในกรุงเทพฯ',
          detailTraitsEn: '1 year old, gets along with other cats. Home delivery in Bangkok.',
          contactInfoTh: 'ติดต่อ คุณนุ่น · นัดดูตัวได้ที่จตุจักร',
          contactInfoEn: 'Contact Noon · Meet & greet at Chatuchak',
          postedBy: 'noon.jj',
          ownerNameTh: 'คุณนุ่น',
          ownerNameEn: 'Noon',
        ),
        HelpPost(
          id: 'post-adoption-2',
          titleTh: 'ส้มแป้น · พร้อมย้ายบ้าน',
          titleEn: 'Sompaen · Ready for adoption',
          category: HelpCategory.adoption,
          imageAsset: 'assets/images/help/leo.jpg',
          locationTh: 'ห้วยขวาง',
          locationEn: 'Huai Khwang',
          distanceKm: 3.4,
          timeAgoTh: 'ประกาศเมื่อ 18 ต.ค.',
          timeAgoEn: 'Posted Oct 18',
          summaryTh: 'ตรวจเลือด FIV/FeLV ลบทั้งคู่ ใช้กระบะทรายเป็น 100%',
          summaryEn: 'FIV/FeLV negative, 100% litter box trained.',
          detailTraitsTh: 'ขี้เล่น อารมณ์ดี เหมาะกับคอนโดเลี้ยงระบบปิด',
          detailTraitsEn: 'Playful and cheerful, ideal for indoor apartment living.',
          contactInfoTh: 'ติดต่อ คุณกิ๊ฟ · แชต แมว.live',
          contactInfoEn: 'Contact Gift · Cat.live chat',
          postedBy: 'gift.hk',
          ownerNameTh: 'คุณกิ๊ฟ',
          ownerNameEn: 'Gift',
        ),
        HelpPost(
          id: 'post-mommam',
          titleTh: 'ทุนรักษา “มอมแมม” แมวจรขาหัก',
          titleEn: 'Medical fund for “Mommaem”',
          shortNameTh: 'มอมแมม',
          shortNameEn: 'Mommaem',
          category: HelpCategory.helpRequest,
          imageAsset: 'assets/images/hero/kitten.jpg',
          locationTh: 'อารีย์',
          locationEn: 'Ari',
          distanceKm: 0.3,
          timeAgoTh: 'โพสต์เมื่อ 3 วันที่แล้ว',
          timeAgoEn: 'Posted 3d ago',
          summaryTh: 'ลูกแมวต้องการค่ารักษาและดูแลฟื้นฟู ครบเป้าหมายแล้ว ขอบคุณทุกท่านที่ร่วมช่วยเหลือ',
          summaryEn: 'Kitten recovery care reached target. Thank you everyone for helping.',
          detailTraitsTh: 'อาการดีขึ้นมาก กินเก่ง ร่าเริง พร้อมอัปเดตใบเสร็จค่ารักษาครบถ้วน',
          detailTraitsEn: 'Recovering well, eating actively. Vet receipts attached.',
          contactInfoTh: 'ติดต่อผ่านแชต แมว.live',
          contactInfoEn: 'Contact via Cat.live chat',
          postedBy: 'me.catlive',
          donation: DonationInfo(
            raisedBaht: 3150,
            targetBaht: 3000,
            purposeTh: 'ค่าผ่าตัดและยาหลังผ่าตัด',
            purposeEn: 'Surgery and post-op medication',
            donorCount: 4,
            supportersTextTh: 'ผู้ใจดีที่ช่วย "มอมแมม": noon.mochi, maew.vetnote...',
            supportersTextEn: 'Supporters for "Mommaem": noon.mochi, maew.vetnote...',
            donorAvatars: [
              'assets/images/avatars/1494790108377-be9c29b29330.jpg',
              'assets/images/avatars/1503777119540-ce54b422baff.jpg',
              'assets/images/avatars/1511044568932-338cba0ad803.jpg',
            ],
          ),
          isMine: true,
          ownerNameTh: 'ตัวฉัน',
          ownerNameEn: 'Me',
        ),
        HelpPost(
          id: 'post-persian',
          titleTh: 'หาบ้านพักชั่วคราว เปอร์เซียส้ม',
          titleEn: 'Temporary foster for Orange Persian',
          shortNameTh: 'เปอร์เซียส้ม',
          shortNameEn: 'Orange Persian',
          category: HelpCategory.foster,
          imageAsset: 'assets/images/help/persian.jpg',
          locationTh: 'ลาดพร้าว',
          locationEn: 'Lat Phrao',
          distanceKm: 4.5,
          timeAgoTh: 'ประกาศเมื่อ 24 ต.ค.',
          timeAgoEn: 'Posted Oct 24',
          summaryTh: 'เจ้าของเดิมเข้าโรงพยาบาล ต้องการบ้านอุปการะชั่วคราว 1 เดือน มีอาหารและทรายให้ครบ',
          summaryEn: 'Owner hospitalized, needs 1-month temporary foster. Food & litter provided.',
          detailTraitsTh: 'นิสัยนิ่ง ไม่ดุ อาบน้ำแปรงขนเรียบร้อยแล้ว',
          detailTraitsEn: 'Gentle and calm, recently groomed.',
          contactInfoTh: 'ติดต่อ ทีมอาสาแมว.live',
          contactInfoEn: 'Contact Cat.live Volunteer Team',
          postedBy: 'rescue.bkk',
          donation: DonationInfo(
            raisedBaht: 800,
            targetBaht: 800,
            purposeTh: 'ค่าอาหารและยาระหว่างพักฟื้น',
            purposeEn: 'Food & recovery care',
            donorCount: 2,
            supportersTextTh: 'ผู้ใจดีที่ช่วย "เปอร์เซียส้ม": bow.persian, plo...',
            supportersTextEn: 'Supporters for "Orange Persian": bow.persian, plo...',
            donorAvatars: [
              'assets/images/avatars/1494790108377-be9c29b29330.jpg',
              'assets/images/avatars/1503777119540-ce54b422baff.jpg',
            ],
            isClosed: true,
          ),
          isMine: false,
          ownerNameTh: 'ทีมอาสาแมว.live',
          ownerNameEn: 'Cat.live Volunteer Team',
        ),
      ],
      symptoms: [
        EmergencySymptom(
          titleTh: 'หายใจลำบาก',
          titleEn: 'Difficulty breathing',
        ),
        EmergencySymptom(
          titleTh: 'ชัก / หมดสติ',
          titleEn: 'Seizures / unconsciousness',
        ),
        EmergencySymptom(
          titleTh: 'ไม่ฉี่เกิน 24 ชม.',
          titleEn: 'No urination > 24 hrs',
        ),
        EmergencySymptom(
          titleTh: 'กินสารพิษ / ยา',
          titleEn: 'Ingested poison / medicine',
        ),
        EmergencySymptom(
          titleTh: 'เลือดออกไม่หยุด',
          titleEn: 'Uncontrolled bleeding',
        ),
        EmergencySymptom(
          titleTh: 'โดนรถ / ตกที่สูง',
          titleEn: 'Hit by vehicle / fall from height',
        ),
      ],
      hospital: EmergencyHospital(
        nameTh: 'รพ.สัตว์ทองหล่อ (พระราม 9)',
        nameEn: 'Thonglor Pet Hospital (Rama 9)',
        distanceKm: 3.2,
        hoursTh: 'เปิด 24 ชม.',
        hoursEn: 'Open 24 hrs',
        phone: '02-079-9999',
      ),
      rescueRecords: [
        MyRescueRecord(
          id: 'rescue-1',
          titleTh: '“ลายสลิดขาเจ็บ”',
          titleEn: '“Injured Tabby”',
          catNameTh: 'ลายสลิดขาเจ็บ',
          catNameEn: 'Injured Tabby',
          dateTh: 'เมื่อวาน',
          dateEn: 'Yesterday',
          typeTh: 'บริจาค (ไม่แสดงชื่อ)',
          typeEn: 'Donation (Anonymous)',
          amountBaht: 100,
        ),
      ],
    );
  }
}
