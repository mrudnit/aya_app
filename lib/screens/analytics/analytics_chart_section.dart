import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsChartsSection extends StatelessWidget {
  final Map<String, dynamic> sleep, nutrition, activity, weight;

  const AnalyticsChartsSection({
    super.key,
    required this.sleep,
    required this.nutrition,
    required this.activity,
    required this.weight,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ChartCard(
          title: 'Sleep (hours)',
          icon: Icons.bedtime_outlined,
          status: sleep['status'] as String? ?? 'insufficient',
          insufficientMsg: sleep['message'] as String?,
          chartData: (sleep['chart_data'] as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>(),
          valueKey: 'hours',
          color: const Color(0xFF4FC3F7),
          targetLine: (sleep['target_hours'] as num?)?.toDouble(),
        ),
        const SizedBox(height: 12),
        _ChartCard(
          title: 'Nutrition (kcal)',
          icon: Icons.restaurant_outlined,
          status: nutrition['status'] as String? ?? 'insufficient',
          insufficientMsg: nutrition['message'] as String?,
          chartData: (nutrition['chart_data'] as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>(),
          valueKey: 'kcal',
          color: const Color(0xFFFFA726),
          targetLine: (nutrition['target_kcal'] as num?)?.toDouble(),
        ),
        const SizedBox(height: 12),
        _ChartCard(
          title: 'Activity (min)',
          icon: Icons.directions_run_outlined,
          status: activity['status'] as String? ?? 'insufficient',
          insufficientMsg: activity['message'] as String?,
          chartData: (activity['chart_data'] as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>(),
          valueKey: 'duration_min',
          color: const Color(0xFF66BB6A),
        ),
        const SizedBox(height: 12),
        _ChartCard(
          title: 'Weight (kg)',
          icon: Icons.monitor_weight_outlined,
          status: weight['status'] as String? ?? 'insufficient',
          insufficientMsg: weight['message'] as String?,
          chartData: (weight['chart_data'] as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>(),
          valueKey: 'weight_kg',
          color: const Color(0xFFAB47BC),
        ),
      ],
    );
  }
}

// Chart card shell
class _ChartCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String status;
  final String? insufficientMsg;
  final List<Map<String, dynamic>> chartData;
  final String valueKey;
  final Color color;
  final double? targetLine;

  const _ChartCard({
    required this.title,
    required this.icon,
    required this.status,
    this.insufficientMsg,
    required this.chartData,
    required this.valueKey,
    required this.color,
    this.targetLine,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: dark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(title,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700, fontSize: 14)),
          ]),
          const SizedBox(height: 12),
          if (status != 'ok')
            _InsufficientBanner(message: insufficientMsg)
          else if (chartData.isEmpty)
            const _InsufficientBanner(message: 'No chart data available.')
          else
            SizedBox(
              height: 130,
              child: _LineChart(
                data: chartData,
                valueKey: valueKey,
                color: color,
                targetLine: targetLine,
              ),
            ),
        ],
      ),
    );
  }
}

// Line chart
class _LineChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String valueKey;
  final Color color;
  final double? targetLine;

  const _LineChart({
    required this.data,
    required this.valueKey,
    required this.color,
    this.targetLine,
  });

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (int i = 0; i < data.length; i++) {
      final val = (data[i][valueKey] as num?)?.toDouble();
      if (val != null) spots.add(FlSpot(i.toDouble(), val));
    }

    if (spots.isEmpty) {
      return const _InsufficientBanner(message: 'No data points.');
    }

    final minY    = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY    = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) * 0.15 + 0.5;

    return LineChart(
      LineChartData(
        minY: minY - padding,
        maxY: (targetLine != null && targetLine! > maxY)
            ? targetLine! + padding
            : maxY + padding,
        gridData: FlGridData(
          drawHorizontalLine: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: Colors.grey.withOpacity(0.15), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (val, _) => Text(
                val.toStringAsFixed(0),
                style: GoogleFonts.inter(
                    fontSize: 9, color: Colors.grey.shade500),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (data.length / 4).ceilToDouble().clamp(1, 99),
              getTitlesWidget: (val, _) {
                final idx = val.toInt();
                if (idx < 0 || idx >= data.length) return const SizedBox();
                final parts = (data[idx]['date'] as String? ?? '').split('-');
                if (parts.length < 3) return const SizedBox();
                return Text('${parts[2]}/${parts[1]}',
                    style: GoogleFonts.inter(
                        fontSize: 9, color: Colors.grey.shade500));
              },
            ),
          ),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        extraLinesData: targetLine != null
            ? ExtraLinesData(horizontalLines: [
          HorizontalLine(
            y: targetLine!,
            color: Colors.grey.withOpacity(0.4),
            strokeWidth: 1.2,
            dashArray: [4, 4],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.topRight,
              style: GoogleFonts.inter(
                  fontSize: 9, color: Colors.grey.shade500),
              labelResolver: (_) => 'target',
            ),
          ),
        ])
            : null,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: color,
            barWidth: 2.5,
            dotData: FlDotData(
              show: data.length <= 10,
              getDotPainter: (_, __, ___, ____) =>
                  FlDotCirclePainter(radius: 3, color: color, strokeWidth: 0),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: color.withOpacity(0.08),
            ),
          ),
        ],
      ),
    );
  }
}

// Shared tiny widget
class _InsufficientBanner extends StatelessWidget {
  final String? message;
  const _InsufficientBanner({this.message});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Icon(Icons.hourglass_empty_outlined, size: 14, color: Colors.grey),
      const SizedBox(width: 6),
      Expanded(
        child: Text(message ?? 'Not enough data yet.',
            style: GoogleFonts.inter(
                fontSize: 12, color: Colors.grey.shade500)),
      ),
    ]);
  }
}
