import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Menu de 3 pontinhos com "Editar" / "Excluir" — equivalente a
/// `itemMenuHTML()` + `toggleItemMenu()` no JS. Usa PopupMenuButton nativo.
class ItemMenuButton extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ItemMenuButton({super.key, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: c.textMuted, size: 20),
      padding: EdgeInsets.zero,
      color: c.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: c.border),
      ),
      onSelected: (value) {
        if (value == 'edit') onEdit();
        if (value == 'delete') onDelete();
      },
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 16, color: c.text),
              const SizedBox(width: 8),
              Text('Editar', style: TextStyle(color: c.text, fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 16, color: c.red),
              const SizedBox(width: 8),
              Text('Excluir', style: TextStyle(color: c.red, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}
