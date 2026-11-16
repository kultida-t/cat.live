import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/dio_tag_data_source.dart';
import '../../data/datasources/mock_tag_data_source.dart';
import '../../data/datasources/tag_remote_data_source.dart';
import '../../data/repositories/tag_repository_impl.dart';
import '../../domain/repositories/tag_repository.dart';
import '../../domain/usecases/load_tag_product.dart';

const _useMockData = bool.fromEnvironment('USE_MOCK_DATA', defaultValue: true);

final _tagDioProvider = Provider<Dio>((ref) => createApiClient());

final tagRemoteDataSourceProvider = Provider<TagRemoteDataSource>((ref) {
  return _useMockData
      ? const MockTagDataSource()
      : DioTagDataSource(ref.watch(_tagDioProvider));
});

final tagRepositoryProvider = Provider<TagRepository>(
  (ref) => TagRepositoryImpl(ref.watch(tagRemoteDataSourceProvider)),
);

final loadTagProductProvider = Provider<LoadTagProduct>(
  (ref) => LoadTagProduct(ref.watch(tagRepositoryProvider)),
);
