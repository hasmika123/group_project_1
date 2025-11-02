import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import 'workout_log_screen.dart';
import '../widgets/profile_setup_form.dart';
import '../services/database_helper.dart';
import 'progress_screen.dart';

// Modal sheet for logging weight
class _LogWeightSheet extends StatefulWidget {
  @override
  State<_LogWeightSheet> createState() => _LogWeightSheetState();
}

class _LogWeightSheetState extends State<_LogWeightSheet> {
  final _formKey = GlobalKey<FormState>();
  double? _weight;
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  bool _saving = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final dt = DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
    await DatabaseHelper.instance.insertWeightLog({'weight': _weight, 'date': dt.millisecondsSinceEpoch});
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Weight logged')));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Log Weight', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Weight (kg)', prefixIcon: Icon(Icons.monitor_weight)),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                final val = double.tryParse(v ?? '');
                if (val == null || val <= 0) return 'Enter a valid weight';
                return null;
              },
              onChanged: (v) => setState(() => _weight = double.tryParse(v)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                      );
                      if (picked != null) setState(() => _date = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Date'),
                      child: Text('${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: _time);
                      if (picked != null) setState(() => _time = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Time'),
                      child: Text('${_time.format(context)}'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _submit,
              child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Log Weight'),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  // Notifiers used to instruct tabs to open specific actions after switching
  final ValueNotifier<String?> _workoutActionNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<String?> _calorieActionNotifier = ValueNotifier<String?>(null);

  @override
  void initState() {
    super.initState();
    _maybeShowProfileSetup();
  }

  Future<void> _maybeShowProfileSetup() {
    // Use .then to avoid using 'await' so we don't use the widget BuildContext across an async gap.
    // Show profile setup when there is no profile row in the database.
    return DatabaseHelper.instance.getProfile().then((row) {
      final hasProfile = row != null;
      if (!hasProfile) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showProfileSetup(context);
        });
      }
    });
  }

  Future<void> _showProfileSetup(BuildContext ctx) async {
    await showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      barrierColor: Colors.black54,
      enableDrag: false,
      isDismissible: false,
      builder: (c) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom),
          child: ProfileSetupForm(onSave: (name, age, sex, weight, height, bmr) async {
          final navigator = Navigator.of(c);
          final messenger = ScaffoldMessenger.of(ctx);
          // Persist profile to SQLite (we use presence of the profile row as the first-run indicator)
          await DatabaseHelper.instance.upsertProfile({
            'name': name,
            'age': age,
            'sex': sex,
            'weight': weight,
            'height': height,
            'bmr': bmr,
          });
          if (mounted) {
            navigator.pop();
            messenger.showSnackBar(const SnackBar(content: Text('Profile saved')));
          }
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
  final titles = ['Home', 'Workouts', 'Calories', 'Progress'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_currentIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.of(context).pushNamed('/profile');
            },
          )
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _HomeContent(onSelectTab: (i) => setState(() => _currentIndex = i), workoutActionNotifier: _workoutActionNotifier, calorieActionNotifier: _calorieActionNotifier),
          _WorkoutsTab(actionNotifier: _workoutActionNotifier),
          _CaloriesTab(actionNotifier: _calorieActionNotifier),
          ProgressScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Workouts'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Calories'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Progress'),
        ],
        currentIndex: _currentIndex,
        onTap: (idx) {
          setState(() => _currentIndex = idx);
        },
      ),
    );
  }
}

class _HomeContent extends StatefulWidget {
  final void Function(int)? onSelectTab;
  final ValueNotifier<String?>? workoutActionNotifier;
  final ValueNotifier<String?>? calorieActionNotifier;
  const _HomeContent({Key? key, this.onSelectTab, this.workoutActionNotifier, this.calorieActionNotifier}) : super(key: key);

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  int _caloriesConsumed = 0;
  int _caloriesBurned = 0;
  double? _weight;
  int _bmrDaily = 0;
  int _workoutsThisWeek = 0;

  @override
  void initState() {
    super.initState();
    _loadOverview();
    // Listen for DB changes to refresh the overview dynamically
    DatabaseHelper.instance.caloriesNotifier.addListener(_loadOverview);
    DatabaseHelper.instance.workoutsNotifier.addListener(_loadOverview);
    DatabaseHelper.instance.profileNotifier.addListener(_loadOverview);
  }

