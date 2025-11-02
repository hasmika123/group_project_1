import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import '../services/database_helper.dart';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;


class WeightProgressChart extends StatelessWidget {
  final List<double> weights;
  final List<DateTime> dates;

  const WeightProgressChart({
    Key? key,
    required this.weights,
    required this.dates,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (weights.isEmpty || dates.isEmpty || weights.length != dates.length) {
      return const Center(child: Text('No weight data'));
    }

    final spots = List.generate(
      weights.length,
      (i) => FlSpot(i.toDouble(), weights[i]),
    );

    final latestWeight = weights.last;
    final latestIndex = weights.length - 1;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LineChart(
        LineChartData(
          minY: weights.reduce((a, b) => a < b ? a : b) - 2,
          maxY: weights.reduce((a, b) => a > b ? a : b) + 2,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  int idx = value.toInt();
                  if (idx < 0 || idx >= dates.length) return const SizedBox();
                  final dateStr = DateFormat('MMM d').format(dates[idx]);
                  return Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  );
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.purple,
              barWidth: 2,
              dotData: FlDotData(
                show: true,
                // dotColor removed for fl_chart 0.65.0 compatibility
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.withOpacity(0.18),
                    Colors.purple.withOpacity(0.01),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Colors.white,
              getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                final idx = spot.x.toInt();
                final dateStr = DateFormat('MMM d').format(dates[idx]);
                return LineTooltipItem(
                  '$dateStr\n${spot.y.toStringAsFixed(1)} kg',
                  const TextStyle(color: Colors.purple),
                );
              }).toList(),
            ),
          ),
          extraLinesData: ExtraLinesData(horizontalLines: [
            HorizontalLine(
              y: latestWeight,
              color: Colors.purple,
              strokeWidth: 0,
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.centerRight,
                style: const TextStyle(
                  color: Colors.purple,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                labelResolver: (_) => 'Latest: ${latestWeight.toStringAsFixed(1)} kg',
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// Top-level custom painter for weight line chart
class _WeightLineChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  _WeightLineChartPainter(this.values, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..isAntiAlias = true;

    final fill = Paint()
      ..color = color.withOpacity(0.12)
      ..style = PaintingStyle.fill;

    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final minVal = values.reduce((a, b) => a < b ? a : b);
    final range = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    final stepX = size.width / (values.length - 1 == 0 ? 1 : (values.length - 1));
    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = i * stepX;
      final normalized = (values[i] - minVal) / range;
      final y = size.height - (normalized * size.height);
      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) path.lineTo(points[i].dx, points[i].dy);

    // area fill
    final area = Path.from(path)..lineTo(size.width, size.height)..lineTo(0, size.height)..close();
    canvas.drawPath(area, fill);
    canvas.drawPath(path, paint);

    // draw dots
    final dotPaint = Paint()..color = color;
    for (final pnt in points) {
      canvas.drawCircle(pnt, 2.6, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_WeightLineChartPainter oldDelegate) => oldDelegate.values != values || oldDelegate.color != color;
}

// Top-level custom painter for calories/workouts line chart
class _LineChartPainter extends CustomPainter {
  final List<int> values;
  final Color color;
  _LineChartPainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..isAntiAlias = true;

    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final minVal = values.reduce((a, b) => a < b ? a : b);
    final range = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal).toDouble();

    final stepX = size.width / (values.length - 1 == 0 ? 1 : (values.length - 1));
    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = i * stepX;
      final normalized = (values[i] - minVal) / range;
      final y = size.height - (normalized * size.height);
      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) path.lineTo(points[i].dx, points[i].dy);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_LineChartPainter oldDelegate) => oldDelegate.values != values || oldDelegate.color != color;
}

class ProgressScreen extends StatefulWidget {
  static const routeName = '/progress';
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  List<DateTime> _days = [];
  List<int> _caloriesPerDay = [];
  List<int> _minutesPerDay = [];
  List<double?> _weightsPerDay = [];
  double? _startingWeight;
  double? _profileStartingWeight;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initDays();
    DatabaseHelper.instance.caloriesNotifier.addListener(_loadData);
    DatabaseHelper.instance.workoutsNotifier.addListener(_loadData);
    DatabaseHelper.instance.profileNotifier.addListener(_loadData);
    _loadData();
  }

  void _initDays() {
    final now = DateTime.now();
    _days = List.generate(7, (i) => DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i)));
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    final caloriesList = <int>[];
    final minutesList = <int>[];
    final weightsList = <double?>[];

