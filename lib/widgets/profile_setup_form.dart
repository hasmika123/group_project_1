import 'package:flutter/material.dart';
import '../utils/responsive.dart';

typedef ProfileSaveCallback = Future<void> Function(String name, int age, String sex, double weight, double height, double bmr);

class ProfileSetupForm extends StatefulWidget {
  final ProfileSaveCallback onSave;
  final String? initialName;
  final int? initialAge;
  final String? initialSex;
  final double? initialWeight;
  final double? initialHeight;

  const ProfileSetupForm({Key? key, required this.onSave, this.initialName, this.initialAge, this.initialSex, this.initialWeight, this.initialHeight}) : super(key: key);

  @override
  State<ProfileSetupForm> createState() => _ProfileSetupFormState();
}

class _ProfileSetupFormState extends State<ProfileSetupForm> {
  late final TextEditingController _nameCtl;
  late final TextEditingController _ageCtl;
  late final TextEditingController _weightCtl;
  late final TextEditingController _heightCtl;
  late String _sex;

  double _bmr = 0;

  @override
  void initState() {
    super.initState();
    _nameCtl = TextEditingController(text: widget.initialName ?? '');
    _ageCtl = TextEditingController(text: widget.initialAge?.toString() ?? '');
    _weightCtl = TextEditingController(text: widget.initialWeight?.toString() ?? '');
    _heightCtl = TextEditingController(text: widget.initialHeight?.toString() ?? '');
    _sex = widget.initialSex ?? 'male';
    _ageCtl.addListener(_recalc);
    _weightCtl.addListener(_recalc);
    _heightCtl.addListener(_recalc);
    // initial calc
    WidgetsBinding.instance.addPostFrameCallback((_) => _recalc());
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _ageCtl.dispose();
    _weightCtl.dispose();
    _heightCtl.dispose();
    super.dispose();
  }

  void _recalc() {
    final age = int.tryParse(_ageCtl.text) ?? 0;
    final weight = double.tryParse(_weightCtl.text) ?? 0.0;
    final height = double.tryParse(_heightCtl.text) ?? 0.0;
    setState(() => _bmr = _calculateBmr(sex: _sex, weightKg: weight, heightCm: height, age: age));
  }

  double _calculateBmr({required String sex, required double weightKg, required double heightCm, required int age}) {
    if (sex == 'male') {
      return 10 * weightKg + 6.25 * heightCm - 5 * age + 5;
    } else {
      return 10 * weightKg + 6.25 * heightCm - 5 * age - 161;
    }
  }

  bool get _valid {
    final name = _nameCtl.text.trim();
    final age = int.tryParse(_ageCtl.text);
    final weight = double.tryParse(_weightCtl.text);
    final height = double.tryParse(_heightCtl.text);
    return name.isNotEmpty && (age != null && age > 0) && (weight != null && weight > 0) && (height != null && height > 0);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [IconButton(onPressed: () {}, icon: const Icon(Icons.person)), Expanded(child: Text('Profile setup', style: TextStyle(fontSize: Responsive.fontSize(context, 18), fontWeight: FontWeight.w700)))]),
            const SizedBox(height: 8),
            TextField(controller: _nameCtl, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 8),
            Row(children: [Expanded(child: TextField(controller: _ageCtl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Age'))), const SizedBox(width: 8), Expanded(child: DropdownButtonFormField<String>(initialValue: _sex, items: const [DropdownMenuItem(value: 'male', child: Text('Male')), DropdownMenuItem(value: 'female', child: Text('Female'))], onChanged: (v) => setState(() { _sex = v ?? 'male'; _recalc(); }), decoration: const InputDecoration(labelText: 'Sex')))]),
            const SizedBox(height: 8),
            Row(children: [Expanded(child: TextField(controller: _weightCtl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Weight (kg)'))), const SizedBox(width: 8), Expanded(child: TextField(controller: _heightCtl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Height (cm)')))]),
            const SizedBox(height: 12),
            Text('Estimated BMR: ${_bmr.toStringAsFixed(0)} kcal/day', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _valid
                  ? () async {
                      final name = _nameCtl.text.trim();
                      final age = int.parse(_ageCtl.text);
                      final weight = double.parse(_weightCtl.text);
                      final height = double.parse(_heightCtl.text);
                      final bmr = _calculateBmr(sex: _sex, weightKg: weight, heightCm: height, age: age);
                      await widget.onSave(name, age, _sex, weight, height, bmr);
                    }
                  : null,
              child: const Text('Save Profile'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
