import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/storage/app_prefs.dart';
import '../colleagues/colleagues_service.dart';
import '../items/items_service.dart';
import '../items/item_model.dart';
import '../colleagues/colleague_model.dart';

class AddBatchItemSheet extends StatefulWidget {
  const AddBatchItemSheet({super.key});

  @override
  State<AddBatchItemSheet> createState() => _AddBatchItemSheetState();
}

class _AddBatchItemSheetState extends State<AddBatchItemSheet> {
  final _priceCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late final ColleaguesService _colleaguesService;
  late final ItemsService _itemsService;

  List<Colleague> _colleagues = [];
  List<Item> _items = [];

  int? _colleagueId;
  int? _itemId;

  int _qty = 1;
  double? _price;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final api = ApiClient(AppPrefs());
    _colleaguesService = ColleaguesService(api);
    _itemsService = ItemsService(api);
    _load();
  }

  Future<void> _load() async {
    try {
      final colleagues = await _colleaguesService.fetchColleagues();
      final items = await _itemsService.fetchItems(includeInactive: false);

      setState(() {
        _colleagues = colleagues;
        _items = items;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load dropdowns: $e')),
      );
    }
  }

  void _onItemChanged(int? id) {
    setState(() {
      _itemId = id;
      final found = _items.where((x) => x.id == id).toList();
      if (found.isNotEmpty) {
        _price = found.first.default_price;
        _priceCtrl.text = _price!.toString();
      }
    });
  }


  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_colleagueId == null || _itemId == null) return;
    if (_price == null) return; // extra safety

    Navigator.pop(context, {
      'colleague_id': _colleagueId!,
      'item_id': _itemId!,
      'quantity': _qty,
      'price': _price!,
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: _loading
            ? const SizedBox(
          height: 220,
          child: Center(child: CircularProgressIndicator()),
        )
            : Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Add Order Item', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),

                DropdownButtonFormField<int>(
                  value: _colleagueId,
                  decoration: const InputDecoration(labelText: 'Colleague'),
                  items: _colleagues
                      .map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.name),
                  ))
                      .toList(),
                  onChanged: (v) => setState(() => _colleagueId = v),
                  validator: (v) => v == null ? 'Select a colleague' : null,
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<int>(
                  value: _itemId,
                  decoration: const InputDecoration(labelText: 'Item'),
                  items: _items
                      .map((it) => DropdownMenuItem(
                    value: it.id,
                    child: Text(it.name),
                  ))
                      .toList(),
                  onChanged: _onItemChanged,
                  validator: (v) => v == null ? 'Select an item' : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  initialValue: '1',
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final n = int.tryParse((v ?? '').trim());
                    if (n == null || n <= 0) return 'Enter qty > 0';
                    return null;
                  },
                  onChanged: (v) => _qty = int.tryParse(v) ?? 1,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _priceCtrl,
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    final n = double.tryParse((v ?? '').trim());
                    if (n == null || n < 0) return 'Enter valid price';
                    return null;
                  },
                  onChanged: (v) => _price = double.tryParse(v),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Add'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