    for (final day in _days) {
      final calRows = await DatabaseHelper.instance.getCalories(day: day);
      final dayCalories = calRows.fold<int>(0, (acc, r) {
        final v = r['calories'];
        if (v is int) return acc + v;
        if (v is double) return acc + v.toInt();
        if (v is num) return acc + v.toInt();
        if (v is String) return acc + (int.tryParse(v) ?? 0);
        return acc;
      });
      caloriesList.add(dayCalories);

      final wRows = await DatabaseHelper.instance.getWorkouts(day: day);
      final dayMinutes = wRows.fold<int>(0, (acc, r) {
        final v = r['minutes'];
        if (v is int) return acc + v;
        if (v is double) return acc + v.toInt();
        if (v is num) return acc + v.toInt();
        if (v is String) return acc + (int.tryParse(v) ?? 0);
        return acc;
      });
      minutesList.add(dayMinutes);

      final weightRows = await DatabaseHelper.instance.getWeightLogs(day: day);
      double? dayWeight;
      if (weightRows.isNotEmpty) {
        final w = weightRows.first['weight'];
        if (w is double) dayWeight = w;
        else if (w is int) dayWeight = w.toDouble();
        else if (w is num) dayWeight = w.toDouble();
        else if (w is String) dayWeight = double.tryParse(w);
      }
      weightsList.add(dayWeight);
    }
    final allWeightLogs = await DatabaseHelper.instance.getWeightLogs();
    if (allWeightLogs.isNotEmpty) {
      final firstWeight = allWeightLogs.last['weight'];
      if (firstWeight is double) _startingWeight = firstWeight;
      else if (firstWeight is int) _startingWeight = firstWeight.toDouble();
      else if (firstWeight is num) _startingWeight = firstWeight.toDouble();
      else if (firstWeight is String) _startingWeight = double.tryParse(firstWeight);
    } else {
      _startingWeight = null;
    }
    final profile = await DatabaseHelper.instance.getProfile();
    if (profile != null && profile['weight'] != null) {
      final pw = profile['weight'];
      if (pw is double) _profileStartingWeight = pw;
      else if (pw is int) _profileStartingWeight = pw.toDouble();
      else if (pw is num) _profileStartingWeight = pw.toDouble();
      else if (pw is String) _profileStartingWeight = double.tryParse(pw);
    } else {
      _profileStartingWeight = null;
    }

