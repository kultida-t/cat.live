import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/dio_my_cat_data_source.dart';
import '../../data/datasources/mock_my_cat_data_source.dart';
import '../../data/datasources/my_cat_remote_data_source.dart';
import '../../data/repositories/my_cat_repository_impl.dart';
import '../../domain/repositories/my_cat_repository.dart';
import '../../domain/usecases/my_cat_usecases.dart';

/// สลับ Mock ↔ Backend API จริงผ่าน `--dart-define=USE_MOCK_DATA=false`
const _useMockData = bool.fromEnvironment('USE_MOCK_DATA', defaultValue: true);

final myCatDioProvider = Provider<Dio>((ref) => createApiClient());

final myCatDataSourceProvider = Provider<MyCatRemoteDataSource>((ref) {
  return _useMockData
      ? MockMyCatDataSource()
      : DioMyCatDataSource(ref.watch(myCatDioProvider));
});

final myCatRepositoryProvider = Provider<MyCatRepository>(
  (ref) => MyCatRepositoryImpl(ref.watch(myCatDataSourceProvider)),
);

final getMyCatBundleProvider = Provider(
  (ref) => GetMyCatBundle(ref.watch(myCatRepositoryProvider)),
);

final toggleCareTaskProvider = Provider(
  (ref) => ToggleCareTask(ref.watch(myCatRepositoryProvider)),
);

final updateCatProfileProvider = Provider(
  (ref) => UpdateCatProfile(ref.watch(myCatRepositoryProvider)),
);

final addCatProfileProvider = Provider(
  (ref) => AddCatProfile(ref.watch(myCatRepositoryProvider)),
);

final updateOwnerProfileProvider = Provider(
  (ref) => UpdateOwnerProfile(ref.watch(myCatRepositoryProvider)),
);

final addCatPhotoProvider = Provider(
  (ref) => AddCatPhoto(ref.watch(myCatRepositoryProvider)),
);
