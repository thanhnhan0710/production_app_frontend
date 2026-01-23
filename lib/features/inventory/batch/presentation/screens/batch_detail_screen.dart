import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

// Import Models
import '../../domain/batch_model.dart';
import '../../../../quality/iqc/domain/iqc_result_model.dart';

// Import Cubits & Repositories
import '../../../../quality/iqc/data/iqc_result_repository.dart';
import '../../../../quality/iqc/presentation/bloc/iqc_result_cubit.dart';

import 'iqc_form_dialog.dart'; 

class BatchDetailScreen extends StatelessWidget {
  final Batch batch;

  const BatchDetailScreen({super.key, required this.batch});

  @override
  Widget build(BuildContext context) {
    // Cung cấp IQCResultCubit cho màn hình này
    return BlocProvider(
      create: (context) => IQCResultCubit(IQCResultRepository())
        ..loadResultsByBatch(batch.batchId),
      child: _BatchDetailView(batch: batch),
    );
  }
}

class _BatchDetailView extends StatefulWidget {
  final Batch batch;
  const _BatchDetailView({required this.batch});

  @override
  State<_BatchDetailView> createState() => _BatchDetailViewState();
}

class _BatchDetailViewState extends State<_BatchDetailView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color _primaryColor = const Color(0xFF003366);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Batch: ${widget.batch.internalBatchCode}", style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
            Text(widget.batch.supplierBatchNo, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: _primaryColor,
          tabs: const [
            Tab(text: "General Info", icon: Icon(Icons.info_outline)),
            Tab(text: "Quality Control (IQC)", icon: Icon(Icons.fact_check_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGeneralInfoTab(),
          _buildIQCTab(),
        ],
      ),
    );
  }

  // --- TAB 1: THÔNG TIN CHUNG ---
  Widget _buildGeneralInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCard(
            title: "Basic Information",
            children: [
              _buildRow("Internal Code", widget.batch.internalBatchCode),
              _buildRow("Supplier Batch", widget.batch.supplierBatchNo),
              _buildRow("Material ID", "${widget.batch.materialId}"), 
              _buildRow("Origin", widget.batch.originCountry ?? "N/A"),
              _buildRow("Created At", widget.batch.createdAt ?? "N/A"),
            ],
          ),
          const SizedBox(height: 16),
          _buildCard(
            title: "Status & Logistics",
            children: [
              _buildRow("QC Status", widget.batch.qcStatus, isStatus: true),
              _buildRow("QC Note", widget.batch.qcNote ?? "--"),
              _buildRow("Mfg Date", widget.batch.manufactureDate ?? "--"),
              _buildRow("Exp Date", widget.batch.expiryDate ?? "--"),
              _buildRow("Receipt ID", widget.batch.receiptDetailId != null ? "#${widget.batch.receiptDetailId}" : "--"),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.batch.note != null)
             _buildCard(
               title: "Note", 
               children: [Text(widget.batch.note!, style: const TextStyle(fontSize: 14, color: Colors.black87))]
             ),
        ],
      ),
    );
  }

  // --- TAB 2: LỊCH SỬ KIỂM TRA (QC) ---
  Widget _buildIQCTab() {
    return BlocConsumer<IQCResultCubit, IQCResultState>(
      listener: (context, state) {
        if (state is IQCOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.green));
        } else if (state is IQCError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
        }
      },
      builder: (context, state) {
        if (state is IQCLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        List<IQCResult> results = [];
        if (state is IQCListLoaded) {
          results = state.results;
        }

        return Column(
          children: [
            // Nút tạo mới
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showIQCForm(context),
                  icon: const Icon(Icons.add_task),
                  label: const Text("ADD NEW TEST RESULT"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            
            Expanded(
              child: results.isEmpty
                  ? Center(child: Text("No test results yet.", style: TextStyle(color: Colors.grey.shade500)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final item = results[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: item.finalResult == IQCResultStatus.pass ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                item.finalResult == IQCResultStatus.pass ? Icons.check : Icons.close,
                                color: item.finalResult == IQCResultStatus.pass ? Colors.green : Colors.red,
                              ),
                            ),
                            title: Text("Test #${item.testId}", style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text("Date: ${item.testDate ?? 'N/A'}"),
                                Text("Tester: ${item.testerName ?? 'Unknown'}"),
                                if (item.note != null) Text("Note: ${item.note}", style: const TextStyle(fontStyle: FontStyle.italic)),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  item.finalResult.toJson().toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: item.finalResult == IQCResultStatus.pass ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  // [QUAN TRỌNG] ĐÃ SỬA LẠI HÀM NÀY
  void _showIQCForm(BuildContext context) {
    // 1. Lấy Cubit hiện tại từ context của màn hình
    final iqcCubit = context.read<IQCResultCubit>();

    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        // 2. Truyền Cubit này vào context của Dialog
        value: iqcCubit, 
        child: IQCFormDialog(batchId: widget.batch.batchId),
      ),
    ).then((result) {
      if (result != null) {
        // Reload lại danh sách sau khi đóng dialog (dù saveResult đã reload, nhưng gọi lại cho chắc chắn state mới nhất)
        iqcCubit.loadResultsByBatch(widget.batch.batchId);
      }
    });
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _primaryColor)),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isStatus = false}) {
    Color valColor = Colors.black87;
    if (isStatus) {
      if (value == "Pass") {
        valColor = Colors.green;
      } else if (value == "Fail") {
        valColor = Colors.red;
      } else {
        valColor = Colors.orange;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          Text(value, style: TextStyle(fontWeight: isStatus ? FontWeight.bold : FontWeight.w500, color: valColor, fontSize: 14)),
        ],
      ),
    );
  }
}