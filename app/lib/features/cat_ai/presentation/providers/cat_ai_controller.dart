import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/media/strip_image_metadata.dart';
import '../../domain/entities/cat_ai_data.dart';
import '../../domain/repositories/cat_ai_repository.dart';
import 'cat_ai_providers.dart';

/// สถานะทั้งหมดของหน้า Cat AI (/cat-ai)
/// ประวัติแชทแยกตามแมวแต่ละตัว เพื่อไม่ให้คำตอบปนข้อมูลของแมวคนละตัว
class CatAiState {
  const CatAiState({
    this.isLoading = true,
    this.errorMessage,
    this.snapshot,
    this.selectedIndex = 0,
    this.threads = const {},
    this.isSending = false,
    this.detailedAnswers = true,
  });

  final bool isLoading;
  final String? errorMessage;
  final CatAiSnapshot? snapshot;
  final int selectedIndex;

  /// ประวัติแชทของแต่ละแมว ใช้ id ของแมวเป็นคีย์
  final Map<String, List<CatAiMessage>> threads;
  final bool isSending;
  final bool detailedAnswers;

  /// แมวที่กำลังเลือกอยู่ (null เมื่อยังไม่มีแมวในโปรไฟล์)
  CatAiCat? get selectedCat {
    final cats = snapshot?.cats ?? const <CatAiCat>[];
    if (cats.isEmpty) return null;
    return cats[selectedIndex % cats.length];
  }

  /// ประวัติแชทของแมวที่เลือกอยู่เท่านั้น
  List<CatAiMessage> get messages {
    final id = selectedCat?.id;
    return id == null ? const [] : (threads[id] ?? const []);
  }

  CatAiState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    CatAiSnapshot? snapshot,
    int? selectedIndex,
    Map<String, List<CatAiMessage>>? threads,
    bool? isSending,
    bool? detailedAnswers,
  }) {
    return CatAiState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      snapshot: snapshot ?? this.snapshot,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      threads: threads ?? this.threads,
      isSending: isSending ?? this.isSending,
      detailedAnswers: detailedAnswers ?? this.detailedAnswers,
    );
  }
}

final catAiControllerProvider = NotifierProvider<CatAiController, CatAiState>(
  CatAiController.new,
);

class CatAiController extends Notifier<CatAiState> {
  CatAiRepository get _repo => ref.read(catAiRepositoryProvider);

  @override
  CatAiState build() {
    Future.microtask(load);
    return const CatAiState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final data = await _repo.fetchSnapshot();
      state = state.copyWith(isLoading: false, snapshot: data);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// สลับไปแมวตัวถัดไปเมื่อกดชื่อ ประวัติของแต่ละตัวยังอยู่ครบ
  void nextCat() {
    final count = state.snapshot?.cats.length ?? 0;
    if (count < 2) return;
    state = state.copyWith(selectedIndex: (state.selectedIndex + 1) % count);
  }

  void setDetailedAnswers(bool detailed) {
    state = state.copyWith(detailedAnswers: detailed);
  }

  /// ล้างเฉพาะประวัติของแมวที่เลือกอยู่
  void clearMessages() {
    final id = state.selectedCat?.id;
    if (id == null) return;
    state = state.copyWith(threads: {...state.threads, id: const []});
  }

  /// ส่งข้อความและ/หรือรูปที่แนบให้แมวที่เลือกอยู่ ตอบกลับเข้าประวัติของแมวตัวนั้น
  /// รูปจะถูกลบข้อมูลแฝง (GPS/EXIF) ก่อนเก็บและส่งทุกครั้ง คืน false เมื่อส่งไม่สำเร็จ
  Future<bool> send(String text, {Uint8List? image}) async {
    final question = text.trim();
    if (question.isEmpty && image == null) return false;
    final cat = state.selectedCat;
    if (cat == null || state.isSending) return false;
    state = state.copyWith(isSending: true);
    try {
      final clean = image == null ? null : await stripImageMetadata(image);
      final prompt = question.isEmpty ? 'ส่งรูปแมวให้ดูอาการ' : question;
      _appendMessage(
        cat.id,
        CatAiMessage(text: question, isFromUser: true, imageBytes: clean),
      );
      final reply = clean == null
          ? CatAiMessage(
              text: await _repo.ask(prompt, detailed: state.detailedAnswers),
              isFromUser: false,
            )
          : await _imageReply(clean, prompt);
      _appendMessage(cat.id, reply);
      state = state.copyWith(isSending: false);
      return true;
    } catch (_) {
      state = state.copyWith(isSending: false);
      return false;
    }
  }

  Future<CatAiMessage> _imageReply(Uint8List bytes, String question) async {
    final r = await _repo.analyzeImage(bytes, question);
    return CatAiMessage(
      text: r.text,
      isFromUser: false,
      level: r.level,
      record: r.record,
    );
  }

  /// ยืนยันการ์ดสรุปเข้าประวัติ (ตอนนี้บันทึกในแชทเท่านั้น ยังไม่เขียนลงสมุดสุขภาพจริง)
  void confirmRecord(String catId, CatAiMessage target) {
    _updateRecord(catId, target, (r) => r.copyWith(saved: true));
  }

  /// แก้รายละเอียดในการ์ดก่อนยืนยัน ใช้ได้เฉพาะการ์ดที่ยังไม่ได้บันทึก
  void editRecordDetails(String catId, CatAiMessage target, String details) {
    _updateRecord(catId, target, (r) => r.copyWith(details: details));
  }

  void _updateRecord(
    String catId,
    CatAiMessage target,
    CatAiRecordSummary Function(CatAiRecordSummary) update,
  ) {
    final record = target.record;
    if (record == null || record.saved) return;
    final list = [...(state.threads[catId] ?? const <CatAiMessage>[])];
    final i = list.indexOf(target);
    if (i < 0) return;
    list[i] = target.copyWith(record: update(record));
    state = state.copyWith(threads: {...state.threads, catId: list});
  }

  void _appendMessage(String catId, CatAiMessage message) {
    final current = state.threads[catId] ?? const <CatAiMessage>[];
    state = state.copyWith(
      threads: {
        ...state.threads,
        catId: [...current, message],
      },
    );
  }
}
