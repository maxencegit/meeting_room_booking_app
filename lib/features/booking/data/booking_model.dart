import 'package:uuid/uuid.dart';

class BookingModel {
  const BookingModel({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.title,
  });

  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final String title;

  Map<String, dynamic> toJson() => {
        'id': id,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'title': title,
      };

  factory BookingModel.fromJson(Map<String, dynamic> json) => BookingModel(
        id: json['id'] as String? ?? const Uuid().v7(),
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: DateTime.parse(json['endTime'] as String),
        title: json['title'] as String,
      );
}
