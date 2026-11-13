import 'treat_item.dart';
import 'treat_recipient.dart';

/// ข้อมูลเริ่มต้นของหน้าเลี้ยงขนมแมว
class TreatsData {
  const TreatsData({required this.recipients, required this.treats});

  final List<TreatRecipient> recipients;
  final List<TreatItem> treats;
}
