/// Modos de recorrência de uma tarefa.
enum RecMode { none, repeat, custom }

/// Período da recorrência "repeat" (com recorrência).
enum RecPeriod { semana, mes, ano }

RecPeriod recPeriodFromString(String s) {
  switch (s) {
    case 'mês':
    case 'mes':
      return RecPeriod.mes;
    case 'ano':
      return RecPeriod.ano;
    default:
      return RecPeriod.semana;
  }
}

String recPeriodToString(RecPeriod p) {
  switch (p) {
    // BUG 12 fix: serializa sem acento. Antes gravava 'mês' (com acento),
    // o que o próprio app sempre leu de volta corretamente (fromJson aceita
    // os dois), mas é uma armadilha para qualquer consulta externa direta
    // ao banco/JSON (problemas de encoding, comparação case/acento-sensível,
    // URLs). Dados antigos com 'mês' continuam sendo lidos normalmente pelo
    // fallback em recPeriodFromString — esta mudança só afeta o que é
    // gravado a partir de agora.
    case RecPeriod.mes:
      return 'mes';
    case RecPeriod.ano:
      return 'ano';
    case RecPeriod.semana:
      return 'semana';
  }
}

/// Espelha o objeto `recurrence` do app original:
/// - mode: none | repeat | custom
/// - freq: quantas vezes por período (modo repeat)
/// - period: semana | mês | ano (modo repeat)
/// - days: dias da semana (0-6), dias do mês (1-31) ou datas 'YYYY-MM-DD' (ano),
///   guardados como List<String> para suportar todos os formatos
class Recurrence {
  final RecMode mode;
  final int freq;
  final RecPeriod period;
  final List<String> days; // semana: '0'-'6' | mês: '1'-'31' | ano/custom: 'YYYY-MM-DD'

  const Recurrence({
    this.mode = RecMode.none,
    this.freq = 1,
    this.period = RecPeriod.semana,
    this.days = const [],
  });

  factory Recurrence.none() => const Recurrence(mode: RecMode.none);

  bool get isRecurrent => mode != RecMode.none;

  Map<String, dynamic> toJson() {
    if (mode == RecMode.none) return {'mode': 'none'};
    if (mode == RecMode.repeat) {
      // 'days' é sempre serializado como lista de strings:
      // semana: '0'-'6' | mês: '1'-'31' | ano: 'YYYY-MM-DD'
      return {
        'mode': 'repeat',
        'freq': freq,
        'period': recPeriodToString(period),
        'days': List<String>.from(days),
      };
    }
    // custom
    return {'mode': 'custom', 'dates': days};
  }

  factory Recurrence.fromJson(dynamic json) {
    if (json == null) return Recurrence.none();
    if (json is String) {
      // formato legado: string simples tipo 'none'
      return Recurrence.none();
    }
    final map = Map<String, dynamic>.from(json as Map);
    final modeStr = map['mode'] as String? ?? 'none';
    if (modeStr == 'none') return Recurrence.none();
    if (modeStr == 'custom') {
      final dates = (map['dates'] as List?)?.map((e) => e.toString()).toList() ?? [];
      return Recurrence(mode: RecMode.custom, days: dates);
    }
    // repeat
    final period = recPeriodFromString(map['period'] as String? ?? 'semana');
    final rawDays = (map['days'] as List?) ?? [];
    final days = rawDays.map((e) => e.toString()).toList();
    return Recurrence(
      mode: RecMode.repeat,
      freq: (map['freq'] as num?)?.toInt() ?? 1,
      period: period,
      days: days,
    );
  }

  /// Verifica se a tarefa ocorre na [date] informada.
  bool matchesDate(DateTime date) {
    if (mode == RecMode.none) return true;
    if (mode == RecMode.repeat) {
      if (period == RecPeriod.semana) {
        final dow = date.weekday % 7; // Dart: Mon=1..Sun=7 -> queremos 0=Dom
        return days.contains(dow.toString());
      }
      if (period == RecPeriod.mes) {
        return days.contains(date.day.toString());
      }
      if (period == RecPeriod.ano) {
        // days guarda datas 'YYYY-MM-DD'; comparamos mês+dia se ano bater no padrão de uso
        // (no app original, o ano grava 'YYYY-MM-DD' completas, então comparamos mês/dia)
        final monthDay =
            '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        return days.any((d) {
          final parts = d.split('-');
          if (parts.length != 3) return false;
          return '${parts[1]}-${parts[2]}' == monthDay;
        });
      }
    }
    if (mode == RecMode.custom) {
      final key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      return days.contains(key);
    }
    return true;
  }
}
