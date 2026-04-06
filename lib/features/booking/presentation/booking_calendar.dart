import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';

import '../data/booking_model.dart';
import '../data/booking_repository.dart';

import 'booking_dialog.dart';

import 'package:uuid/uuid.dart';
class BookingCalendar extends StatefulWidget {
  const BookingCalendar({super.key});

  @override
  State<BookingCalendar> createState() => _BookingCalendarState();
}

class _BookingCalendarState extends State<BookingCalendar>
    with WidgetsBindingObserver {
  final _repository = BookingRepository();
  static const _startHour = 8;
  static const _endHour = 19;
  static const _weekTitleHeight = 48.0;

  Key _calendarKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadBookings();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() => _calendarKey = UniqueKey());
    }
  }

  double _heightPerMinute(BuildContext context) {
    final mq = MediaQuery.of(context);
    final available = mq.size.height
        - mq.padding.top
        - mq.padding.bottom
        - _weekTitleHeight;
    const totalMinutes = (_endHour - _startHour) * 60;
    return (available / totalMinutes).clamp(0.6, 1.4);
  }

  double _scrollOffset(BuildContext context) {
    final now = DateTime.now();
    final minutesFromStart = (now.hour - _startHour) * 60 + now.minute;
    final currentTimePixel = minutesFromStart * _heightPerMinute(context);
    final mq = MediaQuery.of(context);
    final viewportHeight = mq.size.height - mq.padding.top - mq.padding.bottom;
    return (currentTimePixel - viewportHeight / 2).clamp(0.0, double.maxFinite);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadBookings() async {
    final bookings = await _repository.loadAll();
    if (!mounted) return;

    final controller = CalendarControllerProvider.of<BookingModel>(context).controller;
    for (final booking in bookings) {
      controller.add(
        CalendarEventData<BookingModel>(
          title: booking.title,
          date: booking.startTime,
          startTime: booking.startTime,
          endTime: booking.endTime,
          color: Theme.of(context).colorScheme.primary,
          event: booking,
        ),
      );
    }
  }

  Future<void> _onSlotTapped(DateTime dateTime) async {
    final suggested = await _repository.getSuggestedTimes(dateTime);

    if (!mounted) return;

    final dialogResult = await showDialog<(String, TimeOfDay, TimeOfDay)>(
      context: context,
      builder: (_) => BookingDialog(
        // Full DateTime so the dialog has both the date (for the label)
        // and the suggested start time.
        initialDateTime: suggested.start,
        // Only the time is needed for the end — the date is already
        // carried by initialDateTime above.
        initialEndTime: TimeOfDay.fromDateTime(suggested.end),
      ),
    );

    if (dialogResult == null || !mounted) return;

    final (name, startTime, endTime) = dialogResult;
    final start = DateTime(
      dateTime.year, dateTime.month, dateTime.day,
      startTime.hour, startTime.minute,
    );
    final end = DateTime(
      dateTime.year, dateTime.month, dateTime.day,
      endTime.hour, endTime.minute,
    );

    final booking = BookingModel(id: Uuid().v7(), startTime: start, endTime: end, title: name);
    final result = await _repository.save(booking);

    if (!mounted) return;

    switch (result) {
      case SaveBookingConflict():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('A meeting already exists during this time slot'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      case SaveBookingSuccess():
        CalendarControllerProvider.of<BookingModel>(context).controller.add(
          CalendarEventData<BookingModel>(
            title: booking.title,
            date: booking.startTime,
            startTime: booking.startTime,
            endTime: booking.endTime,
            color: Theme.of(context).colorScheme.primary,
            event: booking,
          ),
        );
    }
  }

  Future<void> _onEventLongTap(
    List<CalendarEventData<BookingModel>> events,
    DateTime dateTime,
  ) async {
    if (events.isEmpty) return;
    final event = events.first;
    final booking = event.event;
    if (booking == null) return;

    final dialogResult = await showDialog<(String, TimeOfDay, TimeOfDay)>(
      context: context,
      builder: (_) => BookingDialog(
        initialDateTime: booking.startTime,
        initialEndTime: TimeOfDay.fromDateTime(booking.endTime),
        initialTitle: booking.title,
      ),
    );

    if (dialogResult == null || !mounted) return;

    final (name, startTime, endTime) = dialogResult;
    final start = DateTime(
      booking.startTime.year,
      booking.startTime.month,
      booking.startTime.day,
      startTime.hour,
      startTime.minute,
    );
    final end = DateTime(
      booking.startTime.year,
      booking.startTime.month,
      booking.startTime.day,
      endTime.hour,
      endTime.minute,
    );

    await _repository.delete(booking.id);

    final updated = BookingModel(
      id: booking.id,
      startTime: start,
      endTime: end,
      title: name,
    );
    final result = await _repository.save(updated);

    if (!mounted) return;

    switch (result) {
      case SaveBookingConflict():
        await _repository.save(booking);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'A meeting already exists during this time slot',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      case SaveBookingSuccess():
        final controller =
            CalendarControllerProvider.of<BookingModel>(context).controller;
        controller.remove(event);
        controller.add(
          CalendarEventData<BookingModel>(
            title: updated.title,
            date: updated.startTime,
            startTime: updated.startTime,
            endTime: updated.endTime,
            color: Theme.of(context).colorScheme.primary,
            event: updated,
          ),
        );
    }
  }

  Future<void> _onEventTap(
    List<CalendarEventData<BookingModel>> events,
    DateTime dateTime,
  ) async {
    if (events.isEmpty) return;
    final event = events.first;
    final booking = event.event;
    if (booking == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete meeting'),
        content: Text(
          'Are you sure you want to delete this meeting?\n'
          '${TimeOfDay.fromDateTime(event.startTime!).format(ctx)} → '
          '${TimeOfDay.fromDateTime(event.endTime!).format(ctx)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await _repository.delete(booking.id);

    if (!mounted) return;
    CalendarControllerProvider.of<BookingModel>(context).controller.remove(event);
  }

  @override
  Widget build(BuildContext context) {
    return WeekView<BookingModel>(
      key: _calendarKey,
      showLiveTimeLineInAllDays: true,
      timeLineWidth: 56,
      weekTitleHeight: _weekTitleHeight,
      startHour: _startHour,
      endHour: _endHour,
      heightPerMinute: _heightPerMinute(context),
      minuteSlotSize: MinuteSlotSize.minutes15,
      scrollOffset: _scrollOffset(context),
      weekDays: const [
        WeekDays.monday,
        WeekDays.tuesday,
        WeekDays.wednesday,
        WeekDays.thursday,
        WeekDays.friday,
      ],
      weekDayBuilder: (date) => _WeekDayHeader(date: date),
      headerStyle: HeaderStyle(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
        ),
      ),
      onDateTap: _onSlotTapped,
      onEventTap: (events, dateTime) => _onEventTap(events, dateTime),
      onEventLongTap: (events, dateTime) =>
          _onEventLongTap(events, dateTime),
      eventTileBuilder: (date, events, boundary, start, end) {
        final event = events.firstOrNull;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Text(
            event?.title ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
          ),
        );
      },
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
          backgroundColor: isToday ? colorScheme.primary : Colors.transparent,
          child: Text(
            '${date.day}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: isToday ? colorScheme.onPrimary : colorScheme.onSurface,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
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
