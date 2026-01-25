import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

// --- IMPORTS ---
import '../../../../../core/widgets/responsive_layout.dart';
import '../../../../../l10n/app_localizations.dart';

// Import Material Repository & Model
import '../../../material/data/material_repository.dart';
import '../../../material/domain/material_model.dart';

import '../../domain/batch_model.dart';
import '../bloc/batch_cubit.dart';

// Import màn hình chi tiết
import 'batch_detail_screen.dart';

class BatchScreen extends StatefulWidget {
  const BatchScreen({super.key});

  @override
  State<BatchScreen> createState() => _BatchScreenState();
}

class _BatchScreenState extends State<BatchScreen> {
  final _searchController = TextEditingController();
  final Color _primaryColor = const Color(0xFF003366);
  final Color _accentColor = const Color(0xFF0055AA);
  final Color _bgLight = const Color(0xFFF5F7FA);

  // --- STATE QUẢN LÝ VẬT TƯ ---
  List<MaterialModel> _materials = [];
  bool _isLoadingMaterials = true;
  String? _materialErrorMsg;

  @override
  void initState() {
    super.initState();
    context.read<BatchCubit>().loadBatches();
    _loadMaterials();
  }

  // Hàm load vật tư
  Future<void> _loadMaterials() async {
    try {
      final repo = MaterialRepository();
      final materials = await repo.getMaterials();
      
      if (mounted) {
        setState(() {
          _materials = materials;
          _isLoadingMaterials = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMaterials = false;
          _materialErrorMsg = e.toString();
        });
      }
    }
  }

  // Helper lấy tên vật tư theo ID
  String _getMaterialName(int materialId, BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    if (_isLoadingMaterials) return loc.processing;
    final material = _materials.where((m) => m.id == materialId).firstOrNull;
    if (material != null) {
      return material.materialCode;
    }
    // [FIX 1] Truyền int thay vì String (materialId.toString())
    return loc.unknownMaterial(materialId);
  }

