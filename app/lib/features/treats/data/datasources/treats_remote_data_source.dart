import '../models/treats_models.dart';

abstract interface class TreatsRemoteDataSource {
  Future<TreatsDataModel> fetchTreatsData();
}
