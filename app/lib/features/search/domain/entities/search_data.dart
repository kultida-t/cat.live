import 'search_account.dart';
import 'search_post.dart';

/// ข้อมูลทั้งหมดที่ใช้ในหน้าค้นหา (คำค้นยอดนิยม, บัญชี, โพสต์แนะนำ)
class SearchData {
  const SearchData({
    required this.trendingKeywords,
    required this.accounts,
    required this.posts,
  });

  final List<String> trendingKeywords;
  final List<SearchAccount> accounts;
  final List<SearchPost> posts;
}
