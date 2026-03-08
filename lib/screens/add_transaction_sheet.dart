import 'package:flutter/material.dart';
import '../core/database/database_helper.dart';
import '../models/transaction_model.dart';

class AddTransactionSheet extends StatefulWidget {
  final VoidCallback? onSaved;

  const AddTransactionSheet({super.key, this.onSaved});

  @override
  _AddTransactionSheetState createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  List<Map<String, dynamic>> categories = [];
  TransactionType _type = TransactionType.expense;
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  int? selectedCategoryId;

  Future<void> loadCategories() async {
    final data = await DatabaseHelper.instance.getCategories(_type.name);

    setState(() {
      categories = data;

      if (categories.isNotEmpty) {
        selectedCategoryId = categories.first['id'];
      }
    });
  }

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  Future<void> _save() async {
    if (_valueController.text.isEmpty) return;

    await DatabaseHelper.instance.insertTransaction(
      TransactionModel(
        name: _descController.text.isEmpty
            ? 'Sem descrição'
            : _descController.text,
        quantity: double.parse(_valueController.text),
        description: _descController.text,
        categoryId: selectedCategoryId ?? 1,
        date: DateTime.now(),
        type: _type,
      ),
    );

    widget.onSaved?.call();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Nova Transação",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),

              /// Toggle Tipo
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _type == TransactionType.expense
                            ? Colors.red
                            : Colors.grey.shade300,
                      ),
                      onPressed: () {
                        setState(() {
                          _type = TransactionType.expense;
                        });

                        loadCategories();
                      },
                      child: Text(
                        "Gasto",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _type == TransactionType.income
                            ? Colors.green
                            : Colors.grey.shade300,
                      ),
                      onPressed: () {
                        setState(() {
                          _type = TransactionType.income;
                        });

                        loadCategories();
                      },
                      child: Text(
                        "Ganho",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),

              TextField(
                controller: _valueController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: "Valor"),
              ),

              SizedBox(height: 15),

              DropdownButtonFormField<int>(
                initialValue: selectedCategoryId,
                decoration: InputDecoration(
                  labelText: "Categoria",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: categories.map((category) {
                  return DropdownMenuItem<int>(
                    value: category['id'],
                    child: Text(category['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCategoryId = value!;
                  });
                },
              ),

              SizedBox(height: 15),

              TextField(
                controller: _descController,
                decoration: InputDecoration(labelText: "Descrição"),
              ),

              SizedBox(height: 25),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _type == TransactionType.expense
                      ? Colors.red
                      : Colors.green,
                  minimumSize: Size(double.infinity, 50),
                ),
                onPressed: _save,
                child: Text(
                  _type == TransactionType.expense
                      ? "Adicionar Gasto"
                      : "Adicionar Ganho",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