  @override
  void dispose() {
    DatabaseHelper.instance.caloriesNotifier.removeListener(_loadOverview);
    DatabaseHelper.instance.workoutsNotifier.removeListener(_loadOverview);
    DatabaseHelper.instance.profileNotifier.removeListener(_loadOverview);
    super.dispose();
  }

  Future<void> _loadOverview() async {
    final today = DateTime.now();
    // consumed today
    final cRows = await DatabaseHelper.instance.getCalories(day: today);
    final consumed = cRows.fold<int>(0, (s, r) => s + ((r['calories'] as num?)?.toInt() ?? 0));

    // burned today (from workouts)
    final wRows = await DatabaseHelper.instance.getWorkouts(day: today);
    final burned = wRows.fold<int>(0, (s, r) => s + ((r['calories'] as num?)?.toInt() ?? 0));

    // workouts this week (simple last 7 days)
    final weekStart = DateTime(today.year, today.month, today.day).subtract(const Duration(days: 6));
    final weekRows = await DatabaseHelper.instance.getWorkouts();
    final workoutsThisWeek = weekRows.where((r) {
      final d = DateTime.fromMillisecondsSinceEpoch((r['date'] as num?)?.toInt() ?? 0);
      return d.isAfter(weekStart.subtract(const Duration(seconds: 1)));
    }).length;

    // profile weight
    final profile = await DatabaseHelper.instance.getProfile();
  final weight = (profile != null && profile['weight'] != null) ? (profile['weight'] as num).toDouble() : null;
  final bmr = (profile != null && profile['bmr'] != null) ? (profile['bmr'] as num).toInt() : 0;

    if (!mounted) return;
    setState(() {
      _caloriesConsumed = consumed;
      _caloriesBurned = burned;
      _workoutsThisWeek = workoutsThisWeek;
      _weight = weight;
      _bmrDaily = bmr;
    });
  }

