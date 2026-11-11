import '../../domain/entities/my_cat_data.dart';

/// ตัวช่วยแปลข้อความและข้อมูลจำลองในหน้า /my-cat เมื่อผู้ใช้เลือกภาษา EN
abstract final class MyCatL10n {
  static String t(bool isEn, String th, String en) => isEn ? en : th;

  static String catName(String name, bool isEn) {
    if (!isEn) return name;
    return switch (name) {
      'มะลิ' => 'Mali',
      'ส้มจี๊ด' => 'Somjeed',
      'ถั่วดำ' => 'Thua Dam',
      _ => name,
    };
  }

  static String breed(String breed, bool isEn) {
    if (!isEn) return breed;
    return switch (breed) {
      'วิเชียรมาศ' => 'Siamese',
      'ไทยสีส้ม' => 'Thai orange',
      'ดำปลอด' => 'Solid black',
      'ไทยผสม' => 'Thai mix',
      _ => breed,
    };
  }

  static String age(String ageLabel, bool isEn) {
    if (!isEn) return ageLabel;
    if (ageLabel == 'น้อยกว่า 3 เดือน') return '< 3 mos';
    if (ageLabel == '15+ ปี') return '15+ yrs';
    if (ageLabel.endsWith(' เดือน')) {
      final n = ageLabel.replaceFirst(' เดือน', '').trim();
      return '$n mos';
    }
    if (ageLabel.endsWith(' ปี')) {
      final n = ageLabel.replaceFirst(' ปี', '').trim();
      return n == '1' ? '1 yr' : '$n yrs';
    }
    return ageLabel;
  }

  static String catSummary(CatProfile cat, bool isEn) {
    if (!isEn) return cat.summarySubtitle;
    final g = cat.gender == CatGender.female ? 'Female' : 'Male';
    final n = cat.neutered ? 'spayed' : 'intact';
    return '${breed(cat.breed, true)} · $g · $n';
  }

  static String trackerLabel(CatTrackerStatus status, String raw, bool isEn) {
    if (!isEn) return raw;
    return switch (status) {
      CatTrackerStatus.safe => 'In the safe zone',
      CatTrackerStatus.outOfZone => 'Outside safe zone',
      CatTrackerStatus.noCollar => 'No collar yet',
    };
  }

  static String ownerName(String name, bool isEn) {
    if (!isEn) return name;
    return name == 'จุฑามาศ ลูกแก้ว' ? 'Jutamas Lukkaew' : name;
  }

  static String ownerBio(String bio, bool isEn) {
    if (!isEn) return bio;
    return bio == 'ทาสแมว 3 ตัว รักการช่วยแมวจร'
        ? 'Servant to 3 cats, loves helping strays'
        : bio;
  }

  static String ownerDistrict(String district, bool isEn) {
    if (!isEn) return district;
    return district == 'บางซื่อ กรุงเทพฯ' ? 'Bang Sue, Bangkok' : district;
  }

  static String memberSince(String raw, bool isEn) {
    if (!isEn) return raw;
    return raw.replaceFirst('มี.ค.', 'Mar');
  }

  static String careTaskTitle(CareTaskItem task, bool isEn) {
    if (!isEn) return task.title;
    return switch (task.id) {
      'care-food' => 'Food',
      'care-water' => 'Water',
      'care-litter' => 'Litter',
      'care-meds' => 'Medicine',
      'care-weight' => 'Weight',
      _ => task.title,
    };
  }

  static String careTaskSubtitle(CareTaskItem task, bool isEn) {
    if (!isEn) return task.subtitle;
    return switch (task.subtitle) {
      'เสร็จแล้ว · แม่ · 07:30' => 'Done · Mom · 07:30',
      'เสร็จแล้ว · พี่สาว · 08:10' => 'Done · Sister · 08:10',
      'เสร็จแล้ว · ฉัน · 08:00' => 'Done · Me · 08:00',
      'ตักทราย · ครั้งล่าสุดเมื่อวาน 21:00' =>
        'Scoop litter · last yesterday 21:00',
      'ตักทรายเช้าเย็น · กดเพื่อติ๊ก' =>
        'Scoop morning & evening · tap to check',
      'ยาหยอดตา 1 หยด · 20:00' => 'Eye drops 1 drop · 20:00',
      'ยาตามรอบ · กดเพื่อติ๊ก' => 'Scheduled meds · tap to check',
      'ชั่งสัปดาห์ละครั้ง · ครั้งล่าสุด 4.1 กก.' => 'Weekly · last 4.1 kg',
      'ชั่งสัปดาห์ละครั้ง · กดเพื่อติ๊ก' => 'Weekly · tap to check',
      _ =>
        task.subtitle
            .replaceFirst('เสร็จแล้ว · ', 'Done · ')
            .replaceFirst('ฉัน', 'Me')
            .replaceFirst('แม่', 'Mom')
            .replaceFirst('พี่สาว', 'Sister')
            .replaceFirst('กก.', 'kg'),
    };
  }

  static String healthReminderTitle(String raw, bool isEn) {
    if (!isEn) return raw;
    return raw == 'วัคซีนรวมครบกำหนดใน 12 วัน'
        ? 'Combo vaccine due in 12 days'
        : raw;
  }

