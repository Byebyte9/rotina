import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../widgets/common.dart';
import '../widgets/task_list_item.dart';
import '../widgets/add_edit_sheet.dart';
import '../widgets/confirm_dialog.dart';

class TarefasScreen extends StatelessWidget {
  const TarefasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final tasks = [...state.tasks]..sort((a, b) => a.time.compareTo(b.time));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        const SectionLabel('Todas as tarefas'),
        AppCard(
          child: tasks.isEmpty
              ? const EmptyState(emoji: '✨', text: 'Nenhuma tarefa ainda')
              : Column(
                  children: tasks.asMap().entries.map((entry) {
                    final i = entry.key;
                    final t = entry.value;
                    final metaList = t.linkedMeta != null
                        ? state.metas.where((m) => m.id == t.linkedMeta).toList()
                        : const [];
                    final meta = metaList.isNotEmpty ? metaList.first : null;
                    return TaskListItem(
                      task: t,
                      linkedMeta: meta,
                      showBorder: i != tasks.length - 1,
                      onToggle: () => state.toggleTask(t.id),
                      onEdit: () => showAddEditSheet(context, editingTask: t),
                      onDelete: () => showAppConfirm(
                        context,
                        title: 'Excluir tarefa?',
                        body: '"${t.name}" será removida permanentemente.',
                        confirmLabel: 'Sim, excluir',
                        onConfirm: () => state.deleteTask(t.id),
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}
