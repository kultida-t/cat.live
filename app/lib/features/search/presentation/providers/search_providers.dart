import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/dio_search_data_source.dart';
import '../../data/datasources/mock_search_data_source.dart';
import '../../data/datasources/search_remote_data_source.dart';
import '../../data/repositories/search_repository_impl.dart';
import '../../domain/repositories/search_repository.dart';
import '../../domain/usecases/load_search_data.dart';

const _useMockData = bool.fromEnvironment('USE_MOCK_DATA', defaultValue: true);

final _searchDioProvider = Provider<Dio>((ref) => createApiClient());

final searchRemoteDataSourceProvider = Provider<SearchRemoteDataSource>((ref) {
  return _useMockData
      ? const MockSearchDataSource()
      : DioSearchDataSource(ref.watch(_searchDioProvider));
});

final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => SearchRepositoryImpl(ref.watch(searchRemoteDataSourceProvider)),
);

final loadSearchDataProvider = Provider<LoadSearchData>(
  (ref) => LoadSearchData(ref.watch(searchRepositoryProvider)),
);
