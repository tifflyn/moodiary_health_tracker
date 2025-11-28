import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/emotionlog.dart';

typedef EmotionColorGetter = Color Function(String emotion);
typedef EmotionIconGetter = IconData Function(String emotion);

/// -----------------------------
/// BAR CHART WIDGET
/// -----------------------------
Widget buildBarChart({
  required List<DateTime> weekDates,
  required Map<String, List<EmotionLog>> groupedLogs,
  required EmotionColorGetter getEmotionColor,
  required EmotionIconGetter getEmotionIcon,
}) {
  return SizedBox(
    key: const ValueKey('barChart'),
    height: 200,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: weekDates.map((date) {
        final dateKey = DateFormat('yyyy-MM-dd').format(date);
        final logsForDay = groupedLogs[dateKey] ?? [];
        final isToday =
            dateKey == DateFormat('yyyy-MM-dd').format(DateTime.now());

        String? dominantEmotion;
        if (logsForDay.isNotEmpty) {
          final emotionCounts = <String, int>{};
          for (var log in logsForDay) {
            emotionCounts[log.emotion] =
                (emotionCounts[log.emotion] ?? 0) + 1;
          }
          dominantEmotion = emotionCounts.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;
        }

        return Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                DateFormat('E').format(date),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color: isToday ? Colors.purple : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                date.day.toString(),
                style: TextStyle(
                  fontSize: 10,
                  color: isToday ? Colors.purple : Colors.grey[500],
                ),
              ),
              const SizedBox(height: 8),
              if (dominantEmotion != null)
                Container(
                  height: 80 + (logsForDay.length * 10.0),
                  width: 40,
                  decoration: BoxDecoration(
                    color: getEmotionColor(dominantEmotion).withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        getEmotionIcon(dominantEmotion),
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${logsForDay.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: Icon(Icons.add, color: Colors.grey[400], size: 20),
                ),
            ],
          ),
        );
      }).toList(),
    ),
  );
}

/// -----------------------------
/// LINE CHART WIDGET
/// -----------------------------
Widget buildLineChart({
  required List<DateTime> weekDates,
  required List<FlSpot> spots,
  required bool hasData,
}) {
  return SizedBox(
    key: const ValueKey('lineChart'),
    height: 200,
    child: !hasData
        ? Center(
            child: Text(
              'Log emotions to see trend',
              style: TextStyle(color: Colors.grey[500]),
            ),
          )
        : Padding(
            padding: const EdgeInsets.only(right: 20, top: 10),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: Colors.grey[300]!, strokeWidth: 1);
                  },
                ),
                titlesData: FlTitlesData(
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < weekDates.length) {
                          final date = weekDates[value.toInt()];
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              DateFormat('E').format(date),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 35,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                    left: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                ),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 5,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.purple,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.purple.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
  );
}
