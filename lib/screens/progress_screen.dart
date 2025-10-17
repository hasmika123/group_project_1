import 'package:flutter/material.dart';
import '../utils/responsive.dart';

class ProgressScreen extends StatelessWidget {
  static const routeName = '/progress';
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: Padding(
        padding: Responsive.pagePadding(context),
        child: Center(child: Text('Progress (stub)', style: TextStyle(fontSize: Responsive.fontSize(context, 16)))),
      ),
    );
  }
}
