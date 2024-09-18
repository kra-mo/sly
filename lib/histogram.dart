import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:fl_chart/fl_chart.dart';

import 'image.dart';

LineChart _buildHistogram(Uint8List imagdeData) {
  final List<List<FlSpot>> spots = [
    List.generate(16, (index) => FlSpot(index.toDouble(), 0)),
    List.generate(16, (index) => FlSpot(index.toDouble(), 0)),
    List.generate(16, (index) => FlSpot(index.toDouble(), 0))
  ];

  int channel = 0;
  for (int pixel in imagdeData) {
    int i = pixel >> 4;
    if (i == 0 && pixel != 0) {
      i = 1;
    } else if (i == 15 && pixel != 255) {
      i = 14;
    }

    spots[channel][i] = FlSpot((i).toDouble(), spots[channel][i].y + 1);
    channel = (channel + 1) % 3;
  }

  final List<List<Color>> colors = [
    [Colors.red.shade900, Colors.red],
    [Colors.green.shade900, Colors.green],
    [Colors.blue.shade900, Colors.blue],
  ];

  final List<LineChartBarData> lineBarsData = [];

  for (int i = 0; i < 3; i++) {
    lineBarsData.add(
      LineChartBarData(
        spots: spots[i],
        isCurved: true,
        gradient: LinearGradient(
          colors: [colors[i][0], colors[i][1]],
        ),
        barWidth: 2,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            colors: [colors[i][0], colors[i][1]]
                .map((color) => color.withOpacity(1 / 3))
                .toList(),
          ),
        ),
      ),
    );
  }

  return LineChart(
    LineChartData(
      titlesData: const FlTitlesData(show: false),
      lineTouchData: const LineTouchData(enabled: false),
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      lineBarsData: lineBarsData,
    ),
  );
}

Future<LineChart> getHistogram(SlyImage image) async {
  return await compute(_buildHistogram, await image.getHistogramData());
}
