import 'package:catlive/core/format/compact_count.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ต่ำกว่าพัน แสดงตามจริง', () {
    expect(compactCount(0), '0');
    expect(compactCount(999), '999');
  });

  test('พันขึ้นไปย่อเป็น K ทศนิยม 1 ตำแหน่ง ตัด .0 ทิ้ง', () {
    expect(compactCount(1000), '1K');
    expect(compactCount(1200), '1.2K');
    expect(compactCount(2500), '2.5K');
  });

  test('หมื่นขึ้นไปไม่มีทศนิยม', () {
    expect(compactCount(12000), '12K');
    expect(compactCount(15600), '16K');
  });
}
