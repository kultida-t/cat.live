import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/datasources/mock_nearby_data_source.dart';
import '../../data/datasources/nearby_remote_data_source.dart';
import '../../data/repositories/nearby_repository_impl.dart';
import '../../domain/repositories/nearby_repository.dart';
import 'nearby_controller.dart';

/// ผลลัพธ์การขอพิกัด GPS จากเครื่องผู้ใช้
sealed class NearbyLocationResult {
  const NearbyLocationResult();
}

class NearbyLocationSuccess extends NearbyLocationResult {
  const NearbyLocationSuccess(this.latitude, this.longitude);
  final double latitude;
  final double longitude;
}

class NearbyLocationDenied extends NearbyLocationResult {
  const NearbyLocationDenied();
}

/// บริการดึงพิกัดปัจจุบันจาก GPS (แยกไว้เพื่อให้เทสแทนที่ได้)
abstract class NearbyLocationService {
  Future<NearbyLocationResult> getCurrentLocation();
}

class GeolocatorNearbyLocationService implements NearbyLocationService {
  @override
  Future<NearbyLocationResult> getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return const NearbyLocationDenied();

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return const NearbyLocationDenied();
      }

      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        return NearbyLocationSuccess(lastKnown.latitude, lastKnown.longitude);
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 6),
        ),
      );
      return NearbyLocationSuccess(pos.latitude, pos.longitude);
    } catch (_) {
      return const NearbyLocationDenied();
    }
  }
}

final nearbyRemoteDataSourceProvider = Provider<NearbyRemoteDataSource>(
  (ref) => MockNearbyDataSource(),
);

final nearbyRepositoryProvider = Provider<NearbyRepository>(
  (ref) => NearbyRepositoryImpl(ref.watch(nearbyRemoteDataSourceProvider)),
);

final nearbyLocationServiceProvider = Provider<NearbyLocationService>(
  (ref) => GeolocatorNearbyLocationService(),
);

final nearbyControllerProvider =
    NotifierProvider<NearbyController, NearbyState>(NearbyController.new);
