import '../models/search_models.dart';

/// แหล่งข้อมูลระยะไกลสำหรับหน้าค้นหา (สลับระหว่าง Mock กับ Dio ได้)
abstract interface class SearchRemoteDataSource {
  Future<SearchDataModel> fetchSearchData();
}
