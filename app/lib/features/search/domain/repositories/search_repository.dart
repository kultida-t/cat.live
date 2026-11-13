import '../entities/search_data.dart';

/// สัญญาดึงข้อมูลสำหรับหน้าค้นหา
abstract interface class SearchRepository {
  Future<SearchData> loadSearchData();
}
