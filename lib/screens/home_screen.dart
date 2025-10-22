import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import 'workout_log_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

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
          const _HomeContent(),
          const _WorkoutsTab(),
          const _CaloriesTab(),
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
  const _HomeContent({Key? key}) : super(key: key);

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
                        Navigator.of(context).pushNamed('/workouts');
                      },
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _QuickAction(
                      icon: Icons.restaurant_menu,
                      label: 'Log Calories',
                      onTap: () {
                        Navigator.of(context).pushNamed('/calories');
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
  const _WorkoutsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const WorkoutLogScreen();
  }
}

class _CaloriesTab extends StatelessWidget {
  const _CaloriesTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).pushNamed('/calories'),
        child: const Text('Open Calorie Tracker'),
      ),
    );
  }
}

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
