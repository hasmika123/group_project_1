import 'package:flutter/material.dart';

class WorkoutLogScreen extends StatelessWidget {
  static const routeName = '/workouts';
  const WorkoutLogScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workout Log')),
      body: const Center(child: Text('Workout Log (stub)')),
    );
  }
}
