import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hydroponic_app/theme/app_theme.dart';
import '../widgets/main_layout.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Analytics & History',
      currentIndex: 3,
      actions: [
        IconButton(
          icon: const Icon(Icons.download_for_offline_outlined, color: Colors.white),
          tooltip: 'Export Data',
          onPressed: () {
            // Placeholder for export functionality
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Export functionality coming soon!')),
            );
          },
        ),
      ],
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDateRangeSelector(), // New Section
                const SizedBox(height: 24),
                _buildSectionHeader('Sensor Trends (Last 24h)'),
                const SizedBox(height: 16),
                _buildLineChartCard(),
                const SizedBox(height: 24),
                _buildSectionHeader('Trend Analysis'), // New Section
                const SizedBox(height: 16),
                _buildTrendAnalysisCard(), // New Widget
                const SizedBox(height: 24),
                _buildSectionHeader('Daily Averages'),
                const SizedBox(height: 16),
                _buildBarChartCard(),
                const SizedBox(height: 24),
                _buildSectionHeader('Historical Data'), // New Section
                const SizedBox(height: 16),
                _buildHistoricalDataTable(), // New Widget
                const SizedBox(height: 24),
                _buildSectionHeader('System Uptime'),
                const SizedBox(height: 16),
                _buildSystemUptimeCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // New Widget: Date Range Selector
  Widget _buildDateRangeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Date Range: Last 24 Hours',
            style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodySmall?.color),
          ),
          Icon(Icons.calendar_today_outlined, color: Theme.of(context).colorScheme.primary),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
    );
  }

  // New Widget: Trend Analysis Summary
  Widget _buildTrendAnalysisCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildTrendRow('Temperature', 'Stable', '25.8°C', Icons.thermostat, Colors.orange),
            const Divider(height: 24),
            _buildTrendRow('pH Level', 'Slight Decrease', '6.5', Icons.science_outlined, Colors.blue),
            const Divider(height: 24),
            _buildTrendRow('Humidity', 'Optimal', '65%', Icons.water_drop_outlined, Colors.teal),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendRow(String metric, String trend, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(metric, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(trend, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
            ],
          ),
        ),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // New Widget: Historical Data Table
  Widget _buildHistoricalDataTable() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Time', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Temp', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('pH', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: [
          DataRow(cells: [
            DataCell(Text('12:00 PM')),
            DataCell(Text('26.1°C')),
            DataCell(Text('6.5')),
          ]),
          DataRow(cells: [
            DataCell(Text('08:00 AM')),
            DataCell(Text('25.8°C')),
            DataCell(Text('6.7')),
          ]),
          DataRow(cells: [
            DataCell(Text('04:00 AM')),
            DataCell(Text('25.2°C')),
            DataCell(Text('6.9')),
          ]),
        ],
      ),
    );
  }

  Widget _buildLineChartCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Temperature & pH Levels',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodySmall?.color),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 22)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    _buildLineSeries([
                      const FlSpot(0, 25.5),
                      const FlSpot(4, 25.2),
                      const FlSpot(8, 25.8),
                      const FlSpot(12, 26.1),
                      const FlSpot(16, 25.9),
                      const FlSpot(20, 25.7),
                      const FlSpot(24, 26.0),
                    ], Colors.orange),
                    _buildLineSeries([
                      const FlSpot(0, 6.8),
                      const FlSpot(4, 6.9),
                      const FlSpot(8, 6.7),
                      const FlSpot(12, 6.5),
                      const FlSpot(16, 6.6),
                      const FlSpot(20, 6.8),
                      const FlSpot(24, 6.9),
                    ], Colors.blue),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  LineChartBarData _buildLineSeries(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 4,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: true, color: color.withOpacity(0.2)),
    );
  }

  Widget _buildBarChartCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Humidity & Water Level',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodySmall?.color),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 14);
                          String text;
                          switch (value.toInt()) {
                            case 0:
                              text = 'Humidity';
                              break;
                            case 1:
                              text = 'Water';
                              break;
                            default:
                              text = '';
                              break;
                          }
                          return SideTitleWidget(axisSide: meta.axisSide, child: Text(text, style: style));
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  barGroups: [
                    _buildBarGroupData(0, 65, Colors.teal),
                    _buildBarGroupData(1, 88, Colors.lightBlue),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _buildBarGroupData(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 30,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
        ),
      ],
    );
  }

  Widget _buildSystemUptimeCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            Icon(Icons.power_settings_new, color: Colors.white, size: 32),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '99.8% Uptime',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Last 30 days',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}