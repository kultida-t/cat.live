import 'package:equatable/equatable.dart';

/// หมวดหมู่บันทึกในสมุดสุขภาพ (/my-cat/health)
enum HealthRecordCategory {
  vaccine('วัคซีน', 'Vaccine'),
  deworming('ถ่ายพยาธิ', 'Deworming'),
  bloodTest('ตรวจเลือด', 'Blood test'),
  illness('อาการป่วย', 'Illness'),
  checkup('ตรวจประจำปี', 'Checkup'),
  surgery('ผ่าตัด', 'Surgery'),
  weight('น้ำหนัก', 'Weight'),
  other('อื่น ๆ', 'Other');

  const HealthRecordCategory(this.thLabel, this.enLabel);
  final String thLabel;
  final String enLabel;
}

/// 8 จุดอวัยวะบนแผนผังร่างกายแมว (แท็บ ร่างกาย)
enum BodyOrganId {
  eyesEars('ตาและหู', 'Eyes & ears', true),
  mouthTeeth('ปากและฟัน', 'Mouth & teeth', true),
  heartLungs('หัวใจและปอด', 'Heart & lungs', true),
  stomachGut('ท้องและลำไส้', 'Stomach & gut', true),
  skinCoat('ผิวหนังและขน', 'Skin & coat', false),
  kidneyLiver('ไตและตับ', 'Kidney & liver', false),
  weight('น้ำหนัก', 'Weight', false),
  jointsBones('ข้อและกระดูก', 'Joints & bones', false);

  const BodyOrganId(this.thLabel, this.enLabel, this.isLeft);
  final String thLabel;
  final String enLabel;
  final bool isLeft;
}

/// สถานะของแต่ละอวัยวะบนแผนผังร่างกาย
enum BodyOrganStatus {
  normal('ปกติดี', 'All normal'),
  watch('ควรจับตา', 'Keep an eye on it'),
  abnormal('ผิดปกติ', 'Abnormal'),
  empty('ยังไม่มีข้อมูล', 'No info yet');

  const BodyOrganStatus(this.thLabel, this.enLabel);
  final String thLabel;
  final String enLabel;
}

/// ประเภทนัดหมายในปฏิทินสุขภาพ
enum HealthCalendarEventType { deworming, vaccine, checkup }

/// การ์ดนัดหมายครั้งถัดไปบนสุดของแท็บประวัติ
class HealthNextAppointment extends Equatable {
  const HealthNextAppointment({
    required this.daysLeft,
    required this.titleTh,
    required this.titleEn,
    required this.dateTh,
    required this.dateEn,
  });

  final int daysLeft;
  final String titleTh;
  final String titleEn;
  final String dateTh;
  final String dateEn;

  @override
  List<Object?> get props => [daysLeft, titleTh, titleEn, dateTh, dateEn];
}

/// รายการบันทึกสุขภาพหนึ่งรายการในแท็บประวัติ
class HealthRecordEntry extends Equatable {
  const HealthRecordEntry({
    required this.id,
    required this.category,
    required this.dateTh,
    required this.dateEn,
    required this.titleTh,
    required this.titleEn,
    this.detailsTh = '',
    this.detailsEn = '',
    this.clinicTh = '',
    this.clinicEn = '',
    this.treatmentTh = '',
    this.treatmentEn = '',
    this.noteTh = '',
    this.noteEn = '',
    this.sourceTh = '',
    this.sourceEn = '',
    this.costThb,
  });

  final String id;
  final HealthRecordCategory category;
  final String dateTh;
  final String dateEn;
  final String titleTh;
  final String titleEn;
  final String detailsTh;
  final String detailsEn;
  final String clinicTh;
  final String clinicEn;
  final String treatmentTh;
  final String treatmentEn;
  final String noteTh;
  final String noteEn;
  final String sourceTh;
  final String sourceEn;
  final int? costThb;

