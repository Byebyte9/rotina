import 'recurrence.dart';

enum TaskWeight { light, medium, heavy }

TaskWeight taskWeightFromString(String s) {
  switch (s) {
    case 'light':
      return TaskWeight.light;
    case 'heavy':
      return TaskWeight.heavy;
    default:
      return TaskWeight.medium;
  }
}

String taskWeightToString(TaskWeight w) {
  switch (w) {
    case TaskWeight.light:
      return 'light';
    case TaskWeight.heavy:
      return 'heavy';
    case TaskWeight.medium:
      return 'medium';
  }
}

class Task {
  final int id;
  String name;
  String time; // 'HH:mm'
  TaskWeight weight;
  Recurrence recurrence;
  bool done;
  int? linkedMeta;

  Task({
    required this.id,
    required this.name,
    required this.time,
    this.weight = TaskWeight.medium,
    Recurrence? recurrence,
    this.done = false,
    this.linkedMeta,
  }) : recurrence = recurrence ?? Recurrence.none();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'time': time,
        'weight': taskWeightToString(weight),
        'recurrence': recurrence.toJson(),
        'done': done,
        'linkedMeta': linkedMeta,
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String? ?? '',
        time: json['time'] as String? ?? '09:00',
        weight: taskWeightFromString(json['weight'] as String? ?? 'medium'),
        recurrence: Recurrence.fromJson(json['recurrence']),
        done: json['done'] as bool? ?? false,
        linkedMeta: (json['linkedMeta'] as num?)?.toInt(),
      );
}
