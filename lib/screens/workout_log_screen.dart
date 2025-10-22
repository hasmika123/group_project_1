import 'package:flutter/material.dart';
import '../utils/responsive.dart';

// Basic models used in this file (moved here to repair file after corruption)
class Workout {
  final String title;
  final String type;
  final int minutes;
  final int? reps;
  final int calories;
  final String? notes;
  final DateTime date;

  Workout({required this.title, required this.type, required this.minutes, this.reps, required this.calories, this.notes, DateTime? date}) : date = date ?? DateTime.now();
}

class WorkoutTemplate {
  final String title;
  final String type;
  final int minutes;
  final int? reps;
  final int calories;
  final String? notes;
  final TimeOfDay? time;

  WorkoutTemplate({required this.title, required this.type, required this.minutes, this.reps, required this.calories, this.notes, this.time});
}

class PlanEntry {
  final int dayOffset;
  final List<WorkoutTemplate> templates;
  PlanEntry({required this.dayOffset, required this.templates});
}

class WorkoutPlan {
  final String name;
  final String? description;
  final List<PlanEntry> entries;
  WorkoutPlan({required this.name, this.description, required this.entries});
}

int calculateCalories({required String type, required int minutes, int? reps}) {
  if (type == 'Other') return 0;
  switch (type) {
    case 'Running':
      return (10 * minutes).round();
    case 'Cycling':
      return (8 * minutes).round();
    case 'Strength Training':
      return (6 * minutes + (reps ?? 0) * 0).round();
    case 'Yoga':
      return (3 * minutes).round();
    case 'HIIT':
      return (12 * minutes).round();
    default:
      return (5 * minutes).round();
  }
}

class WorkoutLogScreen extends StatefulWidget {
  static const routeName = '/workout_log';
  const WorkoutLogScreen({Key? key}) : super(key: key);
  @override
  State<WorkoutLogScreen> createState() => _WorkoutLogScreenState();
}

class _WorkoutLogScreenState extends State<WorkoutLogScreen> {

  final List<Workout> _workouts = [
    Workout(title: 'Morning Run', type: 'Running', minutes: 30, calories: 300, notes: 'Felt good'),
    Workout(title: 'Strength Set', type: 'Strength Training', minutes: 30, reps: 50, calories: 150, notes: 'Upper body'),
    Workout(title: 'Evening Yoga', type: 'Yoga', minutes: 40, calories: 120),
  ];

  // in-memory templates ("My Workouts")
  final List<WorkoutTemplate> _templates = [
    WorkoutTemplate(title: 'Quick Run', type: 'Running', minutes: 20, calories: 200),
    WorkoutTemplate(title: 'Full Strength', type: 'Strength Training', minutes: 45, reps: 60, calories: 350),
  ];

  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDate;

  // Workout plans
  final List<WorkoutPlan> _plans = [];

  @override
  void initState() {
    super.initState();
    // add some basic plans
      _plans.addAll([
      WorkoutPlan(
        name: 'Beginner',
        description: 'Light 3-day starter plan',
        entries: [
          PlanEntry(dayOffset: 0, templates: [WorkoutTemplate(title: 'Light Run', type: 'Running', minutes: 20, calories: 180)]),
          PlanEntry(dayOffset: 1, templates: [WorkoutTemplate(title: 'Bodyweight Strength', type: 'Strength Training', minutes: 25, calories: 200)]),
          PlanEntry(dayOffset: 2, templates: [WorkoutTemplate(title: 'Yoga Stretch', type: 'Yoga', minutes: 30, calories: 100)]),
        ],
      ),
      WorkoutPlan(
        name: 'Intermediate',
        description: '5-day mix of cardio and strength',
        entries: [
          PlanEntry(dayOffset: 0, templates: [WorkoutTemplate(title: 'Run', type: 'Running', minutes: 30, calories: 300)]),
          PlanEntry(dayOffset: 1, templates: [WorkoutTemplate(title: 'Strength', type: 'Strength Training', minutes: 40, calories: 300)]),
          PlanEntry(dayOffset: 2, templates: [WorkoutTemplate(title: 'HIIT', type: 'HIIT', minutes: 20, calories: 240)]),
          PlanEntry(dayOffset: 3, templates: [WorkoutTemplate(title: 'Cycle', type: 'Cycling', minutes: 45, calories: 360)]),
          PlanEntry(dayOffset: 4, templates: [WorkoutTemplate(title: 'Yoga', type: 'Yoga', minutes: 30, calories: 120)]),
        ],
      ),
      WorkoutPlan(
        name: 'Advanced',
        description: '7-day higher intensity plan',
        entries: [
          PlanEntry(dayOffset: 0, templates: [WorkoutTemplate(title: 'Long Run', type: 'Running', minutes: 60, calories: 600)]),
          PlanEntry(dayOffset: 1, templates: [WorkoutTemplate(title: 'Strength Heavy', type: 'Strength Training', minutes: 50, calories: 400)]),
          PlanEntry(dayOffset: 2, templates: [WorkoutTemplate(title: 'HIIT', type: 'HIIT', minutes: 30, calories: 360)]),
          PlanEntry(dayOffset: 3, templates: [WorkoutTemplate(title: 'Cycle Endurance', type: 'Cycling', minutes: 60, calories: 480)]),
          PlanEntry(dayOffset: 4, templates: [WorkoutTemplate(title: 'Strength', type: 'Strength Training', minutes: 45, calories: 350)]),
          PlanEntry(dayOffset: 5, templates: [WorkoutTemplate(title: 'HIIT', type: 'HIIT', minutes: 30, calories: 360)]),
          PlanEntry(dayOffset: 6, templates: [WorkoutTemplate(title: 'Recovery Yoga', type: 'Yoga', minutes: 40, calories: 160)]),
        ],
      ),
    ]);
  }


