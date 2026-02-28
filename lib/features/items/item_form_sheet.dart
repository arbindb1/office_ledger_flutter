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
    final theme = Theme.of(context);
    final isEdit = widget.initial != null;

    return Container(
      // FIXED: Removed duplicate 'color' property
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Figma-style Grab Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              isEdit ? 'Edit Inventory Item' : 'Add New Item',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _name,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Item Name',
                hintText: 'e.g. Chicken Momo',
                prefixIcon: const Icon(Icons.drive_file_rename_outline_rounded),
                filled: true,
                fillColor: theme.colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cost,
              decoration: InputDecoration(
                labelText: 'Default Price',
                prefixText: 'Rs. ',
                prefixIcon: const Icon(Icons.payments_rounded),
                filled: true,
                fillColor: theme.colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                final d = double.tryParse((v ?? '').trim());
                if (d == null) return 'Enter a valid number';
                if (d < 0) return 'Must be 0 or more';
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary, // Indigo from Figma
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
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
                child: Text(
                  _saving ? 'Saving...' : (isEdit ? 'Update Item' : 'Create Item'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}