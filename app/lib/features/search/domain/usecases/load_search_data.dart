import '../entities/search_data.dart';
import '../repositories/search_repository.dart';

/// กรณีใช้งาน: โหลดข้อมูลเริ่มต้นสำหรับหน้าค้นหา
class LoadSearchData {
  const LoadSearchData(this._repository);

  final SearchRepository _repository;

  Future<SearchData> call() => _repository.loadSearchData();
}
