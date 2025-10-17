import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

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

    return Padding(
      padding: const EdgeInsets.all(16.0),
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
                  const Text(
                    'Today',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Calorie Deficit', style: TextStyle(fontSize: 14)),
                          const SizedBox(height: 6),
                          Text(
                            '$deficit',
                            style: TextStyle(
                              fontSize: 28,
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

          const SizedBox(height: 16),

          // Progress summary
          Row(
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
          ),

          const SizedBox(height: 16),

          // Quick actions
          const Text('Quick actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _QuickAction(
                icon: Icons.add_circle_outline,
                label: 'Add Workout',
                onTap: () {
                  Navigator.of(context).pushNamed('/workouts');
                },
              ),
              _QuickAction(
                icon: Icons.restaurant_menu,
                label: 'Log Calories',
                onTap: () {
                  Navigator.of(context).pushNamed('/calories');
                },
              ),
              _QuickAction(
                icon: Icons.show_chart,
                label: 'View Progress',
                onTap: () {
                  Navigator.of(context).pushNamed('/progress');
                },
              ),
            ],
          ),

          const Spacer(),

          // Small footer / tip
          Text(
            'Tip: Tap actions or use the navigation bar to explore other sections.',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _WorkoutsTab extends StatelessWidget {
  const _WorkoutsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).pushNamed('/workouts'),
        child: const Text('Open Workout Log'),
      ),
    );
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
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              child: Icon(icon, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 6),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            )
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
    return Expanded(
      child: InkWell(
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
              Icon(icon, size: 28),
              const SizedBox(height: 6),
              Text(label, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
