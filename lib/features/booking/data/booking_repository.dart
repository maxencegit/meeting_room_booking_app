import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'booking_model.dart';

sealed class SaveBookingResult {
  const SaveBookingResult();
}

class SaveBookingSuccess extends SaveBookingResult {
  const SaveBookingSuccess();
}

class SaveBookingConflict extends SaveBookingResult {
  const SaveBookingConflict(this.conflictingBooking);
  final BookingModel conflictingBooking;
}

class BookingRepository {
  static const _key = 'bookings';

  Future<List<BookingModel>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((s) => BookingModel.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<SaveBookingResult> save(BookingModel booking) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final existing = raw
        .map((s) => BookingModel.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();

    final conflict = existing.where(_overlaps(booking)).firstOrNull;
    if (conflict != null) return SaveBookingConflict(conflict);

    raw.add(jsonEncode(booking.toJson()));
    await prefs.setStringList(_key, raw);
    return const SaveBookingSuccess();
  }

  Future<void> delete(BookingModel booking) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.removeWhere((s) {
      final b = BookingModel.fromJson(jsonDecode(s) as Map<String, dynamic>);
      return b.startTime == booking.startTime && b.endTime == booking.endTime;
    });
    await prefs.setStringList(_key, raw);
  }

  Future<void> deleteAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  bool Function(BookingModel) _overlaps(BookingModel booking) =>
      (existing) =>
          booking.startTime.isBefore(existing.endTime) &&
          booking.endTime.isAfter(existing.startTime);
}
