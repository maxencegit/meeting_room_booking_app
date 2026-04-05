class BookingModel {
  const BookingModel({
    required this.startTime,
    required this.endTime,
    required this.title,
  });

  final DateTime startTime;
  final DateTime endTime;
  final String title;

  Map<String, dynamic> toJson() => {
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'title': title,
      };

  factory BookingModel.fromJson(Map<String, dynamic> json) => BookingModel(
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: DateTime.parse(json['endTime'] as String),
        title: json['title'] as String,
      );
}
