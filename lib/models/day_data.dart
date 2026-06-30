class SleepData {
  String start; // 'HH:mm'
  String end; // 'HH:mm'

  SleepData({this.start = '23:00', this.end = '07:00'});

  Map<String, dynamic> toJson() => {'start': start, 'end': end};

  factory SleepData.fromJson(Map<String, dynamic>? json) {
    if (json == null) return SleepData();
    return SleepData(
      start: json['start'] as String? ?? '23:00',
      end: json['end'] as String? ?? '07:00',
    );
  }

  /// Duração do sono em minutos, lidando com virada de meia-noite.
  int get durationMinutes {
    final s = start.split(':').map(int.parse).toList();
    final e = end.split(':').map(int.parse).toList();
    int mins = (e[0] * 60 + e[1]) - (s[0] * 60 + s[1]);
    if (mins < 0) mins += 1440;
    return mins;
  }

  /// BUG 14 fix: quando start == end, durationMinutes retorna 0 — mas isso
  /// é ambíguo: pode significar "dormiu 0 minutos" (sem sentido prático) ou
  /// "ainda não configurou o horário de sono" (caso mais provável, já que
  /// os defaults '23:00'/'07:00' nunca colidem por acaso). A UI deve usar
  /// esta propriedade para mostrar algo como "Sono não configurado" em vez
  /// de "0h0m", que sugeriria uma noite sem dormir.
  bool get isLikelyUnset => start == end;
}

/// Espelha os dados gravados por dia no localStorage (`day_YYYY-MM-DD`):
/// nota, "dot" (ótimo/parcial/difícil), sono daquele dia e tarefas concluídas.
class DayData {
  String note;
  String dot; // '', 'green', 'orange', 'red'
  SleepData? sleep;
  List<int> tasksDone;

  DayData({
    this.note = '',
    this.dot = '',
    this.sleep,
    List<int>? tasksDone,
  }) : tasksDone = tasksDone ?? [];

  Map<String, dynamic> toJson() => {
        'note': note,
        'dot': dot,
        'sleep': sleep?.toJson(),
        'tasksDone': tasksDone,
      };

  factory DayData.fromJson(Map<String, dynamic>? json) {
    if (json == null) return DayData();
    return DayData(
      note: json['note'] as String? ?? '',
      dot: json['dot'] as String? ?? '',
      sleep: json['sleep'] != null
          ? SleepData.fromJson(Map<String, dynamic>.from(json['sleep'] as Map))
          : null,
      tasksDone: json['tasksDone'] != null
          ? List<int>.from((json['tasksDone'] as List).map((e) => (e as num).toInt()))
          : [],
    );
  }

  bool get isEmpty =>
      note.isEmpty && dot.isEmpty && sleep == null && tasksDone.isEmpty;
}