  void _openAddWorkoutSheet({DateTime? initialDate}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Add workout', style: TextStyle(fontSize: Responsive.fontSize(context, 18), fontWeight: FontWeight.w700)),
            ),
            ListTile(
              leading: const Icon(Icons.create),
              title: const Text('Create new workout'),
              onTap: () {
                Navigator.of(ctx).pop();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (c2) => Padding(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(c2).viewInsets.bottom),
                    child: _AddWorkoutForm(
                      // pass initial date/time to the form via a constructor parameter
                      initialDate: _selectedDate,
                      onAdd: (w) {
                        setState(() => _workouts.insert(0, w));
                        Navigator.of(c2).pop();
                      },
                      onSaveTemplate: (tmpl) => setState(() => _templates.insert(0, tmpl)),
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmarks_outlined),
              title: const Text('Add from My Workouts'),
              onTap: () async {
                Navigator.of(ctx).pop();
                // open templates list and schedule selected template; pass initialDate so scheduling can be quicker
                await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (c3) => Padding(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(c3).viewInsets.bottom),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text('My Workouts', style: TextStyle(fontSize: Responsive.fontSize(context, 18), fontWeight: FontWeight.w700)),
                        ),
                        Flexible(
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: _templates.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (ctx2, i) {
                              final t = _templates[i];
                              return ListTile(
                                title: Text(t.title),
                                subtitle: Text('${t.type} • ${t.minutes} min • ${t.calories} kcal'),
                                onTap: () async {
                                  Navigator.of(c3).pop();
                                  // schedule it using the provided initialDate
                                  final scheduled = await _scheduleTemplate(t, baseDate: initialDate);
                                  if (!mounted) return;
                                  if (scheduled != null) setState(() => _workouts.insert(0, Workout(title: t.title, type: t.type, minutes: t.minutes, reps: t.reps, calories: t.calories, notes: t.notes, date: scheduled)));
                                },
                                trailing: PopupMenuButton<String>(
                                  onSelected: (action) async {
                                    if (action == 'edit') {
                                      Navigator.of(c3).pop();
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        builder: (c2) => Padding(
                                          padding: EdgeInsets.only(bottom: MediaQuery.of(c2).viewInsets.bottom),
                                          child: _TemplateForm(initial: t, onSave: (updated) {
                                            setState(() => _templates[i] = updated);
                                            Navigator.of(c2).pop();
                                          }),
                                        ),
                                      );
                                    } else if (action == 'delete') {
                                      setState(() => _templates.removeAt(i));
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
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
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _openTemplatesManager() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('My Workouts', style: TextStyle(fontSize: Responsive.fontSize(context, 18), fontWeight: FontWeight.w700)),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (c2) => Padding(
                          padding: EdgeInsets.only(bottom: MediaQuery.of(c2).viewInsets.bottom),
                          child: _TemplateForm(
                            onSave: (t) {
                              setState(() => _templates.insert(0, t));
                              Navigator.of(c2).pop();
                            },
                          ),
                        ),
                      );
                    },
                    child: const Text('New'),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _templates.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final t = _templates[i];
                  return ListTile(
                    title: Text(t.title),
                    subtitle: Text('${t.type} • ${t.minutes} min • ${t.calories} kcal'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) async {
                          if (action == 'add') {
                          // close templates manager, then schedule template instance to a chosen date/time
                          Navigator.of(context).pop();
                          final scheduled = await _scheduleTemplate(t);
                          if (!mounted) return;
                          if (scheduled != null) {
                            setState(() => _workouts.insert(0, Workout(title: t.title, type: t.type, minutes: t.minutes, reps: t.reps, calories: t.calories, notes: t.notes, date: scheduled)));
                          }
                        } else if (action == 'edit') {
                          Navigator.of(context).pop();
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (c2) => Padding(
                              padding: EdgeInsets.only(bottom: MediaQuery.of(c2).viewInsets.bottom),
                              child: _TemplateForm(initial: t, onSave: (updated) {
                                setState(() => _templates[i] = updated);
                                Navigator.of(c2).pop();
                              }),
                            ),
                          );
                        } else if (action == 'delete') {
                          setState(() => _templates.removeAt(i));
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'add', child: Text('Schedule...')),
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _openPlansManager() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back)),
                  Expanded(child: Text('Plans', style: TextStyle(fontSize: Responsive.fontSize(context, 18), fontWeight: FontWeight.w700))),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (c2) => Padding(
                          padding: EdgeInsets.only(bottom: MediaQuery.of(c2).viewInsets.bottom),
                          child: _PlanForm(onSave: (p) {
                              setState(() => _plans.insert(0, p));
                            }),
                        ),
                      );
                    },
                    child: const Text('New'),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _plans.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final p = _plans[i];
                  return ListTile(
                    title: Text(p.name),
                    subtitle: Text(p.description ?? ''),
                    onTap: () => _previewPlan(p),
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) async {
                        if (action == 'schedule') {
                          Navigator.of(context).pop();
                          final start = await showDatePicker(context: context, initialDate: _selectedDate ?? DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 3650)));
                          if (start == null) return;
                          // schedule entries sequentially by dayOffset; use entry.template.time when present
                          for (final e in p.entries) {
                            final entryDate = DateTime(start.year, start.month, start.day + e.dayOffset);
                            for (final tmpl in e.templates) {
                              final t = tmpl.time;
                              final d = t == null ? DateTime(entryDate.year, entryDate.month, entryDate.day, TimeOfDay.fromDateTime(DateTime.now()).hour, TimeOfDay.fromDateTime(DateTime.now()).minute) : DateTime(entryDate.year, entryDate.month, entryDate.day, t.hour, t.minute);
                              setState(() => _workouts.insert(0, Workout(title: tmpl.title, type: tmpl.type, minutes: tmpl.minutes, reps: tmpl.reps, calories: tmpl.calories, notes: tmpl.notes, date: d)));
                            }
                          }
                        } else if (action == 'edit') {
                          Navigator.of(context).pop();
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (c2) => Padding(
                              padding: EdgeInsets.only(bottom: MediaQuery.of(c2).viewInsets.bottom),
                              child: _PlanForm(initial: p, onSave: (updated) {
                                  setState(() => _plans[i] = updated);
                                }),
                            ),
                          );
                        } else if (action == 'delete') {
                          setState(() => _plans.removeAt(i));
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'schedule', child: Text('Schedule')),
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
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

