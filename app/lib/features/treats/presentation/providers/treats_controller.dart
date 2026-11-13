import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/treat_item.dart';
import '../../domain/entities/treat_recipient.dart';
import 'treats_providers.dart';

enum TreatsStatus { loading, empty, error, ready }

enum TreatsStep { select, payment, success }

class TreatsState {
  const TreatsState({
    this.status = TreatsStatus.loading,
    this.step = TreatsStep.select,
    this.recipients = const [],
    this.treats = const [],
    this.selectedRecipientId = '',
    this.selectedTreatId = '',
    this.stepperQty = 1,
    this.cart = const {},
    this.note = '',
    this.hopTrigger = 0,
    this.openedFromPost = false,
    this.errorMessage,
  });

  final TreatsStatus status;
  final TreatsStep step;
  final List<TreatRecipient> recipients;
  final List<TreatItem> treats;
  final String selectedRecipientId;
  final String selectedTreatId;
  final int stepperQty;
  final Map<String, int> cart;
  final String note;
  final int hopTrigger;
  final bool openedFromPost;
  final String? errorMessage;

  TreatRecipient? get selectedRecipient {
    for (final r in recipients) {
      if (r.id == selectedRecipientId) return r;
    }
    return recipients.isNotEmpty ? recipients.first : null;
  }

  TreatItem? get selectedTreat {
    for (final t in treats) {
      if (t.id == selectedTreatId) return t;
    }
    return treats.isNotEmpty ? treats.first : null;
  }

  /// ย้ายผู้รับที่เลือกมาอยู่หน้าสุดของแถว 4 คน (ตรงกับเว็บต้นแบบ)
  List<TreatRecipient> get visibleRecipients {
    if (recipients.isEmpty) return const [];
    final chosen = selectedRecipient;
    if (chosen == null) return recipients.take(4).toList();
    return [
      chosen,
      ...recipients.where((r) => r.id != chosen.id),
    ].take(4).toList();
  }

  int get totalCount => cart.values.fold(0, (sum, q) => sum + q);

  int get totalPrice {
    var sum = 0;
    for (final t in treats) {
      sum += (cart[t.id] ?? 0) * t.price;
    }
    return sum;
  }

  TreatsState copyWith({
    TreatsStatus? status,
    TreatsStep? step,
    List<TreatRecipient>? recipients,
    List<TreatItem>? treats,
    String? selectedRecipientId,
    String? selectedTreatId,
    int? stepperQty,
    Map<String, int>? cart,
    String? note,
    int? hopTrigger,
    bool? openedFromPost,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TreatsState(
      status: status ?? this.status,
      step: step ?? this.step,
      recipients: recipients ?? this.recipients,
      treats: treats ?? this.treats,
      selectedRecipientId: selectedRecipientId ?? this.selectedRecipientId,
      selectedTreatId: selectedTreatId ?? this.selectedTreatId,
      stepperQty: stepperQty ?? this.stepperQty,
      cart: cart ?? this.cart,
      note: note ?? this.note,
      hopTrigger: hopTrigger ?? this.hopTrigger,
      openedFromPost: openedFromPost ?? this.openedFromPost,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final treatsControllerProvider = NotifierProvider.autoDispose
    .family<TreatsController, TreatsState, String?>(TreatsController.new);

class TreatsController extends Notifier<TreatsState> {
  TreatsController(this._initialRecipientId);

  final String? _initialRecipientId;

  @override
  TreatsState build() {
    Future.microtask(_load);
    return const TreatsState(status: TreatsStatus.loading);
  }

  Future<void> _load() async {
    try {
      final data = await ref.read(loadTreatsDataProvider)();
      if (data.recipients.isEmpty || data.treats.isEmpty) {
        state = state.copyWith(status: TreatsStatus.empty, clearError: true);
        return;
      }

      var recipients = data.recipients;
      var selectedId = recipients.first.id;
      var fromPost = false;

      final toId = _initialRecipientId?.trim();
      if (toId != null && toId.isNotEmpty) {
        final match = recipients.where((r) => r.id == toId).toList();
        if (match.isNotEmpty) {
          selectedId = match.first.id;
          fromPost = true;
          recipients = [
            match.first,
            ...recipients.where((r) => r.id != selectedId),
          ];
        }
      }

      state = state.copyWith(
        status: TreatsStatus.ready,
        recipients: recipients,
        treats: data.treats,
        selectedRecipientId: selectedId,
        selectedTreatId: data.treats.first.id,
        openedFromPost: fromPost,
        clearError: true,
      );
    } on Failure catch (f) {
      state = state.copyWith(
        status: TreatsStatus.error,
        errorMessage: f.message,
      );
    } catch (_) {
      state = state.copyWith(
        status: TreatsStatus.error,
        errorMessage: 'ไม่สามารถโหลดข้อมูลได้ในขณะนี้',
      );
    }
  }

  Future<void> retry() async {
    state = state.copyWith(status: TreatsStatus.loading, clearError: true);
    await _load();
  }

  void selectRecipient(String id) {
    state = state.copyWith(selectedRecipientId: id);
  }

  void selectTreat(String id) {
    if (state.selectedTreatId == id) return;
    state = state.copyWith(selectedTreatId: id, stepperQty: 1);
  }

  void decrementQty() {
    if (state.stepperQty <= 1) return;
    state = state.copyWith(stepperQty: state.stepperQty - 1);
  }

  void incrementQty() {
    if (state.stepperQty >= 9) return;
    state = state.copyWith(stepperQty: state.stepperQty + 1);
  }

  void addToCart() {
    final id = state.selectedTreatId;
    if (id.isEmpty) return;
    final next = Map<String, int>.from(state.cart);
    final current = next[id] ?? 0;
    next[id] = (current + state.stepperQty).clamp(1, 20);
    state = state.copyWith(
      cart: next,
      stepperQty: 1,
      hopTrigger: state.hopTrigger + 1,
    );
  }

  void removeFromCart(String treatId) {
    final next = Map<String, int>.from(state.cart)..remove(treatId);
    state = state.copyWith(cart: next);
  }

  void updateNote(String value) {
    state = state.copyWith(note: value);
  }

  void goToPayment() {
    if (state.totalCount == 0) return;
    state = state.copyWith(step: TreatsStep.payment);
  }

  void backToSelect() {
    state = state.copyWith(step: TreatsStep.select);
  }

  void markPaid() {
    state = state.copyWith(step: TreatsStep.success);
  }

  void resetForAnother() {
    state = state.copyWith(
      step: TreatsStep.select,
      cart: const {},
      note: '',
      stepperQty: 1,
    );
  }
}