  @override
  List<Object?> get props => [
    id,
    category,
    dateTh,
    dateEn,
    titleTh,
    titleEn,
    detailsTh,
    detailsEn,
    clinicTh,
    clinicEn,
    treatmentTh,
    treatmentEn,
    noteTh,
    noteEn,
    sourceTh,
    sourceEn,
    costThb,
  ];
}

/// สถานะและรายละเอียดของอวัยวะแต่ละจุดบนตัวแมว
class BodyOrganReport extends Equatable {
  const BodyOrganReport({
    required this.organ,
    this.status = BodyOrganStatus.empty,
    this.summaryTh = '',
    this.summaryEn = '',
    this.sourceTh = '',
    this.sourceEn = '',
  });

  final BodyOrganId organ;
  final BodyOrganStatus status;
  final String summaryTh;
  final String summaryEn;
  final String sourceTh;
  final String sourceEn;

  BodyOrganReport copyWith({
    BodyOrganStatus? status,
    String? summaryTh,
    String? summaryEn,
    String? sourceTh,
    String? sourceEn,
  }) {
    return BodyOrganReport(
      organ: organ,
      status: status ?? this.status,
      summaryTh: summaryTh ?? this.summaryTh,
      summaryEn: summaryEn ?? this.summaryEn,
      sourceTh: sourceTh ?? this.sourceTh,
      sourceEn: sourceEn ?? this.sourceEn,
    );
  }

  @override
  List<Object?> get props => [
    organ,
    status,
    summaryTh,
    summaryEn,
    sourceTh,
    sourceEn,
  ];
}

/// ประวัติการฉีดวัคซีนพร้อมข้อมูลสติ๊กเกอร์และสัตวแพทย์
class VaccineRecord extends Equatable {
  const VaccineRecord({
    required this.id,
    required this.nameTh,
    required this.nameEn,
    required this.dateTh,
    required this.dateEn,
    required this.doseTh,
    required this.doseEn,
    required this.nextDueTh,
    required this.nextDueEn,
    this.manufacturer = '',
    this.productName = '',
    this.lotNumber = '',
    this.expiryDate = '',
    this.clinicTh = '',
    this.clinicEn = '',
    this.clinicPhone = '',
    this.vetName = '',
    this.licenseNumber = '',
  });

  final String id;
  final String nameTh;
  final String nameEn;
  final String dateTh;
  final String dateEn;
  final String doseTh;
  final String doseEn;
  final String nextDueTh;
  final String nextDueEn;
  final String manufacturer;
  final String productName;
  final String lotNumber;
  final String expiryDate;
  final String clinicTh;
  final String clinicEn;
  final String clinicPhone;
  final String vetName;
  final String licenseNumber;

  bool get hasSticker =>
      manufacturer.isNotEmpty ||
      productName.isNotEmpty ||
      lotNumber.isNotEmpty;

  @override
  List<Object?> get props => [
    id,
    nameTh,
    nameEn,
    dateTh,
    dateEn,
    doseTh,
    doseEn,
    nextDueTh,
    nextDueEn,
    manufacturer,
    productName,
    lotNumber,
    expiryDate,
    clinicTh,
    clinicEn,
    clinicPhone,
    vetName,
    licenseNumber,
  ];
}

/// ข้อมูลป้องกันเห็บหมัด/ถ่ายพยาธิในสมุดวัคซีน
class ParasitePreventionRecord extends Equatable {
  const ParasitePreventionRecord({
    required this.productTh,
    required this.productEn,
    required this.dateTh,
    required this.dateEn,
    required this.noteTh,
    required this.noteEn,
  });

  final String productTh;
  final String productEn;
  final String dateTh;
  final String dateEn;
  final String noteTh;
  final String noteEn;

  @override
  List<Object?> get props => [
    productTh,
    productEn,
    dateTh,
    dateEn,
    noteTh,
    noteEn,
  ];
}