  void _previewPlan(WorkoutPlan p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back)),
                  Expanded(child: Text(p.name, style: TextStyle(fontSize: Responsive.fontSize(context, 18), fontWeight: FontWeight.w700))),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: p.entries.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx2, i) {
                  final e = p.entries[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Day ${e.dayOffset + 1}', style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          ...e.templates.asMap().entries.map((me) {
                            final ti = me.key;
                            final tmpl = me.value;
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(tmpl.title),
                              subtitle: Text('${tmpl.type} • ${tmpl.minutes} min • ${tmpl.calories} kcal${tmpl.time != null ? ' • ${tmpl.time!.format(context)}' : ''}'),
                              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () async {
                                    Navigator.of(ctx).pop();
                                    final updated = await showModalBottomSheet<WorkoutTemplate>(
                                      context: context,
                                      isScrollControlled: true,
                                      builder: (c3) => Padding(
                                        padding: EdgeInsets.only(bottom: MediaQuery.of(c3).viewInsets.bottom),
                                        child: _TemplateForm(initial: tmpl, onSave: (t) => Navigator.of(c3).pop(t)),
                                      ),
                                    );
                                    if (updated != null) {
                                      setState(() => p.entries[i].templates[ti] = updated);
                                    }
                                    Future.delayed(const Duration(milliseconds: 50), () => _previewPlan(p));
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    setState(() => p.entries[i].templates.removeAt(ti));
                                    Future.delayed(const Duration(milliseconds: 50), () => _previewPlan(p));
                                  },
                                ),
                              ]),
                            );
                          }).toList(),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () async {
                                // add a new template to this day
                                Navigator.of(ctx).pop();
                                final created = await showModalBottomSheet<WorkoutTemplate>(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (c4) => Padding(
                                    padding: EdgeInsets.only(bottom: MediaQuery.of(c4).viewInsets.bottom),
                                    child: _TemplateForm(onSave: (t) => Navigator.of(c4).pop(t)),
                                  ),
                                );
                                if (created != null) setState(() => p.entries[i].templates.add(created));
                                Future.delayed(const Duration(milliseconds: 50), () => _previewPlan(p));
                              },
                              child: const Text('Add workout to this day'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _openPreview(Workout w) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(w.title, style: TextStyle(fontSize: Responsive.fontSize(context, 18), fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('${TimeOfDay.fromDateTime(w.date).format(context)} • ${w.type} • ${w.minutes} min • ${w.calories} kcal'),
                  if (w.reps != null) Text('Reps: ${w.reps}'),
                  if (w.notes != null) ...[const SizedBox(height: 8), Text('Notes:', style: TextStyle(fontWeight: FontWeight.w600)), Text(w.notes!)],
                ],
              ),
            ),
            OverflowBar(
              spacing: 8,
              overflowSpacing: 8,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // open edit
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (ctx) => Padding(
                        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
                        child: _EditWorkoutForm(
                          workout: w,
                          onSave: (updated) {
                            setState(() {
                              final idx = _workouts.indexOf(w);
                              if (idx != -1) _workouts[idx] = updated;
                            });
                            Navigator.of(ctx).pop();
                          },
                        ),
                      ),
                    );
                  },
                  child: const Text('Edit'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _workouts.remove(w));
                    Navigator.of(context).pop();
                  },
                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<DateTime?> _scheduleTemplate(WorkoutTemplate t, {DateTime? baseDate}) async {
    DateTime initialDate = baseDate ?? _selectedDate ?? DateTime.now();
    TimeOfDay initialTime = t.time ?? TimeOfDay.now();

    DateTime? chosenDate = await showDatePicker(context: context, initialDate: initialDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 3650)));
    if (chosenDate == null) return null;
    if (!mounted) return null;

    final pickedTime = await showTimePicker(context: context, initialTime: initialTime);
    if (pickedTime == null) return null;
    if (!mounted) return null;

    return DateTime(chosenDate.year, chosenDate.month, chosenDate.day, pickedTime.hour, pickedTime.minute);
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
                                                IconButton(onPressed: _openPlansManager, icon: const Icon(Icons.list_alt), tooltip: 'Plans'),
                                                IconButton(onPressed: _openTemplatesManager, icon: const Icon(Icons.bookmarks_outlined), tooltip: 'My Workouts'),
                                                IconButton(onPressed: () => _openAddWorkoutSheet(initialDate: _selectedDate), icon: const Icon(Icons.add)),
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
                                  IconButton(onPressed: _openPlansManager, icon: const Icon(Icons.list_alt), tooltip: 'Plans'),
                                  IconButton(onPressed: _openTemplatesManager, icon: const Icon(Icons.bookmarks_outlined), tooltip: 'My Workouts'),
                                  IconButton(onPressed: () => _openAddWorkoutSheet(initialDate: _selectedDate), icon: const Icon(Icons.add)),
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
                      onTap: () => _openPreview(w),
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