    setState(() {
      _caloriesPerDay = caloriesList;
      _minutesPerDay = minutesList;
      _weightsPerDay = weightsList;
      _loading = false;
    });
  }

  @override
  void dispose() {
    DatabaseHelper.instance.caloriesNotifier.removeListener(_loadData);
    DatabaseHelper.instance.workoutsNotifier.removeListener(_loadData);
    DatabaseHelper.instance.profileNotifier.removeListener(_loadData);
    super.dispose();
  }

  Widget _buildBarChart(List<int> values, Color color, String unit) {
    final maxVal = values.isEmpty ? 1 : values.reduce((a, b) => a > b ? a : b);
    final displayMax = maxVal == 0 ? 1 : maxVal;
    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(values.length, (i) {
          final v = values[i];
          final fraction = v / displayMax;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Tooltip(
                    message: '${_dayLabel(_days[i])}: $v $unit',
                    child: Container(
                      height: 120 * fraction + 4,
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(_shortWeekday(_days[i]), style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildLineChart(List<int> values, Color color) {
    return SizedBox(
      height: 80,
      child: CustomPaint(
        painter: _LineChartPainter(values: values, color: color),
        size: const Size.fromHeight(80),
      ),
    );
  }

  Widget _buildWeightLineChart(List<double?> values, Color color, double? startingWeight) {
    final validValues = values.map((v) => v ?? 0.0).toList();
    if (startingWeight != null && validValues.isNotEmpty) {
      validValues.insert(0, startingWeight);
    }
    return SizedBox(
      height: 80,
      child: CustomPaint(
        painter: _WeightLineChartPainter(validValues, color),
        size: const Size.fromHeight(80),
      ),
    );
  }

  String _shortWeekday(DateTime d) => ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][d.weekday - 1];
  String _dayLabel(DateTime d) => '${_shortWeekday(d)} ${d.month}/${d.day}';

  Future<void> _exportCsv() async {
    final rows = <String>['date,calories,minutes'];
    for (var i = 0; i < _days.length; i++) {
      rows.add('${_days[i].toIso8601String().split('T').first},${_caloriesPerDay[i]},${_minutesPerDay[i]}');
    }
    final csv = rows.join('\n');
    if (kIsWeb) {
      await Clipboard.setData(ClipboardData(text: csv));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV copied to clipboard (web)')));
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'progress_export.csv'));
      await file.writeAsString(csv);
      await Clipboard.setData(ClipboardData(text: csv));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV saved to ${file.path} and copied to clipboard')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progress'), actions: [IconButton(icon: const Icon(Icons.download), onPressed: _exportCsv)]),
      body: Padding(
        padding: Responsive.pagePadding(context),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Last 7 days', style: TextStyle(fontSize: Responsive.fontSize(context, 18), fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Calories', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            _caloriesPerDay.every((v) => v == 0)
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 24.0),
                                    child: Center(child: Text('No calories logged in the last 7 days')),
                                  )
                                : _buildBarChart(_caloriesPerDay, Colors.orange, 'kcal'),
                            const SizedBox(height: 8),
                            Text('Total: ${_caloriesPerDay.fold<int>(0, (a, b) => a + b)} kcal', style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            _buildLineChart(_caloriesPerDay, Colors.orange),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Workouts', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            _minutesPerDay.every((v) => v == 0)
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 24.0),
                                    child: Center(child: Text('No workouts logged in the last 7 days')),
                                  )
                                : _buildBarChart(_minutesPerDay, Colors.blue, 'min'),
                            const SizedBox(height: 8),
                            Text('Total: ${_minutesPerDay.fold<int>(0, (a, b) => a + b)} min', style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            _buildLineChart(_minutesPerDay, Colors.blue),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Weight', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            FutureBuilder<List<Map<String, Object?>>>(
                              future: DatabaseHelper.instance.getWeightLogs(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData || snapshot.data!.length < 2) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 24.0),
                                    child: Center(child: Text('Not enough weight data for chart')), // At least 2 points required
                                  );
                                }
                                final logs = snapshot.data!..sort((a, b) => ((a['date'] as int?) ?? 0).compareTo((b['date'] as int?) ?? 0));
                                final weights = logs.map((m) => (m['weight'] as num?)?.toDouble() ?? 0.0).toList();
                                final dates = logs.map((m) => DateTime.fromMillisecondsSinceEpoch(m['date'] as int)).toList();
                                return SizedBox(
                                  height: 220,
                                  child: WeightProgressChart(weights: weights, dates: dates),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            Text('Initial Profile Weight: ${_profileStartingWeight?.toStringAsFixed(1) ?? '--'} kg', style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Text('Latest: ${_weightsPerDay.lastWhere((v) => v != null, orElse: () => null)?.toStringAsFixed(1) ?? '--'} kg', style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Text('Average: ${_weightsPerDay.where((v) => v != null).isEmpty ? '--' : (_weightsPerDay.where((v) => v != null).map((v) => v!).reduce((a, b) => a + b) / _weightsPerDay.where((v) => v != null).length).toStringAsFixed(1)} kg', style: const TextStyle(color: Colors.black54)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.refresh),
        onPressed: _seedSampleData,
        tooltip: 'Seed sample data',
      ),
    );
  }

  Future<void> _seedSampleData() async {
    final now = DateTime.now();
    for (var i = 0; i < 7; i++) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i));
      await DatabaseHelper.instance.insertCalorie({
        'date': day.millisecondsSinceEpoch,
        'calories': 1500 + i * 100,
      });
      await DatabaseHelper.instance.insertWorkout({
        'date': day.millisecondsSinceEpoch,
        'minutes': 30 + i * 5,
      });
      await DatabaseHelper.instance.insertWeightLog({
        'date': day.millisecondsSinceEpoch,
        'weight': 70.0 + i * 0.5, // Example: gradual weight change
      });
    }
    _loadData();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sample data seeded')));
  }
}