import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';

class RangeDatePicker extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isHalfDay;
  final void Function(DateTime? start, DateTime? end) onChanged;

  const RangeDatePicker({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.isHalfDay,
    required this.onChanged,
  });

  @override
  State<RangeDatePicker> createState() => _RangeDatePickerState();
}

class _RangeDatePickerState extends State<RangeDatePicker> {
  late DateTime _focusedMonth;

  static const _weekLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  static const _rangeColor = Color(0xFFCCF3F8);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _onDayTap(DateTime tapped) {
    if (tapped.weekday == DateTime.saturday ||
        tapped.weekday == DateTime.sunday) return;

    final start = widget.startDate;
    final end = widget.endDate;

    if (widget.isHalfDay) {
      widget.onChanged(tapped, tapped);
      return;
    }

    if (start == null || (end != null)) {
      widget.onChanged(tapped, null);
      return;
    }

    if (_sameDay(tapped, start)) {
      widget.onChanged(start, start);
    } else if (tapped.isBefore(start)) {
      widget.onChanged(tapped, start);
    } else {
      widget.onChanged(start, tapped);
    }
  }

  Widget _buildDayCell(DateTime day) {
    final start = widget.startDate;
    final end = widget.endDate;

    final isStart = start != null && _sameDay(day, start);
    final isEnd = end != null && _sameDay(day, end);
    final isSingleDay = isStart && isEnd;

    final hasRange = start != null && end != null && !_sameDay(start, end);
    final inRange = hasRange && day.isAfter(start) && day.isBefore(end);

    final isToday = _sameDay(day, DateTime.now());
    final isWeekend = day.weekday == DateTime.saturday ||
        day.weekday == DateTime.sunday;

    final isDisabled = isWeekend ||
        day.isBefore(DateTime.now().subtract(const Duration(days: 30))) ||
        day.isAfter(DateTime.now().add(const Duration(days: 365)));

    final bool leftBg = inRange || (isEnd && hasRange);
    final bool rightBg = inRange || (isStart && hasRange);

    return GestureDetector(
      onTap: isDisabled ? null : () => _onDayTap(day),
      child: SizedBox(
        height: 40,
        child: Stack(
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    color: leftBg ? _rangeColor : Colors.transparent,
                  ),
                ),
                Expanded(
                  child: Container(
                    color: rightBg ? _rangeColor : Colors.transparent,
                  ),
                ),
              ],
            ),
            if (isWeekend && !isStart && !isEnd)
              Container(color: const Color(0xFFF3F4F6)),
            Center(
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (isStart || isEnd) && !isSingleDay
                      ? AppTheme.primary
                      : isSingleDay
                          ? AppTheme.primary
                          : Colors.transparent,
                  shape: BoxShape.circle,
                  border: isToday && !isStart && !isEnd
                      ? Border.all(color: AppTheme.primary, width: 1.5)
                      : null,
                ),
                child: Center(
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: (isStart || isEnd)
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: (isStart || isEnd)
                          ? Colors.white
                          : isWeekend
                              ? const Color(0xFFD1D5DB)
                              : isDisabled
                                  ? const Color(0xFFD1D5DB)
                                  : isToday
                                      ? AppTheme.primary
                                      : AppTheme.textDark,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstOfMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final startOffset = firstOfMonth.weekday % 7;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 22),
                color: AppTheme.textDark,
                onPressed: () => setState(() {
                  _focusedMonth = DateTime(
                    _focusedMonth.year,
                    _focusedMonth.month - 1,
                  );
                }),
              ),
              Text(
                DateFormat('MMMM yyyy').format(_focusedMonth),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 22),
                color: AppTheme.textDark,
                onPressed: () => setState(() {
                  _focusedMonth = DateTime(
                    _focusedMonth.year,
                    _focusedMonth.month + 1,
                  );
                }),
              ),
            ],
          ),
          Row(
            children: _weekLabels
                .asMap()
                .entries
                .map(
                  (e) => Expanded(
                    child: Center(
                      child: Text(
                        e.value,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: (e.key == 0 || e.key == 6)
                              ? const Color(0xFFD1D5DB)
                              : AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 4),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
            ),
            itemCount: startOffset + daysInMonth,
            itemBuilder: (_, index) {
              if (index < startOffset) return const SizedBox();
              final day = DateTime(
                _focusedMonth.year,
                _focusedMonth.month,
                index - startOffset + 1,
              );
              return _buildDayCell(day);
            },
          ),
        ],
      ),
    );
  }
}
