import '../entities/treats_data.dart';
import '../repositories/treats_repository.dart';

class LoadTreatsData {
  const LoadTreatsData(this._repository);

  final TreatsRepository _repository;

  Future<TreatsData> call() => _repository.loadTreatsData();
}
