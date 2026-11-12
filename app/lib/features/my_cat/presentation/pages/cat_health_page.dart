import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/config/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/toast_pill.dart';
import '../../domain/entities/my_cat_data.dart';
import '../providers/my_cat_controller.dart';
import '../widgets/health_body_tab.dart';
import '../widgets/health_calendar_tab.dart';
import '../widgets/health_documents_tab.dart';
import '../widgets/health_form_sheets.dart';
import '../widgets/health_history_tab.dart';
import '../widgets/health_medicine_tab.dart';
import '../widgets/health_vaccine_tab.dart';
import '../widgets/health_vet_summary_sheet.dart';
import '../widgets/health_weight_tab.dart';
import '../widgets/my_cat_l10n.dart';
import '../widgets/my_cat_skeleton.dart';

enum HealthBookTab {
  history('ประวัติ', 'History'),
  body('ร่างกาย', 'Body'),
  vaccine('สมุดวัคซีน', 'Vaccine book'),
  medicine('ยา', 'Medicine'),
  calendar('ปฏิทิน', 'Calendar'),
  weight('น้ำหนัก', 'Weight'),
  documents('เอกสาร', 'Documents');

  const HealthBookTab(this.thLabel, this.enLabel);
  final String thLabel;
  final String enLabel;
}

/// หน้าสมุดสุขภาพทั้งหมด (/my-cat/health) — เทียบตรงจาก www.แมว.live/my-cat/health
class CatHealthPage extends ConsumerStatefulWidget {
  const CatHealthPage({super.key});

  @override
  ConsumerState<CatHealthPage> createState() => _CatHealthPageState();
}

class _CatHealthPageState extends ConsumerState<CatHealthPage> with ToastMixin {
  String? _selectedCatId;
  HealthBookTab _activeTab = HealthBookTab.history;
  final Map<String, GlobalKey> _catChipKeys = {};
  final Map<HealthBookTab, GlobalKey> _tabKeys = {};
  final ScrollController _tabScrollCtrl = ScrollController();
  bool _canFadeTabsLeft = false;
  bool _canFadeTabsRight = true;
  String? _lastFocusedCatId;