class _EditWorkoutForm extends StatefulWidget {
  final Workout workout;
  final void Function(Workout) onSave;
  _EditWorkoutForm({Key? key, required this.workout, required this.onSave}) : super(key: key);

  @override
  State<_EditWorkoutForm> createState() => _EditWorkoutFormState();
}

class _EditWorkoutFormState extends State<_EditWorkoutForm> {
  late final TextEditingController _titleCtl = TextEditingController(text: widget.workout.title);
  late final TextEditingController _minutesCtl = TextEditingController(text: widget.workout.minutes.toString());
  late final TextEditingController _repsCtl = TextEditingController(text: widget.workout.reps?.toString() ?? '');
  late final TextEditingController _caloriesCtl = TextEditingController(text: widget.workout.calories.toString());
  late final TextEditingController _notesCtl = TextEditingController(text: widget.workout.notes ?? '');
  late DateTime _selectedDate = widget.workout.date;
  TimeOfDay? _selectedTime;
  late String _selectedType = widget.workout.type;
  final List<String> _types = ['Running', 'Cycling', 'Strength Training', 'Yoga', 'HIIT', 'Other'];
  bool _manualCalories = false;

  @override
  void dispose() {
    _titleCtl.dispose();
    _minutesCtl.dispose();
    _repsCtl.dispose();
    _caloriesCtl.dispose();
    _notesCtl.dispose();
    _minutesCtl.removeListener(_updateCaloriesIfNeeded);
    _repsCtl.removeListener(_updateCaloriesIfNeeded);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _selectedTime = TimeOfDay(hour: widget.workout.date.hour, minute: widget.workout.date.minute);
    // manual calories if type was Other initially
    _manualCalories = _selectedType == 'Other';
    _minutesCtl.addListener(_updateCaloriesIfNeeded);
    _repsCtl.addListener(_updateCaloriesIfNeeded);
  }

