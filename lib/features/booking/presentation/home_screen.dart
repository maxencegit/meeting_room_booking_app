import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _roomNumberKey = 'room_number';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = TextEditingController();
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _loadSavedValue();
  }

  Future<void> _loadSavedValue() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_roomNumberKey);
    if (saved != null && mounted) {
      _controller.text = saved.toString();
    }
  }

  Future<void> _onSubmit() async {
    final value = int.tryParse(_controller.text.trim());
    if (value == null) return;

    setState(() => _isSaved = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_roomNumberKey, value);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Room number saved')),
      );
    } catch (e, st) {
      debugPrint('SharedPreferences error: $e\n$st');
      if (!mounted) return;
      setState(() => _isSaved = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Room number',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() => _isSaved = false),
                onSubmitted: (_) => _onSubmit(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaved ? null : _onSubmit,
                  style: FilledButton.styleFrom(
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade500,
                  ),
                  child: const Text('Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
