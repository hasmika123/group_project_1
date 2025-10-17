import 'package:flutter/material.dart';
import '../utils/responsive.dart';

class Workout {
  final String title;
  final int minutes;
  final int calories;
  final DateTime date;

  Workout({required this.title, required this.minutes, required this.calories, DateTime? date}) : date = date ?? DateTime.now();
}

class WorkoutLogScreen extends StatelessWidget {
  static const routeName = '/workouts';
  const WorkoutLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workout Log')),
      body: const WorkoutLogContent(),
      floatingActionButton: null,
    );
  }
}

class WorkoutLogContent extends StatefulWidget {
  const WorkoutLogContent({Key? key}) : super(key: key);

  @override
  State<WorkoutLogContent> createState() => _WorkoutLogContentState();
}

class _WorkoutLogContentState extends State<WorkoutLogContent> {
  final List<Workout> _workouts = [
    Workout(title: 'Morning Run', minutes: 30, calories: 280),
    Workout(title: 'Strength Training', minutes: 45, calories: 350),
    Workout(title: 'Evening Yoga', minutes: 40, calories: 180),
  ];

  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDate;

  void _openAddWorkoutSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _AddWorkoutForm(onAdd: (w) {
          setState(() => _workouts.insert(0, w));
          Navigator.of(ctx).pop();
        }),
      ),
    );
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Map<DateTime, List<Workout>> _groupByDate() {
    final map = <DateTime, List<Workout>>{};
    for (final w in _workouts) {
      final d = _dateOnly(w.date);
      map.putIfAbsent(d, () => []).add(w);
    }
    return map;
  }

  Widget _buildCalendar(BuildContext context) {
    final map = _groupByDate();
    final first = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);
    // weekday: Monday=1 .. Sunday=7
    final leadingEmpty = first.weekday - 1; // make week start Monday

    final List<Widget> dayWidgets = [];
    for (var i = 0; i < leadingEmpty; i++) {
      dayWidgets.add(const SizedBox.shrink());
    }

    for (var d = 1; d <= daysInMonth; d++) {
      final day = DateTime(_focusedMonth.year, _focusedMonth.month, d);
      final isSelected = _selectedDate != null && _dateOnly(_selectedDate!) == _dateOnly(day);
      final isToday = _dateOnly(DateTime.now()) == _dateOnly(day);
      final hasWorkout = map.containsKey(_dateOnly(day));

      dayWidgets.add(GestureDetector(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedDate = null;
            } else {
              _selectedDate = day;
            }
          });
        },
        child: Container(
          margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.primary.withAlpha((0.12 * 255).round()) : null,
            borderRadius: BorderRadius.circular(8),
            border: isToday && !isSelected ? Border.all(color: Theme.of(context).colorScheme.primary, width: 1) : null,
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(d.toString(), style: TextStyle(fontSize: 13)),
              const SizedBox(height: 4),
              if (hasWorkout)
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ));
    }

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
                        });
                      },
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text(
                      '${_focusedMonth.year} - ${_focusedMonth.month.toString().padLeft(2, '0')}',
                      style: TextStyle(fontSize: Responsive.fontSize(context, 16), fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
                        });
                      },
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => setState(() => _selectedDate = null),
                  child: const Text('Show All'),
                )
              ],
            ),
            const SizedBox(height: 6),
            // Weekday headers
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                Text('Mon', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                Text('Tue', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                Text('Wed', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                Text('Thu', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                Text('Fri', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                Text('Sat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                Text('Sun', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 6),
            // Grid -> use a Wrap with LayoutBuilder to avoid nested scrollable inside CustomScrollView
            LayoutBuilder(
              builder: (ctx, constraints) {
                final tileWidth = (constraints.maxWidth - 8 * 2 - 6 * 8) / 7; // account for margins/padding
                return Wrap(
                  alignment: WrapAlignment.start,
                  children: dayWidgets.map((w) => SizedBox(width: tileWidth, child: w)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final device = Responsive.deviceType(context);
    final padding = Responsive.pagePadding(context);

    // If a date is selected, show only workouts for that date, otherwise show all
    final displayedWorkouts = _selectedDate == null
        ? _workouts
        : _workouts.where((w) => _dateOnly(w.date) == _dateOnly(_selectedDate!)).toList();
    final totalCalories = displayedWorkouts.fold<int>(0, (s, w) => s + w.calories);

    return Padding(
      padding: padding,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: device == DeviceType.mobile
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Workouts', style: TextStyle(fontSize: Responsive.fontSize(context, 20), fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(child: Text('Total: ${displayedWorkouts.length} • Calories: $totalCalories kcal')),
                                  IconButton(onPressed: _openAddWorkoutSheet, icon: const Icon(Icons.add)),
                                ],
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Workouts', style: TextStyle(fontSize: Responsive.fontSize(context, 22), fontWeight: FontWeight.w700)),
                              Row(
                                children: [
                                  Text('Total: ${displayedWorkouts.length}  •  Calories: $totalCalories kcal'),
                                  const SizedBox(width: 8),
                                  IconButton(onPressed: _openAddWorkoutSheet, icon: const Icon(Icons.add)),
                                ],
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 12),

                // Calendar
                _buildCalendar(context),

                const SizedBox(height: 12),
              ],
            ),
          ),

          if (displayedWorkouts.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('No workouts yet. Tap + to add one.', style: TextStyle(fontSize: Responsive.fontSize(context, 16)))),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final w = displayedWorkouts[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: WorkoutCard(
                      workout: w,
                      onDelete: () {
                        setState(() => _workouts.remove(w));
                      },
                    ),
                  );
                },
                childCount: displayedWorkouts.length,
              ),
            ),
        ],
      ),
    );
  }
}

