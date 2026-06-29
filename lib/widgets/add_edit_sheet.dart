import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../models/meta.dart';
import '../models/recurrence.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import 'pickers.dart';
import 'recurrence_picker.dart';

enum _AddType { task, meta }

/// Abre o bottom sheet de criar/editar tarefa ou meta.
/// [editingTask] / [editingMeta]: se informado, o sheet abre em modo edição.
Future<void> showAddEditSheet(
  BuildContext context, {
  Task? editingTask,
  Meta? editingMeta,
}) async {
  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _AddEditSheet(editingTask: editingTask, editingMeta: editingMeta),
  );
}

class _AddEditSheet extends StatefulWidget {
  final Task? editingTask;
  final Meta? editingMeta;
  const _AddEditSheet({this.editingTask, this.editingMeta});

  @override
  State<_AddEditSheet> createState() => _AddEditSheetState();
}

class _AddEditSheetState extends State<_AddEditSheet> {
  late _AddType type;
  final nameCtrl = TextEditingController();
  String time = '09:00';
  TaskWeight weight = TaskWeight.medium;
  Recurrence recurrence = Recurrence.none();
  int? linkedMetaId;

  MetaType metaType = MetaType.count;
  final targetCtrl = TextEditingController(text: '10');
  final unitCtrl = TextEditingController();
  MetaColor metaColor = MetaColor.green;

  bool get isEditing => widget.editingTask != null || widget.editingMeta != null;