  void _updateCaloriesIfNeeded() {
    if (!mounted) return;
    if (_manualCalories) return;
    if (_selectedType == 'Other') return;
    final minutes = int.tryParse(_minutesCtl.text) ?? 0;
    final reps = int.tryParse(_repsCtl.text);
    final c = calculateCalories(type: _selectedType, minutes: minutes, reps: reps);
    _caloriesCtl.text = c.toString();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _selectedTime ?? TimeOfDay.now());
    if (picked != null) setState(() => _selectedTime = picked);
  }

  void _save() {
    final title = _titleCtl.text.trim();
    final minutes = int.tryParse(_minutesCtl.text) ?? 0;
    final reps = int.tryParse(_repsCtl.text);
    final calories = int.tryParse(_caloriesCtl.text) ?? 0;
    if (title.isEmpty || minutes <= 0) return;
  final t = _selectedTime ?? TimeOfDay.now();
  final combined = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, t.hour, t.minute);
    widget.onSave(Workout(title: title, type: _selectedType, minutes: minutes, reps: reps, calories: calories, notes: _notesCtl.text.trim().isEmpty ? null : _notesCtl.text.trim(), date: combined));
  }

  @override
  Widget build(BuildContext context) {
  String formatDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Edit Workout', style: TextStyle(fontSize: Responsive.fontSize(context, 18), fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Text('Date: ${formatDate(_selectedDate)}')),
              TextButton(onPressed: _pickDate, child: const Text('Change')),
              const SizedBox(width: 8),
              Expanded(child: Text('Time: ${_selectedTime?.format(context) ?? 'Not set'}')),
              TextButton(onPressed: _pickTime, child: const Text('Change')),
            ],
          ),
          const SizedBox(height: 8),
          TextField(controller: _titleCtl, decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedType,
            items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) {
              setState(() {
                final newType = v ?? _types.first;
                // if switching to Other, keep manual flag true, else keep existing unless was Other
                if (_selectedType == 'Other' && newType != 'Other') {
                  _manualCalories = false;
                } else if (newType == 'Other') {
                  _manualCalories = true;
                }
                _selectedType = newType;
                _updateCaloriesIfNeeded();
              });
            },
            decoration: const InputDecoration(labelText: 'Type'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: TextField(controller: _minutesCtl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Minutes'))),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: _repsCtl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Reps (optional)'))),
            ],
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextField(controller: _caloriesCtl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Calories'))),
            const SizedBox(width: 12),
            Column(children: [
              const Text('Manual'),
              Checkbox(value: _manualCalories, onChanged: (v) => setState(() => _manualCalories = v ?? false)),
            ])
          ]),
          const SizedBox(height: 8),
          TextField(controller: _notesCtl, decoration: const InputDecoration(labelText: 'Notes (optional)')),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
    );
  }
}

class WorkoutCard extends StatelessWidget {
  final Workout workout;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  const WorkoutCard({super.key, required this.workout, this.onDelete, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Card(
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
                    Text('${TimeOfDay.fromDateTime(workout.date).format(context)} • ${workout.type} • ${workout.minutes} min • ${workout.calories} kcal', style: TextStyle(color: Colors.grey[700])),
                    if (workout.notes != null && workout.notes!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(workout.notes!, style: TextStyle(color: Colors.grey[600], fontSize: Responsive.fontSize(context, 12)), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ]
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline))
            ],
          ),
        ),
      ),
    );
  }
}


class _AddWorkoutForm extends StatefulWidget {
  final void Function(Workout) onAdd;
  final void Function(WorkoutTemplate)? onSaveTemplate;
  final DateTime? initialDate;
  _AddWorkoutForm({Key? key, required this.onAdd, this.onSaveTemplate, this.initialDate}) : super(key: key);

  @override
  State<_AddWorkoutForm> createState() => _AddWorkoutFormState();
}

class _AddWorkoutFormState extends State<_AddWorkoutForm> {
  final _titleCtl = TextEditingController();
  final _minutesCtl = TextEditingController();
  final _caloriesCtl = TextEditingController();
  late DateTime _selectedDate;
  TimeOfDay? _selectedTime;

