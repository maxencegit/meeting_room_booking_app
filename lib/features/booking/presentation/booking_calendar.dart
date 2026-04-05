import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';

class BookingCalendar extends StatelessWidget {
  const BookingCalendar({super.key});

  @override
  Widget build(BuildContext context) {
    return WeekView(
      showLiveTimeLineInAllDays: true,
      timeLineWidth: 56,
      weekTitleHeight: 40,
      weekDayBuilder: (date) => _WeekDayHeader(date: date),
      headerStyle: HeaderStyle(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
        ),
      ),
    );
  }
}

class _WeekDayHeader extends StatelessWidget {
  const _WeekDayHeader({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _weekdayLabel(date.weekday),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isToday ? colorScheme.primary : colorScheme.onSurface,
              ),
        ),
        const SizedBox(height: 2),
        CircleAvatar(
          radius: 14,
          backgroundColor:
              isToday ? colorScheme.primary : Colors.transparent,
          child: Text(
            '${date.day}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: isToday
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                  fontWeight:
                      isToday ? FontWeight.bold : FontWeight.normal,
                ),
          ),
        ),
      ],
    );
  }

  String _weekdayLabel(int weekday) => switch (weekday) {
        1 => 'MON',
        2 => 'TUE',
        3 => 'WED',
        4 => 'THU',
        5 => 'FRI',
        6 => 'SAT',
        _ => 'SUN',
      };
}
