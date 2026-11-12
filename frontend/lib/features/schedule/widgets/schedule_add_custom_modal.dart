import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/schedule_model.dart';

class ScheduleAddCustomModal extends StatefulWidget {
  final Function(ScheduleItem) onSave;
  final List<Map<String, String>>? days;
  final ScheduleItem? initialItem;
  final VoidCallback? onDelete;
  final String? weekRange;
  final int? initialDayNum;

  const ScheduleAddCustomModal({
    super.key,
    required this.onSave,
    this.days,
    this.initialItem,
    this.onDelete,
    this.weekRange,
    this.initialDayNum,
  });

  static Future<void> show(
    BuildContext context, {
    required Function(ScheduleItem) onSave,
    List<Map<String, String>>? days,
    ScheduleItem? initialItem,
    VoidCallback? onDelete,
    String? weekRange,
    int? initialDayNum,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ScheduleAddCustomModal(
        onSave: onSave,
        days: days,
        initialItem: initialItem,
        onDelete: onDelete,
        weekRange: weekRange,
        initialDayNum: initialDayNum,
      ),
    );
  }

  @override
  State<ScheduleAddCustomModal> createState() => _ScheduleAddCustomModalState();
}

class _ScheduleAddCustomModalState extends State<ScheduleAddCustomModal> {
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();
  final TextEditingController _lecturerController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _dateInputController = TextEditingController();

  String _selectedType = 'dot_xuat'; // 'dot_xuat', 'hoc_bu', 'kiem_tra', 'khac'
  int _selectedDayIndex = 0; // 0 -> Thứ 2
  String _selectedTime = 'Tiết 7-10';
  bool _periodDropdownOpen = false;
  bool _isCustomTime = false;
  bool _isSaving = false;
  final TextEditingController _customTimeController = TextEditingController();
  late List<Map<String, String>> _weekDays;

  final List<Map<String, dynamic>> _types = [
    {
      'key': 'dot_xuat',
      'label': 'Thực hành',
      'icon': Icons.show_chart,
      'color': const Color(0xFFD97706),
      'bg': const Color(0xFFFEF3C7),
      'lightBg': const Color(0xFFFFFBEB),
    },
    {
      'key': 'hoc_bu',
      'label': 'Học bù',
      'icon': Icons.bolt,
      'color': const Color(0xFF2563EB),
      'bg': const Color(0xFFEFF6FF),
      'lightBg': const Color(0xFFEFF6FF),
    },
    {
      'key': 'kiem_tra',
      'label': 'Kiểm tra / Thi',
      'icon': Icons.description_outlined,
      'color': const Color(0xFFDC2626),
      'bg': const Color(0xFFFEE2E2),
      'lightBg': const Color(0xFFFEF2F2),
    },
    {
      'key': 'khac',
      'label': 'Khác',
      'icon': Icons.bookmark_border,
      'color': const Color(0xFF059669),
      'bg': const Color(0xFFD1FAE5),
      'lightBg': const Color(0xFFF0FDF4),
    },
  ];

  final List<Map<String, String>> _periodOptions = [
    {'label': 'Tiết 1-2', 'desc': '07:00 – 08:40'},
    {'label': 'Tiết 1-4', 'desc': '07:00 – 10:40'},
    {'label': 'Tiết 3-4', 'desc': '08:50 – 10:40'},
    {'label': 'Tiết 5-6', 'desc': '10:50 – 12:30'},
    {'label': 'Tiết 7-8', 'desc': '13:50 – 15:30'},
    {'label': 'Tiết 7-10', 'desc': '13:50 – 17:30'},
    {'label': 'Tiết 9-10', 'desc': '15:40 – 17:30'},
    {'label': 'Tiết 11-12', 'desc': '17:40 – 19:20'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.days != null && widget.days!.isNotEmpty) {
      _weekDays = widget.days!.map((d) {
        final day = d['day'] ?? 'Thứ 2';
        final date = d['date'] ?? '';
        final fullDate = d['fullDate'] ?? date;
        return {
          'day': day,
          'date': date,
          'fullDate': fullDate,
          'dayLabel': '$day, ngày $fullDate',
        };
      }).toList();
    } else {
      final now = DateTime.now();
      final distToMon = (now.weekday - 1) % 7;
      final mon = now.subtract(Duration(days: distToMon));
      final dayNames = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'CN'];
      String pad(int n) => n.toString().padLeft(2, '0');
      _weekDays = List.generate(7, (i) {
        final d = mon.add(Duration(days: i));
        final dateStr = '${pad(d.day)}/${pad(d.month)}';
        final fullDateStr = '${pad(d.day)}/${pad(d.month)}/${d.year}';
        return {
          'day': dayNames[i],
          'date': dateStr,
          'fullDate': fullDateStr,
          'dayLabel': '${dayNames[i]}, ngày $fullDateStr',
        };
      });
    }
    final now = DateTime.now();
    final todayIdx = (now.weekday - 1).clamp(0, _weekDays.length - 1);
    if (widget.initialDayNum != null) {
      final targetIdx = widget.initialDayNum == 1 ? 6 : (widget.initialDayNum! - 2);
      _selectedDayIndex = targetIdx.clamp(0, _weekDays.length - 1);
    } else {
      _selectedDayIndex = todayIdx;
    }
    _dateInputController.text = _weekDays[_selectedDayIndex]['fullDate']!;