class WorkoutCard extends StatelessWidget {
  final Workout workout;
  final VoidCallback? onDelete;

  const WorkoutCard({Key? key, required this.workout, this.onDelete}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              child: Icon(Icons.fitness_center, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(workout.title, style: TextStyle(fontSize: Responsive.fontSize(context, 16), fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text('${workout.minutes} min • ${workout.calories} kcal', style: TextStyle(color: Colors.grey[700])),
                ],
              ),
            ),
            if (onDelete != null)
              IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline))
          ],
        ),
      ),
    );
  }
}

class _AddWorkoutForm extends StatefulWidget {
  final void Function(Workout) onAdd;
  const _AddWorkoutForm({Key? key, required this.onAdd}) : super(key: key);

  @override
  State<_AddWorkoutForm> createState() => _AddWorkoutFormState();
}

class _AddWorkoutFormState extends State<_AddWorkoutForm> {
  final _titleCtl = TextEditingController();
  final _minutesCtl = TextEditingController();
  final _caloriesCtl = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  String _formatDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  void dispose() {
    _titleCtl.dispose();
    _minutesCtl.dispose();
    _caloriesCtl.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleCtl.text.trim();
    final minutes = int.tryParse(_minutesCtl.text) ?? 0;
    final calories = int.tryParse(_caloriesCtl.text) ?? 0;
    if (title.isEmpty || minutes <= 0) return; // minimal validation for UI demo
    widget.onAdd(Workout(title: title, minutes: minutes, calories: calories, date: _selectedDate));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Add Workout', style: TextStyle(fontSize: Responsive.fontSize(context, 18), fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Text('Date: ${_formatDate(_selectedDate)}')),
              TextButton(onPressed: _pickDate, child: const Text('Change')),
            ],
          ),
          const SizedBox(height: 8),
          TextField(controller: _titleCtl, decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: TextField(controller: _minutesCtl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Minutes'))),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: _caloriesCtl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Calories'))),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _submit, child: const Text('Add')),
        ],
      ),
    );
  }
}

