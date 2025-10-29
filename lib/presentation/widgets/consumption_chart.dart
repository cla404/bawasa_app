import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../domain/entities/meter_reading.dart';

class ConsumptionChart extends StatefulWidget {
  final List<MeterReading> meterReadings;

  const ConsumptionChart({super.key, required this.meterReadings});

  @override
  State<ConsumptionChart> createState() => _ConsumptionChartState();
}

class _ConsumptionChartState extends State<ConsumptionChart> {
  bool _showComparison = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildChart(),
          const SizedBox(height: 16),
          _buildComparisonToggle(),
          if (_showComparison) ...[
            const SizedBox(height: 16),
            _buildComparisonInfo(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Text(
      'Water Consumption',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A3A5C),
      ),
    );
  }

  Widget _buildChart() {
    final chartData = _getChartData();

    if (chartData.isEmpty || chartData.length < 2) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart, color: Colors.grey, size: 48),
              SizedBox(height: 8),
              Text(
                'Insufficient data for chart',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              SizedBox(height: 4),
              Text(
                'Need at least 2 meter readings',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: _getChartInterval() > 0
                ? _getChartInterval()
                : 1,
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
            },
            getDrawingVerticalLine: (value) {
              return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return _getBottomTitle(value, meta);
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: _getChartInterval(),
                getTitlesWidget: (double value, TitleMeta meta) {
                  return Text(
                    '${value.toInt()}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                },
                reservedSize: 42,
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.shade300),
          ),
          minX: 0,
          maxX: chartData.length.toDouble() - 1,
          minY: 0,
          maxY: _getMaxY(chartData),
          lineBarsData: [
            LineChartBarData(
              spots: chartData.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value);
              }).toList(),
              isCurved: true,
              gradient: const LinearGradient(
                colors: [Color(0xFF4A90E2), Color(0xFF7BB3F0)],
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: const Color(0xFF4A90E2),
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF4A90E2).withOpacity(0.3),
                    const Color(0xFF4A90E2).withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            if (_showComparison && _getComparisonData().isNotEmpty)
              LineChartBarData(
                spots: _getComparisonData().asMap().entries.map((entry) {
                  return FlSpot(entry.key.toDouble(), entry.value);
                }).toList(),
                isCurved: true,
                color: Colors.orange.withOpacity(0.7),
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 3,
                      color: Colors.orange,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonToggle() {
    return Row(
      children: [
        Switch(
          value: _showComparison,
          onChanged: (value) {
            setState(() {
              _showComparison = value;
            });
          },
          activeColor: const Color(0xFF4A90E2),
        ),
        const SizedBox(width: 8),
        const Text(
          'Compare with previous period',
          style: TextStyle(fontSize: 14, color: Color(0xFF1A3A5C)),
        ),
      ],
    );
  }

  Widget _buildComparisonInfo() {
    final currentData = _getChartData();
    final comparisonData = _getComparisonData();

    if (currentData.isEmpty || comparisonData.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentAvg = currentData.reduce((a, b) => a + b) / currentData.length;
    final comparisonAvg =
        comparisonData.reduce((a, b) => a + b) / comparisonData.length;
    final difference = currentAvg - comparisonAvg;
    final percentageChange = comparisonAvg > 0
        ? (difference / comparisonAvg * 100)
        : 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: percentageChange > 0
            ? Colors.red.withOpacity(0.1)
            : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: percentageChange > 0
              ? Colors.red.withOpacity(0.3)
              : Colors.green.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            percentageChange > 0 ? Icons.trending_up : Icons.trending_down,
            color: percentageChange > 0 ? Colors.red : Colors.green,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${percentageChange.abs().toStringAsFixed(1)}% ${percentageChange > 0 ? 'increase' : 'decrease'} compared to previous period',
              style: TextStyle(
                fontSize: 12,
                color: percentageChange > 0 ? Colors.red : Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getBottomTitle(double value, TitleMeta meta) {
    final chartData = _getChartData();
    if (value >= chartData.length) return const SizedBox.shrink();

    final date = _getDateForIndex(value.toInt());
    final label = _getMonthName(date.month);

    return Text(
      label,
      style: const TextStyle(
        color: Colors.grey,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    );
  }

  List<double> _getChartData() {
    final now = DateTime.now();
    return _getMonthlyData(now);
  }

  List<double> _getComparisonData() {
    final now = DateTime.now();
    return _getMonthlyData(DateTime(now.year - 1, now.month));
  }

  List<double> _getMonthlyData(DateTime startDate) {
    final data = <double>[];
    for (int i = 0; i < 6; i++) {
      final monthStart = DateTime(startDate.year, startDate.month + i, 1);
      final monthEnd = DateTime(startDate.year, startDate.month + i + 1, 0);
      final consumption = _getConsumptionForDateRange(monthStart, monthEnd);
      data.add(consumption);
    }
    return data;
  }

  double _getConsumptionForDateRange(DateTime startDate, DateTime endDate) {
    // Find meter readings within this date range
    final readings = widget.meterReadings.where((reading) {
      return reading.readingDate.isAfter(
            startDate.subtract(const Duration(days: 1)),
          ) &&
          reading.readingDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    if (readings.length < 2) return 0.0;

    // Sort by reading date
    readings.sort((a, b) => a.readingDate.compareTo(b.readingDate));

    // Calculate total consumption
    double totalConsumption = 0.0;
    for (int i = 1; i < readings.length; i++) {
      final consumption =
          readings[i].readingValue - readings[i - 1].readingValue;
      totalConsumption += consumption > 0 ? consumption : 0.0;
    }

    return totalConsumption;
  }

  DateTime _getDateForIndex(int index) {
    final now = DateTime.now();
    return DateTime(now.year, now.month - (5 - index));
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  double _getChartInterval() {
    final data = _getChartData();
    if (data.isEmpty) return 10.0;

    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final interval = (maxValue / 5).ceil().toDouble();
    return interval > 0 ? interval : 10.0;
  }

  double _getMaxY(List<double> data) {
    if (data.isEmpty) return 100.0;

    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final maxY = (maxValue * 1.2).ceil().toDouble();
    return maxY > 0 ? maxY : 100.0;
  }
}