/// รายการยาในแท็บยา
class MedicationItem extends Equatable {
  const MedicationItem({
    required this.id,
    required this.nameTh,
    required this.nameEn,
    required this.isActive,
    required this.dosageTh,
    required this.dosageEn,
    required this.periodTh,
    required this.periodEn,
    this.reasonTh = '',
    this.reasonEn = '',
    this.clinicTh = '',
    this.clinicEn = '',
  });

  final String id;
  final String nameTh;
  final String nameEn;
  final bool isActive;
  final String dosageTh;
  final String dosageEn;
  final String periodTh;
  final String periodEn;
  final String reasonTh;
  final String reasonEn;
  final String clinicTh;
  final String clinicEn;

  @override
  List<Object?> get props => [
    id,
    nameTh,
    nameEn,
    isActive,
    dosageTh,
    dosageEn,
    periodTh,
    periodEn,
    reasonTh,
    reasonEn,
    clinicTh,
    clinicEn,
  ];
}

/// จุดน้ำหนักรายเดือนสำหรับกราฟแท็บน้ำหนัก
class WeightPoint extends Equatable {
  const WeightPoint({
    required this.monthTh,
    required this.monthEn,
    required this.kg,
  });

  final String monthTh;
  final String monthEn;
  final double kg;

  @override
  List<Object?> get props => [monthTh, monthEn, kg];
}

/// ไฟล์เอกสารสุขภาพที่แนบไว้ในแท็บเอกสาร
class HealthDocumentItem extends Equatable {
  const HealthDocumentItem({
    required this.id,
    required this.fileName,
    required this.dateTh,
    required this.dateEn,
    required this.sizeLabel,
    required this.isPdf,
  });

  final String id;
  final String fileName;
  final String dateTh;
  final String dateEn;
  final String sizeLabel;
  final bool isPdf;

  @override
  List<Object?> get props => [id, fileName, dateTh, dateEn, sizeLabel, isPdf];
}

/// นัดหมายรวมในแท็บปฏิทินของบ้าน
class HealthCalendarEvent extends Equatable {
  const HealthCalendarEvent({
    required this.id,
    required this.catNameTh,
    required this.catNameEn,
    required this.year,
    required this.month,
    required this.day,
    required this.titleTh,
    required this.titleEn,
    required this.pillLabel,
    required this.type,
    required this.dateTh,
    required this.dateEn,
    required this.daysLeft,
  });

  final String id;
  final String catNameTh;
  final String catNameEn;
  final int year;
  final int month;
  final int day;
  final String titleTh;
  final String titleEn;
  final String pillLabel;
  final HealthCalendarEventType type;
  final String dateTh;
  final String dateEn;
  final int daysLeft;

  @override
  List<Object?> get props => [
    id,
    catNameTh,
    catNameEn,
    year,
    month,
    day,
    titleTh,
    titleEn,
    pillLabel,
    type,
    dateTh,
    dateEn,
    daysLeft,
  ];
}

/// ชุดข้อมูลสมุดสุขภาพฉบับสมบูรณ์ของแมว 1 ตัว (/my-cat/health)
class CatHealthBook extends Equatable {
  const CatHealthBook({
    this.nextAppointment,
    this.records = const [],
    this.bodyReports = const [],
    this.vaccines = const [],
    this.parasitePrevention,
    this.allergyTh = 'ไม่มีประวัติแพ้ยา',
    this.allergyEn = 'No known drug allergies',
    this.pastIllnessTh = 'ไม่มี',
    this.pastIllnessEn = 'None',
    this.surgeryTh = 'ไม่มี',
    this.surgeryEn = 'None',
    this.remarksTh = '',
    this.remarksEn = '',
    this.medications = const [],
    this.weightHistory = const [],
    this.weightDeltaTh = '',
    this.weightDeltaEn = '',
    this.weightDropping = false,
    this.documents = const [],
    this.primaryConcernTh = 'ยังไม่มีข้อกังวลเร่งด่วน',
    this.primaryConcernEn = 'No urgent concerns recorded',
  });

