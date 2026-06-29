import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/meta.dart';
import '../theme/app_theme.dart';
import 'common.dart';
import 'item_menu.dart';

/// Item de tarefa na lista — equivalente a `taskHTML()` no JS.
class TaskListItem extends StatelessWidget {
  final Task task;
  final Meta? linkedMeta;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool showBorder;

  const TaskListItem({
    super.key,
    required this.task,
    this.linkedMeta,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: showBorder
          ? BoxDecoration(border: Border(bottom: BorderSide(color: c.border)))
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                color: task.done ? c.green : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: task.done ? c.green : c.border, width: 2),
              ),
              child: task.done
                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.name,
                  style: AppFonts.inter(
                    color: task.done ? c.textMuted : c.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ).copyWith(
                    decoration: task.done ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (task.time.isNotEmpty)
                      AppTag(label: '⏰ ${task.time}', color: c.blue),
                    if (task.recurrence.isRecurrent)
                      const NeutralTag(label: '🔄 recorrente'),
                    if (linkedMeta != null)
                      AppTag(label: '🎯 ${linkedMeta!.name}', color: c.green),
                    if (task.weight == TaskWeight.heavy)
                      AppTag(label: 'pesada', color: c.orange),
                  ],
                ),
              ],
            ),
          ),
          ItemMenuButton(onEdit: onEdit, onDelete: onDelete),
        ],
      ),
    );
  }
}
