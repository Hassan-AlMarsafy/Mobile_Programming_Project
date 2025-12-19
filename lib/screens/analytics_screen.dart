import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hydroponic_app/theme/app_theme.dart';
import 'package:path_provider/path_provider.dart';
import '../services/database_service.dart';
import '../widgets/main_layout.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final DatabaseService _databaseService = DatabaseService();

  List<Map<String, dynamic>> _sensorHistory = [];
  Map<String, dynamic> _statistics = {};
  bool _loading = true;
  int _selectedDays = 7;
  String _selectedSensor = 'temperature';
  bool _showScrollHint = true;
  final ScrollController _chipScrollController = ScrollController();

  final Map<String, String> _sensorLabels = {
    'temperature': 'Temperature (°C)',
    'ph': 'pH Level',
    'water_level': 'Water Level (%)',
    'tds': 'TDS (ppm)',
    'light_intensity': 'Light (lux)',
  };

  final Map<String, Color> _sensorColors = {
    'temperature': Colors.orange,
    'ph': Colors.blue,
    'water_level': Colors.cyan,
    'tds': Colors.purple,
    'light_intensity': Colors.amber,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
    _chipScrollController.addListener(_onChipScroll);
  }

  void _onChipScroll() {
    final maxScroll = _chipScrollController.position.maxScrollExtent;
    final currentScroll = _chipScrollController.position.pixels;
    setState(() {
      _showScrollHint = currentScroll < maxScroll - 10;
    });
  }

  @override
  void dispose() {
    _chipScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    final history =
        await _databaseService.getSensorHistory(days: _selectedDays);
    final stats =
        await _databaseService.getSensorStatistics(days: _selectedDays);

    setState(() {
      _sensorHistory = history;
      _statistics = stats;
      _loading = false;
    });
  }

  Future<void> _exportData() async {
    if (_sensorHistory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export')),
      );
      return;
    }

    // Build CSV content
    final buffer = StringBuffer();
    buffer.writeln('Timestamp,Temperature,pH,Water Level,TDS,Light Intensity');

    for (final row in _sensorHistory) {
      final timestamp =
          DateTime.fromMillisecondsSinceEpoch(row['timestamp'] as int);
      buffer.writeln('${timestamp.toIso8601String()},'
          '${row['temperature']},'
          '${row['ph']},'
          '${row['water_level']},'
          '${row['tds']},'
          '${row['light_intensity']}');
    }

    try {
      // Get Downloads directory
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
      } else {
        directory = await getDownloadsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not access Downloads folder');
      }

      final fileName =
          'hydroponic_data_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(buffer.toString());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to Downloads: $fileName'),
            backgroundColor: Colors.green[700],
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Analytics & History',
      currentIndex: 3,
      actions: [
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          tooltip: 'Export Data',
          onPressed: _exportData,
        ),
        PopupMenuButton<int>(
          icon: const Icon(Icons.calendar_today, color: Colors.white),
          tooltip: 'Select Time Range',
          onSelected: (days) {
            setState(() => _selectedDays = days);
            _loadData();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 1, child: Text('Last 24 hours')),
            const PopupMenuItem(value: 3, child: Text('Last 3 days')),
            const PopupMenuItem(value: 7, child: Text('Last 7 days')),
          ],
        ),
      ],
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTimeRangeInfo(),
                    const SizedBox(height: 16),
                    _buildSensorSelector(),
                    const SizedBox(height: 16),
                    _buildTrendChart(),
                    const SizedBox(height: 24),
                    _buildStatisticsCards(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTimeRangeInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.darkPrimaryColor
            : AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.darkPrimaryColor
                : AppTheme.primaryColor),
      ),
      child: Row(
        children: [
          Icon(Icons.analytics,
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.white
                  : AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Viewing: Last $_selectedDays day${_selectedDays > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.white
                        : AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorSelector() {
    return Stack(
      children: [
        SingleChildScrollView(
          controller: _chipScrollController,
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ..._sensorLabels.entries.map((entry) {
                final isSelected = _selectedSensor == entry.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(entry.value.split(' ').first),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedSensor = entry.key);
                      }
                    },
                    selectedColor: _sensorColors[entry.key]?.withOpacity(0.3),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? _sensorColors[entry.key]
                          : Colors.grey[600],
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }),
              const SizedBox(width: 20),
            ],
          ),
        ),
        // Scroll indicator on the right (hides when scrolled to end)
        if (_showScrollHint)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.only(left: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Theme.of(context).scaffoldBackgroundColor.withOpacity(0),
                    Theme.of(context).scaffoldBackgroundColor,
                  ],
                ),
              ),
              child: Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
                size: 20,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTrendChart() {
    if (_sensorHistory.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          height: 250,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.show_chart, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'No sensor data yet',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Data will appear as sensors report readings',
                style: TextStyle(fontSize: 14, color: Colors.grey[400]),
              ),
            ],
          ),
        ),
      );
    }

    final spots = _getChartSpots();
    if (spots.isEmpty) {
      return Card(
        child: Container(
          height: 200,
          alignment: Alignment.center,
          child: const Text('No data for this sensor'),
        ),
      );
    }

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    // Ensure we have a valid range to prevent horizontalInterval from being zero
    final range = maxY - minY;
    final safeRange = range == 0 ? 1.0 : range;
    final padding = safeRange * 0.1;
    final horizontalInterval = safeRange / 4;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _sensorLabels[_selectedSensor] ?? '',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: horizontalInterval,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey[300]!,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(1),
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey[600]),
                          );
                        },
                      ),
                    ),
                    bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            spot.y.toStringAsFixed(2),
                            TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  minY: minY - padding,
                  maxY: maxY + padding,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: _sensorColors[_selectedSensor],
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: _sensorColors[_selectedSensor]?.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _getChartSpots() {
    final spots = <FlSpot>[];
    for (int i = 0; i < _sensorHistory.length; i++) {
      final value = _sensorHistory[i][_selectedSensor];
      if (value != null) {
        spots.add(FlSpot(i.toDouble(), (value as num).toDouble()));
      }
    }
    return spots;
  }

  Widget _buildStatisticsCards() {
    final keyMap = {
      'temperature': ['avg_temp', 'min_temp', 'max_temp'],
      'ph': ['avg_ph', 'min_ph', 'max_ph'],
      'water_level': ['avg_water', 'min_water', 'max_water'],
      'tds': ['avg_tds', 'min_tds', 'max_tds'],
      'light_intensity': ['avg_light', 'min_light', 'max_light'],
    };

    final keys = keyMap[_selectedSensor] ?? [];
    if (keys.length < 3) return const SizedBox();

    final avg = _statistics[keys[0]] as num? ?? 0;
    final min = _statistics[keys[1]] as num? ?? 0;
    final max = _statistics[keys[2]] as num? ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistics',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                  'Average', avg.toStringAsFixed(1), Colors.green),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                  'Minimum', min.toStringAsFixed(1), Colors.blue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                  'Maximum', max.toStringAsFixed(1), Colors.orange),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
