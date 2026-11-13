import '../entities/treats_data.dart';

abstract interface class TreatsRepository {
  Future<TreatsData> loadTreatsData();
}