  @override
  void initState() {
    super.initState();
    if (widget.editingTask != null) {
      type = _AddType.task;
      final t = widget.editingTask!;
      nameCtrl.text = t.name;
      time = t.time;
      weight = t.weight;
      recurrence = t.recurrence;
      linkedMetaId = t.linkedMeta;
    } else if (widget.editingMeta != null) {
      type = _AddType.meta;
      final m = widget.editingMeta!;
      nameCtrl.text = m.name;
      metaType = m.type;
      targetCtrl.text = m.target == m.target.roundToDouble()
          ? m.target.toInt().toString()
          : m.target.toString();
      unitCtrl.text = m.unit;
      metaColor = m.color;
    } else {
      type = _AddType.task;
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    targetCtrl.dispose();
    unitCtrl.dispose();
    super.dispose();
  }

  Future<bool> _confirmDiscardIfNeeded() async {
    if (nameCtrl.text.trim().isEmpty) return true;
    final c = AppTheme.of(context);
    final discard = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          decoration: BoxDecoration(
            color: c.surface,
            border: Border.all(color: c.border),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Descartar alterações?',
                  style: AppFonts.playfair(color: c.cream, fontSize: 18), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Você tem dados não salvos. Se fechar agora, eles serão perdidos.',
                  style: AppFonts.inter(color: c.textMuted, fontSize: 13).copyWith(height: 1.5),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.gold,
                    foregroundColor: const Color(0xFF1A1000),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Descartar', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.textSoft,
                    backgroundColor: c.card,
                    side: BorderSide(color: c.border),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Continuar editando'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return discard ?? false;
  }

  Future<void> _save() async {
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;
    final state = context.read<AppState>();

    if (type == _AddType.task) {
      if (widget.editingTask != null) {
        widget.editingTask!
          ..name = name
          ..time = time
          ..weight = weight
          ..recurrence = recurrence
          ..linkedMeta = linkedMetaId;
        await state.updateTask(widget.editingTask!);
      } else {
        await state.addTask(Task(
          id: state.nextId(), // Bug 7 fix: usa o gerador central de IDs
          name: name,
          time: time,
          weight: weight,
          recurrence: recurrence,
          linkedMeta: linkedMetaId,
        ));
      }
    } else {
      final target = double.tryParse(targetCtrl.text.replaceAll(',', '.')) ?? 10;
      final unit = unitCtrl.text.trim().isEmpty ? 'vezes' : unitCtrl.text.trim();
      if (widget.editingMeta != null) {
        widget.editingMeta!
          ..name = name
          ..type = metaType
          ..target = target
          ..unit = unit
          ..color = metaColor;
        await state.updateMetaFields(widget.editingMeta!);
      } else {
        await state.addMeta(Meta(
          id: state.nextId(), // Bug 7 fix: usa o gerador central de IDs
          name: name,
          type: metaType,
          target: target,
          unit: unit,
          color: metaColor,
        ));
      }
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final state = context.watch<AppState>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _confirmDiscardIfNeeded();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: SafeArea(
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
          decoration: BoxDecoration(
            color: c.surface,
            border: Border.all(color: c.border),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16, 20, 16, 16 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: c.border,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                Text(
                  isEditing
                      ? (type == _AddType.task ? 'Editar tarefa' : 'Editar meta')
                      : (type == _AddType.task ? 'Nova tarefa' : 'Nova meta'),
                  style: AppFonts.playfair(color: c.cream, fontSize: 18),
                ),
                const SizedBox(height: 16),

                if (!isEditing) ...[
                  _FieldLabel('Tipo'),
                  _SelectField(
                    label: type == _AddType.task ? 'Tarefa' : 'Meta',
                    onTap: () async {
                      final result = await showSelectSheet<_AddType>(
                        context,
                        title: 'Tipo',
                        selected: type,
                        options: const [
                          (value: _AddType.task, label: 'Tarefa'),
                          (value: _AddType.meta, label: 'Meta'),
                        ],
                      );
                      if (result != null) setState(() => type = result);
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                _FieldLabel('Nome'),
                _TextField(controller: nameCtrl, hint: 'Ex: Estudar inglês'),
                const SizedBox(height: 12),

                if (type == _AddType.task) ..._buildTaskFields(c, state) else ..._buildMetaFields(c),

                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.creamSoft,
                      foregroundColor: c.bg,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: Text(isEditing ? 'Salvar' : 'Criar',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTaskFields(AppColors c, AppState state) {
    final weightLabels = {
      TaskWeight.light: 'Leve',
      TaskWeight.medium: 'Médio',
      TaskWeight.heavy: 'Pesado',
    };
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldLabel('Horário'),
                _SelectField(
                  label: time,
                  icon: Icons.access_time,
                  onTap: () async {
                    final result = await showTimePickerSheet(context, initialTime: time, title: 'Horário');
                    if (result != null) setState(() => time = result);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldLabel('Peso'),
                _SelectField(
                  label: weightLabels[weight]!,
                  onTap: () async {
                    final result = await showSelectSheet<TaskWeight>(
                      context,
                      title: 'Peso',
                      selected: weight,
                      options: [
                        (value: TaskWeight.light, label: 'Leve'),
                        (value: TaskWeight.medium, label: 'Médio'),
                        (value: TaskWeight.heavy, label: 'Pesado'),
                      ],
                    );
                    if (result != null) setState(() => weight = result);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      RecurrencePicker(
        initial: recurrence,
        onChanged: (r) => recurrence = r,
      ),
      const SizedBox(height: 14),
      _FieldLabel('Vincular a meta (opcional)'),
      _SelectField(
        label: () {
          if (linkedMetaId == null) return 'Nenhuma';
          final matches = state.metas.where((m) => m.id == linkedMetaId);
          return matches.isNotEmpty ? matches.first.name : 'Nenhuma';
        }(),
        onTap: () async {
          final options = <({int? value, String label})>[
            (value: null, label: 'Nenhuma'),
            ...state.metas.map((m) => (value: m.id, label: m.name)),
          ];
          final result = await showSelectSheet<int?>(
            context,
            title: 'Vincular a meta',
            selected: linkedMetaId,
            options: options,
          );
          setState(() => linkedMetaId = result);
        },
      ),
      const SizedBox(height: 12),
    ];
  }

  List<Widget> _buildMetaFields(AppColors c) {
    final typeLabels = {
      MetaType.hours: 'Horas de foco',
      MetaType.count: 'Quantidade de vezes',
      MetaType.habit: 'Hábito diário',
    };
    final colorLabels = {
      MetaColor.green: 'Verde',
      MetaColor.blue: 'Azul',
      MetaColor.orange: 'Laranja',
      MetaColor.purple: 'Roxo',
      MetaColor.gold: 'Dourado',
    };
    return [
      _FieldLabel('Tipo de meta'),
      _SelectField(
        label: typeLabels[metaType]!,
        onTap: () async {
          final result = await showSelectSheet<MetaType>(
            context,
            title: 'Tipo de meta',
            selected: metaType,
            options: [
              (value: MetaType.hours, label: 'Horas de foco'),
              (value: MetaType.count, label: 'Quantidade de vezes'),
              (value: MetaType.habit, label: 'Hábito diário'),
            ],
          );
          if (result != null) setState(() => metaType = result);
        },
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldLabel('Meta total'),
                _TextField(controller: targetCtrl, hint: 'Ex: 30', keyboardType: TextInputType.number),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldLabel('Unidade'),
                _TextField(controller: unitCtrl, hint: 'horas / vezes'),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _FieldLabel('Cor'),
      _SelectField(
        label: colorLabels[metaColor]!,
        onTap: () async {
          final result = await showSelectSheet<MetaColor>(
            context,
            title: 'Cor',
            selected: metaColor,
            options: [
              (value: MetaColor.green, label: 'Verde'),
              (value: MetaColor.blue, label: 'Azul'),
              (value: MetaColor.orange, label: 'Laranja'),
              (value: MetaColor.purple, label: 'Roxo'),
              (value: MetaColor.gold, label: 'Dourado'),
            ],
          );
          if (result != null) setState(() => metaColor = result);
        },
      ),
      const SizedBox(height: 12),
    ];
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: AppFonts.inter(color: c.textMuted, fontSize: 11, fontWeight: FontWeight.w600)
            .copyWith(letterSpacing: 0.5),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  const _TextField({required this.controller, required this.hint, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: AppFonts.inter(color: c.text, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppFonts.inter(color: c.textMuted, fontSize: 14),
        filled: true,
        fillColor: c.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c.creamSoft),
        ),
      ),
    );
  }
}

class _SelectField extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData icon;
  const _SelectField({required this.label, required this.onTap, this.icon = Icons.keyboard_arrow_down});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: c.card,
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.inter(color: c.text, fontSize: 14)),
            ),
            Icon(icon, size: 16, color: c.textMuted),
          ],
        ),
      ),
    );
  }
}