    final initial = widget.initialItem;
    if (initial != null) {
      _courseController.text = initial.courseName;
      _roomController.text = initial.room;
      _lecturerController.text = initial.lecturer ?? '';
      _noteController.text = initial.note ?? '';
      if (initial.type != null && initial.type!.isNotEmpty) {
        _selectedType = initial.type!;
      }

      final matches = _periodOptions.any((p) => p['label'] == initial.timeSlot);
      if (matches) {
        _selectedTime = initial.timeSlot;
        _isCustomTime = false;
      } else {
        _isCustomTime = true;
        _customTimeController.text = initial.timeSlot;
      }

      int foundIdx = -1;
      if (initial.date != null && initial.date!.isNotEmpty) {
        foundIdx = _weekDays.indexWhere((w) => w['fullDate'] == initial.date || w['date'] == initial.date);
      }
      if (foundIdx == -1) {
        foundIdx = _weekDays.indexWhere((w) => initial.matchesDay(w['day'] ?? ''));
      }
      if (foundIdx != -1) {
        _selectedDayIndex = foundIdx;
        _dateInputController.text = _weekDays[_selectedDayIndex]['fullDate']!;
      } else if (initial.date != null && initial.date!.isNotEmpty) {
        _dateInputController.text = initial.date!;
      }
    }
  }

  @override
  void dispose() {
    _courseController.dispose();
    _roomController.dispose();
    _lecturerController.dispose();
    _noteController.dispose();
    _dateInputController.dispose();
    _customTimeController.dispose();
    super.dispose();
  }

  void _shiftDate(int offset) {
    setState(() {
      _selectedDayIndex = (_selectedDayIndex + offset).clamp(0, _weekDays.length - 1);
      _dateInputController.text = _weekDays[_selectedDayIndex]['fullDate']!;
    });
  }

  void _saveSchedule() async {
    if (_isSaving) return;
    final course = _courseController.text.trim();
    final room = _roomController.text.trim();
    if (course.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập tên môn học hoặc hoạt động'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    if (room.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập phòng học hoặc địa điểm'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final time = _isCustomTime && _customTimeController.text.isNotEmpty
        ? _customTimeController.text.trim()
        : _selectedTime;

    final selectedDay = _weekDays[_selectedDayIndex];
    final selectedDayName = selectedDay['day']!;
    final selectedDate = _dateInputController.text.trim().isNotEmpty
        ? _dateInputController.text.trim()
        : selectedDay['fullDate']!;
    final selectedDateShort = selectedDay['date']!;
    final calculatedDayNum = ScheduleItem.dayStrToNum(selectedDayName);

    final item = ScheduleItem(
      id: widget.initialItem?.id ?? (DateTime.now().millisecondsSinceEpoch % 100000),
      courseName: course,
      room: room,
      dayOfWeek: selectedDayName,
      dayNum: calculatedDayNum,
      date: selectedDate,
      dateShort: selectedDateShort,
      timeSlot: time,
      lecturer: _lecturerController.text.trim().isNotEmpty ? _lecturerController.text.trim() : null,
      note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
      type: _selectedType,
      isCustom: true,
      weekRange: widget.weekRange ?? widget.initialItem?.weekRange,
    );

    try {
      await widget.onSave(item);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final currentDay = _weekDays[_selectedDayIndex];

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── HEADER ───
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: widget.initialItem != null ? const Color(0xFFEFF6FF) : const Color(0xFFFEF3C7),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          widget.initialItem != null ? Icons.edit_calendar_outlined : Icons.add_circle_outline,
                          color: widget.initialItem != null ? AppColors.primary : const Color(0xFFD97706),
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.initialItem != null ? 'Chỉnh sửa lịch học' : 'Thêm lịch học / Thực hành',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textForeground,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.initialItem != null
                              ? 'Cập nhật môn học, thời gian, phòng học'
                              : 'Lịch thực hành đột xuất, học bù, kiểm tra',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 18, color: Color(0xFF64748B)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // ─── FORM CONTENT ───
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset > 0 ? bottomInset + 20 : 32),
              children: [
                // 1. Tên môn học *
                _buildLabel('Tên môn học', isRequired: true),
                const SizedBox(height: 6),
                _buildTextInput(
                  controller: _courseController,
                  hint: '',
                ),
                const SizedBox(height: 16),

                // 2. Phân loại lịch (2x2 Grid)
                _buildLabel('Phân loại lịch'),
                const SizedBox(height: 8),
                _buildTypeGrid(),
                const SizedBox(height: 16),

                // 3. Khối chọn ngày học
                _buildDatePickerBox(currentDay),
                const SizedBox(height: 16),

                // 4. Tiết học *
                _buildLabel('Tiết học', isRequired: true),
                const SizedBox(height: 6),
                _buildPeriodDropdown(),
                const SizedBox(height: 16),

                // 5. Phòng *
                _buildLabel('Phòng', isRequired: true),
                const SizedBox(height: 6),
                _buildTextInput(
                  controller: _roomController,
                  hint: 'Phòng học',
                ),
                const SizedBox(height: 16),

                // 6. Giảng viên
                _buildLabel('Giảng viên'),
                const SizedBox(height: 6),
                _buildTextInput(
                  controller: _lecturerController,
                  hint: 'Tên giảng viên',
                ),
                const SizedBox(height: 16),

                // 7. Ghi chú cho ca học
                _buildLabel('Ghi chú cho ca học'),
                const SizedBox(height: 6),
                _buildTextInput(
                  controller: _noteController,
                  hint: '',
                  maxLines: 2,
                ),
                const SizedBox(height: 24),

                // 8. Action Buttons
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveSchedule,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(widget.initialItem != null ? Icons.check_circle_outline : Icons.add_circle_outline, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              widget.initialItem != null ? 'Lưu thay đổi' : 'Lưu vào thời khóa biểu',
                              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                ),
                if (widget.initialItem != null && widget.onDelete != null) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: widget.onDelete,
                    icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)),
                    label: const Text(
                      'Xóa lịch học này',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFFECACA), width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Hủy bỏ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, {bool isRequired = false}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textForeground,
        ),
        children: isRequired
            ? const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: Color(0xFFEF4444)),
                ),
              ]
            : null,
      ),
    );
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.textForeground,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildTypeGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _types.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.8,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final t = _types[index];
        final isSelected = _selectedType == t['key'];
        final color = t['color'] as Color;

        return GestureDetector(
          onTap: () => setState(() => _selectedType = t['key']),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? t['lightBg'] as Color : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? color : const Color(0xFFE2E8F0),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isSelected ? t['bg'] as Color : const Color(0xFFEDF2F7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Icon(
                      t['icon'] as IconData,
                      size: 16,
                      color: isSelected ? color : const Color(0xFF64748B),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t['label'] as String,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? color : AppColors.textForeground,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check, size: 16, color: color),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDatePickerBox(Map<String, String> currentDay) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row Header: Icon + Date Label + Shifts
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: const TextSpan(
                        text: 'Ngày học',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textForeground),
                        children: [
                          TextSpan(text: ' *', style: TextStyle(color: Color(0xFFEF4444))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentDay['dayLabel']!,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              // Controls: < | Hôm nay | >
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _shiftDate(-1),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDF2F7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.chevron_left, size: 16, color: Color(0xFF64748B)),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      final now = DateTime.now();
                      final todayIdx = (now.weekday - 1).clamp(0, _weekDays.length - 1);
                      setState(() {
                        _selectedDayIndex = todayIdx;
                        _dateInputController.text = _weekDays[todayIdx]['fullDate']!;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDF2F7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Hôm nay',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _shiftDate(1),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDF2F7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.chevron_right, size: 16, color: Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Label: Chọn nhanh các ngày trong tuần:
          const Text(
            'Chọn nhanh các ngày trong tuần:',
            style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),

          // Horizontal 7 Day Chips
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _weekDays.length,
              separatorBuilder: (context, index) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final d = _weekDays[index];
                final isSelected = _selectedDayIndex == index;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDayIndex = index;
                      _dateInputController.text = d['fullDate']!;
                    });
                  },
                  child: Container(
                    width: 58,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          d['day']!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : AppColors.textForeground,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          d['date']!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.white.withValues(alpha: 0.85) : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodDropdown() {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _periodDropdownOpen = !_periodDropdownOpen),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _periodDropdownOpen ? AppColors.primary : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      _isCustomTime ? (_customTimeController.text.isNotEmpty ? _customTimeController.text : 'Tự nhập giờ') : _selectedTime,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textForeground,
                      ),
                    ),
                  ],
                ),
                Icon(
                  _periodDropdownOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 20,
                  color: const Color(0xFF64748B),
                ),
              ],
            ),
          ),
        ),

        // Dropdown List
        if (_periodDropdownOpen) ...[
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0C000000),
                  offset: Offset(0, 4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: [
                ..._periodOptions.map((p) {
                  final isSel = !_isCustomTime && _selectedTime == p['label'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTime = p['label']!;
                        _isCustomTime = false;
                        _periodDropdownOpen = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFFEEF2FF) : Colors.transparent,
                        border: const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p['label']!,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w600,
                                  color: isSel ? AppColors.primary : AppColors.textForeground,
                                ),
                              ),
                              Text(
                                p['desc']!,
                                style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                          if (isSel)
                            const Icon(Icons.check, size: 16, color: AppColors.primary),
                        ],
                      ),
                    ),
                  );
                }),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isCustomTime = true;
                      _periodDropdownOpen = false;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: const Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 14, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text(
                          'Tự nhập khác...',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        if (_isCustomTime) ...[
          const SizedBox(height: 8),
          _buildTextInput(
            controller: _customTimeController,
            hint: 'Ví dụ: 13:50 - 15:30',
          ),
        ],
      ],
    );
  }
}