  @override
  Widget build(BuildContext context) {
  final int caloriesConsumed = _caloriesConsumed;
  final int workoutBurned = _caloriesBurned;
  final int bmr = _bmrDaily;
  final int totalBurned = workoutBurned + bmr;
  final int deficit = totalBurned - caloriesConsumed;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: Responsive.pagePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
          // Daily calorie overview
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                          Text(
                            'Today',
                            style: TextStyle(fontSize: Responsive.fontSize(context, 16), color: Colors.grey),
                          ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Calorie Deficit', style: TextStyle(fontSize: Responsive.fontSize(context, 14))),
                          const SizedBox(height: 6),
                            Text(
                            '$deficit',
                            style: TextStyle(
                              fontSize: Responsive.fontSize(context, 28),
                              fontWeight: FontWeight.bold,
                              color: deficit >= 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Consumed: $caloriesConsumed kcal'),
                          const SizedBox(height: 6),
                          Text('Workout burned: $workoutBurned kcal'),
                          const SizedBox(height: 4),
                          Text('BMR (est.): $bmr kcal'),
                          const SizedBox(height: 6),
                          Text('Total expenditure: $totalBurned kcal', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      )
                    ],
                  )
                ],
              ),
            ),
          ),

          SizedBox(height: Responsive.deviceType(context) == DeviceType.mobile ? 16 : 20),

          // Progress summary
          Responsive.useHorizontalLayout(context)
              ? Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                          title: 'Weight',
                          value: _weight != null ? '${_weight!.toStringAsFixed(1)} kg' : '--',
                          subtitle: '−0.4 kg this week',
                          icon: Icons.monitor_weight,
                        ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Activity',
                        value: '$_workoutsThisWeek workouts',
                        subtitle: 'This week',
                        icon: Icons.fitness_center,
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    _SummaryCard(
                      title: 'Weight',
                      value: _weight != null ? '${_weight!.toStringAsFixed(1)} kg' : '--',
                      subtitle: '−0.4 kg this week',
                      icon: Icons.monitor_weight,
                    ),
                    const SizedBox(height: 12),
                    _SummaryCard(
                      title: 'Activity',
                      value: '$_workoutsThisWeek workouts',
                      subtitle: 'This week',
                      icon: Icons.fitness_center,
                    ),
                  ],
                ),

          SizedBox(height: Responsive.deviceType(context) == DeviceType.mobile ? 16 : 20),

          // Quick actions
          Text('Quick actions', style: TextStyle(fontSize: Responsive.fontSize(context, 16), fontWeight: FontWeight.w600)),
          SizedBox(height: Responsive.deviceType(context) == DeviceType.mobile ? 8 : 12),
          LayoutBuilder(
            builder: (ctx, box) {
              final maxW = box.maxWidth;
              // choose 3 columns when wide enough, otherwise 2 columns for narrow phones
              final isNarrow = maxW < 360;
              final cols = isNarrow ? 2 : 3;
              final spacing = 12.0;
              final totalSpacing = spacing * (cols - 1);
              final itemWidth = (maxW - totalSpacing) / cols;
              // Prevent negative width
              final safeItemWidth = itemWidth < 0 ? 0.0 : itemWidth;

              return Wrap(
                spacing: spacing,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: safeItemWidth,
                    child: _QuickAction(
                      icon: Icons.add_circle_outline,
                      label: 'Add Workout',
                      onTap: () {
                        final parent = context.findAncestorWidgetOfExactType<_HomeContent>();
                        if (parent is _HomeContent && parent.onSelectTab != null) {
                          parent.onSelectTab!(1);
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            parent.workoutActionNotifier?.value = 'create_new';
                          });
                        } else {
                          Navigator.of(context).pushNamed('/workouts');
                        }
                      },
                    ),
                  ),
                  SizedBox(
                    width: safeItemWidth,
                    child: _QuickAction(
                      icon: Icons.restaurant_menu,
                      label: 'Log Calories',
                      onTap: () {
                        final parent = context.findAncestorWidgetOfExactType<_HomeContent>();
                        if (parent is _HomeContent && parent.onSelectTab != null) {
                          parent.onSelectTab!(2);
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            parent.calorieActionNotifier?.value = 'log';
                          });
                        } else {
                          Navigator.of(context).pushNamed('/calories');
                        }
                      },
                    ),
                  ),
                  SizedBox(
                    width: safeItemWidth,
                    child: _QuickAction(
                      icon: Icons.monitor_weight,
                      label: 'Log Weight',
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (c) => Padding(
                            padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom),
                            child: _LogWeightSheet(),
                          ),
                        );
                      },
                    ),
                  ),
                  // Removed 'View Progress' quick action
                ],
              );
            },
          ),

          // Small spacer to keep footer off the immediate content (avoid Spacer inside scrollables)
          SizedBox(height: Responsive.deviceType(context) == DeviceType.mobile ? 24 : 40),

          // Small footer / tip
          Text(
            'Tip: Tap actions or use the navigation bar to explore other sections.',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WorkoutsTab extends StatelessWidget {
  final ValueNotifier<String?>? actionNotifier;
  const _WorkoutsTab({Key? key, this.actionNotifier}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WorkoutLogScreen(actionNotifier: actionNotifier);
  }
}

class CalorieEntry {
  final int? id;
  final String name;
  final int calories;
  final DateTime date;
  CalorieEntry({this.id, required this.name, required this.calories, DateTime? date}) : date = date ?? DateTime.now();

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'calories': calories,
        'date': date.millisecondsSinceEpoch,
      };

  static CalorieEntry fromMap(Map<String, Object?> m) => CalorieEntry(
  id: m['id'] as int?,
  name: m['name'] as String? ?? '',
  calories: m['calories'] as int,
  date: DateTime.fromMillisecondsSinceEpoch(m['date'] as int),
      );
}

class _CaloriesTab extends StatefulWidget {
  final ValueNotifier<String?>? actionNotifier;
  const _CaloriesTab({Key? key, this.actionNotifier}) : super(key: key);

  @override
  State<_CaloriesTab> createState() => _CaloriesTabState();
}

class _CaloriesTabState extends State<_CaloriesTab> {
  final List<CalorieEntry> _entries = [];

  int get _consumedToday {
    final today = DateTime.now();
    return _entries.where((e) => e.date.year == today.year && e.date.month == today.month && e.date.day == today.day).fold(0, (s, e) => s + e.calories);
  }

  int _burnedToday = 0;

