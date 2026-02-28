import 'package:flutter/material.dart';
import 'item_model.dart';

class ItemFormSheet extends StatefulWidget {
  const ItemFormSheet({super.key, this.initial});

  final Item? initial;

  @override
  State<ItemFormSheet> createState() => _ItemFormSheetState();
}

class _ItemFormSheetState extends State<ItemFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _cost;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initial?.name ?? '');
    _cost = TextEditingController(
        text: widget.initial == null ? '' : widget.initial!.default_price.toString());
  }

  @override
  void dispose() {
    _name.dispose();
    _cost.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isEdit ? 'Edit Item' : 'New Item',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Item name',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cost,
              decoration: const InputDecoration(
                labelText: 'Cost',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                final d = double.tryParse((v ?? '').trim());
                if (d == null) return 'Enter a number';
                if (d < 0) return 'Must be >= 0';
                return null;
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving
                    ? null
                    : () {
                  if (!_formKey.currentState!.validate()) return;
                  setState(() => _saving = true);
                  Navigator.pop(context, {
                    'name': _name.text.trim(),
                    'cost': double.parse(_cost.text.trim()),
                  });
                },
                child: Text(_saving ? 'Saving...' : (isEdit ? 'Update' : 'Create')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
