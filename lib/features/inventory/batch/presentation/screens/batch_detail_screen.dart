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
            Text(
              "Batch: ${widget.batch.internalBatchCode}", 
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)
            ),
            // [SỬA] Hiển thị Material Code và Type/Spec
            Text(
              "${widget.batch.materialCode ?? 'Unknown Material'} | ${widget.batch.materialType ?? ''}", 
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12, overflow: TextOverflow.ellipsis)
            ),
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
            title: "Material & Supplier",
            children: [
              // [SỬA] Thay thế Name bằng Code và Type
              _buildRow("Material Code", widget.batch.materialCode ?? "--", isHighlight: true),
              _buildRow("Type", widget.batch.materialType ?? "--"),
              _buildRow("Spec (Denier)", widget.batch.specDenier ?? "--"), // Hiển thị thông số kỹ thuật
              
              const Divider(height: 20, thickness: 0.5),
              
              _buildRow("Supplier", widget.batch.supplierName ?? "Unknown"),
              _buildRow("Supplier Batch", widget.batch.supplierBatchNo),
              _buildRow("Origin", widget.batch.originCountry ?? "N/A"),
            ],
          ),
          const SizedBox(height: 16),
          _buildCard(
            title: "Logistics & Storage",
            children: [
              _buildRow("Location", widget.batch.location ?? "Unassigned", isHighlight: true),
              _buildRow("Receipt Number", widget.batch.receiptNumber ?? "--"),
              
              _buildRow("Mfg Date", widget.batch.manufactureDate != null 
                  ? DateFormat('dd/MM/yyyy').format(DateTime.parse(widget.batch.manufactureDate!)) 
                  : "--"),
              _buildRow("Exp Date", widget.batch.expiryDate != null 
                  ? DateFormat('dd/MM/yyyy').format(DateTime.parse(widget.batch.expiryDate!)) 
                  : "--"),
               _buildRow("Created At", widget.batch.createdAt != null 
                  ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(widget.batch.createdAt!)) 
                  : "--"),
            ],
          ),
          const SizedBox(height: 16),
          _buildCard(
            title: "Quality Status",
            children: [
              _buildRow("QC Status", widget.batch.qcStatus, isStatus: true),
              _buildRow("QC Note", widget.batch.qcNote ?? "--"),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.batch.note != null && widget.batch.note!.isNotEmpty)
             _buildCard(
               title: "Note", 
               children: [Text(widget.batch.note!, style: const TextStyle(fontSize: 14, color: Colors.black87))]
             ),
        ],
      ),
    );
  }

  // --- TAB 2: LỊCH SỬ KIỂM TRA (QC) ---
  // (Giữ nguyên phần này như code trước vì không ảnh hưởng bởi Material Name)
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                              ],
                            ),
                            trailing: Text(
                              item.finalResult.toJson().toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: item.finalResult == IQCResultStatus.pass ? Colors.green : Colors.red,
                              ),
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

  void _showIQCForm(BuildContext context) {
    final iqcCubit = context.read<IQCResultCubit>();
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: iqcCubit, 
        child: IQCFormDialog(batchId: widget.batch.batchId),
      ),
    ).then((result) {
      if (result != null) {
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

  Widget _buildRow(String label, String value, {bool isStatus = false, bool isHighlight = false}) {
    Color valColor = Colors.black87;
    FontWeight valWeight = FontWeight.w500;

    if (isStatus) {
      if (value == "Pass") {
        valColor = Colors.green;
        valWeight = FontWeight.bold;
      } else if (value == "Fail") {
        valColor = Colors.red;
        valWeight = FontWeight.bold;
      } else {
        valColor = Colors.orange;
        valWeight = FontWeight.bold;
      }
    } else if (isHighlight) {
      valColor = _primaryColor;
      valWeight = FontWeight.bold;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(flex: 4, child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 14))),
          Expanded(
            flex: 6,
            child: Text(
              value, 
              style: TextStyle(fontWeight: valWeight, color: valColor, fontSize: 14),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}