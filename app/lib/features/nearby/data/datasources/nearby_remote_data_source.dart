import '../../domain/entities/nearby_data.dart';

/// แหล่งข้อมูลสำหรับหน้าใกล้ฉัน (รองรับสลับจาก Mock เป็น API จริงในเฟสถัดไป)
abstract class NearbyRemoteDataSource {
  Future<NearbySnapshot> fetchNearby();

  Future<Set<String>> toggleBookmark(String placeId);
}