  @override
  void initState() {
    super.initState();
    // Load persisted calorie entries from the database
    _loadEntries();

    widget.actionNotifier?.addListener(() {
      final v = widget.actionNotifier?.value;
      if (v == 'log') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showEntrySheet();
            widget.actionNotifier?.value = null;
          }
        });
      }
    });
    // react to DB changes
    DatabaseHelper.instance.caloriesNotifier.addListener(_loadEntries);
    DatabaseHelper.instance.workoutsNotifier.addListener(_loadEntries);
    DatabaseHelper.instance.profileNotifier.addListener(_loadEntries);
  }

  @override
  void dispose() {
    DatabaseHelper.instance.caloriesNotifier.removeListener(_loadEntries);
    DatabaseHelper.instance.workoutsNotifier.removeListener(_loadEntries);
    DatabaseHelper.instance.profileNotifier.removeListener(_loadEntries);
    super.dispose();
  }

  Future<void> _loadEntries() async {
    final rows = await DatabaseHelper.instance.getCalories();
    _entries.clear();
    _entries.addAll(rows.map((r) => CalorieEntry.fromMap(r)));
    // compute burned today from workouts
    final today = DateTime.now();
    final wRows = await DatabaseHelper.instance.getWorkouts(day: today);
    final burned = wRows.fold<int>(0, (s, r) => s + ((r['calories'] as num?)?.toInt() ?? 0));
    // include BMR estimate from profile
    final profile = await DatabaseHelper.instance.getProfile();
    final bmr = (profile != null && profile['bmr'] != null) ? (profile['bmr'] as num).toInt() : 0;
    _burnedToday = burned + bmr;
    if (mounted) setState(() {});
  }

  

  Future<void> _showEntrySheet({CalorieEntry? existing, int? index}) async {
    final nameCtl = TextEditingController(text: existing?.name ?? '');
    final calCtl = TextEditingController(text: existing?.calories.toString() ?? '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (c) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(c).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [IconButton(onPressed: () => Navigator.of(c).pop(), icon: const Icon(Icons.close)), Expanded(child: Text(existing == null ? 'Log calories' : 'Edit entry', style: TextStyle(fontSize: Responsive.fontSize(context, 18), fontWeight: FontWeight.w700)))]),
            const SizedBox(height: 8),
            TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Food / Meal')),
            const SizedBox(height: 8),
            TextField(controller: calCtl, decoration: const InputDecoration(labelText: 'Calories'), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () async {
              final nav = Navigator.of(c);
              final messenger = ScaffoldMessenger.of(context);
              final name = nameCtl.text.trim();
              final cals = int.tryParse(calCtl.text) ?? 0;
              if (name.isEmpty || cals <= 0) return;

              if (existing == null) {
                // insert into DB
                final now = DateTime.now();
                final id = await DatabaseHelper.instance.insertCalorie({'name': name, 'calories': cals, 'date': now.millisecondsSinceEpoch});
                final newEntry = CalorieEntry(id: id, name: name, calories: cals, date: now);
                if (!mounted) return;
                setState(() => _entries.insert(0, newEntry));

                messenger.clearSnackBars();
                messenger.showSnackBar(SnackBar(
                  content: Text('Added ${newEntry.calories} kcal'),
                  action: SnackBarAction(label: 'Undo', onPressed: () async {
                    // remove from DB and list
                    await DatabaseHelper.instance.deleteCalorie(newEntry.id!);
                    if (!mounted) return;
                    setState(() {
                      final idx = _entries.indexWhere((e) => e.id == newEntry.id);
                      if (idx != -1) _entries.removeAt(idx);
                    });
                  }),
                ));
              } else if (index != null && index >= 0 && index < _entries.length) {
                final old = _entries[index];
                // update DB
                if (old.id != null) {
                  await DatabaseHelper.instance.updateCalorie(old.id!, {'name': name, 'calories': cals, 'date': old.date.millisecondsSinceEpoch});
                  final updated = CalorieEntry(id: old.id, name: name, calories: cals, date: old.date);
                  if (!mounted) return;
                  setState(() => _entries[index] = updated);

                  messenger.clearSnackBars();
                  messenger.showSnackBar(SnackBar(
                    content: const Text('Entry updated'),
                    action: SnackBarAction(label: 'Undo', onPressed: () async {
                      // revert DB change
                      await DatabaseHelper.instance.updateCalorie(old.id!, {'name': old.name, 'calories': old.calories, 'date': old.date.millisecondsSinceEpoch});
                      if (!mounted) return;
                      setState(() => _entries[index] = old);
                    }),
                  ));
                }
              }

              nav.pop();
            }, child: Text(existing == null ? 'Add' : 'Save')),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final consumed = _consumedToday;
    final burned = _burnedToday;
    final deficit = burned - consumed;

    return Padding(
      padding: Responsive.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Today', style: TextStyle(fontSize: Responsive.fontSize(context, 14), color: Colors.grey)), const SizedBox(height: 6), Text('$deficit', style: TextStyle(fontSize: Responsive.fontSize(context, 26), fontWeight: FontWeight.bold, color: deficit >= 0 ? Colors.green : Colors.red))]),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('Consumed: $consumed kcal'), const SizedBox(height: 6), Text('Burned: $burned kcal')]),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(onPressed: () => _showEntrySheet(), icon: const Icon(Icons.add), label: const Text('Log calories')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _entries.isEmpty
                ? Center(child: Text('No calorie entries yet. Tap "Log calories" to add one.', style: TextStyle(color: Colors.grey[600])))
                : ListView.separated(
                    itemCount: _entries.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final e = _entries[i];
                      return ListTile(
                        title: Text(e.name),
                        subtitle: Text('${e.date.hour.toString().padLeft(2, '0')}:${e.date.minute.toString().padLeft(2, '0')} • Tap to edit'),
                        onTap: () => _showEntrySheet(existing: e, index: i),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(onPressed: () => _showEntrySheet(existing: e, index: i), icon: const Icon(Icons.edit, color: Colors.blue)),
                            PopupMenuButton<String>(
                              onSelected: (v) async {
                                if (v == 'delete') {
                                  final messenger = ScaffoldMessenger.of(context);
                                  final removed = _entries.removeAt(i);
                                  if (!mounted) return;
                                  setState(() {});
                                  if (removed.id != null) await DatabaseHelper.instance.deleteCalorie(removed.id!);
                                  messenger.clearSnackBars();
                                  messenger.showSnackBar(SnackBar(
                                    content: Text('Removed ${removed.name} (${removed.calories} kcal)'),
                                    action: SnackBarAction(label: 'Undo', onPressed: () async {
                                      final newId = await DatabaseHelper.instance.insertCalorie({'name': removed.name, 'calories': removed.calories, 'date': removed.date.millisecondsSinceEpoch});
                                      final restored = CalorieEntry(id: newId, name: removed.name, calories: removed.calories, date: removed.date);
                                      if (!mounted) return;
                                      setState(() => _entries.insert(i, restored));
                                    }),
                                  ));
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Delete'))),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Text('${e.calories} kcal'),
                          ],
                        ),
                        onLongPress: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final removed = _entries.removeAt(i);
                          if (!mounted) return;
                          setState(() {});
                          // delete from DB
                          if (removed.id != null) {
                            await DatabaseHelper.instance.deleteCalorie(removed.id!);
                          }
                          messenger.clearSnackBars();
                          messenger.showSnackBar(SnackBar(
                            content: Text('Removed ${removed.name} (${removed.calories} kcal)'),
                            action: SnackBarAction(label: 'Undo', onPressed: () async {
                              // re-insert into DB and list
                              final newId = await DatabaseHelper.instance.insertCalorie({'name': removed.name, 'calories': removed.calories, 'date': removed.date.millisecondsSinceEpoch});
                              final restored = CalorieEntry(id: newId, name: removed.name, calories: removed.calories, date: removed.date);
                              if (!mounted) return;
                              setState(() => _entries.insert(i, restored));
                            }),
                          ));
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ...existing code...

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  const _SummaryCard({Key? key, required this.title, required this.value, required this.subtitle, required this.icon}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool horizontal = Responsive.useHorizontalLayout(context);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: horizontal
            ? Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    child: Icon(icon, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontSize: Responsive.fontSize(context, 14), color: Colors.grey)),
                      const SizedBox(height: 6),
                      Text(value, style: TextStyle(fontSize: Responsive.fontSize(context, 16), fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(subtitle, style: TextStyle(fontSize: Responsive.fontSize(context, 12), color: Colors.grey[600])),
                    ],
                  )
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(radius: 20, child: Icon(icon, size: 18)),
                      const SizedBox(width: 8),
                      Text(title, style: TextStyle(fontSize: Responsive.fontSize(context, 14), color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(value, style: TextStyle(fontSize: Responsive.fontSize(context, 16), fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(subtitle, style: TextStyle(fontSize: Responsive.fontSize(context, 12), color: Colors.grey[600])),
                ],
              ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({Key? key, required this.icon, required this.label, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[100],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: Responsive.fontSize(context, 28)),
            SizedBox(height: Responsive.deviceType(context) == DeviceType.mobile ? 6 : 8),
            Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: Responsive.fontSize(context, 14))),
          ],
        ),
      ),
    );
  }
}
