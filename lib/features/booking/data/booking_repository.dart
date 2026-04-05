import 'dart:convert';

import 'package:flutter/material.dart';
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

  Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.removeWhere((s) => BookingModel.fromJson(jsonDecode(s) as Map<String, dynamic>).id == id);
    await prefs.setStringList(_key, raw);
  }

  Future<({DateTime start, DateTime end})> getSuggestedTimes(
    DateTime tappedAt,
  ) async {
    final all = await loadAll();
    final dayBookings = all
        .where((b) => DateUtils.isSameDay(b.startTime, tappedAt))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    // Latest meeting that ends at or before the tapped time
    final previous = dayBookings
        .where((b) => !b.endTime.isAfter(tappedAt))
        .lastOrNull;

    // Earliest meeting that starts after the tapped time
    final next = dayBookings
        .where((b) => b.startTime.isAfter(tappedAt))
        .firstOrNull;

    final start = previous?.endTime ?? tappedAt;
    final end = next?.startTime ?? start.add(const Duration(hours: 1));

    return (start: start, end: end);
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
