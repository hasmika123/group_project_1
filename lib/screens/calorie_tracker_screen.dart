import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import '../services/database_helper.dart';

class CalorieTrackerScreen extends StatefulWidget {
  static const routeName = '/calories';
  const CalorieTrackerScreen({super.key});

  @override
  State<CalorieTrackerScreen> createState() => _CalorieTrackerScreenState();
}

class _CalorieEntry {
  int? id;
  String name;
  int calories;
  DateTime date;
  _CalorieEntry({this.id, required this.name, required this.calories, required this.date});
}

class _CalorieTrackerScreenState extends State<CalorieTrackerScreen> {
  final List<_CalorieEntry> _entries = [];
  DateTime? _selectedDate;
  int _burned = 0;

  @override
  void initState() {
    super.initState();
    _load();
    // react to DB changes
    DatabaseHelper.instance.caloriesNotifier.addListener(_load);
    DatabaseHelper.instance.workoutsNotifier.addListener(_load);
    DatabaseHelper.instance.profileNotifier.addListener(_load);
  }

  Future<void> _load() async {
    final rows = await DatabaseHelper.instance.getCalories(day: _selectedDate);
    _entries.clear();
    _entries.addAll(rows.map((r) => _CalorieEntry(
      id: (r['id'] is num) ? (r['id'] as num).toInt() : (r['id'] as int?),
      name: r['name'] as String,
      calories: (r['calories'] as num).toInt(),
      date: DateTime.fromMillisecondsSinceEpoch((r['date'] as num).toInt()),
    )));
    // compute burned calories for the selected day from workouts
    final wRows = await DatabaseHelper.instance.getWorkouts(day: _selectedDate);
    final burnedFromWorkouts = wRows.fold<int>(0, (s, r) => s + ((r['calories'] as num?)?.toInt() ?? 0));
    // include daily BMR estimate from profile
    final profile = await DatabaseHelper.instance.getProfile();
    final bmr = (profile != null && profile['bmr'] != null) ? (profile['bmr'] as num).toInt() : 0;
    _burned = burnedFromWorkouts + bmr;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    DatabaseHelper.instance.caloriesNotifier.removeListener(_load);
    DatabaseHelper.instance.workoutsNotifier.removeListener(_load);
    DatabaseHelper.instance.profileNotifier.removeListener(_load);
    super.dispose();
  }

  Future<void> _addEntry() async {
    final nameCtrl = TextEditingController();
    final calCtrl = TextEditingController();
    DateTime chosenDate = _selectedDate ?? DateTime.now();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Log calories', style: TextStyle(fontSize: Responsive.fontSize(context, 18), fontWeight: FontWeight.w700)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Item')),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(controller: calCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Calories')),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(onPressed: () async { final d = await showDatePicker(context: context, initialDate: chosenDate, firstDate: DateTime(2000), lastDate: DateTime(2100)); if (d != null) chosenDate = d; }, child: const Text('Pick date')),
                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                ElevatedButton(onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final calories = int.tryParse(calCtrl.text.trim()) ?? 0;
                  if (name.isEmpty || calories <= 0) return;
                  final id = await DatabaseHelper.instance.insertCalorie({'name': name, 'calories': calories, 'date': chosenDate.millisecondsSinceEpoch});
                  if (!mounted) return;
                  _entries.insert(0, _CalorieEntry(id: id, name: name, calories: calories, date: chosenDate));
                  setState(() {});
                  Navigator.of(ctx).pop();
                }, child: const Text('Save')),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _editEntry(_CalorieEntry entry) async {
    final nameCtrl = TextEditingController(text: entry.name);
    final calCtrl = TextEditingController(text: entry.calories.toString());
    DateTime chosenDate = entry.date;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Edit calorie entry', style: TextStyle(fontSize: Responsive.fontSize(context, 18), fontWeight: FontWeight.w700)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Item')),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(controller: calCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Calories')),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(onPressed: () async { final d = await showDatePicker(context: context, initialDate: chosenDate, firstDate: DateTime(2000), lastDate: DateTime(2100)); if (d != null) chosenDate = d; }, child: const Text('Pick date')),
                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                ElevatedButton(onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final calories = int.tryParse(calCtrl.text.trim()) ?? 0;
                  if (name.isEmpty || calories <= 0) return;
                  if (entry.id == null) {
                    final id = await DatabaseHelper.instance.insertCalorie({'name': name, 'calories': calories, 'date': chosenDate.millisecondsSinceEpoch});
                    if (!mounted) return;
                    _entries.insert(0, _CalorieEntry(id: id, name: name, calories: calories, date: chosenDate));
                  } else {
                    await DatabaseHelper.instance.updateCalorie(entry.id!, {'name': name, 'calories': calories, 'date': chosenDate.millisecondsSinceEpoch});
                    if (!mounted) return;
                    final idx = _entries.indexWhere((e) => e.id == entry.id);
                    if (idx != -1) {
                      _entries[idx].name = name;
                      _entries[idx].calories = calories;
                      _entries[idx].date = chosenDate;
                    }
                  }
                  setState(() {});
                  Navigator.of(ctx).pop();
                }, child: const Text('Save')),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(_CalorieEntry entry) async {
    final confirm = await showDialog<bool>(context: context, builder: (dctx) => AlertDialog(
      title: const Text('Delete entry?'),
      content: const Text('Are you sure you want to delete this calorie entry?'),
      actions: [TextButton(onPressed: () => Navigator.of(dctx).pop(false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.of(dctx).pop(true), child: const Text('Delete'))],
    ));
    if (confirm != true) return;

    // optimistic remove
  _entries.removeWhere((e) => e.id == entry.id);
    if (mounted) setState(() {});

  if (entry.id != null) await DatabaseHelper.instance.deleteCalorie(entry.id!);

    // show undo snackbar
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Deleted "${entry.name}"'),
      action: SnackBarAction(label: 'Undo', onPressed: () async {
        // re-insert the entry
  await DatabaseHelper.instance.insertCalorie({'name': entry.name, 'calories': entry.calories, 'date': entry.date.millisecondsSinceEpoch});
        // refresh list to canonical state
        await _load();
        // attempt to position the reinserted entry at top if present
        if (mounted) setState(() {});
      }),
      duration: const Duration(seconds: 4),
    ));

    // final sync to canonical state
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final total = _entries.fold<int>(0, (s, e) => s + e.calories);
    return Scaffold(
      appBar: AppBar(title: const Text('Calorie Tracker')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEntry,
        child: const Icon(Icons.add),
        tooltip: 'Log calories',
      ),
      body: Padding(
        padding: Responsive.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Consumed: $total kcal', style: TextStyle(fontSize: Responsive.fontSize(context, 16), fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text('Burned: $_burned kcal', style: TextStyle(fontSize: Responsive.fontSize(context, 14), color: Colors.grey[700])),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _entries.isEmpty
                  ? Center(child: Text('No calories logged yet. Tap + to add.', style: TextStyle(fontSize: Responsive.fontSize(context, 16))))
                  : ListView.separated(
                      itemCount: _entries.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final e = _entries[i];
                        return ListTile(
                          title: Text(e.name),
                          subtitle: Text('${e.calories} kcal • ${e.date.year}-${e.date.month.toString().padLeft(2,'0')}-${e.date.day.toString().padLeft(2,'0')} • Tap to edit'),
                          onTap: () => _editEntry(e),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _editEntry(e)),
                              PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'edit') _editEntry(e);
                                  else if (v == 'delete') _delete(e);
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Edit'))),
                                  const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Delete'))),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
