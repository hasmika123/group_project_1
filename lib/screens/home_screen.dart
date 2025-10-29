import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'workout_log_screen.dart';
import '../widgets/profile_setup_form.dart';

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
    return SharedPreferences.getInstance().then((prefs) {
      final done = prefs.getBool('profile_setup_done') ?? false;
      if (!done) {
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
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('profile_setup_done', true);
          await prefs.setString('profile_name', name);
          await prefs.setInt('profile_age', age);
          await prefs.setString('profile_sex', sex);
          await prefs.setDouble('profile_weight', weight);
          await prefs.setDouble('profile_height', height);
          await prefs.setDouble('profile_bmr', bmr);
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
    final titles = ['Home', 'Workouts', 'Calories'];

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
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Workouts'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Calories'),
        ],
        currentIndex: _currentIndex,
        onTap: (idx) {
          setState(() => _currentIndex = idx);
        },
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final void Function(int)? onSelectTab;
  final ValueNotifier<String?>? workoutActionNotifier;
  final ValueNotifier<String?>? calorieActionNotifier;
  const _HomeContent({Key? key, this.onSelectTab, this.workoutActionNotifier, this.calorieActionNotifier}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Simple sample values; future work will wire these to real data/models
    final int caloriesConsumed = 1450;
    final int caloriesBurned = 400;
    final int deficit = caloriesBurned - caloriesConsumed; // intentionally simple

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
                          Text('Burned: $caloriesBurned kcal'),
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
                        value: '72 kg',
                        subtitle: '−0.4 kg this week',
                        icon: Icons.monitor_weight,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Activity',
                        value: '3 workouts',
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
                      value: '72 kg',
                      subtitle: '−0.4 kg this week',
                      icon: Icons.monitor_weight,
                    ),
                    const SizedBox(height: 12),
                    _SummaryCard(
                      title: 'Activity',
                      value: '3 workouts',
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

              return Wrap(
                spacing: spacing,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _QuickAction(
                      icon: Icons.add_circle_outline,
                      label: 'Add Workout',
                      onTap: () {
                        final parent = context.findAncestorWidgetOfExactType<_HomeContent>();
                        if (parent is _HomeContent && parent.onSelectTab != null) {
                          parent.onSelectTab!(1);
                          // after switching tabs, instruct the workouts tab to open the create-new sheet
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
                    width: itemWidth,
                    child: _QuickAction(
                      icon: Icons.restaurant_menu,
                      label: 'Log Calories',
                      onTap: () {
                        // switch to the Calories tab (index 2) via optional callback
                        final parent = context.findAncestorWidgetOfExactType<_HomeContent>();
                        // if parent provided an onSelectTab callback, use it; otherwise fallback to navigation
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
                    width: itemWidth,
                    child: _QuickAction(
                      icon: Icons.show_chart,
                      label: 'View Progress',
                      onTap: () {
                        Navigator.of(context).pushNamed('/progress');
                      },
                    ),
                  ),
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
  final String name;
  final int calories;
  final DateTime date;
  CalorieEntry({required this.name, required this.calories, DateTime? date}) : date = date ?? DateTime.now();
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

  // For demo purposes we show a fixed burned value; in a later pass this can come from workouts data
  int get _burnedToday => 400;

  @override
  void initState() {
    super.initState();
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
            ElevatedButton(onPressed: () {
              final name = nameCtl.text.trim();
              final cals = int.tryParse(calCtl.text) ?? 0;
              if (name.isEmpty || cals <= 0) return;

              if (existing == null) {
                final newEntry = CalorieEntry(name: name, calories: cals);
                setState(() => _entries.insert(0, newEntry));

                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Added ${newEntry.calories} kcal'),
                  action: SnackBarAction(label: 'Undo', onPressed: () {
                    setState(() {
                      final idx = _entries.indexOf(newEntry);
                      if (idx != -1) _entries.removeAt(idx);
                    });
                  }),
                ));
              } else if (index != null && index >= 0 && index < _entries.length) {
                final old = _entries[index];
                final updated = CalorieEntry(name: name, calories: cals, date: old.date);
                setState(() => _entries[index] = updated);

                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('Entry updated'),
                  action: SnackBarAction(label: 'Undo', onPressed: () {
                    setState(() => _entries[index] = old);
                  }),
                ));
              }

              Navigator.of(c).pop();
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
                        subtitle: Text('${e.date.hour.toString().padLeft(2, '0')}:${e.date.minute.toString().padLeft(2, '0')}'),
                        trailing: Text('${e.calories} kcal'),
                        onTap: () => _showEntrySheet(existing: e, index: i),
                        onLongPress: () {
                          final removed = _entries.removeAt(i);
                          setState(() {});
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Removed ${removed.name} (${removed.calories} kcal)'),
                            action: SnackBarAction(label: 'Undo', onPressed: () {
                              setState(() => _entries.insert(i, removed));
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