  @override
  void initState() {
    super.initState();
    _tabScrollCtrl.addListener(_updateTabFade);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateTabFade());
  }

  @override
  void dispose() {
    _tabScrollCtrl.removeListener(_updateTabFade);
    _tabScrollCtrl.dispose();
    disposeToast();
    super.dispose();
  }

  void _updateTabFade() {
    if (!_tabScrollCtrl.hasClients) return;
    final pos = _tabScrollCtrl.position;
    final nextLeft = pos.pixels > 4;
    final nextRight =
        pos.maxScrollExtent > 4 && pos.pixels < pos.maxScrollExtent - 4;
    if ((nextLeft != _canFadeTabsLeft || nextRight != _canFadeTabsRight) &&
        mounted) {
      setState(() {
        _canFadeTabsLeft = nextLeft;
        _canFadeTabsRight = nextRight;
      });
    }
  }

  GlobalKey _catKey(String catId) =>
      _catChipKeys.putIfAbsent(catId, GlobalKey.new);

  GlobalKey _tabKey(HealthBookTab tab) =>
      _tabKeys.putIfAbsent(tab, GlobalKey.new);

  void _ensureVisible(GlobalKey? key, {required bool animate}) {
    if (key == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = key.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.5,
        duration: animate ? const Duration(milliseconds: 220) : Duration.zero,
        curve: Curves.easeOutCubic,
      );
    });
  }

  CatProfile? _resolveCat(MyCatState state) {
    final cats = state.bundle?.cats ?? const [];
    if (cats.isEmpty) return null;
    final targetId = _selectedCatId ?? state.selectedCat?.id;
    if (targetId != null) {
      for (final cat in cats) {
        if (cat.id == targetId) return cat;
      }
    }
    return cats.first;
  }

  void _selectTab(HealthBookTab tab) {
    if (_activeTab == tab) return;
    setState(() => _activeTab = tab);
    _ensureVisible(_tabKeys[tab], animate: true);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myCatControllerProvider);
    final locale = ref.watch(appLocaleProvider);
    final isEn =
        locale == 'en' || state.bundle?.owner.notifications.locale == 'en';
    final bundle = state.bundle;
    final cats = bundle?.cats ?? const <CatProfile>[];
    final activeCat = _resolveCat(state);

    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                _HealthHeader(
                  title: isEn ? 'Health book' : 'สมุดสุขภาพ',
                  backLabel: isEn ? 'Back' : 'ย้อนกลับ',
                  summaryTooltip: isEn
                      ? 'Create Vet Summary'
                      : 'สร้าง Vet Summary',
                  canOpenSummary: activeCat != null,
                  onBack: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/my-cat');
                    }
                  },
                  onOpenVetSummary: activeCat == null
                      ? null
                      : () => showVetSummarySheet(
                          context,
                          cats: cats,
                          initialCat: activeCat,
                          owner: bundle!.owner,
                          isEn: isEn,
                          onNotify: showToast,
                        ),
                ),
                Expanded(child: _buildBody(state, bundle, cats, activeCat, isEn)),
              ],
            ),
            if (toastMessage != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 18,
                child: Center(child: ToastPill(message: toastMessage!)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    MyCatState state,
    MyCatBundle? bundle,
    List<CatProfile> cats,
    CatProfile? activeCat,
    bool isEn,
  ) {
    switch (state.status) {
      case MyCatLoadStatus.loading:
        return const MyCatSkeleton();
      case MyCatLoadStatus.error:
        return ErrorView(
          message:
              state.errorMessage ??
              (isEn
                  ? 'Unable to load health book'
                  : 'โหลดข้อมูลสมุดสุขภาพไม่สำเร็จ'),
          onRetry: () => ref.read(myCatControllerProvider.notifier).load(),
        );
      case MyCatLoadStatus.ready:
        if (bundle == null || activeCat == null) {
          return _EmptyCatsHealthView(
            isEn: isEn,
            onGoMyCat: () => context.go('/my-cat'),
          );
        }

        if (_lastFocusedCatId != activeCat.id) {
          final isInitial = _lastFocusedCatId == null;
          _lastFocusedCatId = activeCat.id;
          _ensureVisible(_catChipKeys[activeCat.id], animate: !isInitial);
        }

        final controller = ref.read(myCatControllerProvider.notifier);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // แถวเลือกแมว (ชิดซ้ายตรงเว็บตัวอย่าง)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (var i = 0; i < cats.length; i++) ...[
                          if (i > 0) const SizedBox(width: 10),
                          _HealthCatChip(
                            key: _catKey(cats[i].id),
                            cat: cats[i],
                            selected: cats[i].id == activeCat.id,
                            isEn: isEn,
                            onTap: () {
                              setState(() => _selectedCatId = cats[i].id);
                              _ensureVisible(
                                _catChipKeys[cats[i].id],
                                animate: true,
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // แถบ 7 แท็บเลื่อนแนวนอนพร้อมเฟดจางขอบซ้าย/ขวาตามเว็บตัวอย่าง (ไม่มีปุ่มลูกศร)
            Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.line)),
              ),
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (bounds) {
                  final leftStop = _canFadeTabsLeft ? 0.08 : 0.0;
                  final rightStop = _canFadeTabsRight ? 0.90 : 1.0;
                  return LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      _canFadeTabsLeft ? Colors.transparent : Colors.black,
                      Colors.black,
                      Colors.black,
                      _canFadeTabsRight ? Colors.transparent : Colors.black,
                    ],
                    stops: [0.0, leftStop, rightStop, 1.0],
                  ).createShader(bounds);
                },
                child: SingleChildScrollView(
                  controller: _tabScrollCtrl,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      for (final tab in HealthBookTab.values)
                        _HealthSubTabButton(
                          key: _tabKey(tab),
                          label: isEn ? tab.enLabel : tab.thLabel,
                          selected: _activeTab == tab,
                          onTap: () => _selectTab(tab),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            // เนื้อหาของแท็บที่เลือก
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
                child: _buildTabContent(
                  tab: _activeTab,
                  cats: cats,
                  cat: activeCat,
                  owner: bundle.owner,
                  isEn: isEn,
                  controller: controller,
                ),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildTabContent({
    required HealthBookTab tab,
    required List<CatProfile> cats,
    required CatProfile cat,
    required OwnerProfile owner,
    required bool isEn,
    required MyCatController controller,
  }) {
    return switch (tab) {
      HealthBookTab.history => HealthHistoryTab(
        healthBook: cat.healthBook,
        isEn: isEn,
        onFindClinic: () => context.go('/nearby'),
        onAddRecord: () => showAddHealthRecordSheet(
          context,
          isEn: isEn,
          onSave: (entry) {
            _saveHealthRecordOrWeight(controller, cat.id, entry, isEn);
          },
        ),
      ),
      HealthBookTab.body => HealthBodyTab(
        cat: cat,
        isEn: isEn,
        onUploadDocument: () => _selectTab(HealthBookTab.documents),
      ),
      HealthBookTab.vaccine => HealthVaccineTab(
        cat: cat,
        owner: owner,
        isEn: isEn,
        onNotify: showToast,
        onAddVaccine: () => showAddVaccineSheet(
          context,
          isEn: isEn,
          onSave: (vaccine) {
            controller.addVaccineRecord(cat.id, vaccine);
            showToast(
              isEn ? 'Vaccination saved' : 'บันทึกวัคซีนเรียบร้อยแล้ว',
            );
          },
        ),
      ),
      HealthBookTab.medicine => HealthMedicineTab(
        medications: cat.healthBook.medications,
        isEn: isEn,
        onAddMedication: () => showAddMedicationSheet(
          context,
          isEn: isEn,
          onSave: (med) {
            controller.addMedication(cat.id, med);
            showToast(isEn ? 'Medication added' : 'เพิ่มรายการยาแล้ว');
          },
        ),
      ),
      HealthBookTab.calendar => HealthCalendarTab(
        cats: cats,
        initialCatId: cat.id,
        isEn: isEn,
        onQuickAddForDate: (targetCatId, category, title, dateTh, dateEn) =>
            _saveHealthRecordOrWeight(
              controller,
              targetCatId,
              HealthRecordEntry(
                id: 'cal-note-${DateTime.now().microsecondsSinceEpoch}',
                category: category,
                dateTh: dateTh,
                dateEn: dateEn,
                titleTh: title,
                titleEn: title,
              ),
              isEn,
            ),
      ),
      HealthBookTab.weight => HealthWeightTab(
        healthBook: cat.healthBook,
        latestWeightKg: cat.weightKg,
        isEn: isEn,
        onLogWeight: () => showAddHealthRecordSheet(
          context,
          isEn: isEn,
          initialCategory: HealthRecordCategory.weight,
          initialTitle: isEn ? 'Weight check' : 'ชั่งน้ำหนัก',
          onSave: (entry) {
            _saveHealthRecordOrWeight(controller, cat.id, entry, isEn);
          },
        ),
      ),
      HealthBookTab.documents => HealthDocumentsTab(
        documents: cat.healthBook.documents,
        isEn: isEn,
        onUploadTap: () => showUploadDocumentSheet(
          context,
          isEn: isEn,
          onNotify: showToast,
          onAddDocument: (doc) {
            controller.addHealthDocument(cat.id, doc);
            showToast(
              isEn ? 'Document added' : 'เพิ่มเอกสารสุขภาพแล้ว',
            );
          },
        ),
      ),
    };
  }

  void _saveHealthRecordOrWeight(
    MyCatController controller,
    String catId,
    HealthRecordEntry entry,
    bool isEn,
  ) {
    if (entry.category == HealthRecordCategory.weight) {
      final combined = '${entry.detailsTh} ${entry.titleTh}';
      final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(combined);
      final parsedKg = match != null ? double.tryParse(match.group(1)!) : null;
      if (parsedKg != null && parsedKg > 0 && parsedKg <= 30) {
        controller.logWeight(
          catId,
          weightKg: parsedKg,
          dateTh: entry.dateTh,
          dateEn: entry.dateEn,
          note: entry.detailsTh,
        );
        showToast(isEn ? 'Weight logged' : 'บันทึกน้ำหนักวันนี้แล้ว');
        return;
      }
    }
    controller.addHealthRecord(catId, entry);
    showToast(isEn ? 'Health note saved' : 'เพิ่มบันทึกสุขภาพแล้ว');
  }
}

class _HealthHeader extends StatelessWidget {
  const _HealthHeader({
    required this.title,
    required this.backLabel,
    required this.summaryTooltip,
    required this.canOpenSummary,
    required this.onBack,
    this.onOpenVetSummary,
  });

  final String title;
  final String backLabel;
  final String summaryTooltip;
  final bool canOpenSummary;
  final VoidCallback onBack;
  final VoidCallback? onOpenVetSummary;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      color: AppColors.page,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: backLabel,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(LucideIcons.chevronLeft, size: 22),
              color: AppColors.text,
              tooltip: backLabel,
            ),
          ),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ),
          if (canOpenSummary)
            Semantics(
              button: true,
              label: summaryTooltip,
              child: IconButton(
                onPressed: onOpenVetSummary,
                icon: const Icon(LucideIcons.scrollText, size: 20),
                color: AppColors.text,
                tooltip: summaryTooltip,
              ),
            ),
        ],
      ),
    );
  }
}

