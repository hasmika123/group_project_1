import 'package:flutter/material.dart';

class ProgressScreen extends StatelessWidget {
  static const routeName = '/progress';
  const ProgressScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: const Center(child: Text('Progress (stub)')),
    );
  }
}
