import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/dio_treats_data_source.dart';
import '../../data/datasources/mock_treats_data_source.dart';
import '../../data/datasources/treats_remote_data_source.dart';
import '../../data/repositories/treats_repository_impl.dart';
import '../../domain/repositories/treats_repository.dart';
import '../../domain/usecases/load_treats_data.dart';

const _useMockData = bool.fromEnvironment('USE_MOCK_DATA', defaultValue: true);

final _treatsDioProvider = Provider<Dio>((ref) => createApiClient());

final treatsRemoteDataSourceProvider = Provider<TreatsRemoteDataSource>((ref) {
  return _useMockData
      ? const MockTreatsDataSource()
      : DioTreatsDataSource(ref.watch(_treatsDioProvider));
});

final treatsRepositoryProvider = Provider<TreatsRepository>(
  (ref) => TreatsRepositoryImpl(ref.watch(treatsRemoteDataSourceProvider)),
);

final loadTreatsDataProvider = Provider<LoadTreatsData>(
  (ref) => LoadTreatsData(ref.watch(treatsRepositoryProvider)),
);
