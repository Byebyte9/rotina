enum MetaType { hours, count, habit }

MetaType metaTypeFromString(String s) {
  switch (s) {
    case 'hours':
      return MetaType.hours;
    case 'habit':
      return MetaType.habit;
    default:
      return MetaType.count;
  }
}

String metaTypeToString(MetaType t) {
  switch (t) {
    case MetaType.hours:
      return 'hours';
    case MetaType.habit:
      return 'habit';
    case MetaType.count:
      return 'count';
  }
}

enum MetaColor { green, blue, orange, purple, gold }

MetaColor metaColorFromString(String s) {
  switch (s) {
    case 'blue':
      return MetaColor.blue;
    case 'orange':
      return MetaColor.orange;
    case 'purple':
      return MetaColor.purple;
    case 'gold':
      return MetaColor.gold;
    default:
      return MetaColor.green;
  }
}

String metaColorToString(MetaColor c) {
  switch (c) {
    case MetaColor.blue:
      return 'blue';
    case MetaColor.orange:
      return 'orange';
    case MetaColor.purple:
      return 'purple';
    case MetaColor.gold:
      return 'gold';
    case MetaColor.green:
      return 'green';
  }
}

class Meta {
  final int id;
  String name;
  MetaType type;
  double target;
  double current;
  String unit;
  int streak;
  MetaColor color;
  int focusSecs;
  Map<String, dynamic> checkins; // key: 'YYYY-MM-DD' -> bool (habit) ou int (count)
  int todayCount;

  Meta({
    required this.id,
    required this.name,
    this.type = MetaType.count,
    this.target = 10,
    this.current = 0,
    this.unit = 'vezes',
    this.streak = 0,
    this.color = MetaColor.green,
    this.focusSecs = 0,
    Map<String, dynamic>? checkins,
    this.todayCount = 0,
  }) : checkins = checkins ?? {};

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': metaTypeToString(type),
        'target': target,
        'current': current,
        'unit': unit,
        'streak': streak,
        'color': metaColorToString(color),
        'focusSecs': focusSecs,
        'checkins': checkins,
        'todayCount': todayCount,
      };

  factory Meta.fromJson(Map<String, dynamic> json) => Meta(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String? ?? '',
        type: metaTypeFromString(json['type'] as String? ?? 'count'),
        target: (json['target'] as num?)?.toDouble() ?? 10,
        current: (json['current'] as num?)?.toDouble() ?? 0,
        unit: json['unit'] as String? ?? 'vezes',
        streak: (json['streak'] as num?)?.toInt() ?? 0,
        color: metaColorFromString(json['color'] as String? ?? 'green'),
        focusSecs: (json['focusSecs'] as num?)?.toInt() ?? 0,
        checkins: json['checkins'] != null
            ? Map<String, dynamic>.from(json['checkins'] as Map)
            : {},
        todayCount: (json['todayCount'] as num?)?.toInt() ?? 0,
      );
}
