import '../../../feed/data/datasources/mock_accounts.dart';
import '../models/search_models.dart';
import 'search_remote_data_source.dart';

const _postDir = 'asset:assets/images/posts';

/// ข้อมูลตัวอย่างหน้าค้นหา — ตรงกับเว็บต้นแบบ www.แมว.live/search
class MockSearchDataSource implements SearchRemoteDataSource {
  const MockSearchDataSource();

  @override
  Future<SearchDataModel> fetchSearchData() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return SearchDataModel.fromJson({
      'trending_keywords': const [
        'กินน้ำ',
        'ลูกแมว',
        'คาเฟ่',
        'แมวสูงวัย',
        'หาบ้าน',
      ],
      'accounts': [for (final key in mockAccountKeys) mockAccountJson(key)],
      'posts': const [
        {
          'id': 'p1',
          'category': 'daily',
          'category_label': 'ชีวิตแมว',
          'caption': 'ตื่นมาเจอนอนกอดตุ๊กตาแบบนี้ วันหยุดที่ดีที่สุดแล้ว 🧸',
          'author_name': 'นุ่น & โมจิ',
          'author_handle': 'noon.mochi',
          'time_text': '2 ชม.',
          'thumbnail_url': '$_postDir/1759588032622-1388cf9505ad.jpg',
          'thumbnail_alt': 'แมวส้มนอนหลับบนเตียง',
          'place': 'กับน้องโมจิ',
        },
        {
          'id': 'p2',
          'category': 'learn',
          'category_label': 'ความรู้',
          'caption': 'แมวควรกินน้ำวันละเท่าไหร่? ประมาณ 40–60 มล. ต่อน้ำหนักตัว 1 กก. ปัดดูวิธีสังเกตว่าน้องดื่มน้อยเกินไป 👉',
          'author_name': 'หมอแมว Vet Note',
          'author_handle': 'maew.vetnote',
          'time_text': '4 ชม.',
          'thumbnail_url': '$_postDir/1478098711619-5ab0b478d6e6.jpg',
          'thumbnail_alt': 'แมวลายสลิดระยะใกล้',
          'place': '',
        },
        {
          'id': 'p3',
          'category': 'health',
          'category_label': 'คำถาม · สุขภาพ',
          'caption':
              'แมวอายุ 12 ปี กินน้ำเยอะขึ้นกว่าปกติ ควรพาไปตรวจอะไรบ้างครับ',
          'author_name': 'กาย · แมวสูงวัย',
          'author_handle': 'guy.oldcat',
          'time_text': '5 ชม.',
          'thumbnail_url': '$_postDir/1514888286974-6c03e2ca1dba.jpg',
          'thumbnail_alt': 'แมวขาวดำนอนบนเก้าอี้ไม้ไผ่',
          'place': '',
        },
        {
          'id': 'p4',
          'category': 'nearby',
          'category_label': 'ใกล้ฉัน',
          'caption':
              'คาเฟ่แถวอารีย์เปิดโซนให้พาแมวมาได้แล้ว มีที่นั่งแยกเงียบ ๆ ด้วย',
          'author_name': 'มุก อารีย์',
          'author_handle': 'muk.ari',
          'time_text': '1 ชม.',
          'thumbnail_url': '$_postDir/1495360010541-f48722b34f7d.jpg',
          'thumbnail_alt': 'แมวลายสลิดบนบันได',
          'place': 'อารีย์ · ห่างจากคุณ 900 ม.',
        },
        {
          'id': 'p5',
          'category': 'rescue',
          'category_label': 'ช่วยแมว',
          'caption': 'พบลูกแมว 3 ตัวหลังตลาด ต้องการบ้านอุปการะชั่วคราว ใครสะดวกทักมาได้เลยค่ะ 🙏',
          'author_name': 'ช่วยแมวกรุงเทพ',
          'author_handle': 'rescue.bkk',
          'time_text': '30 นาที',
          'thumbnail_url': '$_postDir/1561948955-570b270e7c36.jpg',
          'thumbnail_alt': 'ลูกแมวสีขาว',
          'place': 'ลาดพร้าว 71',
        },
      ],
    });
  }
}
