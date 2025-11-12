import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/dashboard_stats.dart';

class DepartmentChart extends StatelessWidget {
  final List<DepartmentCount> departmentData;

  const DepartmentChart({
    super.key,
    required this.departmentData,
  });

  @override
  Widget build(BuildContext context) {
    if (departmentData.isEmpty) {
      return const Center(
        child: Text('No department data available'),
      );
    }

    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.amber,
    ];

    return PieChart(
      PieChartData(
        sections: departmentData.asMap().entries.map((entry) {
          final index = entry.key;
          final dept = entry.value;
          final color = colors[index % colors.length];
          
          return PieChartSectionData(
            value: dept.count.toDouble(),
            title: '${dept.count}',
            color: color,
            radius: 60,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
      ),
    );
  }
}

class DepartmentChartLegend extends StatelessWidget {
  final List<DepartmentCount> departmentData;

  const DepartmentChartLegend({
    super.key,
    required this.departmentData,
  });

  @override
  Widget build(BuildContext context) {
    if (departmentData.isEmpty) {
      return const SizedBox.shrink();
    }

    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.amber,
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: departmentData.asMap().entries.map((entry) {
        final index = entry.key;
        final dept = entry.value;
        final color = colors[index % colors.length];

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${dept.department} (${dept.count})',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      }).toList(),
    );
  }
}

