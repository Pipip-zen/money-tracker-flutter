import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/transaction_entity.dart';

class ExportService {
  static final _dateFormat = DateFormat('dd/MM/yyyy', 'id_ID');
  static final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
  static final _monthFormat = DateFormat('MMMM yyyy', 'id_ID');

  // ─── CSV ───────────────────────────────────────────────────────────────────

  static Future<File> exportToCSV(List<TransactionEntity> transactions) async {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('Tanggal,Tipe,Kategori,Jumlah,Catatan');

    for (final tx in transactions) {
      final note = (tx.note ?? '').replaceAll('"', '""');
      final catName = tx.categoryName.replaceAll('"', '""');
      buffer.writeln(
        '${_dateFormat.format(tx.date)},'
        '${tx.type == 'income' ? 'Pemasukan' : 'Pengeluaran'},'
        '"$catName",'
        '${tx.amount},'
        '"$note"',
      );
    }

    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'transactions_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(buffer.toString());

    await _share(file, 'text/csv');
    return file;
  }

  // ─── PDF ───────────────────────────────────────────────────────────────────

  static Future<File> exportToPDF(
    List<TransactionEntity> transactions,
    int month,
    int year,
  ) async {
    final monthLabel = _monthFormat.format(DateTime(year, month));
    final doc = pw.Document();

    final double totalIncome = transactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
    final double totalExpense = transactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);
    final double netBalance = totalIncome - totalExpense;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Money Tracker',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Laporan Bulan $monthLabel',
              style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
            ),
            pw.Divider(thickness: 1, color: PdfColors.grey400),
            pw.SizedBox(height: 8),
          ],
        ),
        build: (context) => [
          // Summary table
          pw.Text(
            'Ringkasan',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              _pdfHeaderRow(['Keterangan', 'Jumlah']),
              _pdfDataRow(['Total Pemasukan', _currency.format(totalIncome)]),
              _pdfDataRow(['Total Pengeluaran', _currency.format(totalExpense)]),
              _pdfDataRow(['Saldo Bersih', _currency.format(netBalance)]),
            ],
          ),
          pw.SizedBox(height: 24),

          // Transaction table
          pw.Text(
            'Daftar Transaksi',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(2.5),
              3: const pw.FlexColumnWidth(2.5),
              4: const pw.FlexColumnWidth(3),
            },
            children: [
              _pdfHeaderRow(['Tanggal', 'Tipe', 'Kategori', 'Jumlah', 'Catatan']),
              ...transactions.map((tx) => _pdfDataRow([
                _dateFormat.format(tx.date),
                tx.type == 'income' ? 'Pemasukan' : 'Pengeluaran',
                tx.categoryName,
                _currency.format(tx.amount),
                tx.note ?? '-',
              ])),
            ],
          ),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'laporan_${month}_${year}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await doc.save());

    await _share(file, 'application/pdf');
    return file;
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  static pw.TableRow _pdfHeaderRow(List<String> cells) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.green800),
      children: cells.map((cell) => pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(
          cell,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
        ),
      )).toList(),
    );
  }

  static pw.TableRow _pdfDataRow(List<String> cells) {
    return pw.TableRow(
      children: cells.map((cell) => pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(cell, style: const pw.TextStyle(fontSize: 9)),
      )).toList(),
    );
  }

  static Future<void> _share(File file, String mimeType) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: mimeType)],
        text: 'Ekspor dari Money Tracker',
      ),
    );
  }
}
