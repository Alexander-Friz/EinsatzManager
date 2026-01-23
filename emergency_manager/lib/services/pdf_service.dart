import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  static Future<void> generateStatisticsPdf({
    required int selectedYear,
    required Map<int, int> operationsPerMonth,
    required Map<String, int> operationTypeStats,
    required Map<String, int> dayNightStats,
    required Map<String, int> trainingStats,
    required List<MapEntry<String, int>> topPersonnel,
    required int totalPersonnel,
  }) async {
    final pdf = pw.Document();

    // Berechne Gesamteinsätze
    final totalOperations = operationsPerMonth.values.fold(0, (a, b) => a + b);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Titel
            pw.Header(
              level: 0,
              child: pw.Text(
                'Einsatzstatistik $selectedYear',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 20),

            // Zusammenfassung
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Zusammenfassung',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text('Gesamteinsätze: $totalOperations'),
                  pw.Text('Personal: $totalPersonnel Mitglieder'),
                  pw.Text(
                    'Erstellt am: ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}',
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Einsätze pro Monat
            pw.Header(
              level: 1,
              child: pw.Text(
                'Einsätze pro Monat',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            _buildMonthBarChart(operationsPerMonth),
            pw.SizedBox(height: 20),

            // Einsatzarten
            pw.Header(
              level: 1,
              child: pw.Text(
                'Einsatzarten',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            if (operationTypeStats.isNotEmpty)
              _buildTypeStatsChart(operationTypeStats)
            else
              pw.Text('Keine Einsätze vorhanden'),
            pw.SizedBox(height: 20),

            // Tag/Nacht-Statistik
            pw.Header(
              level: 1,
              child: pw.Text(
                'Einsatzzeiten (Tag/Nacht)',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            _buildDayNightChart(dayNightStats),
            pw.SizedBox(height: 20),

            // Ausbildungsstatistik
            pw.Header(
              level: 1,
              child: pw.Text(
                'Ausbildungsstatistik',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            if (trainingStats.isNotEmpty)
              _buildTrainingChart(trainingStats, totalPersonnel)
            else
              pw.Text('Keine Ausbildungsdaten vorhanden'),
            pw.SizedBox(height: 20),

            // Top 5 Personal
            pw.Header(
              level: 1,
              child: pw.Text(
                'Top 5 Personal (Einsätze)',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            if (topPersonnel.isNotEmpty && topPersonnel.first.value > 0)
              _buildTopPersonnelTable(topPersonnel)
            else
              pw.Text('Keine Einsatzdaten vorhanden'),
          ];
        },
      ),
    );

    // PDF drucken oder teilen
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static pw.Widget _buildMonthBarChart(Map<int, int> operationsPerMonth) {
    const monthNames = [
      'Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun',
      'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'
    ];

    final maxValue = operationsPerMonth.values.fold(0, (a, b) => a > b ? a : b);
    final maxHeight = 180.0;

    return pw.Container(
      height: 220,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
        children: operationsPerMonth.entries.map((entry) {
          final month = entry.key;
          final count = entry.value;
          final barHeight = maxValue > 0 ? (count / maxValue) * maxHeight : 0.0;

          return pw.Expanded(
            child: pw.Container(
              margin: const pw.EdgeInsets.symmetric(horizontal: 2),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  if (count > 0)
                    pw.Text(
                      count.toString(),
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  pw.SizedBox(height: 4),
                  pw.Container(
                    height: barHeight,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue700,
                      borderRadius: const pw.BorderRadius.vertical(
                        top: pw.Radius.circular(4),
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    monthNames[month - 1],
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  static pw.Widget _buildTypeStatsChart(Map<String, int> operationTypeStats) {
    final total = operationTypeStats.values.fold(0, (a, b) => a + b);
    final sortedEntries = operationTypeStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: sortedEntries.map((entry) {
        final percentage = (entry.value / total * 100).toStringAsFixed(1);
        
        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Row(
            children: [
              pw.SizedBox(
                width: 120,
                child: pw.Text(
                  entry.key,
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
              pw.Expanded(
                child: pw.Stack(
                  children: [
                    pw.Container(
                      height: 20,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey300,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                    ),
                    pw.LayoutBuilder(
                      builder: (context, constraints) => pw.Container(
                        width: constraints!.maxWidth * (entry.value / total),
                        height: 20,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.blue700,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 8),
              pw.SizedBox(
                width: 65,
                child: pw.Text(
                  '${entry.value} ($percentage%)',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  static pw.Widget _buildDayNightChart(Map<String, int> dayNightStats) {
    final total = dayNightStats.values.fold(0, (a, b) => a + b);
    
    return pw.Column(
      children: dayNightStats.entries.map((entry) {
        final percentage = total > 0 
            ? (entry.value / total * 100).toStringAsFixed(1) 
            : '0.0';
        
        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 16),
          child: pw.Row(
            children: [
              pw.SizedBox(
                width: 140,
                child: pw.Text(
                  entry.key,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Expanded(
                child: pw.Stack(
                  children: [
                    pw.Container(
                      height: 24,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey300,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                    ),
                    pw.LayoutBuilder(
                      builder: (context, constraints) => pw.Container(
                        width: constraints!.maxWidth * (total > 0 ? entry.value / total : 0),
                        height: 24,
                        decoration: pw.BoxDecoration(
                          color: entry.key.contains('Tag') 
                              ? PdfColors.orange 
                              : PdfColors.indigo700,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 8),
              pw.SizedBox(
                width: 75,
                child: pw.Text(
                  '${entry.value} ($percentage%)',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  static pw.Widget _buildTrainingChart(Map<String, int> trainingStats, int totalPersonnel) {
    final sortedEntries = trainingStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: sortedEntries.map((entry) {
        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 10),
          child: pw.Row(
            children: [
              pw.SizedBox(
                width: 120,
                child: pw.Text(
                  entry.key,
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
              pw.Expanded(
                child: pw.Stack(
                  children: [
                    pw.Container(
                      height: 18,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey300,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                    ),
                    pw.LayoutBuilder(
                      builder: (context, constraints) => pw.Container(
                        width: constraints!.maxWidth * (totalPersonnel > 0 ? entry.value / totalPersonnel : 0),
                        height: 18,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.blue700,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 8),
              pw.SizedBox(
                width: 30,
                child: pw.Text(
                  '${entry.value}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  static pw.Widget _buildTopPersonnelTable(List<MapEntry<String, int>> topPersonnel) {
    return pw.Table.fromTextArray(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellAlignment: pw.Alignment.centerLeft,
      data: [
        ['Rang', 'Name', 'Anzahl Einsätze'],
        ...topPersonnel.asMap().entries.map((entry) {
          if (entry.value.value == 0) return null;
          return [
            '${entry.key + 1}',
            entry.value.key,
            entry.value.value.toString(),
          ];
        }).whereType<List<String>>(),
      ],
    );
  }
}
