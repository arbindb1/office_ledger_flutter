import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/storage/app_prefs.dart';

class ApiBaseUrlScreen extends StatefulWidget {
  const ApiBaseUrlScreen({super.key});

  @override
  State<ApiBaseUrlScreen> createState() => _ApiBaseUrlScreenState();
}

class _ApiBaseUrlScreenState extends State<ApiBaseUrlScreen> {
  final _prefs = AppPrefs();
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final current = await _prefs.getBaseUrl();
    _controller.text = current ?? ApiClient.defaultBaseUrl;
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await _prefs.setBaseUrl(_controller.text.trim());
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Base URL saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API Base URL')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Base URL',
                hintText: 'http://10.0.2.2:8000',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Emulator: http://10.0.2.2:8000\nPhone: http://<your-laptop-ip>:8000',
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving...' : 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
