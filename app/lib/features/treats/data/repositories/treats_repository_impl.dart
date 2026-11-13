import 'package:dio/dio.dart';

import '../../../../core/network/dio_failure_mapper.dart';
import '../../domain/entities/treats_data.dart';
import '../../domain/repositories/treats_repository.dart';
import '../datasources/treats_remote_data_source.dart';

class TreatsRepositoryImpl implements TreatsRepository {
  const TreatsRepositoryImpl(this._remote);

  final TreatsRemoteDataSource _remote;

  @override
  Future<TreatsData> loadTreatsData() async {
    try {
      final model = await _remote.fetchTreatsData();
      return model.toEntity();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
