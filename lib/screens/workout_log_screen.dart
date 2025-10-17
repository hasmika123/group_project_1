import 'package:flutter/material.dart';
import '../utils/responsive.dart';

class WorkoutLogScreen extends StatelessWidget {
  static const routeName = '/workouts';
  const WorkoutLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workout Log')),
      body: Padding(
        padding: Responsive.pagePadding(context),
        child: Center(child: Text('Workout Log (stub)', style: TextStyle(fontSize: Responsive.fontSize(context, 16)))),
      ),
    );
  }
}
