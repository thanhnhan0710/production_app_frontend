import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:production_app_frontend/l10n/app_localizations.dart'; // [MỚI] Import localization
import 'package:production_app_frontend/features/inventory/stock_in/presentation/screens/material_stock_in_page.dart';

// Import Repository/Cubit
import '../../data/material_receipt_repository.dart';
import '../bloc/material_receipt_cubit.dart';
// Import Page Danh sách


// --- 1. TAB NGUYÊN VẬT LIỆU ---
class MaterialStockInTab extends StatelessWidget {
  const MaterialStockInTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Cung cấp Cubit để quản lý state danh sách phiếu nhập
    return BlocProvider(
      create: (context) => MaterialReceiptCubit(MaterialReceiptRepository()),
      child: const MaterialStockInPage(),
    );
  }
}

// ============================================================================
// CÁC TAB KHÁC (BÁN THÀNH PHẨM, THÀNH PHẨM) - GIỮ NGUYÊN UI MẪU
// ============================================================================

class _StockInFormLayout extends StatelessWidget {
  final String title;
  final Widget headerForm;
  final Widget itemsTable;
  final VoidCallback onSave;

  const _StockInFormLayout({
    required this.title,
    required this.headerForm,
    required this.itemsTable,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // [MỚI]

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // [MỚI] Sử dụng key có tham số title
                  Text(l10n.generalInfoTitle(title), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  headerForm,
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.goodsList, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), // [MỚI]
                      ElevatedButton.icon(
                        onPressed: () {}, 
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(l10n.addRow), // [MỚI]
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade50,
                          foregroundColor: Colors.blue,
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: itemsTable,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
                child: Text(l10n.cancelAction), // [MỚI]
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                icon: const Icon(Icons.save),
                label: Text(l10n.saveReceipt), // [MỚI]
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class SemiFinishedStockInTab extends StatefulWidget {
  const SemiFinishedStockInTab({super.key});

  @override
  State<SemiFinishedStockInTab> createState() => _SemiFinishedStockInTabState();
}

class _SemiFinishedStockInTabState extends State<SemiFinishedStockInTab> {
  final _dateController = TextEditingController(text: DateFormat('dd/MM/yyyy').format(DateTime.now()));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // [MỚI]

    return _StockInFormLayout(
      title: l10n.tabSemiFinished, // [MỚI]
      onSave: () {},
      headerForm: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildTextField(l10n.receiptNumber, "PN-BTP-20231025-002", readOnly: true)), // [MỚI]
              const SizedBox(width: 16),
              Expanded(child: _buildTextField(l10n.importDate, "dd/mm/yyyy", controller: _dateController, icon: Icons.calendar_today)), // [MỚI]
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildDropdown(l10n.receivingWarehouse, ["Kho BTP Dệt", "Kho BTP Nhuộm"], l10n.selectPlaceholder)), // [MỚI]
              const SizedBox(width: 16),
              Expanded(child: _buildDropdown(l10n.sendingDepartment, ["Xưởng Dệt", "Xưởng Nhuộm"], l10n.selectPlaceholder)), // [MỚI]
            ],
          ),
        ],
      ),
      itemsTable: DataTable(
        headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
        columns: [
          DataColumn(label: Text(l10n.semiFinishedCode)), // [MỚI]
          DataColumn(label: Text(l10n.semiFinishedName)), // [MỚI]
          DataColumn(label: Text(l10n.goodQty)), // [MỚI]
          DataColumn(label: Text(l10n.badQty)), // [MỚI]
          DataColumn(label: Text(l10n.actions)), // [MỚI]
        ],
        rows: [
          _buildRow(["GREY-FAB-01", "Vải mộc Type A", "5,000", "20"]),
        ],
      ),
    );
  }
}

class FinishedProductStockInTab extends StatefulWidget {
  const FinishedProductStockInTab({super.key});

  @override
  State<FinishedProductStockInTab> createState() => _FinishedProductStockInTabState();
}

class _FinishedProductStockInTabState extends State<FinishedProductStockInTab> {
  final _dateController = TextEditingController(text: DateFormat('dd/MM/yyyy').format(DateTime.now()));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // [MỚI]

    return _StockInFormLayout(
      title: l10n.tabFinished, // [MỚI]
      onSave: () {},
      headerForm: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildTextField(l10n.receiptNumber, "PN-TP-20231025-003", readOnly: true)), // [MỚI]
              const SizedBox(width: 16),
              Expanded(child: _buildTextField(l10n.importDate, "dd/mm/yyyy", controller: _dateController, icon: Icons.calendar_today)), // [MỚI]
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildDropdown(l10n.receivingWarehouse, ["Kho Thành Phẩm A", "Kho Thành Phẩm B"], l10n.selectPlaceholder)), // [MỚI]
              const SizedBox(width: 16),
              Expanded(child: _buildDropdown(l10n.source, ["Tổ Đóng Gói", "Gia công ngoài"], l10n.selectPlaceholder)), // [MỚI]
            ],
          ),
        ],
      ),
      itemsTable: DataTable(
        headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
        columns: [
          DataColumn(label: Text(l10n.itemCode)), // [MỚI]
          DataColumn(label: Text(l10n.productTitle)), // [MỚI] (Tên thành phẩm)
          DataColumn(label: Text(l10n.quantity)), // [MỚI]
          DataColumn(label: Text(l10n.carton)), // [MỚI]
          DataColumn(label: Text(l10n.actions)), // [MỚI]
        ],
        rows: [
          _buildRow(["SHIRT-001", "Áo thun Polo", "1,200", "12 CTN"]),
        ],
      ),
    );
  }
}

Widget _buildTextField(String label, String hint, {bool readOnly = false, TextEditingController? controller, IconData? icon}) {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.black87)),
    const SizedBox(height: 6),
    TextField(
      controller: controller, readOnly: readOnly,
      decoration: InputDecoration(
        hintText: hint, filled: true, fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
        suffixIcon: icon != null ? Icon(icon, size: 20) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    ),
  ]);
}

Widget _buildDropdown(String label, List<String> items, String hint) {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.black87)),
    const SizedBox(height: 6),
    DropdownButtonFormField<String>(
      decoration: InputDecoration(
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      hint: Text(hint), // [MỚI]
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: (val) {},
    ),
  ]);
}

DataRow _buildRow(List<String> cells) {
  final List<DataCell> dataCells = cells.map((e) => DataCell(Text(e))).toList();
  dataCells.add(DataCell(IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () {})));
  return DataRow(cells: dataCells);
}