import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/einsatz_neu.dart';

class EinsatzDetailScreen extends StatefulWidget {
  final Einsatz einsatz;

  const EinsatzDetailScreen({super.key, required this.einsatz});

  @override
  State<EinsatzDetailScreen> createState() => _EinsatzDetailScreenState();
}

class _EinsatzDetailScreenState extends State<EinsatzDetailScreen> {
  late TextEditingController _notizenController;
  late Einsatz _currentEinsatz;

  @override
  void initState() {
    super.initState();
    _currentEinsatz = widget.einsatz;
    _notizenController = TextEditingController(text: _currentEinsatz.notizen ?? '');
  }

  @override
  void dispose() {
    _notizenController.dispose();
    super.dispose();
  }

  Future<void> _exportEinsatzberichtPdf() async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'EINSATZBERICHT',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Divider(),
          pw.SizedBox(height: 10),

          // Einsatzinformationen
          pw.Text(
            'Einsatzinformationen',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text('Einsatzart:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Expanded(flex: 3, child: pw.Text(_currentEinsatz.einsatzart)),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text('Datum:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      DateFormat('dd.MM.yyyy').format(_currentEinsatz.datum),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text('Uhrzeit:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      '${_currentEinsatz.uhrzeit.hour.toString().padLeft(2, '0')}:${_currentEinsatz.uhrzeit.minute.toString().padLeft(2, '0')}',
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text('Adresse:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Expanded(flex: 3, child: pw.Text(_currentEinsatz.adresse)),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text('Koordinaten:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      '${_currentEinsatz.latitude?.toStringAsFixed(6) ?? 'N/A'}, ${_currentEinsatz.longitude?.toStringAsFixed(6) ?? 'N/A'}',
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.SizedBox(height: 10),

          // Fahrzeuge
          pw.Text(
            'Eingesetzte Fahrzeuge',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Fahrzeug', 'Position', 'Name'],
            data: _buildBesatzungTableData(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 11,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.green,
            ),
            cellHeight: 25,
            rowDecoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
            ),
            cellPadding: const pw.EdgeInsets.all(6),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.5),
              1: const pw.FlexColumnWidth(1.5),
              2: const pw.FlexColumnWidth(2),
            },
          ),
          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.SizedBox(height: 10),

          // Atemschutzlogbuch
          if (_currentEinsatz.atemschutzProtokoll != null &&
              _currentEinsatz.atemschutzProtokoll!.isNotEmpty)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Atemschutzlogbuch',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                pw.TableHelper.fromTextArray(
                  headers: ['Fahrzeug', 'Trupp', 'Mitglieder', 'Zeit', 'Ereignis', 'Druck'],
                  data: _buildAtemschutzLogData(),
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    fontSize: 9,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.blue,
                  ),
                  cellHeight: 25,
                  rowDecoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                  ),
                  cellPadding: const pw.EdgeInsets.all(4),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1.2),
                    1: const pw.FlexColumnWidth(1.2),
                    2: const pw.FlexColumnWidth(1.5),
                    3: const pw.FlexColumnWidth(1),
                    4: const pw.FlexColumnWidth(1.1),
                    5: const pw.FlexColumnWidth(0.8),
                  },
                ),
                pw.SizedBox(height: 16),
                pw.Divider(),
                pw.SizedBox(height: 10),
              ],
            ),

          // Notizen
          pw.Text(
            'Notizen',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            _currentEinsatz.notizen ?? '(keine Notizen)',
            style: const pw.TextStyle(),
          ),
          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.SizedBox(height: 10),

          // Zeiten
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Erstellt:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(dateFormat.format(_currentEinsatz.erstelltAm)),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Beendet:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                      _currentEinsatz.beendetAm != null
                          ? dateFormat.format(_currentEinsatz.beendetAm!)
                          : '(nicht beendet)',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  List<List<String>> _buildBesatzungTableData() {
    final tableData = <List<String>>[];

    for (var fahrzeug in _currentEinsatz.fahrzeuge) {
      for (var besatzung in fahrzeug.besatzung) {
        tableData.add([
          fahrzeug.name,
          besatzung.position.toString().split('.').last,
          besatzung.personName,
        ]);
      }
    }

    return tableData;
  }

  List<List<String>> _buildAtemschutzLogData() {
    final timeFormat = DateFormat('HH:mm:ss');
    final logData = <List<String>>[];

    if (_currentEinsatz.atemschutzProtokoll == null ||
        _currentEinsatz.atemschutzProtokoll!.isEmpty) {
      return logData;
    }

    // Gruppiere Einträge nach Fahrzeug und Trupp
    final grouped = <String, List<AtemschutzEintrag>>{};
    for (var eintrag in _currentEinsatz.atemschutzProtokoll!) {
      final key = '${eintrag.fahrzeugId}_${eintrag.truppName}';
      grouped.putIfAbsent(key, () => []).add(eintrag);
    }

    // Sortiere und konvertiere zu PDF-Tabellendaten
    for (var entry in grouped.entries) {
      final eintraege = entry.value;
      if (eintraege.isEmpty) continue;

      // Finde die Truppmitglieder
      final fahrzeugId = eintraege.first.fahrzeugId;
      final truppName = eintraege.first.truppName;
      final fahrzeug = _currentEinsatz.fahrzeuge
          .firstWhere((f) => f.id == fahrzeugId, orElse: () => _currentEinsatz.fahrzeuge.first);

      String mitglieder = '';
      if (truppName.contains('Angriffstrupp')) {
        final fuehrer = fahrzeug.besatzung.firstWhere(
          (b) => b.position == TruppPosition.angriffstruppfuehrer,
          orElse: () => Besatzung(position: TruppPosition.angriffstruppfuehrer, personName: '-'),
        );
        final mann = fahrzeug.besatzung.firstWhere(
          (b) => b.position == TruppPosition.angriffstruppmann,
          orElse: () => Besatzung(position: TruppPosition.angriffstruppmann, personName: '-'),
        );
        mitglieder = '${fuehrer.personName}, ${mann.personName}';
      } else if (truppName.contains('Wassertrupp')) {
        final fuehrer = fahrzeug.besatzung.firstWhere(
          (b) => b.position == TruppPosition.wassertrupp_fuehrer,
          orElse: () => Besatzung(position: TruppPosition.wassertrupp_fuehrer, personName: '-'),
        );
        final mann = fahrzeug.besatzung.firstWhere(
          (b) => b.position == TruppPosition.wassertrupp_mann,
          orElse: () => Besatzung(position: TruppPosition.wassertrupp_mann, personName: '-'),
        );
        mitglieder = '${fuehrer.personName}, ${mann.personName}';
      }

      // Erstelle einen Eintrag pro Event
      for (var eintrag in eintraege) {
        String ereignisText = '';
        if (eintrag.ereignis == 'START') {
          ereignisText = 'START';
        } else if (eintrag.ereignis == 'STOP') {
          ereignisText = 'STOP';
        } else if (eintrag.ereignis == 'DRUCKABFRAGE') {
          ereignisText = '10-MIN';
        } else if (eintrag.ereignis == '20MIN_ALARM') {
          ereignisText = '20-MIN';
        } else if (eintrag.ereignis == '10MIN_ALARM') {
          ereignisText = 'ALARM';
        }

        logData.add([
          fahrzeug.name,
          truppName.replaceAll('Angriffstrupp (${fahrzeug.name})', 'Angriffstrupp')
              .replaceAll('Wassertrupp (${fahrzeug.name})', 'Wassertrupp'),
          mitglieder,
          timeFormat.format(eintrag.zeitpunkt),
          ereignisText,
          eintrag.druck != null ? '${eintrag.druck} bar' : '-',
        ]);
      }
    }

    return logData;
  }

  Future<void> _exportAnwesenheitslistePdf() async {
    final pdf = pw.Document();

    // Sammle alle Besatzungen mit AGT-Status basierend auf Protokoll
    List<Map<String, dynamic>> allPersonnel = [];
    for (var fahrzeug in _currentEinsatz.fahrzeuge) {
      for (var besatzung in fahrzeug.besatzung) {
        // Bestimme zu welchem Trupp die Person gehört
        String? personTrupp;
        if (besatzung.position == TruppPosition.angriffstruppfuehrer ||
            besatzung.position == TruppPosition.angriffstruppmann) {
          personTrupp = 'Angriffstrupp';
        } else if (besatzung.position == TruppPosition.wassertrupp_fuehrer ||
            besatzung.position == TruppPosition.wassertrupp_mann) {
          personTrupp = 'Wassertrupp';
        }

        // Prüfe ob dieser spezifische Trupp im Protokoll mit START eingetragen ist
        final hasAgtEntry = personTrupp != null &&
            (_currentEinsatz.atemschutzProtokoll?.any((eintrag) =>
                  eintrag.fahrzeugId == fahrzeug.id && 
                  eintrag.ereignis == 'START' &&
                  eintrag.truppName.contains(personTrupp!)) ??
                false);

        allPersonnel.add({
          'fahrzeug': fahrzeug.name,
          'position': besatzung.position.toString().split('.').last,
          'name': besatzung.personName,
          'agt': hasAgtEntry ? 'JA' : 'NEIN',
        });
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'ANWESENHEITSLISTE',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Einsatz: ${_currentEinsatz.einsatzart}',
            style: pw.TextStyle(fontSize: 12),
          ),
          pw.Text(
            'Datum: ${DateFormat('dd.MM.yyyy').format(_currentEinsatz.datum)}',
            style: pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: ['Fahrzeug', 'Position', 'Name', 'A'],
            data: allPersonnel
                .map((p) => [
                      p['fahrzeug'],
                      p['position'],
                      p['name'],
                      p['agt'],
                    ])
                .toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 11,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.red,
            ),
            cellHeight: 30,
            rowDecoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
            ),
            cellPadding: const pw.EdgeInsets.all(6),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Einsatzdetails'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header mit Einsatzart
            Container(
              width: double.infinity,
              color: Colors.red[900],
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentEinsatz.einsatzart,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'vom ${dateFormat.format(_currentEinsatz.erstelltAm)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Grundinformationen
                  _buildInfoCard(),
                  const SizedBox(height: 20),

                  // Fahrzeuge
                  _buildFahrzeugeCard(),
                  const SizedBox(height: 20),

                  // Notizen
                  _buildNotizenCard(),
                  const SizedBox(height: 20),

                  // Export Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _exportEinsatzberichtPdf,
                          icon: const Icon(Icons.description),
                          label: const Text('Einsatzbericht'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[900],
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _exportAnwesenheitslistePdf,
                          icon: const Icon(Icons.people),
                          label: const Text('Anwesenheit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[900],
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Einsatzinformationen',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Einsatzart:', _currentEinsatz.einsatzart),
            _buildInfoRow(
              'Datum:',
              DateFormat('dd.MM.yyyy').format(_currentEinsatz.datum),
            ),
            _buildInfoRow(
              'Uhrzeit:',
              '${_currentEinsatz.uhrzeit.hour.toString().padLeft(2, '0')}:${_currentEinsatz.uhrzeit.minute.toString().padLeft(2, '0')}',
            ),
            _buildInfoRow('Adresse:', _currentEinsatz.adresse),
            _buildInfoRow(
              'Koordinaten:',
              '${_currentEinsatz.latitude?.toStringAsFixed(6) ?? 'N/A'}, ${_currentEinsatz.longitude?.toStringAsFixed(6) ?? 'N/A'}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFahrzeugeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Eingesetzte Fahrzeuge',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _currentEinsatz.fahrzeuge.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final fahrzeug = _currentEinsatz.fahrzeuge[index];
                final hasAgt = fahrzeug.atemschutzEinsatz &&
                    _currentEinsatz.atemschutzZeiten != null &&
                    _currentEinsatz.atemschutzZeiten!.containsKey(fahrzeug.id);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          fahrzeug.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: fahrzeug.atemschutzEinsatz
                                ? Colors.orange
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            hasAgt ? 'A (Aktiv)' : 'A',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: fahrzeug.atemschutzEinsatz
                                  ? Colors.white
                                  : Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: fahrzeug.besatzung
                          .map(
                            (b) => Chip(
                              label: Text(
                                '${b.position.toString().split('.').last}: ${b.personName}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotizenCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notizen',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notizenController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Notizen hinzufügen...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                _currentEinsatz = _currentEinsatz.copyWith(notizen: value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
