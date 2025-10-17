import 'package:flutter/material.dart';
import '../utils/responsive.dart';

class CalendarScreen extends StatelessWidget {
  static const routeName = '/calendar';
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar Streaks')),
      body: Padding(
        padding: Responsive.pagePadding(context),
        child: Center(child: Text('Calendar Streak View (stub)', style: TextStyle(fontSize: Responsive.fontSize(context, 16)))),
      ),
    );
  }
}
