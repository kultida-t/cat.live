import '../entities/nearby_data.dart';

/// สัญญาดึงข้อมูลหน้าใกล้ฉันและบันทึกรายการโปรด
abstract class NearbyRepository {
  Future<NearbySnapshot> fetchNearby();

  Future<Set<String>> toggleBookmark(String placeId);
}
