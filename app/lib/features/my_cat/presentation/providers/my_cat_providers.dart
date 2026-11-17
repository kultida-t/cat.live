import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/token_provider.dart';
import '../../data/datasources/avatar_api.dart';
import '../../data/datasources/dio_my_cat_data_source.dart';
import '../../data/datasources/mock_my_cat_data_source.dart';
import '../../data/datasources/my_cat_remote_data_source.dart';
import '../../data/repositories/my_cat_repository_impl.dart';
import '../../domain/repositories/my_cat_repository.dart';
import '../../domain/usecases/my_cat_usecases.dart';

/// สลับหน้าแมวและฉันไป Backend จริงด้วย `--dart-define=USE_REAL_MY_CAT=true` (ค่าเริ่มต้นเป็นข้อมูลตัวอย่าง)
const _useRealMyCat = bool.fromEnvironment(
  'USE_REAL_MY_CAT',
  defaultValue: false,
);

final myCatDioProvider = Provider<Dio>(
  (ref) => createApiClient(tokens: ref.watch(appTokenProvider)),
);

final myCatDataSourceProvider = Provider<MyCatRemoteDataSource>((ref) {
  return _useRealMyCat
      ? DioMyCatDataSource(ref.watch(myCatDioProvider))
      : MockMyCatDataSource();
});

/// เปิดหน้าแมวและฉันกับ Backend จริงหรือไม่ — ใช้ตัดสินว่าจะเปิดการอัปโหลดรูปโปรไฟล์หรือไม่
final useRealMyCatProvider = Provider<bool>((ref) => _useRealMyCat);

final avatarApiProvider = Provider<AvatarApi>(
  (ref) => AvatarApi(ref.watch(myCatDioProvider)),
);

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
