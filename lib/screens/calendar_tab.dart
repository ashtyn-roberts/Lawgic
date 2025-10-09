import 'package:flutter/material.dart';

class CalendarTab extends StatefulWidget {
  const CalendarTab({super.key});

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Calendar Tab',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}
