import 'package:flutter/material.dart';
import '../../models/organization_model.dart';
import '../../services/category_service.dart';
import '../../services/organization_service.dart';
import '../color_picker.dart';

/// Self-contained modal for creating a new organization/projection.
/// Manages its own state (color, installments, name, value).
/// Call [CreateOrganizationModal.show] to open it.
class CreateOrganizationModal extends StatefulWidget {
  /// Called after the organization is successfully created.
  final VoidCallback onCreated;

  const CreateOrganizationModal({super.key, required this.onCreated});

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onCreated,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: CreateOrganizationModal(onCreated: onCreated),
            );
          },
        );
      },
    );
  }

  @override
  State<CreateOrganizationModal> createState() =>
      _CreateOrganizationModalState();
}

class _CreateOrganizationModalState extends State<CreateOrganizationModal> {
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();
  final _installmentsController = TextEditingController(text: '2');
  late final TextEditingController _hexController;

  Color _selectedColor = const Color(0xFF3B82F6);
  bool _isInstallment = false;
  int _installments = 2;

  @override
  void initState() {
    super.initState();
    _hexController = TextEditingController(
      text:
          '#${_selectedColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    _installmentsController.dispose();
    _hexController.dispose();
    super.dispose();
  }

  void _onColorChanged(Color color) {
    setState(() {
      _selectedColor = color;
      final hex = color
          .toARGB32()
          .toRadixString(16)
          .padLeft(8, '0')
          .substring(2)
          .toUpperCase();
      _hexController.text = '#$hex';
    });
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    final value =
        double.tryParse(_valueController.text.replaceAll(',', '.')) ?? 0;

    if (name.isEmpty || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe nome e valor válidos.')),
      );
      return;
    }

    final installments = _isInstallment ? _installments : 1;

    final org = OrganizationModel(
      name: name,
      quantity: value,
      description: '',
      createdAt: DateTime.now(),
      completed: false,
      color: _selectedColor.toARGB32(),
      installments: installments,
    );

    await OrganizationService.insert(org);

    final categoryId = await CategoryService.getOrCreate(name, 'expense');
    await CategoryService.update(categoryId, name, _selectedColor.toARGB32());

    if (!mounted) return;
    widget.onCreated();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final previewName = _nameController.text.trim().isEmpty
        ? 'Nome da Projeção'
        : _nameController.text.trim();
    final previewValue =
        double.tryParse(_valueController.text.replaceAll(',', '.')) ?? 0;
    final perMonthValue =
        previewValue / (_isInstallment && _installments > 0 ? _installments : 1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Nova Projeção',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Nome da Projeção'),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Ex: Viagem, Comprar casa, Carro, etc.',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Valor a Reservar'),
            const SizedBox(height: 8),
            TextField(
              controller: _valueController,
              onChanged: (_) => setState(() {}),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                prefixText: 'R\$ ',
                hintText: '0,00',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),
            ColorPicker(
                color: _selectedColor, onColorChanged: _onColorChanged),
            const SizedBox(height: 12),
            TextField(
              controller: _hexController,
              decoration: const InputDecoration(
                  labelText: 'Hex', border: OutlineInputBorder()),
              onChanged: (hex) {
                final cleaned = hex.replaceAll('#', '').trim();
                if (cleaned.length == 6) {
                  final parsed = int.tryParse(cleaned, radix: 16);
                  if (parsed != null) {
                    setState(
                        () => _selectedColor = Color(0xFF000000 | parsed));
                  }
                }
              },
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: _isInstallment,
              onChanged: (value) =>
                  setState(() => _isInstallment = value ?? false),
              title: const Text('Parcelado'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            if (_isInstallment) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _installmentsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Meses',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) {
                  final parsed = int.tryParse(value);
                  if (parsed != null && parsed > 0) {
                    setState(() {
                      _installments = parsed;
                    });
                  }
                },
              ),
            ],
            const SizedBox(height: 20),
            const Text('Preview'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black.withAlpha((0.05 * 255).round()),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _selectedColor
                              .withAlpha((0.2 * 255).round()),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                                color: _selectedColor,
                                shape: BoxShape.circle),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(previewName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              'R\$ ${previewValue.toStringAsFixed(2)}',
                              style:
                                  TextStyle(color: _selectedColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_isInstallment) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Por mês: R\$ ${perMonthValue.toStringAsFixed(2)}',
                      style: TextStyle(color: _selectedColor),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _create,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Criar Projeção',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