  // Hàm chuyển hướng sang trang chi tiết
  void _navigateToDetail(BuildContext context, Batch batch) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BatchDetailScreen(batch: batch),
      ),
    ).then((_) {
      context.read<BatchCubit>().loadBatches();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _bgLight,
      body: BlocBuilder<BatchCubit, BatchState>(
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- HEADER SECTION ---
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.inventory_2_outlined, color: Colors.orange, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.batchManagement, 
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              loc.batchSubtitle,
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (isDesktop)
                          ElevatedButton.icon(
                            onPressed: () => _showEditDialog(context, null),
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(loc.addBatch),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // --- SEARCH BAR ---
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: _bgLight,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: TextField(
                              controller: _searchController,
                              textInputAction: TextInputAction.search,
                              decoration: InputDecoration(
                                hintText: loc.searchBatchHint,
                                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 20),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.arrow_forward, color: Colors.blue),
                                  onPressed: () {
                                    context.read<BatchCubit>().loadBatches(search: _searchController.text);
                                  },
                                ),
                              ),
                              onSubmitted: (value) => context.read<BatchCubit>().loadBatches(search: value),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Icon(Icons.filter_list, color: Colors.grey, size: 20),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: Colors.grey.shade200),

              // --- MAIN CONTENT ---
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (state is BatchLoading) {
                      return Center(child: CircularProgressIndicator(color: _primaryColor));
                    } else if (state is BatchError) {
                      return Center(child: Text(loc.errorLabel(state.message), style: const TextStyle(color: Colors.red)));
                    } else if (state is BatchLoaded) {
                      if (state.batches.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_outlined, size: 60, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text(loc.noBatchesFound, style: TextStyle(color: Colors.grey.shade500)),
                            ],
                          ),
                        );
                      }
                      return isDesktop
                          ? _buildDesktopGrid(context, state.batches)
                          : _buildMobileList(context, state.batches);
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: !isDesktop
          ? FloatingActionButton(
              backgroundColor: _accentColor,
              onPressed: () => _showEditDialog(context, null),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  // --- DESKTOP GRID ---
  Widget _buildDesktopGrid(BuildContext context, List<Batch> batches) {
    final loc = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
                    horizontalMargin: 24,
                    columnSpacing: 30,
                    dataRowMinHeight: 60,
                    dataRowMaxHeight: 60,
                    showCheckboxColumn: false,
                    columns: [
                      DataColumn(label: Text(loc.internalCode, style: _headerStyle)),
                      DataColumn(label: Text(loc.supplierBatch, style: _headerStyle)),
                      DataColumn(label: Text(loc.materialLabel.toUpperCase(), style: _headerStyle)),
                      DataColumn(label: Text(loc.originCountry, style: _headerStyle)),
                      DataColumn(label: Text(loc.qcStatus, style: _headerStyle)),
                      DataColumn(label: Text(loc.qcNote, style: _headerStyle)), 
                      DataColumn(label: Text(loc.status.toUpperCase(), style: _headerStyle)),
                      DataColumn(label: Text(loc.traceability, style: _headerStyle)), 
                      DataColumn(label: Text(loc.actions.toUpperCase(), style: _headerStyle)),
                    ],
                    rows: batches.map((batch) {
                      return DataRow(
                        onSelectChanged: (_) => _navigateToDetail(context, batch),
                        cells: [
                          DataCell(Text(batch.internalBatchCode, style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(batch.supplierBatchNo)),
                          DataCell(Text(
                            _getMaterialName(batch.materialId, context),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          )),
                          DataCell(Text(batch.originCountry ?? "--")),
                          DataCell(_StatusBadge(status: batch.qcStatus)),
                          DataCell(
                            Tooltip(
                              message: batch.qcNote ?? "",
                              child: Text(
                                batch.qcNote ?? "--",
                                style: const TextStyle(color: Colors.black87, fontStyle: FontStyle.italic),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: batch.isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                batch.isActive ? loc.active : loc.inactive,
                                style: TextStyle(
                                  color: batch.isActive ? Colors.green : Colors.red,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            )
                          ),
                          DataCell(
                            batch.receiptNumber != null
                            ? Row(
                                children: [
                                  const Icon(Icons.receipt_long, size: 16, color: Colors.blueGrey),
                                  const SizedBox(width: 6),
                                  Text(
                                    batch.receiptNumber!, 
                                    style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)
                                  ),
                                ],
                              )
                            : Text(
                                batch.receiptDetailId != null ? "#${batch.receiptDetailId}" : "--", 
                                style: const TextStyle(color: Colors.grey)
                              ),
                          ),
                          DataCell(Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_note, color: Colors.grey),
                                onPressed: () => _showEditDialog(context, batch),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () => _confirmDelete(context, batch),
                              ),
                            ],
                          )),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  TextStyle get _headerStyle => TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5);

  // --- MOBILE LIST ---
  Widget _buildMobileList(BuildContext context, List<Batch> batches) {
    final loc = AppLocalizations.of(context)!;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: batches.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final batch = batches[index];
        return Opacity(
          opacity: batch.isActive ? 1.0 : 0.6,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
              border: !batch.isActive ? Border.all(color: Colors.red.withOpacity(0.3)) : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _navigateToDetail(context, batch),
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.qr_code_2, color: Colors.blueGrey),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(batch.internalBatchCode, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                                const SizedBox(height: 4),
                                if (batch.originCountry != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text("${loc.origin}: ${batch.originCountry}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
                                  ),
                                
                                Row(
                                  children: [
                                    Icon(Icons.inventory_2, size: 14, color: _primaryColor),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        _getMaterialName(batch.materialId, context),
                                        style: TextStyle(color: _primaryColor, fontWeight: FontWeight.w600, fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text("${loc.supplier}: ", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                    Text(batch.supplierBatchNo, style: TextStyle(fontSize: 12, color: Colors.grey.shade800, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _StatusBadge(status: batch.qcStatus, isChip: true),
                              const SizedBox(height: 4),
                              if (!batch.isActive)
                                 Container(
                                   margin: const EdgeInsets.only(top: 4),
                                   padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                   decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                                   child: Text(loc.inactive, style: const TextStyle(color: Colors.white, fontSize: 10)),
                                 ),
                              const SizedBox(height: 4),
                              PopupMenuButton(
                                padding: EdgeInsets.zero,
                                icon: Icon(Icons.more_horiz, color: Colors.grey.shade400),
                                onSelected: (val) {
                                  if (val == 'view') _navigateToDetail(context, batch);
                                  if (val == 'edit') _showEditDialog(context, batch);
                                  if (val == 'delete') _confirmDelete(context, batch);
                                },
                                itemBuilder: (ctx) => [
                                  // [FIX 2] Sử dụng "View Details" thay vì loc.viewDetails nếu key đó không tồn tại
                                  const PopupMenuItem(value: 'view', child: Row(children: [Icon(Icons.visibility, size: 18, color: Colors.blue), SizedBox(width: 8), Text("View Details")])),
                                  PopupMenuItem(value: 'edit', child: Row(children: [const Icon(Icons.edit, size: 18), const SizedBox(width: 8), Text(loc.edit)])),
                                  PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete, size: 18, color: Colors.red), const SizedBox(width: 8), Text(loc.delete)])),
                                ],
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    
                    if (batch.qcNote != null && batch.qcNote!.isNotEmpty)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.rate_review, size: 16, color: Colors.amber),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "${loc.qcNote}: ${batch.qcNote}",
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade800, fontStyle: FontStyle.italic),
                              ),
                            ),
                          ],
                        ),
                      ),

                    Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Divider(height: 1, color: Colors.grey.shade100)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (batch.receiptNumber != null)
                            Row(children: [
                              Icon(Icons.link, size: 14, color: _accentColor),
                              const SizedBox(width: 4),
                              Text("${loc.linkedReceipt}: ${batch.receiptNumber}", style: TextStyle(fontSize: 12, color: _accentColor, fontWeight: FontWeight.bold)),
                            ])
                          else if (batch.receiptDetailId != null)
                            Text("${loc.linkedReceipt} #${batch.receiptDetailId}", style: const TextStyle(fontSize: 12, color: Colors.grey))
                          else
                            const SizedBox(),

                          _buildInfoRow(Icons.event_busy, "${loc.expDate}: ${batch.expiryDate ?? '--'}"),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade400),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  // --- DIALOG THÊM / SỬA ---
  void _showEditDialog(BuildContext context, Batch? batch) {
    final loc = AppLocalizations.of(context)!;
    final supplierBatchCtrl = TextEditingController(text: batch?.supplierBatchNo ?? '');
    final noteCtrl = TextEditingController(text: batch?.note ?? '');
    final qcNoteCtrl = TextEditingController(text: batch?.qcNote ?? '');
    final originCtrl = TextEditingController(text: batch?.originCountry ?? '');
    
    final receiptIdCtrl = TextEditingController(text: batch?.receiptDetailId?.toString() ?? '');

    bool isActive = batch?.isActive ?? true;
    int? selectedMaterialId = batch?.materialId;
    String? mfgDate = batch?.manufactureDate;
    String? expDate = batch?.expiryDate;
    String selectedQcStatus = batch?.qcStatus ?? "Pending";

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          
          Future<void> pickDate(bool isMfg) async {
            DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (picked != null) {
              setStateDialog(() {
                final formatted = DateFormat('yyyy-MM-dd').format(picked);
                if (isMfg) {
                  mfgDate = formatted;
                } else {
                  expDate = formatted;
                }
              });
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            titlePadding: const EdgeInsets.all(24),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            title: Text(batch == null ? loc.addBatch : loc.edit, style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
            content: Form(
              key: formKey,
              child: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Hiển thị Receipt Number nếu có (Chỉ xem)
                      if (batch?.receiptNumber != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.withOpacity(0.1))
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.link, size: 20, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "${loc.linkedReceipt}: ${batch!.receiptNumber}",
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                                ),
                              ),
                            ],
                          ),
                        ),

                      TextFormField(
                         controller: receiptIdCtrl,
                         keyboardType: TextInputType.number,
                         decoration: InputDecoration(
                           labelText: loc.linkedReceiptId,
                           helperText: loc.linkedReceiptIdHelper,
                           prefixIcon: const Icon(Icons.confirmation_number_outlined),
                           border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                           filled: true, fillColor: Colors.grey.withOpacity(0.05),
                           contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                         ),
                      ),
                      const SizedBox(height: 16),

                      if (_isLoadingMaterials)
                        Padding(padding: const EdgeInsets.all(10), child: Text(loc.processing))
                      else if (_materialErrorMsg != null)
                        Text(loc.errorLoadMaterials(_materialErrorMsg!), style: const TextStyle(color: Colors.red))
                      else
                        DropdownButtonFormField<int>(
                          value: selectedMaterialId,
                          isExpanded: true,
                          decoration: _inputDeco(loc.selectMaterialPlaceholder),
                          items: _materials.map((m) {
                            return DropdownMenuItem<int>(
                              value: m.id,
                              child: Text(
                                m.materialCode,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) => setStateDialog(() => selectedMaterialId = val),
                          validator: (v) => v == null ? loc.required : null,
                        ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: supplierBatchCtrl,
                              decoration: _inputDeco(loc.supplierBatch),
                              validator: (v) => v!.isEmpty ? loc.required : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: originCtrl,
                              decoration: _inputDeco(loc.originCountry),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => pickDate(true),
                              child: InputDecorator(
                                decoration: _inputDeco(loc.mfgDate),
                                child: Text(mfgDate ?? loc.selectPlaceholder, style: TextStyle(color: mfgDate == null ? Colors.grey : Colors.black87)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () => pickDate(false),
                              child: InputDecorator(
                                decoration: _inputDeco(loc.expDate),
                                child: Text(expDate ?? loc.selectPlaceholder, style: TextStyle(color: expDate == null ? Colors.grey : Colors.black87)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blueGrey.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(loc.qualityControl, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: selectedQcStatus,
                              decoration: _inputDeco(loc.qcStatus),
                              items: ["Pending", "Pass", "Fail", "Expired"]
                                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                  .toList(),
                              onChanged: (val) => setStateDialog(() => selectedQcStatus = val!),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: qcNoteCtrl,
                              decoration: _inputDeco(loc.qcNote),
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      TextFormField(controller: noteCtrl, decoration: _inputDeco(loc.generalNote), maxLines: 1),
                      
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white
                        ),
                        child: SwitchListTile(
                          title: Text(loc.isActiveSwitch, style: const TextStyle(fontSize: 14)),
                          subtitle: Text(loc.isActiveBatchHint, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          value: isActive,
                          activeColor: Colors.green,
                          onChanged: (val) => setStateDialog(() => isActive = val),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actionsPadding: const EdgeInsets.all(24),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.cancel, style: const TextStyle(color: Colors.grey))),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate() && selectedMaterialId != null) {
                    final newBatch = Batch(
                      batchId: batch?.batchId ?? 0,
                      internalBatchCode: batch?.internalBatchCode ?? '',
                      supplierBatchNo: supplierBatchCtrl.text,
                      materialId: selectedMaterialId!,
                      manufactureDate: mfgDate,
                      expiryDate: expDate,
                      qcStatus: selectedQcStatus,
                      qcNote: qcNoteCtrl.text,
                      note: noteCtrl.text,
                      receiptDetailId: int.tryParse(receiptIdCtrl.text),
                      originCountry: originCtrl.text, 
                      isActive: isActive,
                    );
                    
                    context.read<BatchCubit>().saveBatch(batch: newBatch, isEdit: batch != null);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(batch == null ? loc.successAdded : loc.successUpdated), backgroundColor: Colors.green));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: Text(loc.save),
              ),
            ],
          );
        },
      ),
    );
  }

  InputDecoration _inputDeco(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  void _confirmDelete(BuildContext context, Batch batch) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [const Icon(Icons.warning_amber_rounded, color: Colors.red), const SizedBox(width: 8), Text(loc.delete)]),
        content: Text(loc.confirmDeleteBatchMsg(batch.internalBatchCode)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.cancel)),
          ElevatedButton(
            onPressed: () {
              context.read<BatchCubit>().deleteBatch(batch.batchId);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(loc.delete),
          ),
        ],
      ),
    );
  }
}

// --- HELPER WIDGETS ---

class _StatusBadge extends StatelessWidget {
  final String status;
  final bool isChip;
  const _StatusBadge({required this.status, this.isChip = false});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case "Pass": color = Colors.green; break;
      case "Fail": color = Colors.red; break;
      case "Expired": color = Colors.grey; break;
      default: color = Colors.orange; // Pending
    }

    if (!isChip) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
        child: Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      );
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.2))),
      child: Text(status, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
    );
  }
}