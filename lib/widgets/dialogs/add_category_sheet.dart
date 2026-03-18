import 'package:flutter/material.dart';
import '../../services/category_service.dart';
import '../color_picker.dart';

/// Modal bottom sheet for creating or editing a category.
/// Use [AddCategorySheet.show] to display it and get back the saved category id.
class AddCategorySheet extends StatefulWidget {
  final String initialName;
  final int initialColor;
  final int? categoryId;
  final String type; // 'expense' or 'income'

  const AddCategorySheet({
    super.key,
    this.initialName = '',
    this.initialColor = 0xFF2196F3,
    this.categoryId,
    required this.type,
  });

  static Future<int?> show(
    BuildContext context, {
    String initialName = '',
    int initialColor = 0xFF2196F3,
    int? categoryId,
    required String type,
  }) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: AddCategorySheet(
                    initialName: initialName,
                    initialColor: initialColor,
                    categoryId: categoryId,
                    type: type,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  State<AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<AddCategorySheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _hexController;
  late int _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
    _nameController = TextEditingController(text: widget.initialName);
    _hexController = TextEditingController(
      text:
          '#${widget.initialColor.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hexController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.categoryId != null ? 'Editar categoria' : 'Nova categoria',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Nome'),
        ),
        const SizedBox(height: 14),
        ColorPicker(
          color: Color(_selectedColor),
          onColorChanged: (color) {
            setState(() {
              _selectedColor = color.toARGB32();
              final hex = color
                  .toARGB32()
                  .toRadixString(16)
                  .padLeft(8, '0')
                  .substring(2)
                  .toUpperCase();
              _hexController.text = '#$hex';
            });
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _hexController,
          decoration: const InputDecoration(
            labelText: 'Hex',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            final hex = value.replaceAll('#', '').trim();
            if (hex.length == 6) {
              final parsed = int.tryParse(hex, radix: 16);
              if (parsed != null) {
                setState(() => _selectedColor = 0xFF000000 | parsed);
              }
            }
          },
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancelar'),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () async {
                final name = _nameController.text.trim();
                if (name.isEmpty) return;

                final navigator = Navigator.of(context);
                final colorValue = _selectedColor;

                if (widget.categoryId != null) {
                  await CategoryService.update(
                      widget.categoryId!, name, colorValue);
                  navigator.pop(widget.categoryId);
                  return;
                }

                final newId =
                    await CategoryService.insert(name, widget.type, colorValue);
                navigator.pop(newId);
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ],
    );
  }
}
