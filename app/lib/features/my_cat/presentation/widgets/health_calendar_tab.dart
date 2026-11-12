import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/datasources/mock_health_books.dart';
import '../../domain/entities/my_cat_data.dart';
import 'health_shared_widgets.dart';
import 'my_cat_l10n.dart';

/// แท็บ 5: ปฏิทินนัดหมายรวมของแมวทุกตัวและรายการที่กำลังจะถึง — เทียบตรงเว็บ www.แมว.live
class HealthCalendarTab extends StatefulWidget {
  const HealthCalendarTab({
    super.key,
    required this.cats,
    required this.initialCatId,
    required this.isEn,
    required this.onQuickAddForDate,
  });

  final List<CatProfile> cats;
  final String initialCatId;
  final bool isEn;
  final void Function(
    String catId,
    HealthRecordCategory category,
    String title,
    String dateTh,
    String dateEn,
  ) onQuickAddForDate;

  @override
  State<HealthCalendarTab> createState() => _HealthCalendarTabState();
}

class _HealthCalendarTabState extends State<HealthCalendarTab> {
  // เริ่มที่เดือน พ.ย. 2569 (2026) และวันที่ 12 (วันนี้) ตามหน้าต้นแบบจริง
  int _year = 2026;
  int _month = 11;
  int _selectedDay = 12;
  late String _quickCatId = widget.initialCatId;
  HealthRecordCategory _quickCategory = HealthRecordCategory.other;
  final TextEditingController _noteCtrl = TextEditingController();
  bool _hasNoteText = false;
  final List<HealthCalendarEvent> _addedEvents = [];

  @override
  void initState() {
    super.initState();
    _noteCtrl.addListener(_onNoteChanged);
  }

  void _onNoteChanged() {
    final next = _noteCtrl.text.trim().isNotEmpty;
    if (next != _hasNoteText) setState(() => _hasNoteText = next);
  }

  @override
  void dispose() {
    _noteCtrl.removeListener(_onNoteChanged);
    _noteCtrl.dispose();
    super.dispose();
  }

  static const _thMonths = [
    '',
    'มกราคม',
    'กุมภาพันธ์',
    'มีนาคม',
    'เมษายน',
    'พฤษภาคม',
    'มิถุนายน',
    'กรกฎาคม',
    'สิงหาคม',
    'กันยายน',
    'ตุลาคม',
    'พฤศจิกายน',
    'ธันวาคม',
  ];

  static const _thShortMonths = [
    '',
    'ม.ค.',
    'ก.พ.',
    'มี.ค.',
    'เม.ย.',
    'พ.ค.',
    'มิ.ย.',
    'ก.ค.',
    'ส.ค.',
    'ก.ย.',
    'ต.ค.',
    'พ.ย.',
    'ธ.ค.',
  ];

