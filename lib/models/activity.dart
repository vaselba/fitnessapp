class Activity {
  final DateTime date;
  final String type;
  final double durationMinutes;
  final double? calories;

  Activity({
    required this.date,
    required this.type,
    required this.durationMinutes,
    this.calories,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'type': type,
        'durationMinutes': durationMinutes,
        'calories': calories,
      };

  factory Activity.fromJson(Map<String, dynamic> json) => Activity(
        date: DateTime.parse(json['date'] as String),
        type: json['type'] as String,
        durationMinutes: (json['durationMinutes'] as num).toDouble(),
        calories: json['calories'] != null
            ? (json['calories'] as num).toDouble()
            : null,
      );
}
