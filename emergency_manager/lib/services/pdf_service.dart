import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:convert';

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

  // PDF für Einsatzprotokolle generieren
  static Future<void> generateOperationProtocolPdf({
    required String alarmstichwort,
    required String adresse,
    required DateTime einsatzTime,
    required List<String> vehicleNames,
    required List<dynamic> protocol, // List<ProtocolEntry>
    required Map<String, dynamic> vehiclePersonnelAssignment,
    required List<dynamic> personnelList,
    required List<dynamic> atemschutzTrupps, // List<AtemschutzTrupp>
    required List<String> externalVehicles,
  }) async {
    final pdf = pw.Document();

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
                'Einsatzprotokoll',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 20),

            // Einsatzinformationen
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
                    'Einsatzinformationen',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Text(
                    'Alarmstichwort: $alarmstichwort',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'Adresse: $adresse',
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'Einsatzzeit: ${einsatzTime.day}.${einsatzTime.month}.${einsatzTime.year} ${einsatzTime.hour}:${einsatzTime.minute.toString().padLeft(2, '0')}',
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'Fahrzeuge: ${vehicleNames.join(", ")}',
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Eingesetzte Kräfte
            pw.Header(
              level: 1,
              child: pw.Text(
                'Eingesetzte Kräfte',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 12),
            _buildPersonnelAssignmentTable(vehiclePersonnelAssignment, personnelList, vehicleNames),
            pw.SizedBox(height: 24),

            // Externe Fahrzeuge
            if (externalVehicles.isNotEmpty) ...[
              pw.Header(
                level: 1,
                child: pw.Text(
                  'Externe Fahrzeuge',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 12),
              ...externalVehicles.map((vehicle) {
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Icon(
                        const pw.IconData(0xe7ef), // groups icon
                        size: 16,
                      ),
                      pw.SizedBox(width: 8),
                      pw.Text(
                        vehicle,
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              pw.SizedBox(height: 24),
            ],

            // Atemschutz-Trupps
            if (atemschutzTrupps.isNotEmpty) ...[
              pw.Header(
                level: 1,
                child: pw.Text(
                  'Atemschutz-Trupps',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 12),
              _buildAtemschutzTable(atemschutzTrupps, personnelList),
              pw.SizedBox(height: 24),
            ],

            // Protokolleinträge
            pw.Header(
              level: 1,
              child: pw.Text(
                'Protokolleinträge',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 12),
            if (protocol.isEmpty)
              pw.Text('Keine Protokolleinträge vorhanden')
            else
              ...protocol.map((entry) {
                final text = entry.text as String;
                final timestamp = entry.timestamp as DateTime;
                final imageBase64 = entry.imageBase64 as String?;
                final audioPath = entry.audioPath as String?;

                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 16),
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              text,
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Text(
                            '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '${timestamp.day}.${timestamp.month}.${timestamp.year}',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                      ),
                      if (imageBase64 != null) ...[
                        pw.SizedBox(height: 10),
                        pw.Container(
                          height: 200,
                          child: pw.Image(
                            pw.MemoryImage(
                              const Base64Decoder().convert(imageBase64),
                            ),
                            fit: pw.BoxFit.contain,
                          ),
                        ),
                      ],
                      if (audioPath != null) ...[
                        pw.SizedBox(height: 8),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(8),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.grey200,
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                          ),
                          child: pw.Row(
                            children: [
                              pw.Icon(
                                const pw.IconData(0xe3a1), // audio icon
                                size: 16,
                              ),
                              pw.SizedBox(width: 8),
                              pw.Text(
                                'Sprachnotiz: $audioPath',
                                style: const pw.TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
          ];
        },
      ),
    );

    // PDF drucken oder teilen
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static pw.Widget _buildPersonnelAssignmentTable(
    Map<String, dynamic> vehiclePersonnelAssignment,
    List<dynamic> personnelList,
    List<String> vehicleNames,
  ) {
    final List<List<String>> tableData = [
      ['Fahrzeug', 'Position', 'Name', 'Dienstgrad'],
    ];

    // Erstelle eine Map für Fahrzeug-IDs zu Namen
    final Map<String, String> vehicleIdToName = {};
    
    vehiclePersonnelAssignment.forEach((vehicleId, assignments) {
      // Versuche den Fahrzeugnamen zu finden (falls in vehicleNames vorhanden)
      final vehicleName = vehicleNames.isNotEmpty && vehicleNames.length > vehicleIdToName.length
          ? vehicleNames[vehicleIdToName.length]
          : vehicleId;
      vehicleIdToName[vehicleId] = vehicleName;
      
      if (assignments is Map<String, dynamic>) {
        assignments.forEach((personnelId, position) {
          // Finde die Person
          try {
            final person = personnelList.firstWhere(
              (p) => p.id == personnelId,
            );
            
            tableData.add([
              vehicleName,
              position as String,
              person.name as String,
              person.dienstgrad as String,
            ]);
          } catch (e) {
            // Person nicht gefunden, überspringe
          }
        });
      }
    });

    if (tableData.length == 1) {
      return pw.Text('Keine Kräfte zugewiesen');
    }

    return pw.Table.fromTextArray(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      cellStyle: const pw.TextStyle(fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellAlignment: pw.Alignment.centerLeft,
      data: tableData,
    );
  }

  static pw.Widget _buildAtemschutzTable(
    List<dynamic> atemschutzTrupps,
    List<dynamic> personnelList,
  ) {
    final List<List<String>> tableData = [
      ['Trupp', 'Person 1', 'Person 2', 'Zeit', 'Status', 'Niedrigster Druck'],
    ];

    for (var trupp in atemschutzTrupps) {
      // Finde die Personen
      dynamic person1;
      dynamic person2;
      
      try {
        person1 = personnelList.firstWhere(
          (p) => p.id == trupp.person1Id,
        );
      } catch (e) {
        person1 = null;
      }
      
      try {
        person2 = personnelList.firstWhere(
          (p) => p.id == trupp.person2Id,
        );
      } catch (e) {
        person2 = null;
      }

      // Berechne die Zeit
      String timeStr = '-';
      if (trupp.startTime != null) {
        final startTime = trupp.startTime as DateTime;
        final now = DateTime.now();
        final elapsed = now.difference(startTime);
        final pausedDuration = trupp.pausedDuration as Duration?;
        
        if (pausedDuration != null) {
          final activeTime = elapsed - pausedDuration;
          timeStr = '${activeTime.inMinutes}:${(activeTime.inSeconds % 60).toString().padLeft(2, '0')} min';
        } else {
          timeStr = '${elapsed.inMinutes}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')} min';
        }
      }

      // Status
      String status = 'Bereit';
      if (trupp.isCompleted == true) {
        status = 'Beendet';
      } else if (trupp.isActive == true) {
        status = 'Aktiv';
      }

      tableData.add([
        '${trupp.name} (${trupp.roundNumber}. DG)',
        person1?.name ?? trupp.person1Id ?? 'Unbekannt',
        person2?.name ?? trupp.person2Id ?? 'Unbekannt',
        timeStr,
        status,
        trupp.lowestPressure != null ? '${trupp.lowestPressure} bar' : '-',
      ]);
    }

    if (tableData.length == 1) {
      return pw.Text('Keine Atemschutz-Trupps eingesetzt');
    }

    return pw.Table.fromTextArray(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
      cellStyle: const pw.TextStyle(fontSize: 8),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellAlignment: pw.Alignment.centerLeft,
      data: tableData,
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1.5),
        5: const pw.FlexColumnWidth(1.5),
      },
    );
  }
}
