import '../../domain/entities/nearby_data.dart';
import '../../domain/repositories/nearby_repository.dart';
import '../datasources/nearby_remote_data_source.dart';

/// ตัวเชื่อมข้อมูลหน้าใกล้ฉันระหว่าง Controller กับ DataSource
class NearbyRepositoryImpl implements NearbyRepository {
  const NearbyRepositoryImpl(this._dataSource);

  final NearbyRemoteDataSource _dataSource;

  @override
  Future<NearbySnapshot> fetchNearby() => _dataSource.fetchNearby();

  @override
  Future<Set<String>> toggleBookmark(String placeId) =>
      _dataSource.toggleBookmark(placeId);
}
