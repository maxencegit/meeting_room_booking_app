import 'package:flutter/material.dart';

class BookingDialog extends StatefulWidget {
  const BookingDialog({
    super.key,
    required this.initialDateTime,
    this.initialEndTime,
    this.initialTitle,
  });

  final DateTime initialDateTime;
  final TimeOfDay? initialEndTime;
  final String? initialTitle;

  @override
  State<BookingDialog> createState() => _BookingDialogState();
}

class _BookingDialogState extends State<BookingDialog> {
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startTime = TimeOfDay.fromDateTime(widget.initialDateTime);
    _endTime = widget.initialEndTime ??
        TimeOfDay.fromDateTime(
          widget.initialDateTime.add(const Duration(hours: 1)),
        );
    if (widget.initialTitle != null) {
      _nameController.text = widget.initialTitle!;
    }
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked == null || !mounted) return;

    setState(() {
      if (isStart) {
        _startTime = picked;
        // push end time forward if it's now before start
        if (_toMinutes(picked) >= _toMinutes(_endTime)) {
          _endTime = TimeOfDay(
            hour: (picked.hour + 1) % 24,
            minute: picked.minute,
          );
        }
      } else {
        _endTime = picked;
      }
    });
  }

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  bool get _isValid =>
      _nameController.text.trim().isNotEmpty &&
      _toMinutes(_endTime) > _toMinutes(_startTime);

  String _formatTime(TimeOfDay t) => t.format(context);

  @override
  Widget build(BuildContext context) {
    final date = widget.initialDateTime;
    final dateLabel =
        '${_weekday(date.weekday)} ${date.day}/${date.month}/${date.year}';

    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            dateLabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Meeting name',
              hintText: 'e.g. Sprint planning',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 16),
          _TimeTile(
            label: 'Start time',
            time: _formatTime(_startTime),
            onTap: () => _pickTime(isStart: true),
          ),
          const SizedBox(height: 8),
          _TimeTile(
            label: 'End time',
            time: _formatTime(_endTime),
            onTap: () => _pickTime(isStart: false),
          ),
          if (!_isValid) ...[
            const SizedBox(height: 8),
            Text(
              _nameController.text.trim().isEmpty
                  ? 'Name is missing'
                  : 'End time must be after start time',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isValid
              ? () => Navigator.of(context).pop(
                    (_nameController.text.trim(), _startTime, _endTime),
                  )
              : null,
          child: const Text('Book'),
        ),
      ],
    );
  }

  String _weekday(int w) => switch (w) {
        1 => 'Monday',
        2 => 'Tuesday',
        3 => 'Wednesday',
        4 => 'Thursday',
        5 => 'Friday',
        6 => 'Saturday',
        _ => 'Sunday',
      };
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({
    required this.label,
    required this.time,
    required this.onTap,
  });

  final String label;
  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Row(
              children: [
                Text(
                  time,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
