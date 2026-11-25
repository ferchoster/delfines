import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class ReportExporter {
  static final _money = NumberFormat.currency(locale: 'es_GT', symbol: 'Q', decimalDigits: 2);
  static final _date = DateFormat('dd/MM/yyyy');

  static double _number(Object? value) => (value as num? ?? 0).toDouble();
  static String _q(Object? value) => _money.format(_number(value));
  static String _text(Object? value, [String fallback = '']) => value?.toString() ?? fallback;

  static Future<File> createPdf(Map<String, Object?> report) async {
    final pdf = pw.Document();
    final totals = report['totals'] as Map<String, Object?>;
    final purchases = report['purchases'] as Map<String, Object?>;
    final from = DateTime.parse(_text(report['from']));
    final to = DateTime.parse(_text(report['to']));
    final daily = (report['daily'] as List).cast<Map<String, Object?>>();
    final services = (report['services'] as List).cast<Map<String, Object?>>();
    final payments = (report['payments'] as List).cast<Map<String, Object?>>();
    final top = (report['top_items'] as List).cast<Map<String, Object?>>();
    final expenses = (report['expense_categories'] as List).cast<Map<String, Object?>>();

    pw.Widget heading(String value) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 14, bottom: 6),
      child: pw.Text(value, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
    );
    pw.Widget table(List<String> headers, List<List<String>> rows) => pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
      headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xff123047)),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      border: pw.TableBorder.all(color: PdfColors.grey300, width: .5),
    );

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(30),
      build: (context) => [
        pw.Text('CEVICHERÍA LOS DELFINES', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xff123047))),
        pw.SizedBox(height: 4),
        pw.Text('Reporte del negocio · ${_date.format(from)} al ${_date.format(to)}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        heading('Resumen general'),
        table(['Indicador', 'Resultado'], [
          ['Ventas totales', _q(totals['revenue'])],
          ['Número de ventas', _text(totals['sales_count'], '0')],
          ['Costo estimado de recetas', _q(totals['cost'])],
          ['Utilidad bruta estimada', _q(totals['gross_profit'])],
          ['Ticket promedio', _q(totals['average_ticket'])],
          ['Salidas de caja', _q(report['cash_outflows'])],
          ['Gastos registrados', _q(report['registered_expenses'])],
          ['Compras de ingredientes', _q(purchases['total'])],
        ]),
        heading('Ventas por día'),
        table(['Fecha', 'Ventas', 'Total'], daily.map((r) => [
          _date.format(DateTime.parse(_text(r['day']))), _text(r['count'], '0'), _q(r['total']),
        ]).toList()),
        heading('Ventas por tipo de servicio'),
        table(['Servicio', 'Cantidad', 'Total'], services.map((r) => [_text(r['service']), _text(r['count'], '0'), _q(r['total'])]).toList()),
        heading('Métodos de pago'),
        table(['Método', 'Ventas', 'Total'], payments.map((r) => [_text(r['method']), _text(r['count'], '0'), _q(r['total'])]).toList()),
        heading('Platos más vendidos'),
        table(['Plato', 'Cantidad', 'Total'], top.map((r) => [_text(r['name']), _text(r['quantity'], '0'), _q(r['total'])]).toList()),
        heading('Gastos por categoría'),
        table(['Categoría', 'Total'], expenses.map((r) => [_text(r['categoria'], 'Sin categoría'), _q(r['total'])]).toList()),
        pw.SizedBox(height: 12),
        pw.Text('Nota: la utilidad es bruta estimada. No descuenta gastos operativos, impuestos ni costos no registrados.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
        pw.Text('Generado desde la base local de Cevichería Los Delfines.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
      ],
    ));

    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, 'reporte_los_delfines_${report['from']}_${report['to']}.pdf'));
    await file.writeAsBytes(await pdf.save(), flush: true);
    return file;
  }

  static Future<File> createExcel(Map<String, Object?> report) async {
    final book = Excel.createExcel();
    final summary = book['Resumen'];
    final totals = report['totals'] as Map<String, Object?>;
    final purchases = report['purchases'] as Map<String, Object?>;
    final from = _text(report['from']);
    final to = _text(report['to']);

    void addRows(String sheetName, List<List<CellValue?>> rows) {
      final sheet = book[sheetName];
      for (final row in rows) {
        sheet.appendRow(row);
      }
      if (rows.isNotEmpty) {
        sheet.setColumnWidth(0, 28);
        for (var i = 1; i < rows.first.length; i++) {
          sheet.setColumnWidth(i, 18);
        }
      }
    }

    summary.appendRow([TextCellValue('CEVICHERÍA LOS DELFINES')]);
    summary.appendRow([TextCellValue('Reporte del negocio')]);
    summary.appendRow([TextCellValue('Desde'), TextCellValue(from), TextCellValue('Hasta'), TextCellValue(to)]);
    summary.appendRow([TextCellValue('Indicador'), TextCellValue('Resultado')]);
    final summaryRows = <List<CellValue?>>[
      [const TextCellValue('Ventas totales'), DoubleCellValue(_number(totals['revenue']))],
      [const TextCellValue('Número de ventas'), IntCellValue((totals['sales_count'] as num? ?? 0).toInt())],
      [const TextCellValue('Costo estimado de recetas'), DoubleCellValue(_number(totals['cost']))],
      [const TextCellValue('Utilidad bruta estimada'), DoubleCellValue(_number(totals['gross_profit']))],
      [const TextCellValue('Ticket promedio'), DoubleCellValue(_number(totals['average_ticket']))],
      [const TextCellValue('Salidas de caja'), DoubleCellValue(_number(report['cash_outflows']))],
      [const TextCellValue('Gastos registrados'), DoubleCellValue(_number(report['registered_expenses']))],
      [const TextCellValue('Compras de ingredientes'), DoubleCellValue(_number(purchases['total']))],
    ];
    for (final row in summaryRows) { summary.appendRow(row); }
    summary.setColumnWidth(0, 32);
    summary.setColumnWidth(1, 22);

    final daily = (report['daily'] as List).cast<Map<String, Object?>>();
    final services = (report['services'] as List).cast<Map<String, Object?>>();
    final payments = (report['payments'] as List).cast<Map<String, Object?>>();
    final top = (report['top_items'] as List).cast<Map<String, Object?>>();
    final expenses = (report['expense_categories'] as List).cast<Map<String, Object?>>();

    addRows('Ventas por dia', [
      [const TextCellValue('Fecha'), const TextCellValue('Cantidad de ventas'), const TextCellValue('Total Q')],
      ...daily.map((r) => [TextCellValue(_text(r['day'])), IntCellValue((r['count'] as num? ?? 0).toInt()), DoubleCellValue(_number(r['total']))]),
    ]);
    addRows('Servicios', [
      [const TextCellValue('Tipo de servicio'), const TextCellValue('Ventas'), const TextCellValue('Total Q')],
      ...services.map((r) => [TextCellValue(_text(r['service'])), IntCellValue((r['count'] as num? ?? 0).toInt()), DoubleCellValue(_number(r['total']))]),
    ]);
    addRows('Metodos de pago', [
      [const TextCellValue('Método'), const TextCellValue('Ventas'), const TextCellValue('Total Q')],
      ...payments.map((r) => [TextCellValue(_text(r['method'])), IntCellValue((r['count'] as num? ?? 0).toInt()), DoubleCellValue(_number(r['total']))]),
    ]);
    addRows('Platos mas vendidos', [
      [const TextCellValue('Plato'), const TextCellValue('Cantidad'), const TextCellValue('Total Q')],
      ...top.map((r) => [TextCellValue(_text(r['name'])), DoubleCellValue(_number(r['quantity'])), DoubleCellValue(_number(r['total']))]),
    ]);
    addRows('Gastos', [
      [const TextCellValue('Categoría'), const TextCellValue('Total Q')],
      ...expenses.map((r) => [TextCellValue(_text(r['categoria'], 'Sin categoría')), DoubleCellValue(_number(r['total']))]),
    ]);

    final bytes = book.save();
    if (bytes == null) throw StateError('No fue posible generar el archivo Excel.');
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, 'reporte_los_delfines_${from}_$to.xlsx'));
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static Future<void> shareFile(File file, String description) async {
    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path)],
      text: '$description · Cevichería Los Delfines',
    ));
  }
}
