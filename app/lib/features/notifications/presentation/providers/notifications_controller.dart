import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/app_notification.dart';
import 'notifications_providers.dart';

class NotificationsState {
  const NotificationsState({
    this.isLoading = true,
    this.failure,
    this.items = const [],
    this.filter = NotificationFilter.all,
  });

  final bool isLoading;
  final Failure? failure;
  final List<AppNotification> items;
  final NotificationFilter filter;

  int get unreadCount => items.where((item) => !item.isRead).length;

  List<AppNotification> get visibleItems {
    if (filter == NotificationFilter.unread) {
      return items.where((item) => !item.isRead).toList();
    }
    return items;
  }

  NotificationsState copyWith({
    bool? isLoading,
    Failure? failure,
    bool clearFailure = false,
    List<AppNotification>? items,
    NotificationFilter? filter,
  }) {
    return NotificationsState(
      isLoading: isLoading ?? this.isLoading,
      failure: clearFailure ? null : (failure ?? this.failure),
      items: items ?? this.items,
      filter: filter ?? this.filter,
    );
  }
}

class NotificationsController extends Notifier<NotificationsState> {
  @override
  NotificationsState build() {
    Future.microtask(load);
    return const NotificationsState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    try {
      final items = await ref.read(loadNotificationsProvider)();
      state = state.copyWith(isLoading: false, items: items);
    } on Failure catch (f) {
      state = state.copyWith(isLoading: false, failure: f);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        failure: const UnknownFailure('โหลดการแจ้งเตือนไม่สำเร็จ'),
      );
    }
  }

  Future<void> refresh() => load();

  Future<void> retry() => load();

  void setFilter(NotificationFilter filter) {
    if (state.filter == filter) return;
    state = state.copyWith(filter: filter);
  }

  Future<Failure?> markAsRead(String id) async {
    final targetIndex = state.items.indexWhere((e) => e.id == id);
    if (targetIndex == -1 || state.items[targetIndex].isRead) return null;

    final previous = state.items;
    final updated = [
      for (final item in previous)
        if (item.id == id) item.copyWith(isRead: true) else item,
    ];
    state = state.copyWith(items: updated);

    try {
      await ref.read(markNotificationReadProvider)(id);
      return null;
    } on Failure catch (f) {
      state = state.copyWith(items: previous);
      return f;
    } catch (_) {
      state = state.copyWith(items: previous);
      return const UnknownFailure('อัปเดตสถานะการอ่านไม่สำเร็จ');
    }
  }

  Future<Failure?> markAllAsRead() async {
    if (state.unreadCount == 0) return null;

    final previous = state.items;
    final updated = [for (final item in previous) item.copyWith(isRead: true)];
    state = state.copyWith(items: updated);

    try {
      await ref.read(markAllNotificationsReadProvider)();
      return null;
    } on Failure catch (f) {
      state = state.copyWith(items: previous);
      return f;
    } catch (_) {
      state = state.copyWith(items: previous);
      return const UnknownFailure('อัปเดตการอ่านทั้งหมดไม่สำเร็จ');
    }
  }
}

final notificationsControllerProvider =
    NotifierProvider<NotificationsController, NotificationsState>(
      NotificationsController.new,
    );

/// จำนวนแจ้งเตือนที่ยังไม่อ่าน — ใช้ซิงก์จุดแดงบนหัวหน้าแรกและหน้าฟีด
final unreadNotificationsCountProvider = Provider<int>((ref) {
  return ref.watch(
    notificationsControllerProvider.select((s) => s.unreadCount),
  );
});