  static const _enMonths = [
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const _enShortMonths = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const _thWeekdays = ['อา', 'จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส'];
  static const _enWeekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  static const _thFullWeekdays = [
    '',
    'วันจันทร์',
    'วันอังคาร',
    'วันพุธ',
    'วันพฤหัสบดี',
    'วันศุกร์',
    'วันเสาร์',
    'วันอาทิตย์',
  ];
  static const _enFullWeekdays = [
    '',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void didUpdateWidget(covariant HealthCalendarTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCatId != widget.initialCatId) {
      _quickCatId = widget.initialCatId;
    }
  }

  void _shiftMonth(int delta) {
    setState(() {
      var m = _month + delta;
      var y = _year;
      if (m < 1) {
        m = 12;
        y -= 1;
      } else if (m > 12) {
        m = 1;
        y += 1;
      }
      _year = y;
      _month = m;
      final daysInMonth = DateUtils.getDaysInMonth(_year, _month);
      if (_selectedDay > daysInMonth) {
        _selectedDay = daysInMonth;
      }
    });
  }

  Color _dotColor(HealthCalendarEventType type) {
    return switch (type) {
      HealthCalendarEventType.deworming => AppColors.healthDewormTeal,
      HealthCalendarEventType.vaccine => AppColors.healthVaccineBlue,
      HealthCalendarEventType.checkup => AppColors.healthIllnessOrange,
    };
  }

  String _typeLabel(HealthCalendarEventType type, bool isEn) {
    return switch (type) {
      HealthCalendarEventType.deworming => isEn ? 'Deworming' : 'ถ่ายพยาธิ',
      HealthCalendarEventType.vaccine => isEn ? 'Vaccine' : 'วัคซีน',
      HealthCalendarEventType.checkup => isEn ? 'Checkup' : 'ตรวจสุขภาพ',
    };
  }

  void _submitQuickNote(String dateTh, String dateEn) {
    final text = _noteCtrl.text.trim();
    if (text.isEmpty) return;
    final cat = widget.cats.firstWhere(
      (c) => c.id == _quickCatId,
      orElse: () => widget.cats.first,
    );
    final evType = switch (_quickCategory) {
      HealthRecordCategory.vaccine => HealthCalendarEventType.vaccine,
      HealthRecordCategory.deworming => HealthCalendarEventType.deworming,
      _ => HealthCalendarEventType.checkup,
    };

    widget.onQuickAddForDate(_quickCatId, _quickCategory, text, dateTh, dateEn);
    setState(() {
      _addedEvents.add(
        HealthCalendarEvent(
          id: 'cal-local-${DateTime.now().microsecondsSinceEpoch}',
          catNameTh: cat.name,
          catNameEn: MyCatL10n.catName(cat.name, true),
          year: _year,
          month: _month,
          day: _selectedDay,
          titleTh: text,
          titleEn: text,
          pillLabel: cat.name,
          type: evType,
          dateTh: dateTh,
          dateEn: dateEn,
          daysLeft: 0,
        ),
      );
      _noteCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEn = widget.isEn;
    final events = [...MockHealthBooks.sharedCalendarEvents, ..._addedEvents];
    final daysInMonth = DateUtils.getDaysInMonth(_year, _month);
    final firstWeekday = DateTime(_year, _month, 1).weekday % 7;
    final monthEvents = events
        .where((e) => e.year == _year && e.month == _month)
        .toList();
    final dayEvents = monthEvents.where((e) => e.day == _selectedDay).toList();

    final monthTitle = isEn
        ? '${_enMonths[_month]} $_year'
        : '${_thMonths[_month]} ${_year + 543}';

    final selectedWeekday = DateTime(_year, _month, _selectedDay).weekday;
    final selectedDateText = isEn
        ? '${_enFullWeekdays[selectedWeekday]}, $_selectedDay ${_enMonths[_month]}'
        : '${_thFullWeekdays[selectedWeekday]}ที่ $_selectedDay ${_thMonths[_month]}';

    final selectedShortDateTh =
        '$_selectedDay ${_thShortMonths[_month]} ${_year + 543}';
    final selectedShortDateEn = '$_selectedDay ${_enShortMonths[_month]} $_year';
    final noteHint = isEn
        ? 'Write note for $_selectedDay ${_enMonths[_month]}...'
        : 'เขียนบันทึกวันที่ $_selectedDay ${_thMonths[_month]}...';

    final weekdays = isEn ? _enWeekdays : _thWeekdays;

    final quickActions = [
      (
        cat: HealthRecordCategory.other,
        th: 'บันทึก',
        en: 'Note',
      ),
      (
        cat: HealthRecordCategory.vaccine,
        th: 'วัคซีน',
        en: 'Vaccine',
      ),
      (
        cat: HealthRecordCategory.deworming,
        th: 'ถ่ายพยาธิ',
        en: 'Deworm',
      ),
      (
        cat: HealthRecordCategory.bloodTest,
        th: 'ตรวจเลือด',
        en: 'Blood test',
      ),
      (
        cat: HealthRecordCategory.checkup,
        th: 'ตรวจประจำปี',
        en: 'Checkup',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // หัวปฏิทินและตารางเดือนวางบนพื้นหลังหน้าโดยตรงเทียบเว็บตัวอย่าง
        Row(
          children: [
            IconButton(
              onPressed: () => _shiftMonth(-1),
              icon: const Icon(LucideIcons.chevronLeft, size: 18),
              color: AppColors.text,
              tooltip: isEn ? 'Previous month' : 'เดือนก่อนหน้า',
            ),
            Expanded(
              child: Text(
                monthTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ),
            IconButton(
              onPressed: () => _shiftMonth(1),
              icon: const Icon(LucideIcons.chevronRight, size: 18),
              color: AppColors.text,
              tooltip: isEn ? 'Next month' : 'เดือนถัดไป',
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final wd in weekdays)
              Expanded(
                child: Center(
                  child: Text(
                    wd,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        _CalendarGrid(
          daysInMonth: daysInMonth,
          firstWeekdayOffset: firstWeekday,
          selectedDay: _selectedDay,
          todayDay: (_year == 2026 && _month == 11) ? 12 : null,
          monthEvents: monthEvents,
          isEn: isEn,
          onSelectDay: (d) => setState(() => _selectedDay = d),
        ),
        const SizedBox(height: 16),
        Text(
          selectedDateText,
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        if (dayEvents.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              isEn ? 'No appointments on this day' : 'ไม่มีนัดหมายในวันนี้',
              style: const TextStyle(fontSize: 13.5, color: AppColors.muted),
            ),
          )
        else ...[
          for (final ev in dayEvents)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: HealthCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                borderRadius: 18,
                child: Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: _dotColor(ev.type),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEn ? ev.titleEn : ev.titleTh,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text:
                                      '${isEn ? ev.catNameEn : ev.catNameTh} · ',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.muted,
                                  ),
                                ),
                                TextSpan(
                                  text: _typeLabel(ev.type, isEn),
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: _dotColor(ev.type),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isEn ? 'in ${ev.daysLeft} days' : 'อีก ${ev.daysLeft} วัน',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
        if (widget.cats.isNotEmpty) ...[
          HealthCard(
            padding: const EdgeInsets.all(14),
            borderRadius: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in widget.cats)
                      _QuickSelectPill(
                        label: MyCatL10n.catName(c.name, isEn),
                        selected: c.id == _quickCatId,
                        onTap: () => setState(() => _quickCatId = c.id),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final act in quickActions)
                      _QuickSelectPill(
                        label: isEn ? act.en : act.th,
                        selected: _quickCategory == act.cat,
                        isCategoryStyle: true,
                        onTap: () => setState(() => _quickCategory = act.cat),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _noteCtrl,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AppColors.text,
                        ),
                        decoration: InputDecoration(
                          hintText: noteHint,
                          hintStyle: const TextStyle(
                            fontSize: 13.5,
                            color: AppColors.muted,
                          ),
                          filled: true,
                          fillColor: AppColors.page,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.line2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.line2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.btnBorder,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Semantics(
                      button: true,
                      enabled: _hasNoteText,
                      label: isEn ? 'Send note' : 'ส่งบันทึก',
                      child: Opacity(
                        opacity: _hasNoteText ? 1.0 : 0.45,
                        child: InkWell(
                          onTap: _hasNoteText
                              ? () => _submitQuickNote(
                                  selectedShortDateTh,
                                  selectedShortDateEn,
                                )
                              : null,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.btn,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.btnBorder),
                            ),
                            child: Icon(
                              LucideIcons.send,
                              size: 18,
                              color: _hasNoteText
                                  ? AppColors.ink
                                  : AppColors.muted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(
              LucideIcons.calendarCheck,
              size: 17,
              color: AppColors.text,
            ),
            const SizedBox(width: 8),
            Text(
              isEn ? 'Upcoming' : 'กำลังจะถึง',
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        HealthCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < events.length; i++) ...[
                if (i > 0)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1, color: AppColors.line),
                  ),
                Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: _dotColor(events[i].type),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEn ? events[i].titleEn : events[i].titleTh,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text:
                                      '${isEn ? events[i].catNameEn : events[i].catNameTh} · ',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.muted,
                                  ),
                                ),
                                TextSpan(
                                  text: _typeLabel(events[i].type, isEn),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _dotColor(events[i].type),
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      ' · ${isEn ? events[i].dateEn : events[i].dateTh}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    HealthTagPill(
                      label: isEn
                          ? 'in ${events[i].daysLeft} days'
                          : 'อีก ${events[i].daysLeft} วัน',
                      backgroundColor: AppColors.soft,
                      textColor: AppColors.ink,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          isEn
              ? 'Calculated from vaccine book and deworming logs · always follow your vet’s schedule'
              : 'คำนวณจากสมุดวัคซีนและบันทึกถ่ายพยาธิ · กำหนดจริงให้ยึดตามที่สัตวแพทย์สั่ง',
          style: const TextStyle(
            fontSize: 12,
            height: 1.4,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }
}

class _QuickSelectPill extends StatelessWidget {
  const _QuickSelectPill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.isCategoryStyle = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isCategoryStyle;

  @override
  Widget build(BuildContext context) {
    final bgColor = !selected
        ? AppColors.card
        : (isCategoryStyle ? AppColors.soft : AppColors.btn);
    final borderColor = !selected
        ? AppColors.line2
        : (isCategoryStyle ? const Color(0xFF9C8470) : AppColors.btnBorder);
    final textColor = !selected
        ? AppColors.text2
        : (isCategoryStyle ? AppColors.text : AppColors.ink);

    return Material(
      color: bgColor,
      shape: StadiumBorder(
        side: BorderSide(
          color: borderColor,
          width: selected && isCategoryStyle ? 1.4 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.daysInMonth,
    required this.firstWeekdayOffset,
    required this.selectedDay,
    required this.todayDay,
    required this.monthEvents,
    required this.isEn,
    required this.onSelectDay,
  });

  final int daysInMonth;
  final int firstWeekdayOffset;
  final int selectedDay;
  final int? todayDay;
  final List<HealthCalendarEvent> monthEvents;
  final bool isEn;
  final ValueChanged<int> onSelectDay;

  @override
  Widget build(BuildContext context) {
    final totalCells = firstWeekdayOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: [
        for (var r = 0; r < rows; r++)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                for (var c = 0; c < 7; c++)
                  Expanded(
                    child: _buildCell(r * 7 + c - firstWeekdayOffset + 1),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCell(int day) {
    if (day < 1 || day > daysInMonth) {
      return const SizedBox(height: 54);
    }
    final isSelected = day == selectedDay;
    final isToday = todayDay == day;
    final dayEvs = monthEvents.where((e) => e.day == day).toList();
    final firstEvent = dayEvs.isNotEmpty ? dayEvs.first : null;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$day',
      child: InkWell(
        onTap: () => onSelectDay(day),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 54,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.btn : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: (isSelected || isToday)
                ? Border.all(
                    color: AppColors.btnBorder,
                    width: isSelected ? 1.5 : 1.0,
                  )
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$day',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: AppColors.text,
                ),
              ),
              if (firstEvent != null) ...[
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.ownerPillBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      isEn ? firstEvent.catNameEn : firstEvent.catNameTh,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ownerTeal,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
