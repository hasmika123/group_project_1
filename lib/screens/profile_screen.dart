import 'package:flutter/material.dart';
import '../utils/responsive.dart';

class ProfileScreen extends StatelessWidget {
  static const routeName = '/profile';
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile & BMR Setup')),
      body: Padding(
        padding: Responsive.pagePadding(context),
        child: Center(child: Text('Profile & BMR Setup (stub)', style: TextStyle(fontSize: Responsive.fontSize(context, 16)))),
      ),
    );
  }
}