class _HealthCatChip extends StatelessWidget {
  const _HealthCatChip({
    super.key,
    required this.cat,
    required this.selected,
    required this.isEn,
    required this.onTap,
  });

  final CatProfile cat;
  final bool selected;
  final bool isEn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor = selected ? AppColors.btn : AppColors.card;
    final borderColor = selected ? AppColors.btnBorder : AppColors.line;
    final textColor = selected ? AppColors.ink : AppColors.text2;

    return Semantics(
      button: true,
      selected: selected,
      label: MyCatL10n.catName(cat.name, isEn),
      child: Material(
        color: bgColor,
        shape: StadiumBorder(side: BorderSide(color: borderColor, width: 1.5)),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.fromLTRB(4, 4, 14, 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppAvatar(
                  source: cat.avatarSource,
                  bg: cat.avatarBg,
                  size: 32,
                ),
                const SizedBox(width: 8),
                Text(
                  MyCatL10n.catName(cat.name, isEn),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HealthSubTabButton extends StatelessWidget {
  const _HealthSubTabButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppColors.text : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppColors.text : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyCatsHealthView extends StatelessWidget {
  const _EmptyCatsHealthView({required this.isEn, required this.onGoMyCat});

  final bool isEn;
  final VoidCallback onGoMyCat;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.soft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.heartPulse,
                size: 28,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isEn ? 'No cats added yet' : 'ยังไม่มีข้อมูลแมวในสมุดสุขภาพ',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isEn
                  ? 'Add your cat on the My Cat page first to start tracking vaccines, meds, and weight.'
                  : 'เพิ่มน้องแมวในหน้าแมวและฉันก่อน เพื่อเริ่มบันทึกวัคซีน ยา และกราฟน้ำหนัก',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onGoMyCat,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 44),
                backgroundColor: AppColors.text,
                foregroundColor: AppColors.card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(isEn ? 'Go to My Cat' : 'ไปหน้าแมวและฉัน'),
            ),
          ],
        ),
      ),
    );
  }
}
