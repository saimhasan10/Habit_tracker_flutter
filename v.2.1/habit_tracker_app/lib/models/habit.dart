class Habit {
  String id;
  String name;
  String category;
  String icon;
  String note;
  String goalType;
  int targetValue;
  String unit;

  Habit({
    required this.id,
    required this.name,
    this.category = 'General',
    this.icon = 'check_circle',
    this.note = '',
    this.goalType = 'checkbox',
    this.targetValue = 1,
    this.unit = 'time',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'icon': icon,
      'note': note,
      'goalType': goalType,
      'targetValue': targetValue,
      'unit': unit,
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'],
      name: json['name'],
      category: json['category'] ?? 'General',
      icon: json['icon'] ?? 'check_circle',
      note: json['note'] ?? '',
      goalType: json['goalType'] ?? 'checkbox',
      targetValue: json['targetValue'] ?? 1,
      unit: json['unit'] ?? 'time',
    );
  }
}
