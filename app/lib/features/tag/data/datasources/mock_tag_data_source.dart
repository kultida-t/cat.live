import '../../domain/entities/tag_product_data.dart';
import '../models/tag_product_models.dart';
import 'tag_remote_data_source.dart';

/// ข้อมูลตัวอย่างของหน้า แมว.live Tag ตรงกับเว็บต้นแบบ www.แมว.live/tag
class MockTagDataSource implements TagRemoteDataSource {
  const MockTagDataSource();

  @override
  Future<TagProductDto> fetchTagProduct() async {
    return const TagProductDto(
      priceThb: 990,
      tagColors: [
        TagColorOptionDto(
          id: 'teal',
          nameTh: 'เขียวมิ้นต์',
          nameEn: 'Mint green',
          colorValue: 0xFF328F87,
        ),
        TagColorOptionDto(
          id: 'cream',
          nameTh: 'ครีม',
          nameEn: 'Cream',
          colorValue: 0xFFDFC8A3,
        ),
        TagColorOptionDto(
          id: 'pink',
          nameTh: 'ชมพู',
          nameEn: 'Pink',
          colorValue: 0xFFCE929C,
        ),
        TagColorOptionDto(
          id: 'white',
          nameTh: 'ขาว',
          nameEn: 'White',
          colorValue: 0xFFF2F0EB,
        ),
        TagColorOptionDto(
          id: 'black',
          nameTh: 'ดำ',
          nameEn: 'Black',
          colorValue: 0xFF2A2A2D,
        ),
      ],
      collarColors: [
        TagColorOptionDto(
          id: 'navy',
          nameTh: 'กรมท่า',
          nameEn: 'Navy',
          colorValue: 0xFF2F3B66,
        ),
        TagColorOptionDto(
          id: 'peach',
          nameTh: 'ชมพูพีช',
          nameEn: 'Peach pink',
          colorValue: 0xFFF4A7B0,
        ),
        TagColorOptionDto(
          id: 'mint',
          nameTh: 'มิ้นต์',
          nameEn: 'Mint',
          colorValue: 0xFF8FD3BF,
        ),
        TagColorOptionDto(
          id: 'butter',
          nameTh: 'เหลืองบัตเตอร์',
          nameEn: 'Butter yellow',
          colorValue: 0xFFF6D47A,
        ),
        TagColorOptionDto(
          id: 'ivory',
          nameTh: 'ขาวนวล',
          nameEn: 'Ivory',
          colorValue: 0xFFF6F1E7,
        ),
        TagColorOptionDto(
          id: 'black',
          nameTh: 'ดำ',
          nameEn: 'Black',
          colorValue: 0xFF2B2B2E,
        ),
      ],
      engraveColors: [
        TagColorOptionDto(
          id: 'black',
          nameTh: 'ดำ',
          nameEn: 'Black',
          colorValue: 0xFF2A2A2D,
        ),
        TagColorOptionDto(
          id: 'white',
          nameTh: 'ขาว',
          nameEn: 'White',
          colorValue: 0xFFF2F0EB,
        ),
        TagColorOptionDto(
          id: 'orange',
          nameTh: 'ส้ม',
          nameEn: 'Orange',
          colorValue: 0xFFE68A5C,
        ),
        TagColorOptionDto(
          id: 'navy',
          nameTh: 'กรมท่า',
          nameEn: 'Navy',
          colorValue: 0xFF2F3B66,
        ),
        TagColorOptionDto(
          id: 'olive',
          nameTh: 'เขียวมะกอก',
          nameEn: 'Olive',
          colorValue: 0xFF6B7B4B,
        ),
        TagColorOptionDto(
          id: 'mint',
          nameTh: 'มิ้นต์',
          nameEn: 'Mint',
          colorValue: 0xFF8FD3BF,
        ),
      ],
      specs: [
        TagSpecItem(
          labelTh: 'ขนาด',
          labelEn: 'Size',
          valueTh: 'Ø 32 มม. หนา 8 มม.',
          valueEn: 'Ø 32 mm · 8 mm thick',
        ),
        TagSpecItem(
          labelTh: 'น้ำหนัก',
          labelEn: 'Weight',
          valueTh: '8 กรัม (รวมซองปลอกคอ)',
          valueEn: '8 g (with collar pouch)',
        ),
        TagSpecItem(
          labelTh: 'แบตเตอรี่',
          labelEn: 'Battery',
          valueTh: 'ถ่านกระดุม CR2032 ใช้ได้ราว 12 เดือน เปลี่ยนเองได้',
          valueEn: 'CR2032 coin cell · ~12 months · replaceable',
        ),
        TagSpecItem(
          labelTh: 'กันน้ำ',
          labelEn: 'Water-resistant',
          valueTh: 'IP67 กันฝนและน้ำกระเซ็น ไม่ควรแช่น้ำนาน',
          valueEn: 'IP67 · fine in rain and splashes, avoid soaking',
        ),
        TagSpecItem(
          labelTh: 'การเชื่อมต่อ',
          labelEn: 'Connectivity',
          valueTh: 'Bluetooth 5.3 · หาผ่านมือถือคนในเครือข่าย แมว.live',
          valueEn: 'Bluetooth 5.3 · แมว.live anonymous relay network',
        ),
        TagSpecItem(
          labelTh: 'ใช้กับ',
          labelEn: 'Compatibility',
          valueTh: 'iOS 15+ / Android 9+ ผ่านแอป แมว.live',
          valueEn: 'iOS 15+ / Android 9+ via แมว.live app',
        ),
        TagSpecItem(
          labelTh: 'ในกล่อง',
          labelEn: 'In the box',
          valueTh: 'แท็ก 1 ชิ้น · ซองติดปลอกคอ · ถ่าน CR2032 · คู่มือ',
          valueEn: '1 Tag · collar pouch · CR2032 battery · guide',
        ),
        TagSpecItem(
          labelTh: 'สลักชื่อ',
          labelEn: 'Engraving',
          valueTh: 'ฟรี ชื่อน้องสูงสุด 10 ตัวอักษร หรือหน้าแมว',
          valueEn: 'Free name up to 10 characters or cat face',
        ),
        TagSpecItem(
          labelTh: 'สี',
          labelEn: 'Color',
          valueTh: 'เขียวทีล · ครีม · ชมพู · ขาว · ดำ',
          valueEn: 'Mint green · Cream · Pink · White · Black',
        ),
        TagSpecItem(
          labelTh: 'รับประกัน',
          labelEn: 'Warranty',
          valueTh: '1 ปี · เปลี่ยนเครื่องใหม่ถ้าเสียจากการผลิต',
          valueEn: '1 year · replacement for manufacturing defects',
        ),
      ],
    );
  }
}
