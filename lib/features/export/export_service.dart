import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/geo_entry.dart';
import '../../core/utils.dart';

class ExportService {
  static Future<void> exportToCsv(List<GeoEntry> entries) async {
    final List<List<dynamic>> rows = [];
    // Header
    rows.add([
      'ID',
      'Date',
      'Latitude',
      'Longitude',
      'Category',
      'Address',
      'Note',
      'Image Path',
    ]);

    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      rows.add([
        i + 1, // Use index as ID
        AppUtils.formatDate(e.timestamp),
        e.latitude,
        e.longitude,
        e.category,
        e.address,
        e.note ?? '',
        e.imagePath,
      ]);
    }

    String csvData = const ListToCsvConverter().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final path =
        "${directory.path}/geotag_export_${DateTime.now().millisecondsSinceEpoch}.csv";
    final file = File(path);
    await file.writeAsString(csvData);

    await Share.shareXFiles([XFile(path)], text: 'GeoTag Pro Export (CSV)');
  }

  static Future<void> exportToPdf(List<GeoEntry> entries) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(level: 0, child: pw.Text('GeoTag Pro Report')),
            pw.Padding(padding: const pw.EdgeInsets.all(10)),
            pw.TableHelper.fromTextArray(
              context: context,
              data: <List<String>>[
                <String>['Date', 'Category', 'Address', 'Lat/Long', 'Note'],
                ...entries.map(
                  (e) => [
                    AppUtils.formatDate(e.timestamp),
                    e.category,
                    e.address,
                    '${e.latitude.toStringAsFixed(5)}, ${e.longitude.toStringAsFixed(5)}',
                    e.note ?? '',
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final path =
        "${directory.path}/geotag_report_${DateTime.now().millisecondsSinceEpoch}.pdf";
    final file = File(path);
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(path)], text: 'GeoTag Pro Report (PDF)');
  }
}
