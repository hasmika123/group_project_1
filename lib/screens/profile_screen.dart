import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/responsive.dart';
import '../widgets/profile_setup_form.dart';

class ProfileScreen extends StatefulWidget {
  static const routeName = '/profile';
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _name;
  int? _age;
  String? _sex;
  double? _weight;
  double? _height;
  double? _bmr;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('profile_name');
      _age = prefs.getInt('profile_age');
      _sex = prefs.getString('profile_sex');
      _weight = prefs.getDouble('profile_weight');
      _height = prefs.getDouble('profile_height');
      _bmr = prefs.getDouble('profile_bmr');
      _loading = false;
    });
  }

  Widget _buildRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: Colors.grey[700]))),
          const SizedBox(width: 12),
          Text(value ?? '-', style: TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile & BMR'), actions: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _openEditProfile(context),
        )
      ]),
      body: Padding(
        padding: Responsive.pagePadding(context),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Profile', style: TextStyle(fontSize: Responsive.fontSize(context, 18), fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      _buildRow('Name', _name),
                      _buildRow('Age', _age?.toString()),
                      _buildRow('Sex', _sex),
                      _buildRow('Weight (kg)', _weight?.toStringAsFixed(1)),
                      _buildRow('Height (cm)', _height?.toStringAsFixed(1)),
                      const Divider(height: 24),
                      _buildRow('Estimated BMR (kcal/day)', _bmr?.toStringAsFixed(0)),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  void _openEditProfile(BuildContext context) async {
  final ctx = context;
  final navigator = Navigator.of(ctx);
  final messenger = ScaffoldMessenger.of(ctx);

    await showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      builder: (c) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom),
        child: ProfileSetupForm(
          initialName: _name,
          initialAge: _age,
          initialSex: _sex,
          initialWeight: _weight,
          initialHeight: _height,
          onSave: (name, age, sex, weight, height, bmr) async {
            // capture navigator/messenger before awaiting
            final nav = navigator;
            final msg = messenger;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('profile_name', name);
            await prefs.setInt('profile_age', age);
            await prefs.setString('profile_sex', sex);
            await prefs.setDouble('profile_weight', weight);
            await prefs.setDouble('profile_height', height);
            await prefs.setDouble('profile_bmr', bmr);
            // update local state
            if (mounted) {
              setState(() {
                _name = name;
                _age = age;
                _sex = sex;
                _weight = weight;
                _height = height;
                _bmr = bmr;
              });
              nav.pop();
              msg.showSnackBar(const SnackBar(content: Text('Profile updated')));
            }
          },
        ),
      ),
    );
  }
}
