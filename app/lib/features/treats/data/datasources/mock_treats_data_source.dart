import '../../../feed/data/datasources/mock_accounts.dart';
import '../models/treats_models.dart';
import 'treats_remote_data_source.dart';

const _catProfileKeys = {'noon', 'guy', 'muk', 'vet', 'rescue', 'som'};

/// ข้อมูลตัวอย่างหน้าเลี้ยงขนมแมว — ตรงกับเว็บต้นแบบ www.แมว.live/treats
class MockTreatsDataSource implements TreatsRemoteDataSource {
  const MockTreatsDataSource();

  @override
  Future<TreatsDataModel> fetchTreatsData() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));

    final keys = mockAccountKeys.where((k) => k != mockMe).toList()
      ..sort((a, b) {
        final aHasCat = _catProfileKeys.contains(a) ? 1 : 0;
        final bHasCat = _catProfileKeys.contains(b) ? 1 : 0;
        return bHasCat.compareTo(aHasCat);
      });

    return TreatsDataModel.fromJson({
      'recipients': [
        for (final key in keys)
          {...mockAccountJson(key), 'has_cat': _catProfileKeys.contains(key)},
      ],
      'treats': const [
        {
          'id': 'lick',
          'name': 'ขนมแมวเลีย รสทูน่า',
          'name_en': 'Tuna Lickable Treats',
          'short_name': 'แมวเลีย',
          'short_name_en': 'Lickable',
          'sub_label': 'รสทูน่า',
          'sub_label_en': 'Tuna',
          'size': '4 ซอง',
          'size_en': '4 sachets',
          'price': 59,
          'pack_label': 'TUNA',
          'pack_size': '4 ซอง',
          'pack_color_hex': 0xFF76B9C8,
          'pack_shape': 'pouch',
        },
        {
          'id': 'crunch',
          'name': 'ขนมกรุบกรอบ รสไก่',
          'name_en': 'Chicken Crunch Bites',
          'short_name': 'กรุบกรอบ',
          'short_name_en': 'Crunch',
          'sub_label': 'รสไก่',
          'sub_label_en': 'Chicken',
          'size': '60 กรัม',
          'size_en': '60 g',
          'price': 89,
          'pack_label': 'CRUNCH',
          'pack_size': '60 กรัม',
          'pack_color_hex': 0xFFE7AB72,
          'pack_shape': 'pouch',
        },
        {
          'id': 'freeze',
          'name': 'ไก่ฟรีซดราย',
          'name_en': 'Freeze-Dried Chicken',
          'short_name': 'ฟรีซดราย',
          'short_name_en': 'Freeze-dried',
          'sub_label': 'ไก่',
          'sub_label_en': 'Chicken',
          'size': '40 กรัม',
          'size_en': '40 g',
          'price': 149,
          'pack_label': 'FREEZE DRIED',
          'pack_size': '40 กรัม',
          'pack_color_hex': 0xFFA5C7B5,
          'pack_shape': 'jar',
        },
        {
          'id': 'box',
          'name': 'กล่องขนมรวม',
          'name_en': 'Happy Treat Box',
          'short_name': 'กล่องรวม',
          'short_name_en': 'Gift Box',
          'sub_label': '6 ชิ้น',
          'sub_label_en': '6 items',
          'size': '6 ชิ้น',
          'size_en': '6 items',
          'price': 299,
          'pack_label': 'HAPPY BOX',
          'pack_size': '6 ชิ้น',
          'pack_color_hex': 0xFFD7A0A2,
          'pack_shape': 'box',
        },
      ],
    });
  }
}