  String formatDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _selectedTime ?? TimeOfDay.now());
    if (picked != null) setState(() => _selectedTime = picked);
  }

  // Workout type handling
  final List<String> _types = ['Running', 'Cycling', 'Strength Training', 'Yoga', 'HIIT', 'Other'];
  String _selectedType = 'Running';
  final _repsCtl = TextEditingController();
  final _notesCtl = TextEditingController();
  bool _saveAsTemplate = false;
  bool _manualCalories = false;

  int _calculateCalories({required String type, required int minutes, int? reps}) {
    // Very simple heuristics for demo purposes
    if (type == 'Other') return 0; // will require manual entry
    switch (type) {
      case 'Running':
        return (10 * minutes).round(); // 10 kcal/min
      case 'Cycling':
        return (8 * minutes).round();
      case 'Strength Training':
        return (6 * minutes + (reps ?? 0) * 0).round();
      case 'Yoga':
        return (3 * minutes).round();
      case 'HIIT':
        return (12 * minutes).round();
      default:
        return (5 * minutes).round();
    }
  }

  @override
  void dispose() {
    _titleCtl.dispose();
    _minutesCtl.dispose();
    _caloriesCtl.dispose();
    _repsCtl.dispose();
    _notesCtl.dispose();
    _minutesCtl.removeListener(_maybeUpdateCalories);
    _repsCtl.removeListener(_maybeUpdateCalories);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  _selectedDate = widget.initialDate ?? DateTime.now();
  _selectedTime = TimeOfDay.now();
  _minutesCtl.addListener(_maybeUpdateCalories);
  _repsCtl.addListener(_maybeUpdateCalories);
  }

  void _maybeUpdateCalories() {
    if (!mounted) return;
    if (_manualCalories) return;
    if (_selectedType == 'Other') return;
    final minutes = int.tryParse(_minutesCtl.text) ?? 0;
    final reps = int.tryParse(_repsCtl.text);
    final c = calculateCalories(type: _selectedType, minutes: minutes, reps: reps);
    _caloriesCtl.text = c.toString();
  }

  void _submit() {
    final title = _titleCtl.text.trim();
    final minutes = int.tryParse(_minutesCtl.text) ?? 0;
    final manualCalories = int.tryParse(_caloriesCtl.text);
    if (title.isEmpty || minutes <= 0) return; // minimal validation for UI demo

    final computed = _calculateCalories(type: _selectedType, minutes: minutes, reps: int.tryParse(_repsCtl.text));
    final calories = _selectedType == 'Other' ? (manualCalories ?? 0) : computed;

  final t = _selectedTime ?? TimeOfDay.now();
  final combined = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, t.hour, t.minute);
    final workout = Workout(
      title: title,
      type: _selectedType,
      minutes: minutes,
      reps: int.tryParse(_repsCtl.text),
      calories: calories,
      notes: _notesCtl.text.trim().isEmpty ? null : _notesCtl.text.trim(),
      date: combined,
    );

    widget.onAdd(workout);

    if (_saveAsTemplate && widget.onSaveTemplate != null) {
      widget.onSaveTemplate!(WorkoutTemplate(title: workout.title, type: workout.type, minutes: workout.minutes, reps: workout.reps, calories: workout.calories, notes: workout.notes));
    }
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
              Expanded(child: Text('Date: ${formatDate(_selectedDate)}')),
              TextButton(onPressed: _pickDate, child: const Text('Change')),
              const SizedBox(width: 8),
              Expanded(child: Text('Time: ${_selectedTime?.format(context) ?? 'Not set'}')),
              TextButton(onPressed: _pickTime, child: const Text('Change')),
            ],
          ),
          const SizedBox(height: 8),
          TextField(controller: _titleCtl, decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 8),

          // Type selector
          DropdownButtonFormField<String>(
            initialValue: _selectedType,
            items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() {
              final newType = v ?? _types.first;
              if (_selectedType == 'Other' && newType != 'Other') _manualCalories = false;
              if (newType == 'Other') _manualCalories = true;
              _selectedType = newType;
              _maybeUpdateCalories();
            }),
            decoration: const InputDecoration(labelText: 'Type'),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(child: TextField(controller: _minutesCtl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Minutes'))),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: _repsCtl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Reps (optional)'))),
            ],
          ),
          const SizedBox(height: 8),

          // If user chose Other, allow manual calories entry
          Row(children: [
            Expanded(child: TextField(controller: _caloriesCtl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Calories'))),
            const SizedBox(width: 12),
            Column(children: [
              const Text('Manual'),
              Checkbox(value: _manualCalories, onChanged: (v) => setState(() => _manualCalories = v ?? false)),
            ])
          ]),
          if (!_manualCalories && _selectedType != 'Other')
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text('Estimated calories: ${calculateCalories(type: _selectedType, minutes: int.tryParse(_minutesCtl.text) ?? 0, reps: int.tryParse(_repsCtl.text))} kcal'),
            ),

          TextField(controller: _notesCtl, decoration: const InputDecoration(labelText: 'Notes (optional)')),
          const SizedBox(height: 8),
          Row(
            children: [
              Checkbox(value: _saveAsTemplate, onChanged: (v) => setState(() => _saveAsTemplate = v ?? false)),
              const SizedBox(width: 8),
              const Expanded(child: Text('Save to My Workouts')),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: _submit, child: const Text('Add')),
        ],
      ),
    );
  }
}

class _PlanForm extends StatefulWidget {
  final WorkoutPlan? initial;
  final void Function(WorkoutPlan) onSave;
  _PlanForm({Key? key, this.initial, required this.onSave}) : super(key: key);

  @override
  State<_PlanForm> createState() => _PlanFormState();
}

