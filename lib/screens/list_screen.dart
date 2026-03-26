import 'package:flutter/material.dart';
import '../models/temporary_list_item_model.dart';
import '../models/temporary_list_model.dart';
import '../services/temporary_list_service.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  List<TemporaryListModel> _lists = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLists();
  }

  Future<void> _loadLists() async {
    final lists = await TemporaryListService.getAllLists();
    if (!mounted) return;
    setState(() {
      _lists = lists;
      _loading = false;
    });
  }

  Future<void> _addList() async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nova lista'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Nome da lista (opcional)',
              hintText: 'Ex.: Mercado da semana',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Adicionar'),
            ),
          ],
        );
      },
    );

    if (name == null) return;

    await TemporaryListService.createList(name);
    await _loadLists();
  }

  Future<void> _deleteList(TemporaryListModel list) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir lista'),
          content: Text(
            'Deseja excluir "${list.name}"? Todos os itens também serão removidos.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await TemporaryListService.deleteList(list.id!);
    await _loadLists();
  }

  Future<void> _openList(TemporaryListModel list) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => _ListDetailsScreen(list: list)),
    );

    await _loadLists();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lista Temporaria')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addList,
        icon: const Icon(Icons.add),
        label: const Text('Adicionar lista'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _lists.isEmpty
          ? const Center(
              child: Text(
                'Nenhuma lista criada\nToque em "Adicionar lista" para começar.',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _lists.length,
              itemBuilder: (context, index) {
                final list = _lists[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(Icons.list_alt_rounded),
                    title: Text(list.name),
                    subtitle: const Text('Toque para abrir e adicionar itens'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteList(list),
                    ),
                    onTap: () => _openList(list),
                  ),
                );
              },
            ),
    );
  }
}

class _ListDetailsScreen extends StatefulWidget {
  final TemporaryListModel list;

  const _ListDetailsScreen({required this.list});

  @override
  State<_ListDetailsScreen> createState() => _ListDetailsScreenState();
}

class _ListDetailsScreenState extends State<_ListDetailsScreen> {
  List<TemporaryListItemModel> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final items = await TemporaryListService.getItems(widget.list.id!);
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _addItem() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Novo item'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nome do item'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Adicionar'),
            ),
          ],
        );
      },
    );

    if (value == null) return;
    if (value.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O nome do item é obrigatório.')),
      );
      return;
    }

    await TemporaryListService.addItem(widget.list.id!, value);
    await _loadItems();
  }

  Future<void> _deleteItem(TemporaryListItemModel item) async {
    await TemporaryListService.deleteItem(item.id!);
    await _loadItems();
  }

  Future<void> _toggleItem(TemporaryListItemModel item, bool? completed) async {
    await TemporaryListService.setItemCompleted(item.id!, completed ?? false);
    await _loadItems();
  }

  Future<void> _deleteCurrentList() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir lista'),
          content: Text(
            'Deseja excluir "${widget.list.name}"? Todos os itens também serão removidos.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await TemporaryListService.deleteList(widget.list.id!);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.list.name),
        actions: [
          IconButton(
            tooltip: 'Excluir lista',
            onPressed: _deleteCurrentList,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addItem,
        icon: const Icon(Icons.add),
        label: const Text('Adicionar item'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? const Center(
              child: Text(
                'Nenhum item nesta lista\nToque em "Adicionar item".',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Checkbox(
                      value: item.completed,
                      onChanged: (value) => _toggleItem(item, value),
                    ),
                    title: Text(
                      item.name,
                      style: TextStyle(
                        decoration: item.completed
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: item.completed ? Colors.grey[600] : null,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteItem(item),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
