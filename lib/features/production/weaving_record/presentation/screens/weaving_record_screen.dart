import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';

// Import các thư viện hỗ trợ đa nền tảng
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
// ignore: depend_on_referenced_packages
import 'package:universal_io/io.dart' as io; // Thay thế dart:io
import 'package:universal_html/html.dart' as html; // Hỗ trợ Web

import 'package:production_app_frontend/features/production/weaving_record/presentation/bloc/weaving_record_cubit.dart';
import 'package:production_app_frontend/features/production/weaving_record/domain/weaving_record_model.dart';

enum DateFilterType { day, week, month, quarter, custom }

class WeavingRecordScreen extends StatefulWidget {
  const WeavingRecordScreen({super.key});

  @override
  State<WeavingRecordScreen> createState() => _WeavingRecordScreenState();
}

class _WeavingRecordScreenState extends State<WeavingRecordScreen> {
  DateFilterType _selectedFilter = DateFilterType.day;
  DateTimeRange? _customDateRange;
  List<WeavingRecord> _filteredList = [];
  String _searchKeyword = "";

  @override
  void initState() {
    super.initState();
    context.read<WeavingRecordCubit>().loadRecords();
  }

  // --- LOGIC LỌC DỮ LIỆU ---
  void _applyFilter(List<WeavingRecord> originalList) {
    final now = DateTime.now();
    DateTime start;
    DateTime end;

    switch (_selectedFilter) {
      case DateFilterType.day:
        start = DateTime(now.year, now.month, now.day);
        end = start.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
        break;
      case DateFilterType.week:
        start = now.subtract(Duration(days: now.weekday - 1));
        start = DateTime(start.year, start.month, start.day);
        end = start.add(const Duration(days: 7)).subtract(const Duration(seconds: 1));
        break;
      case DateFilterType.month:
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 1).subtract(const Duration(seconds: 1));
        break;
      case DateFilterType.quarter:
        int quarter = ((now.month - 1) / 3).floor() + 1;
        start = DateTime(now.year, (quarter - 1) * 3 + 1, 1);
        end = DateTime(now.year, quarter * 3 + 1, 1).subtract(const Duration(seconds: 1));
        break;
      case DateFilterType.custom:
        if (_customDateRange != null) {
          start = _customDateRange!.start;
          end = _customDateRange!.end.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
        } else {
          start = DateTime(2000);
          end = DateTime(3000);
        }
        break;
    }

