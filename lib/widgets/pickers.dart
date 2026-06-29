import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Bottom sheet com wheel picker de horário (HH:mm) — equivalente ao
/// painel `ctimePanelOverlay` (colunas de hora/minuto com scroll-snap) do JS.
Future<String?> showTimePickerSheet(
  BuildContext context, {
  required String initialTime, // 'HH:mm'
  String title = 'Selecionar horário',
}) async {
  final c = AppTheme.of(context);
  final parts = initialTime.split(':');
  int hour = int.tryParse(parts[0]) ?? 0;
  int minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;

  final result = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          decoration: BoxDecoration(
            color: c.surface,
            border: Border.all(color: c.border),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(title, style: AppFonts.playfair(color: c.cream, fontSize: 15)),
              ),
              SizedBox(
                height: 180,
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoPicker(
                        backgroundColor: Colors.transparent,
                        itemExtent: 40,
                        scrollController: FixedExtentScrollController(initialItem: hour),
                        selectionOverlay: _pickerOverlay(c),
                        onSelectedItemChanged: (i) => hour = i,
                        children: List.generate(
                          24,
                          (i) => Center(
                            child: Text(i.toString().padLeft(2, '0'),
                                style: AppFonts.inter(color: c.text, fontSize: 18)),
                          ),
                        ),
                      ),
                    ),
                    Text(':', style: AppFonts.playfair(color: c.cream, fontSize: 22)),
                    Expanded(
                      child: CupertinoPicker(
                        backgroundColor: Colors.transparent,
                        itemExtent: 40,
                        scrollController: FixedExtentScrollController(initialItem: minute),
                        selectionOverlay: _pickerOverlay(c),
                        onSelectedItemChanged: (i) => minute = i,
                        children: List.generate(
                          60,
                          (i) => Center(
                            child: Text(i.toString().padLeft(2, '0'),
                                style: AppFonts.inter(color: c.text, fontSize: 18)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: c.textSoft,
                        backgroundColor: c.card,
                        side: BorderSide(color: c.border),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final value =
                            '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
                        Navigator.of(ctx).pop(value);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.creamSoft,
                        foregroundColor: c.bg,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Definir', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
  return result;
}

Widget _pickerOverlay(AppColors c) {
  return Container(
    decoration: BoxDecoration(
      border: Border.symmetric(
        horizontal: BorderSide(color: c.border),
      ),
    ),
  );
}

/// Bottom sheet de seleção genérica (lista de opções com check) —
/// equivalente ao painel `cselPanelOverlay` do JS.
Future<T?> showSelectSheet<T>(
  BuildContext context, {
  required String title,
  required List<({T value, String label})> options,
  required T selected,
}) async {
  final c = AppTheme.of(context);
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return SafeArea(
        child: Container(
          constraints: const BoxConstraints(maxHeight: 420),
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
          decoration: BoxDecoration(
            color: c.surface,
            border: Border.all(color: c.border),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(title, style: AppFonts.playfair(color: c.cream, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: options.map((o) {
                    final isSelected = o.value == selected;
                    return InkWell(
                      onTap: () => Navigator.of(ctx).pop(o.value),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(
                          color: isSelected ? c.card : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              o.label,
                              style: AppFonts.inter(
                                color: isSelected ? c.cream : c.textSoft,
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                            if (isSelected) Icon(Icons.check, size: 16, color: c.green),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