class _PlanFormState extends State<_PlanForm> {
  late final TextEditingController _nameCtl = TextEditingController(text: widget.initial?.name ?? '');
  late final TextEditingController _descCtl = TextEditingController(text: widget.initial?.description ?? '');
  List<PlanEntry> _entries = [];
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _entries = widget.initial?.entries.map((e) => PlanEntry(dayOffset: e.dayOffset, templates: e.templates.map((t) => WorkoutTemplate(title: t.title, type: t.type, minutes: t.minutes, reps: t.reps, calories: t.calories, notes: t.notes, time: t.time)).toList())).toList() ?? [];
    _nameCtl.addListener(() => _markDirty());
    _descCtl.addListener(() => _markDirty());
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _descCtl.dispose();
    super.dispose();
  }

  void _markDirty() => setState(() => _isDirty = true);

  Future<bool> _confirmDiscard() async {
    final res = await showDialog<bool>(context: context, builder: (dctx) => AlertDialog(
      title: const Text('Discard changes?'),
      content: const Text('You have unsaved changes. Discard and exit?'),
      actions: [TextButton(onPressed: () => Navigator.of(dctx).pop(false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.of(dctx).pop(true), child: const Text('Discard'))],
    ));
    return res == true;
  }

  Future<bool> _onAttemptClose() async {
    if (!_isDirty) return true;
    return await _confirmDiscard();
  }

  void _addEntry() {
    setState(() {
      _entries.add(PlanEntry(dayOffset: _entries.length, templates: [WorkoutTemplate(title: 'New', type: 'Other', minutes: 20, calories: 0)]));
      _markDirty();
    });
  }

  void _save() {
    final p = WorkoutPlan(name: _nameCtl.text.trim(), description: _descCtl.text.trim().isEmpty ? null : _descCtl.text.trim(), entries: _entries);
    widget.onSave(p);
    _isDirty = false;
  }

  @override
  Widget build(BuildContext context) {
    final modalHeight = MediaQuery.of(context).size.height * 0.75;

    return WillPopScope(
      onWillPop: _onAttemptClose,
      child: SizedBox(
        height: modalHeight,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(onPressed: () async {
                    final ok = await _onAttemptClose();
                    if (ok) Navigator.of(context).pop();
                  }, icon: const Icon(Icons.arrow_back)),
                  Expanded(child: Text(widget.initial == null ? 'New Plan' : 'Edit Plan', style: TextStyle(fontSize: Responsive.fontSize(context, 18), fontWeight: FontWeight.w700))),
                ],
              ),
              const SizedBox(height: 12),
              TextField(controller: _nameCtl, decoration: const InputDecoration(labelText: 'Plan name')),
              const SizedBox(height: 8),
              TextField(controller: _descCtl, decoration: const InputDecoration(labelText: 'Description (optional)')),
              const SizedBox(height: 8),

              // Entries list - scrollable inside modal
              Expanded(
                child: _entries.isEmpty
                    ? Center(child: Text('No entries yet. Tap "Add entry" to start.', style: TextStyle(color: Colors.grey[600])))
                    : ListView.builder(
                        itemCount: _entries.length,
                        itemBuilder: (ctx, idx) {
                          final e = _entries[idx];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(children: [Expanded(child: Text('Day ${e.dayOffset + 1}', style: const TextStyle(fontWeight: FontWeight.w700))), IconButton(onPressed: () { setState(() => _entries.removeAt(idx)); _markDirty(); }, icon: const Icon(Icons.delete))]),
                                  const SizedBox(height: 8),
                                  ...e.templates.asMap().entries.map((me2) {
                                    final tidx = me2.key;
                                    final tmpl = me2.value;
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(tmpl.title),
                                      subtitle: Text('${tmpl.type} • ${tmpl.minutes} min • ${tmpl.calories} kcal${tmpl.time != null ? ' • ${tmpl.time!.format(context)}' : ''}'),
                                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () async {
                                            final updated = await showModalBottomSheet<WorkoutTemplate>(
                                              context: context,
                                              isScrollControlled: true,
                                              builder: (c3) => Padding(
                                                padding: EdgeInsets.only(bottom: MediaQuery.of(c3).viewInsets.bottom),
                                                child: _TemplateForm(initial: tmpl, onSave: (t) => Navigator.of(c3).pop(t)),
                                              ),
                                            );
                                            if (updated != null) setState(() { _entries[idx].templates[tidx] = updated; _markDirty(); });
                                          },
                                        ),
                                        IconButton(icon: const Icon(Icons.delete), onPressed: () => setState(() { _entries[idx].templates.removeAt(tidx); _markDirty(); })),
                                      ]),
                                    );
                                  }).toList(),
                                  Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () async {
                                    final created = await showModalBottomSheet<WorkoutTemplate>(
                                      context: context,
                                      isScrollControlled: true,
                                      builder: (c4) => Padding(
                                        padding: EdgeInsets.only(bottom: MediaQuery.of(c4).viewInsets.bottom),
                                        child: _TemplateForm(onSave: (t) => Navigator.of(c4).pop(t)),
                                      ),
                                    );
                                    if (created != null) setState(() { _entries[idx].templates.add(created); _markDirty(); });
                                  }, child: const Text('Add workout to this day'))),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 8),
              Row(children: [TextButton(onPressed: _addEntry, child: const Text('Add entry')), const Spacer(), ElevatedButton(onPressed: () { _save(); Navigator.of(context).pop(); }, child: const Text('Save'))]),
            ],
          ),
        ),
      ),
    );
  }
}