    setState(() {
      _filteredList = originalList.where((item) {
        if (item.updatedAt == null) return false;

        // 1. Lọc theo ngày
        bool inDate = item.updatedAt!.isAfter(start) && item.updatedAt!.isBefore(end);

        // 2. Lọc theo từ khóa
        bool matchKeyword = true;
        if (_searchKeyword.isNotEmpty) {
          final kw = _searchKeyword.toLowerCase();
          matchKeyword = (item.machineName ?? '').toLowerCase().contains(kw) ||
              (item.basketCode ?? '').toLowerCase().contains(kw) ||
              (item.updatedByName ?? '').toLowerCase().contains(kw) ||
              (item.shiftName ?? '').toLowerCase().contains(kw);
        }

        return inDate && matchKeyword;
      }).toList();

      // Sắp xếp: Mới nhất lên đầu
      _filteredList.sort((a, b) => (b.updatedAt ?? DateTime(0)).compareTo(a.updatedAt ?? DateTime(0)));
    });
  }

  // --- LOGIC XUẤT EXCEL (ĐÃ CẬP NHẬT CHO WEB & MOBILE) ---
  Future<void> _exportToExcel() async {
    if (_filteredList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Không có dữ liệu để xuất")));
      return;
    }

    // Hiển thị loading
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đang tạo file Excel..."), duration: Duration(seconds: 1)));

    try {
      var excel = Excel.createExcel();
      Sheet sheet = excel['Sheet1'];

      // Header
      List<String> headers = ['Ngày giờ', 'Máy', 'Line', 'Ca', 'Mã Rổ', 'KL Tịnh (Kg)', 'Phế Run (Kg)', 'Phế Setup (Kg)', 'Người cập nhật'];
      CellStyle headerStyle = CellStyle(bold: true, horizontalAlign: HorizontalAlign.Center, backgroundColorHex: ExcelColor.blueGrey200);

      for (var i = 0; i < headers.length; i++) {
        var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      // Data Rows
      for (var i = 0; i < _filteredList.length; i++) {
        final item = _filteredList[i];
        final row = i + 1;

        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue(item.updatedAt != null ? DateFormat('dd/MM/yyyy HH:mm').format(item.updatedAt!) : "");
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = TextCellValue(item.machineName ?? "-");
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = IntCellValue(item.line);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = TextCellValue(item.shiftName ?? "-");
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = TextCellValue(item.basketCode ?? "-");
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value = DoubleCellValue(item.totalWeight);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value = DoubleCellValue(item.runWaste);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row)).value = DoubleCellValue(item.setupWaste);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row)).value = TextCellValue(item.updatedByName ?? "-");
      }

      // Lấy dữ liệu bytes
      final List<int>? fileBytes = excel.save();

      if (fileBytes != null) {
        // Tên file
        String fileName = 'WeavingReport_${DateFormat('ddMMyy_HHmm').format(DateTime.now())}.xlsx';
        
        // Gọi Helper để lưu (Tự động xử lý Web/Mobile)
        await FileSaveHelper.saveAndLaunch(fileBytes, fileName);
        
        if (!kIsWeb && mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã lưu file: $fileName"), backgroundColor: Colors.green));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi xuất file: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Lịch sử Sản lượng Dệt", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF003366),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: "Xuất Excel",
            onPressed: _exportToExcel,
          )
        ],
      ),
      body: BlocConsumer<WeavingRecordCubit, WeavingRecordState>(
        listener: (context, state) {
          if (state is WeavingRecordLoaded) {
            _applyFilter(state.records);
          }
          if (state is WeavingRecordError) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          }
        },
        builder: (context, state) {
          List<WeavingRecord> originalList = [];
          if (state is WeavingRecordLoaded) originalList = state.records;

          return Column(
            children: [
              // --- 1. THANH CÔNG CỤ ---
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: "Tìm kiếm (Máy, Rổ, Người, Ca...)",
                        prefixIcon: const Icon(Icons.search),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      onChanged: (val) {
                        _searchKeyword = val;
                        _applyFilter(originalList);
                      },
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip("Hôm nay", DateFilterType.day, originalList),
                          _buildFilterChip("Tuần này", DateFilterType.week, originalList),
                          _buildFilterChip("Tháng này", DateFilterType.month, originalList),
                          _buildFilterChip("Quý này", DateFilterType.quarter, originalList),
                          const SizedBox(width: 8),
                          ActionChip(
                            label: Text(_customDateRange == null 
                                ? "Tùy chọn..." 
                                : "${DateFormat('dd/MM').format(_customDateRange!.start)} - ${DateFormat('dd/MM').format(_customDateRange!.end)}"
                            ),
                            avatar: const Icon(Icons.calendar_today, size: 16),
                            backgroundColor: _selectedFilter == DateFilterType.custom ? Colors.blue.shade100 : Colors.grey.shade100,
                            onPressed: () async {
                              final picked = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                                initialDateRange: _customDateRange
                              );
                              if (picked != null) {
                                setState(() {
                                  _customDateRange = picked;
                                  _selectedFilter = DateFilterType.custom;
                                });
                                _applyFilter(originalList);
                              }
                            },
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              const Divider(height: 1),

              // --- 2. HIỂN THỊ DỮ LIỆU ---
              Expanded(
                child: state is WeavingRecordLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredList.isEmpty 
                      ? const Center(child: Text("Không tìm thấy dữ liệu", style: TextStyle(color: Colors.grey)))
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth > 800) {
                              return _buildDesktopTable();
                            } else {
                              return _buildMobileList();
                            }
                          },
                        ),
              ),
              
              // --- 3. FOOTER ---
              if (_filteredList.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.blue.shade50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("SL: ${_filteredList.length} bản ghi", style: const TextStyle(color: Colors.blueGrey)),
                      Text("Tổng KL: ${_filteredList.fold(0.0, (sum, item) => sum + item.totalWeight).toStringAsFixed(2)} kg", 
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003366), fontSize: 16)),
                    ],
                  ),
                )
            ],
          );
        },
      ),
    );
  }

  // ... (Giữ nguyên các hàm _buildDesktopTable, _buildMobileList, _buildInfoRow như cũ) ...
  // Để code gọn, tôi không lặp lại phần UI hiển thị danh sách vì nó không đổi
  
  // UI DESKTOP
  Widget _buildDesktopTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.grey.shade200),
          columns: const [
            DataColumn(label: Text('Ngày giờ')),
            DataColumn(label: Text('Máy / Line')),
            DataColumn(label: Text('Ca')),
            DataColumn(label: Text('Mã Rổ')),
            DataColumn(label: Text('KL Tịnh (Kg)'), numeric: true),
            DataColumn(label: Text('Phế Run'), numeric: true),
            DataColumn(label: Text('Phế Setup'), numeric: true),
            DataColumn(label: Text('Người cập nhật')),
            DataColumn(label: Text('Thao tác')),
          ],
          rows: _filteredList.map((item) {
            return DataRow(cells: [
              DataCell(Text(item.updatedAt != null ? DateFormat('dd/MM HH:mm').format(item.updatedAt!) : "-")),
              DataCell(Text("${item.machineName ?? 'ID:${item.machineId}'} (L${item.line})")),
              DataCell(Text(item.shiftName ?? '-')),
              DataCell(Text(item.basketCode ?? 'ID:${item.basketId}', style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(Text(item.totalWeight.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
              DataCell(Text(item.runWaste.toStringAsFixed(2))),
              DataCell(Text(item.setupWaste.toStringAsFixed(2))),
              DataCell(Text(item.updatedByName ?? '-')),
              DataCell(
                IconButton(
                  icon: const Icon(Icons.edit_note, color: Colors.blue),
                  onPressed: () => _showEditDialog(context, item),
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  // UI MOBILE
  Widget _buildMobileList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _filteredList.length,
      itemBuilder: (context, index) {
        final item = _filteredList[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.precision_manufacturing, size: 18, color: Colors.blueGrey),
                        const SizedBox(width: 6),
                        Text(
                          "${item.machineName ?? '?'} - Line ${item.line}",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                    Text(
                      item.updatedAt != null ? DateFormat('dd/MM HH:mm').format(item.updatedAt!) : "-",
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(Icons.shopping_basket, "Rổ:", item.basketCode ?? "ID:${item.basketId}"),
                          const SizedBox(height: 6),
                          _buildInfoRow(Icons.access_time, "Ca:", item.shiftName ?? "-"),
                          const SizedBox(height: 6),
                          _buildInfoRow(Icons.person, "Nhân viên:", item.updatedByName ?? "-"),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text("KL Tịnh", style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                            Text("${item.totalWeight.toStringAsFixed(2)} kg", 
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text("Phế: Run / Setup", style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                            Text("${item.runWaste} / ${item.setupWaste}", 
                                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _showEditDialog(context, item),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text("Chỉnh sửa số liệu"),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue.shade700,
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text("$label ", style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13), overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _buildFilterChip(String label, DateFilterType type, List<WeavingRecord> originalList) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _selectedFilter == type,
        selectedColor: Colors.blue.shade100,
        backgroundColor: Colors.grey.shade100,
        onSelected: (bool selected) {
          if (selected) {
            setState(() => _selectedFilter = type);
            _applyFilter(originalList);
          }
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, WeavingRecord item) {
    final weightCtrl = TextEditingController(text: item.totalWeight.toString());
    final runWasteCtrl = TextEditingController(text: item.runWaste.toString());
    final setupWasteCtrl = TextEditingController(text: item.setupWaste.toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Sửa bản ghi #${item.id}", style: const TextStyle(fontSize: 18)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("${item.machineName} - Line ${item.line}", style: const TextStyle(fontWeight: FontWeight.bold)),
              Text("Rổ: ${item.basketCode}", style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
              const Divider(),
              const SizedBox(height: 8),
              TextFormField(
                controller: weightCtrl,
                decoration: const InputDecoration(labelText: "KL Tịnh (Kg)", border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? "Nhập số liệu" : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: runWasteCtrl,
                      decoration: const InputDecoration(labelText: "Phế Run", border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: setupWasteCtrl,
                      decoration: const InputDecoration(labelText: "Phế Setup", border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final updatedItem = item.copyWith(
                  totalWeight: double.parse(weightCtrl.text),
                  runWaste: double.parse(runWasteCtrl.text),
                  setupWaste: double.parse(setupWasteCtrl.text),
                );
                context.read<WeavingRecordCubit>().saveRecord(
                  item: updatedItem, 
                  isEdit: true
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }
}

// =========================================================
// HELPER CLASS: XỬ LÝ LƯU FILE ĐA NỀN TẢNG (WEB / MOBILE)
// =========================================================
class FileSaveHelper {
  static Future<void> saveAndLaunch(List<int> bytes, String fileName) async {
    if (kIsWeb) {
      // --- LOGIC CHO WEB ---
      // Tạo Blob và kích hoạt thẻ <a> để tải xuống
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // --- LOGIC CHO MOBILE / DESKTOP ---
      // Lưu vào thư mục ứng dụng và mở file
      io.Directory? directory;
      
      if (io.Platform.isAndroid) {
        directory = await getExternalStorageDirectory(); // Android
      } else {
        directory = await getApplicationDocumentsDirectory(); // iOS
      }

      if (directory != null) {
        final path = "${directory.path}/$fileName";
        final file = io.File(path);
        await file.writeAsBytes(bytes, flush: true);
        
        // Mở file bằng ứng dụng mặc định (Excel/Sheets)
        await OpenFile.open(path);
      }
    }
  }
}