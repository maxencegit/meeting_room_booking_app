import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'booking_calendar.dart';

const _roomNumberKey = 'room_number';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = TextEditingController();
  bool _isSaved = false;

  // null = still loading, false = not set, true = already set
  bool? _isRoomNumberSet;

  @override
  void initState() {
    super.initState();
    _loadSavedValue();
  }

  Future<void> _loadSavedValue() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_roomNumberKey);
    if (!mounted) return;
    setState(() {
      _isRoomNumberSet = saved != null;
      if (saved != null) _controller.text = saved.toString();
    });
  }

  Future<void> _onSubmit() async {
    final value = int.tryParse(_controller.text.trim());
    if (value == null) return;

    setState(() => _isSaved = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_roomNumberKey, value);
      if (!mounted) return;
      setState(() => _isRoomNumberSet = true);
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
      body: SafeArea(
        child: switch (_isRoomNumberSet) {
          null => const Center(child: CircularProgressIndicator()),
          false => _RoomNumberForm(
              controller: _controller,
              isSaved: _isSaved,
              onSubmit: _onSubmit,
              onChanged: () => setState(() => _isSaved = false),
            ),
          true => const BookingCalendar(),
        },
      ),
    );
  }
}

class _RoomNumberForm extends StatelessWidget {
  const _RoomNumberForm({
    required this.controller,
    required this.isSaved,
    required this.onSubmit,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool isSaved;
  final VoidCallback onSubmit;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'What is your room number?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Room number',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
              onChanged: (_) => onChanged(),
              onSubmitted: (_) => onSubmit(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isSaved ? null : onSubmit,
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
    );
  }
}
