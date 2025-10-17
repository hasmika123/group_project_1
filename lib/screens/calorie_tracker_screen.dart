import 'package:flutter/material.dart';

class CalorieTrackerScreen extends StatelessWidget {
  static const routeName = '/calories';
  const CalorieTrackerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calorie Tracker')),
      body: const Center(child: Text('Calorie Tracker (stub)')),
    );
  }
}
