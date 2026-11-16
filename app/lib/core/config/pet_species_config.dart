import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_config.dart';

/// ชนิดสัตว์เลี้ยงหลักของแอป — แยกคอนฟิกเฉพาะ "แมว" ออกจาก UI เพื่อพร้อมต่อยอดเป็น "หมา.live"
enum PetSpecies { cat, dog }

/// คอนฟิกระดับแอปตามชนิดสัตว์เลี้ยง (Species-Specific Configuration)
class PetSpeciesConfig {
  const PetSpeciesConfig({
    required this.species,
    required this.brandNameTh,
    required this.brandNameEn,
    required this.petNounTh,
    required this.petNounEn,
    required this.aiAssistantName,
    required this.tagProductNameTh,
    required this.tagProductNameEn,
    required this.webOrigin,
    required this.defaultBreedsTh,
    required this.defaultBreedsEn,
  });

  final PetSpecies species;
  final String brandNameTh;
  final String brandNameEn;
  final String petNounTh;
  final String petNounEn;
  final String aiAssistantName;
  final String tagProductNameTh;
  final String tagProductNameEn;
  final String webOrigin;
  final List<String> defaultBreedsTh;
  final List<String> defaultBreedsEn;

  String brandName(bool isEn) => isEn ? brandNameEn : brandNameTh;
  String petNoun(bool isEn) => isEn ? petNounEn : petNounTh;
  String tagProductName(bool isEn) =>
      isEn ? tagProductNameEn : tagProductNameTh;
  List<String> defaultBreeds(bool isEn) =>
      isEn ? defaultBreedsEn : defaultBreedsTh;

  /// คอนฟิกเริ่มต้นสำหรับแอป แมว.live
  static const cat = PetSpeciesConfig(
    species: PetSpecies.cat,
    brandNameTh: 'แมว.live',
    brandNameEn: 'Maew.live',
    petNounTh: 'แมว',
    petNounEn: 'Cat',
    aiAssistantName: 'Cat AI',
    tagProductNameTh: 'แมว.live Tag',
    tagProductNameEn: 'Maew.live Tag',
    webOrigin: AppConfig.webOrigin,
    defaultBreedsTh: [
      'ไทย (วิเชียรมาศ / ขาวมณี / สีสวาด / ศุภลักษณ์)',
      'บริติช ชอร์ตแฮร์',
      'สก็อตติช โฟลด์',
      'อเมริกัน ชอร์ตแฮร์',
      'เปอร์เซีย',
      'แร็กดอลล์',
      'เมนคูน',
      'เบงกอล',
      'แมวบ้าน / พันธุ์ผสม',
    ],
    defaultBreedsEn: [
      'Thai (Siamese / Khao Manee / Korat)',
      'British Shorthair',
      'Scottish Fold',
      'American Shorthair',
      'Persian',
      'Ragdoll',
      'Maine Coon',
      'Bengal',
      'Domestic / Mixed',
    ],
  );

  /// คอนฟิกเตรียมพร้อมสำหรับการต่อยอดเป็น หมา.live
  static const dog = PetSpeciesConfig(
    species: PetSpecies.dog,
    brandNameTh: 'หมา.live',
    brandNameEn: 'Ma.live',
    petNounTh: 'หมา',
    petNounEn: 'Dog',
    aiAssistantName: 'Dog AI',
    tagProductNameTh: 'หมา.live Tag',
    tagProductNameEn: 'Ma.live Tag',
    webOrigin: 'https://ma.live',
    defaultBreedsTh: [
      'ไทยหลังอาน / บางแก้ว',
      'ปอมเมอเรเนียน',
      'ชิวาวา',
      'คอร์กี้',
      'พุดเดิ้ล',
      'โกลเด้น รีทรีฟเวอร์',
      'เฟรนช์ บูลด็อก',
      'ชิบะ อินุ',
      'สุนัขบ้าน / พันธุ์ผสม',
    ],
    defaultBreedsEn: [
      'Thai Ridgeback / Bangkaew',
      'Pomeranian',
      'Chihuahua',
      'Corgi',
      'Poodle',
      'Golden Retriever',
      'French Bulldog',
      'Shiba Inu',
      'Mixed Breed',
    ],
  );
}

/// Provider กลางสำหรับอ่านคอนฟิกชนิดสัตว์เลี้ยง (ค่าเริ่มต้น: แมว.live)
final petSpeciesConfigProvider = Provider<PetSpeciesConfig>(
  (ref) => PetSpeciesConfig.cat,
);
