/// ความผิดพลาดที่ชั้น domain/presentation รู้จัก — ข้อความเป็นภาษาไทยพร้อมโชว์ผู้ใช้
sealed class Failure implements Exception {
  const Failure(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'เชื่อมต่ออินเทอร์เน็ตไม่ได้ ลองใหม่อีกครั้ง',
  ]);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'ระบบขัดข้องชั่วคราว ลองใหม่อีกครั้ง']);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'กรุณาเข้าสู่ระบบอีกครั้ง']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'ไม่พบข้อมูลที่ต้องการ']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'เกิดข้อผิดพลาดที่ไม่คาดคิด']);
}
