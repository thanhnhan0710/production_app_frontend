import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html; 

import '../domain/weaving_production_model.dart';

class WeavingExportService {
  
  static Future<void> exportToExcel(List<WeavingDailyProduction> data) async {
    // [DEBUG] Log input data check
    print("🚀 Starting Excel export. Record count: ${data.length}");
    if (data.isEmpty) {
      print("⚠️ Data is empty, the file will be blank!");
    }

    // 1. Initialize Excel
    var excel = Excel.createExcel();
    
    // [FIX EMPTY FILE ISSUE]
    // Get the default sheet to write data first.
    String defaultSheet = 'Sheet1';
    Sheet sheetObject = excel[defaultSheet];

    // 2. Create Header
    List<String> headerStrings = [
      'Time',
      'Item Code',
      'Note',
      'Total line',
      'Prod',
      'M/date'
    ];

    List<CellValue> headerRow = headerStrings
        .map((e) => TextCellValue(e))
        .toList();
    
    sheetObject.appendRow(headerRow);

    // 3. Fill Data
    final dateFormat = DateFormat('dd/MM/yyyy');

    for (var item in data) {
      List<CellValue> row = [
        TextCellValue(dateFormat.format(item.date)),            
        TextCellValue(item.product?.itemCode ?? ""),            
        TextCellValue(item.product?.note ?? ""),                
        IntCellValue(item.activeMachineLines),                  
        DoubleCellValue(item.totalKg),                          
        DoubleCellValue(item.totalMeters),                      
      ];
      sheetObject.appendRow(row);
    }
    
    // [OPTIONAL] Rename Sheet after writing data
    excel.rename(defaultSheet, 'Report');

    // 4. Save File
    final String dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    // Changed filename from 'SanLuong_' to 'Production_'
    final String fileName = 'Production_$dateStr.xlsx'; 
    
    // Encode data
    var fileBytes = excel.save();

    if (fileBytes == null) {
      print("❌ Error: Cannot save excel file (bytes null)");
      return;
    }

    if (kIsWeb) {
      // ================= WEB =================
      print("🌐 Downloading on Web...");
      final blob = html.Blob([fileBytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", fileName)
        ..click();
        
      html.Url.revokeObjectUrl(url);
      print("✅ Download triggered.");
    } else {
      // ================= MOBILE =================
      try {
        final directory = await getTemporaryDirectory();
        final String filePath = '${directory.path}/$fileName';
        
        File(filePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(fileBytes);

        await Share.shareXFiles(
          [XFile(filePath)],
          text: 'Production report date $dateStr',
        );
      } catch (e) {
        throw Exception("Error saving file on Mobile: $e");
      }
    }
  }
}