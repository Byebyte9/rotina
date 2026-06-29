import 'package:flutter/material.dart';
import '../models/recurrence.dart';
import '../theme/app_theme.dart';

const _monthNamesFull = [
  'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
];
const _monthNamesShort = [
  'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
];
const _dowLabels = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];

String _fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Widget completo de seleção de recorrência — equivalente ao bloco
/// "Recorrência" do addSheet no JS (modos none/repeat/custom, com
/// seletor de frequência, período, dias da semana/mês/ano e calendário
/// de pré-visualização / seleção).
class RecurrencePicker extends StatefulWidget {
  final Recurrence initial;
  final ValueChanged<Recurrence> onChanged;

  const RecurrencePicker({super.key, required this.initial, required this.onChanged});

  @override
  State<RecurrencePicker> createState() => _RecurrencePickerState();
}

class _RecurrencePickerState extends State<RecurrencePicker> {
  late RecMode mode;
  late int freq;
  late RecPeriod period;
  late List<String> days; // formato depende do period/mode

  // navegação do calendário "mês" / "ano-modal"
  DateTime monthCalCursor = DateTime(DateTime.now().year, DateTime.now().month);
  int? yearModalMonthIdx;
  DateTime customCalCursor = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    mode = widget.initial.mode;
    freq = widget.initial.freq;
    period = widget.initial.period;
    days = List.from(widget.initial.days);
  }

  void _emit() {
    widget.onChanged(Recurrence(mode: mode, freq: freq, period: period, days: days));
  }

  void _setMode(RecMode m) {
    setState(() {
      mode = m;
      if (mode == RecMode.repeat || mode == RecMode.custom) {
        days = [];
      }
    });
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('RECORRÊNCIA',
            style: AppFonts.inter(color: c.textMuted, fontSize: 11, fontWeight: FontWeight.w600)
                .copyWith(letterSpacing: 0.5)),
        const SizedBox(height: 6),
        Row(
          children: [
            _modeChip(c, 'Sem recorrência', RecMode.none),
            const SizedBox(width: 8),
            _modeChip(c, 'Com recorrência', RecMode.repeat),
            const SizedBox(width: 8),
            _modeChip(c, 'Personalizado', RecMode.custom),
          ],
        ),
        if (mode == RecMode.repeat) ...[
          const SizedBox(height: 14),
          _buildRepeatPanel(c),
        ],
        if (mode == RecMode.custom) ...[
          const SizedBox(height: 14),
          _buildCustomCalendar(c),
        ],
      ],
    );
  }

  Widget _modeChip(AppColors c, String label, RecMode m) {
    final active = mode == m;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setMode(m),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? c.creamSoft : c.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: active ? c.creamSoft : c.border),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppFonts.inter(
              color: active ? c.bg : c.textSoft,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // ── MODO "COM RECORRÊNCIA" ──
  Widget _buildRepeatPanel(AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Repetir', style: AppFonts.inter(color: c.textSoft, fontSize: 13)),
            const SizedBox(width: 10),
            _freqStepper(c),
            const SizedBox(width: 10),
            Text('vezes por', style: AppFonts.inter(color: c.textMuted, fontSize: 13)),
            const SizedBox(width: 10),
            Expanded(child: _periodSelector(c)),
          ],
        ),
        const SizedBox(height: 12),
        if (period == RecPeriod.semana) _weekDaysRow(c),
        if (period == RecPeriod.semana) const SizedBox(height: 10),
        _previewCalendar(c),
      ],
    );
  }

  Widget _freqStepper(AppColors c) {
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.remove, size: 16, color: c.textSoft),
            onPressed: freq > 1
                ? () {
                    setState(() {
                      freq--;
                      _enforceDayLimit();
                    });
                    _emit();
                  }
                : null,
          ),
          SizedBox(
            width: 22,
            child: Text(
              '$freq',
              textAlign: TextAlign.center,
              style: AppFonts.inter(color: c.cream, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.add, size: 16, color: c.textSoft),
            onPressed: freq < 31
                ? () {
                    setState(() => freq++);
                    _emit();
                  }
                : null,
          ),
        ],
      ),
    );
  }

  void _enforceDayLimit() {
    if (period == RecPeriod.semana && days.length > freq) {
      days = days.sublist(0, freq);
    }
  }

  Widget _periodSelector(AppColors c) {
    final opts = [
      (RecPeriod.semana, 'semana'),
      (RecPeriod.mes, 'mês'),
      (RecPeriod.ano, 'ano'),
    ];
    return Wrap(
      spacing: 6,
      children: opts.map((o) {
        final active = period == o.$1;
        return GestureDetector(
          onTap: () {
            setState(() {
              period = o.$1;
              days = [];
            });
            _emit();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: active ? c.creamSoft : c.card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: active ? c.creamSoft : c.border),
            ),
            child: Text(o.$2,
                style: AppFonts.inter(
                  color: active ? c.bg : c.textSoft,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                )),
          ),
        );
      }).toList(),
    );
  }

  Widget _weekDaysRow(AppColors c) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (dow) {
        final key = dow.toString();
        final isOn = days.contains(key);
        final limitReached = !isOn && days.length >= freq;
        return GestureDetector(
          onTap: limitReached
              ? null
              : () {
                  setState(() {
                    if (isOn) {
                      days.remove(key);
                    } else {
                      days.add(key);
                    }
                  });
                  _emit();
                },
          child: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOn ? c.green.withValues(alpha: 0.15) : c.card,
              border: Border.all(color: isOn ? c.green : c.border),
            ),
            child: Text(
              _dowLabels[dow],
              style: AppFonts.inter(
                color: isOn ? c.green : (limitReached ? c.textMuted.withValues(alpha: 0.4) : c.textSoft),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _previewCalendar(AppColors c) {
    if (period == RecPeriod.semana) {
      return _MiniCalendar(
        cursor: monthCalCursor,
        readOnly: true,
        isMarked: (date) {
          final dow = date.weekday % 7;
          return days.contains(dow.toString());
        },
      );
    } else if (period == RecPeriod.mes) {
      return Column(
        children: [
          _MiniCalendar(
            cursor: monthCalCursor,
            onNav: (dir) {
              setState(() {
                monthCalCursor = DateTime(monthCalCursor.year, monthCalCursor.month + dir);
              });
            },
            isMarked: (date) => days.contains(date.day.toString()),
            isSelectable: (date) {
              final limitReached = !days.contains(date.day.toString()) && days.length >= freq;
              return !limitReached;
            },
            onDayTap: (date) {
              setState(() {
                final key = date.day.toString();
                if (days.contains(key)) {
                  days.remove(key);
                } else if (days.length < freq) {
                  days.add(key);
                }
              });
              _emit();
            },
          ),
          const SizedBox(height: 8),
          Text(
            days.isEmpty
                ? 'Selecione até $freq dia${freq > 1 ? 's' : ''} do mês'
                : 'Dias selecionados: ${(days.map(int.parse).toList()..sort()).join(', ')} (${days.length}/$freq)',
            style: AppFonts.inter(color: c.textMuted, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      );
    } else {
      return _yearGrid(c);
    }
  }

  Widget _yearGrid(AppColors c) {
    final year = DateTime.now().year;
    final today = DateTime.now();
    return Column(
      children: [
        Text(
          'Toque em um mês e escolha os dias · até $freq ${freq == 1 ? 'dia' : 'dias'} no ano',
          style: AppFonts.inter(color: c.textMuted, fontSize: 11),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.3,
          ),
          itemCount: 12,
          itemBuilder: (ctx, m) {
            final isPast = year == today.year && m < today.month - 1;
            final pickedInMonth =
                days.where((d) => d.startsWith('$year-${(m + 1).toString().padLeft(2, '0')}-')).length;
            return GestureDetector(
              onTap: isPast
                  ? null
                  : () async {
                      await _openYearMonthModal(c, m);
                    },
              child: Container(
                decoration: BoxDecoration(
                  color: pickedInMonth > 0 ? c.green.withValues(alpha: 0.12) : c.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: pickedInMonth > 0 ? c.green : c.border,
                  ),
                ),
                alignment: Alignment.center,
                child: Opacity(
                  opacity: isPast ? 0.4 : 1,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_monthNamesShort[m],
                          style: AppFonts.inter(
                              color: c.text, fontSize: 12, fontWeight: FontWeight.w600)),
                      Text(
                        pickedInMonth > 0 ? '$pickedInMonth dia${pickedInMonth > 1 ? 's' : ''}' : '—',
                        style: AppFonts.inter(
                          color: pickedInMonth > 0 ? c.green : c.textMuted,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        if (days.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            '${days.length}/$freq dias usados no ano',
            style: AppFonts.inter(color: c.textMuted, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Future<void> _openYearMonthModal(AppColors c, int monthIdx) async {
    final year = DateTime.now().year;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModalState) {
          return SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              decoration: BoxDecoration(
                color: c.surface,
                border: Border.all(color: c.border),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${_monthNamesFull[monthIdx]} $year',
                          style: AppFonts.playfair(color: c.cream, fontSize: 16)),
                      IconButton(
                        icon: Icon(Icons.close, size: 18, color: c.textMuted),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  _MiniCalendar(
                    cursor: DateTime(year, monthIdx + 1),
                    isMarked: (date) => days.contains(_fmtDate(date)),
                    isSelectable: (date) {
                      final key = _fmtDate(date);
                      final limitReached = !days.contains(key) && days.length >= freq;
                      return !limitReached;
                    },
                    onDayTap: (date) {
                      final key = _fmtDate(date);
                      setModalState(() {
                        setState(() {
                          if (days.contains(key)) {
                            days.remove(key);
                          } else if (days.length < freq) {
                            days.add(key);
                          }
                        });
                      });
                      _emit();
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total no ano: ${days.length}/$freq',
                    style: AppFonts.inter(color: c.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
    setState(() {});
  }

  // ── MODO "PERSONALIZADO" (datas específicas) ──
  Widget _buildCustomCalendar(AppColors c) {
    return Column(
      children: [
        _MiniCalendar(
          cursor: customCalCursor,
          onNav: (dir) {
            setState(() {
              customCalCursor = DateTime(customCalCursor.year, customCalCursor.month + dir);
            });
          },
          isMarked: (date) => days.contains(_fmtDate(date)),
          onDayTap: (date) {
            setState(() {
              final key = _fmtDate(date);
              if (days.contains(key)) {
                days.remove(key);
              } else {
                days.add(key);
              }
            });
            _emit();
          },
        ),
        const SizedBox(height: 8),
        Text(
          days.isEmpty
              ? 'Toque nas datas em que a tarefa deve ocorrer'
              : '${days.length} data${days.length > 1 ? 's' : ''} selecionada${days.length > 1 ? 's' : ''}',
          style: AppFonts.inter(color: c.textMuted, fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Mini calendário mensal reutilizável — usado em preview de recorrência
/// semanal/mensal/anual e no modo personalizado.
class _MiniCalendar extends StatelessWidget {
  final DateTime cursor; // qualquer dia dentro do mês exibido
  final void Function(int dir)? onNav;
  final bool Function(DateTime date) isMarked;
  final bool Function(DateTime date)? isSelectable;
  final void Function(DateTime date)? onDayTap;
  final bool readOnly;

  const _MiniCalendar({
    required this.cursor,
    this.onNav,
    required this.isMarked,
    this.isSelectable,
    this.onDayTap,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final year = cursor.year;
    final month = cursor.month;
    final today = DateTime.now();
    final todayStr = _fmtDate(DateTime(today.year, today.month, today.day));
    final firstWeekday = DateTime(year, month, 1).weekday % 7;
    final daysInMonth = DateTime(year, month + 1, 0).day;

    final cells = <Widget>[];
    for (int i = 0; i < firstWeekday; i++) {
      cells.add(const SizedBox());
    }
    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(year, month, d);
      final dateStr = _fmtDate(date);
      final isPast = dateStr.compareTo(todayStr) < 0;
      final isToday = dateStr == todayStr;
      final marked = isMarked(date) && !isPast;
      final selectable = !readOnly && !isPast && (isSelectable?.call(date) ?? true);

      cells.add(
        GestureDetector(
          onTap: selectable ? () => onDayTap?.call(date) : null,
          child: Container(
            margin: const EdgeInsets.all(1),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: marked
                  ? c.green.withValues(alpha: 0.18)
                  : (isToday ? c.surface : Colors.transparent),
              borderRadius: BorderRadius.circular(6),
              border: marked ? Border.all(color: c.green, width: 1) : null,
            ),
            child: Opacity(
              opacity: isPast ? 0.35 : 1,
              child: Text(
                '$d',
                style: AppFonts.inter(
                  color: marked ? c.green : (isToday ? c.cream : c.textSoft),
                  fontSize: 11,
                  fontWeight: isToday || marked ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          if (onNav != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.chevron_left, size: 18, color: c.textSoft),
                    onPressed: () => onNav!(-1),
                  ),
                  Text('${_monthNamesFull[month - 1]} $year',
                      style: AppFonts.inter(color: c.cream, fontSize: 12, fontWeight: FontWeight.w600)),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.chevron_right, size: 18, color: c.textSoft),
                    onPressed: () => onNav!(1),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('${_monthNamesFull[month - 1]} $year',
                  style: AppFonts.inter(color: c.cream, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          Row(
            children: _dowLabels
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d,
                            style: AppFonts.inter(color: c.textMuted, fontSize: 9, fontWeight: FontWeight.w600)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 4),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.3,
            children: cells,
          ),
        ],
      ),
    );
  }
}
