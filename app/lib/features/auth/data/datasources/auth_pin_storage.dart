import '../../domain/entities/pin_account_record.dart';

/// สัญญาที่เก็บ PIN ผูกบัญชีบนเครื่องนี้ — เป็นข้อมูลลับต้องอยู่ใน
/// flutter_secure_storage เท่านั้น ห้ามใช้ shared_preferences หรือไฟล์ธรรมดา
abstract interface class AuthPinStorage {
  Future<List<PinAccountRecord>> readAll();
  Future<PinAccountRecord?> findByPhone(String phone);
  Future<PinAccountRecord?> findByUserId(String userId);
  Future<void> saveRecord(PinAccountRecord record);
  Future<void> deleteForUser(String userId);
}

/// Implementation แบบเก็บในหน่วยความจำสำหรับ UI Mock Baseline และ widget test
class InMemoryAuthPinStorage implements AuthPinStorage {
  final List<PinAccountRecord> _records = [];

  @override
  Future<List<PinAccountRecord>> readAll() async => List.unmodifiable(_records);

  @override
  Future<PinAccountRecord?> findByPhone(String phone) async {
    for (final record in _records) {
      if (record.phone == phone) return record;
    }
    return null;
  }

  @override
  Future<PinAccountRecord?> findByUserId(String userId) async {
    for (final record in _records) {
      if (record.userId == userId) return record;
    }
    return null;
  }

  @override
  Future<void> saveRecord(PinAccountRecord record) async {
    _records.removeWhere((r) => r.phone == record.phone);
    _records.add(record);
  }

  @override
  Future<void> deleteForUser(String userId) async {
    _records.removeWhere((r) => r.userId == userId);
  }
}
