import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:salespulse/models/chart_model.dart';
import 'package:salespulse/models/stats_year_model.dart';

class LineChartWidget extends StatelessWidget {
  final List<StatsYearModel> data;
  const LineChartWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {   
    //convertir data au format modelLinedata
    List<ModelLineData> modelLineData = data
        .map((e) => ModelLineData(
            x: double.parse(e.month.toString()), y: e.totalVentes?.toDouble() ?? 0.0))
        .toList();

        double maxY = modelLineData.map((e) => e.y).fold(0, (prev, el) => el > prev ? el : prev);
        maxY = maxY + maxY * 0.60; // ajoute une marge de 20% en haut

    return Padding(
      padding: const EdgeInsets.all(5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Graphique des ventes
          AspectRatio(
            aspectRatio: 3.1,
            child: Container(
              padding: const EdgeInsets.only(right: 80),
              decoration: BoxDecoration(
                color: const Color(0xff001c30),
                boxShadow: [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: const Color.fromARGB(255, 29, 28, 28).withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
                borderRadius: BorderRadius.circular(10),
              ),
              child: LineChart(
                  duration: const Duration(milliseconds: 20),
             curve: Curves.easeOut,
                LineChartData(
                  minX: 0,
                  maxX: 12,
                  minY: 0,
                  maxY:maxY,
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: true),
                  titlesData: myLineTitlesData(),
                  lineBarsData: [
                    LineChartBarData(
                      spots: modelLineData
                          .asMap()
                          .entries
                          .map((item) => FlSpot(item.value.x, item.value.y))
                          .toList(),
                      isCurved: true,
                      gradient: const LinearGradient(
                        colors: [Colors.redAccent, Colors.orangeAccent],
                      ),
                      dotData: const FlDotData(show: true),
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            // ignore: deprecated_member_use
                            Colors.redAccent.withOpacity(.4),
                            // ignore: deprecated_member_use
                            Colors.orangeAccent.withOpacity(.4),
                          ],
                        ),
                        applyCutOffY: true,
                      ),
                      preventCurveOverShooting: true,
                      preventCurveOvershootingThreshold: 5.9,
                    ),
                  ],
                  // Affichage des labels sur chaque point
                  lineTouchData: LineTouchData(
                    enabled: true,
                    getTouchedSpotIndicator:
                        (LineChartBarData barData, List<int> indicators) {
                      return indicators.map((int index) {
                        // final spot = barData.spots[index];
                        return const TouchedSpotIndicatorData(
                          FlLine(color: Colors.transparent, strokeWidth: 0),
                          FlDotData(show: true),
                        );
                      }).toList();
                    },
                    touchTooltipData: LineTouchTooltipData(
                      // tooltipBgColor: Colors.blueAccent,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((touchedSpot) {
                          // final month = data[touchedSpot.spotIndex].month;
                          final year = data[touchedSpot.spotIndex].year;
                          final totalVentes = data[touchedSpot.spotIndex].totalVentes;
                          final nombreVentes = data[touchedSpot.spotIndex].nombreVentes;
                          return LineTooltipItem(
                            'Année: $year\n'
                            'Nombre de produits: $nombreVentes\n'
                            'Total : $totalVentes XOF',
                            const TextStyle(color: Color.fromRGBO(255, 167, 51, 1)),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  FlTitlesData myLineTitlesData() {
    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 50,
          getTitlesWidget: namedYear,
        ),
      ),
    );
  }

  Widget namedYear(double value, TitleMeta meta) {
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 16,
      child: _textBuild(value.toInt()),
    );
  }

  Widget _textBuild(int value) {
    switch (value) {
      case 1:
        return Text(
          "Jan",
          style: GoogleFonts.roboto(
              fontSize: 14, fontWeight: FontWeight.w300, color: Colors.white),
        );
      case 2:
        return Text(
          "Fev",
          style: GoogleFonts.roboto(
              fontSize: 14, fontWeight: FontWeight.w300, color: Colors.white),
        );
      case 3:
        return Text(
          "Mar",
          style: GoogleFonts.roboto(
              fontSize: 14, fontWeight: FontWeight.w300, color: Colors.white),
        );
      case 4:
        return Text(
          "Avr",
          style: GoogleFonts.roboto(
              fontSize: 14, fontWeight: FontWeight.w300, color: Colors.white),
        );
      case 5:
        return Text(
          "Mai",
          style: GoogleFonts.roboto(
              fontSize: 14, fontWeight: FontWeight.w300, color: Colors.white),
        );
      case 6:
        return Text(
          "Juin",
          style: GoogleFonts.roboto(
              fontSize: 14, fontWeight: FontWeight.w300, color: Colors.white),
        );
      case 7:
        return Text(
          "Juil",
          style: GoogleFonts.roboto(
              fontSize: 14, fontWeight: FontWeight.w300, color: Colors.white),
        );
      case 8:
        return Text(
          "Aou",
          style: GoogleFonts.roboto(
              fontSize: 14, fontWeight: FontWeight.w300, color: Colors.white),
        );
      case 9:
        return Text(
          "Sep",
          style: GoogleFonts.roboto(
              fontSize: 14, fontWeight: FontWeight.w300, color: Colors.white),
        );
      case 10:
        return Text(
          "Oct",
          style: GoogleFonts.roboto(
              fontSize: 14, fontWeight: FontWeight.w300, color: Colors.white),
        );
      case 11:
        return Text(
          "Nov",
          style: GoogleFonts.roboto(
              fontSize: 14, fontWeight: FontWeight.w300, color: Colors.white),
        );
      case 12:
        return Text(
          "Dec",
          style: GoogleFonts.roboto(
              fontSize: 14, fontWeight: FontWeight.w300, color: Colors.white),
        );
      default:
        return const Text("");
    }
  }
}

