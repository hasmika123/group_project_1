import 'package:flutter/material.dart';
import '../utils/responsive.dart';

class CalorieTrackerScreen extends StatelessWidget {
  static const routeName = '/calories';
  const CalorieTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calorie Tracker')),
      body: Padding(
        padding: Responsive.pagePadding(context),
        child: Center(child: Text('Calorie Tracker (stub)', style: TextStyle(fontSize: Responsive.fontSize(context, 16)))),
      ),
    );
  }
}