  static String healthReminderSubtitle(String raw, bool isEn) {
    if (!isEn) return raw;
    return raw == '7 พ.ย. 2569 · ตั้งเตือนล่วงหน้า 3 วัน'
        ? '7 Nov 2026 · remind 3 days ahead'
        : raw;
  }

  static String healthHighlightTitle(String raw, bool isEn) {
    if (!isEn) return raw;
    return switch (raw) {
      'วัคซีนรวม (เข็มกระตุ้น)' => 'Combo vaccine (booster)',
      'อาเจียน 2 ครั้ง · บันทึกจาก Cat AI' =>
        'Vomited twice · note from Cat AI',
      'ถ่ายพยาธิ' => 'Deworming',
      'ตรวจสุขภาพประจำปี' => 'Annual checkup',
      _ => raw,
    };
  }

  static String healthHighlightDate(String raw, bool isEn) {
    if (!isEn) return raw;
    return switch (raw) {
      'ครบกำหนด 7 พ.ย. 2569' => 'Due 7 Nov 2026',
      '26 ต.ค. 2569' => '26 Oct 2026',
      '2 ต.ค. 2569' => '2 Oct 2026',
      '15 ส.ค. 2569' => '15 Aug 2026',
      _ => raw,
    };
  }

  static String caregiverName(String name, bool isEn) {
    if (!isEn) return name;
    return switch (name) {
      'แม่' => 'Mom',
      'พี่สาว' => 'Sister',
      'ฉัน' => 'Me',
      _ => name,
    };
  }

  static String caregiverRole(String role, bool isEn) {
    if (!isEn) return role;
    return switch (role) {
      'ผู้ดูแลหลัก' => 'Main caregiver',
      'ผู้ดูแล' => 'Caregiver',
      'เจ้าของบัญชี' => 'Account holder',
      _ => role,
    };
  }

  static String photoCaption(String caption, bool isEn) {
    if (!isEn) return caption;
    return switch (caption) {
      'มะลินั่งรับลมเช้าที่ระเบียง วันนี้อารมณ์ดีเป็นพิเศษ' =>
        'Mali catching the morning breeze on the balcony',
      'ช่วงบ่ายขดตัวบนเบาะอุ่น ๆ ไม่ยอมลุกเลย' =>
        'Curled up on the warm cushion all afternoon',
      'รอแม่เทขนมเลียหลังกลับจากหาหมอ' =>
        'Waiting for a creamy treat after the vet visit',
      'ตาแป๋วทุกทีเวลาเปิดซองอาหารเปียก' =>
        'Wide-eyed every time a wet food pouch opens',
      'ซ้อมปีนคอนโดแมวชั้นบนสุด' => 'Climbing to the top level of the cat tree',
      'รูปประจำตัวตอนเพิ่งพามะลิมาอยู่บ้านใหม่' =>
        'First day Mali arrived at her new home',
      'ส้มจี๊ดขอกินมื้อสายเพิ่มอีกครึ่งช้อน' =>
        'Somjeed asking for an extra half scoop at brunch',
      'หลับคาตักระหว่างทำงานตลอด' => 'Napping on my lap throughout the workday',
      'วิ่งเล่นหลังฝนหยุดที่หน้าบ้าน' =>
        'Zoomies in the yard right after the rain',
      'สวมปลอกคอใหม่อวดเพื่อนบ้าน' => 'Showing off the new collar to neighbors',
      'ย้อนดูรูปตอนส้มจี๊ดยังตัวจิ๋ว' => 'Throwback to tiny kitten Somjeed',
      'นอนอาบแดดริมหน้าต่างตอนเย็น' => 'Evening sunbathing by the window',
      'พี่ใหญ่ถั่วดำเฝ้าประตูบ้านทุกเช้า' =>
        'Big brother Thua Dam guarding the front door',
      'สายตาดุแต่จริง ๆ ขี้อ้อนที่สุดในบ้าน' =>
        'Fierce look, secretly the sweetest cuddlebug',
      'พึ่งตื่นจากงีบบ่าย 3 ชั่วโมง' =>
        'Just woke up from a 3-hour afternoon nap',
      'ตรวจสุขภาพประจำปีผ่านฉลุย' => 'Passed the annual health checkup cleanly',
      'นั่งดูนกกับน้อง ๆ ในบ้าน' => 'Birdwatching together with the siblings',
      'รูปคู่โปรดของพี่ใหญ่' => 'Big brother’s favorite duo snapshot',
      _ => caption,
    };
  }

  static String relativeTime(String raw, bool isEn) {
    if (!isEn) return raw;
    if (raw == 'เมื่อสักครู่') return 'Just now';
    if (raw.endsWith(' วันที่แล้ว')) {
      final n = raw.replaceFirst(' วันที่แล้ว', '').trim();
      return n == '1' ? '1 day ago' : '$n days ago';
    }
    if (raw.endsWith(' สัปดาห์ที่แล้ว')) {
      final n = raw.replaceFirst(' สัปดาห์ที่แล้ว', '').trim();
      return n == '1' ? '1 week ago' : '$n weeks ago';
    }
    if (raw.endsWith(' เดือนที่แล้ว')) {
      final n = raw.replaceFirst(' เดือนที่แล้ว', '').trim();
      return n == '1' ? '1 month ago' : '$n months ago';
    }
    return raw;
  }
}
