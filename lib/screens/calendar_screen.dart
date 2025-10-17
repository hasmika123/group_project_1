import 'package:flutter/material.dart';

class CalendarScreen extends StatelessWidget {
  static const routeName = '/calendar';
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar Streaks')),
      body: const Center(child: Text('Calendar Streak View (stub)')),
    );
  }
}