  final HealthNextAppointment? nextAppointment;
  final List<HealthRecordEntry> records;
  final List<BodyOrganReport> bodyReports;
  final List<VaccineRecord> vaccines;
  final ParasitePreventionRecord? parasitePrevention;
  final String allergyTh;
  final String allergyEn;
  final String pastIllnessTh;
  final String pastIllnessEn;
  final String surgeryTh;
  final String surgeryEn;
  final String remarksTh;
  final String remarksEn;
  final List<MedicationItem> medications;
  final List<WeightPoint> weightHistory;
  final String weightDeltaTh;
  final String weightDeltaEn;
  final bool weightDropping;
  final List<HealthDocumentItem> documents;
  final String primaryConcernTh;
  final String primaryConcernEn;

  bool get isEmpty =>
      nextAppointment == null &&
      records.isEmpty &&
      vaccines.isEmpty &&
      medications.isEmpty &&
      weightHistory.isEmpty &&
      documents.isEmpty;

  BodyOrganReport reportFor(BodyOrganId organ) {
    for (final r in bodyReports) {
      if (r.organ == organ) return r;
    }
    return BodyOrganReport(organ: organ);
  }

  CatHealthBook copyWith({
    HealthNextAppointment? nextAppointment,
    List<HealthRecordEntry>? records,
    List<BodyOrganReport>? bodyReports,
    List<VaccineRecord>? vaccines,
    ParasitePreventionRecord? parasitePrevention,
    String? allergyTh,
    String? allergyEn,
    String? pastIllnessTh,
    String? pastIllnessEn,
    String? surgeryTh,
    String? surgeryEn,
    String? remarksTh,
    String? remarksEn,
    List<MedicationItem>? medications,
    List<WeightPoint>? weightHistory,
    String? weightDeltaTh,
    String? weightDeltaEn,
    bool? weightDropping,
    List<HealthDocumentItem>? documents,
    String? primaryConcernTh,
    String? primaryConcernEn,
  }) {
    return CatHealthBook(
      nextAppointment: nextAppointment ?? this.nextAppointment,
      records: records ?? this.records,
      bodyReports: bodyReports ?? this.bodyReports,
      vaccines: vaccines ?? this.vaccines,
      parasitePrevention: parasitePrevention ?? this.parasitePrevention,
      allergyTh: allergyTh ?? this.allergyTh,
      allergyEn: allergyEn ?? this.allergyEn,
      pastIllnessTh: pastIllnessTh ?? this.pastIllnessTh,
      pastIllnessEn: pastIllnessEn ?? this.pastIllnessEn,
      surgeryTh: surgeryTh ?? this.surgeryTh,
      surgeryEn: surgeryEn ?? this.surgeryEn,
      remarksTh: remarksTh ?? this.remarksTh,
      remarksEn: remarksEn ?? this.remarksEn,
      medications: medications ?? this.medications,
      weightHistory: weightHistory ?? this.weightHistory,
      weightDeltaTh: weightDeltaTh ?? this.weightDeltaTh,
      weightDeltaEn: weightDeltaEn ?? this.weightDeltaEn,
      weightDropping: weightDropping ?? this.weightDropping,
      documents: documents ?? this.documents,
      primaryConcernTh: primaryConcernTh ?? this.primaryConcernTh,
      primaryConcernEn: primaryConcernEn ?? this.primaryConcernEn,
    );
  }

  @override
  List<Object?> get props => [
    nextAppointment,
    records,
    bodyReports,
    vaccines,
    parasitePrevention,
    allergyTh,
    allergyEn,
    pastIllnessTh,
    pastIllnessEn,
    surgeryTh,
    surgeryEn,
    remarksTh,
    remarksEn,
    medications,
    weightHistory,
    weightDeltaTh,
    weightDeltaEn,
    weightDropping,
    documents,
    primaryConcernTh,
    primaryConcernEn,
  ];
}