class _TemplateForm extends StatefulWidget {
  final WorkoutTemplate? initial;
  final void Function(WorkoutTemplate) onSave;
  _TemplateForm({Key? key, this.initial, required this.onSave}) : super(key: key);

  @override
  State<_TemplateForm> createState() => _TemplateFormState();
}

class _TemplateFormState extends State<_TemplateForm> {
  late final TextEditingController _titleCtl = TextEditingController(text: widget.initial?.title ?? '');
  late final TextEditingController _minutesCtl = TextEditingController(text: widget.initial?.minutes.toString() ?? '');
  late final TextEditingController _repsCtl = TextEditingController(text: widget.initial?.reps?.toString() ?? '');
  late final TextEditingController _caloriesCtl = TextEditingController(text: widget.initial?.calories.toString() ?? '');
  late final TextEditingController _notesCtl = TextEditingController(text: widget.initial?.notes ?? '');
  String _selectedType = 'Running';
  final List<String> _types = ['Running', 'Cycling', 'Strength Training', 'Yoga', 'HIIT', 'Other'];
  TimeOfDay? _templateTime;
  bool _manualCalories = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initial?.type ?? 'Running';
  _templateTime = widget.initial?.time;
  _manualCalories = _selectedType == 'Other';
  _minutesCtl.addListener(_maybeUpdateCalories);
  _repsCtl.addListener(_maybeUpdateCalories);
  }

  @override
  void dispose() {
    _titleCtl.dispose();
    _minutesCtl.dispose();
    _repsCtl.dispose();
    _caloriesCtl.dispose();
    _notesCtl.dispose();
    _minutesCtl.removeListener(_maybeUpdateCalories);
    _repsCtl.removeListener(_maybeUpdateCalories);
    super.dispose();
  }

  void _maybeUpdateCalories() {
    if (!mounted) return;
    if (_manualCalories) return;
    if (_selectedType == 'Other') return;
    final minutes = int.tryParse(_minutesCtl.text) ?? 0;
    final reps = int.tryParse(_repsCtl.text);
    final c = calculateCalories(type: _selectedType, minutes: minutes, reps: reps);
    _caloriesCtl.text = c.toString();
  }

  void _save() {
    final t = WorkoutTemplate(
      title: _titleCtl.text.trim(),
      type: _selectedType,
      minutes: int.tryParse(_minutesCtl.text) ?? 0,
      reps: int.tryParse(_repsCtl.text),
      calories: int.tryParse(_caloriesCtl.text) ?? 0,
      notes: _notesCtl.text.trim().isEmpty ? null : _notesCtl.text.trim(),
      time: _templateTime,
    );
    widget.onSave(t);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back)),
              Expanded(child: Text(widget.initial == null ? 'New Template' : 'Edit Template', style: TextStyle(fontSize: Responsive.fontSize(context, 18), fontWeight: FontWeight.w700))),
            ],
          ),
          const SizedBox(height: 12),
          TextField(controller: _titleCtl, decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedType,
            items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() {
              final newType = v ?? _types.first;
              if (_selectedType == 'Other' && newType != 'Other') _manualCalories = false;
              if (newType == 'Other') _manualCalories = true;
              _selectedType = newType;
              _maybeUpdateCalories();
            }),
            decoration: const InputDecoration(labelText: 'Type'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: TextField(controller: _minutesCtl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Minutes'))),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: _repsCtl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Reps (optional)'))),
            ],
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextField(controller: _caloriesCtl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Calories'))),
            const SizedBox(width: 12),
            Column(children: [
              const Text('Manual'),
              Checkbox(value: _manualCalories, onChanged: (v) => setState(() => _manualCalories = v ?? false)),
            ])
          ]),
          const SizedBox(height: 8),
          TextField(controller: _notesCtl, decoration: const InputDecoration(labelText: 'Notes (optional)')),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Text('Time: ${_templateTime != null ? _templateTime!.format(context) : 'Not set'}')),
              TextButton(
                onPressed: () async {
                  final picked = await showTimePicker(context: context, initialTime: _templateTime ?? TimeOfDay.now());
                  if (picked != null) setState(() => _templateTime = picked);
                },
                child: const Text('Set Time'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
    );
  }
}

