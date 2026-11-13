import 'package:dio/dio.dart';

import '../../../../core/network/dio_failure_mapper.dart';
import '../../domain/entities/search_data.dart';
import '../../domain/repositories/search_repository.dart';
import '../datasources/search_remote_data_source.dart';

class SearchRepositoryImpl implements SearchRepository {
  const SearchRepositoryImpl(this._remote);

  final SearchRemoteDataSource _remote;

  @override
  Future<SearchData> loadSearchData() async {
    try {
      final model = await _remote.fetchSearchData();
      return model.toEntity();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
