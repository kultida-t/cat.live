import '../entities/help_data.dart';

/// สัญญาการดึงและจัดการข้อมูลหน้าช่วยเหลือ (/help)
abstract interface class HelpRepository {
  Future<HelpSnapshot> fetchHelpData();

  Future<HelpPost> createHelpPost(CreateHelpPostInput input);

  Future<void> sendClue(String postId);

  Future<void> updatePostStatus(String postId, HelpPostStatus status);

  Future<void> setDonationClosed(String postId, bool isClosed);

  Future<void> updatePostContent(
    String postId, {
    required String title,
    required String summary,
    required String location,
  });
}
