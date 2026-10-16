import 'package:flutter/material.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, required this.initialDate});

  final DateTime initialDate;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _selectedDate = widget.initialDate;

  void _selectDate(DateTime date) {
    setState(() => _selectedDate = date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('캘린더')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Text(MaterialLocalizations.of(context).formatFullDate(_selectedDate)),
            ),
            Expanded(
              child: CalendarDatePicker(
                initialDate: widget.initialDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100, 12, 31),
                currentDate: widget.initialDate,
                onDateChanged: _selectDate,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
