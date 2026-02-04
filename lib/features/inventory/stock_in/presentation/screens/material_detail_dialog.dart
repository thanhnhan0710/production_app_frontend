import 'package:flutter/material.dart';
import 'package:production_app_frontend/l10n/app_localizations.dart'; 
import '../../domain/material_receipt_model.dart';
import '../../../material/data/material_repository.dart';
// import '../../../material/domain/material_model.dart'; // Nếu cần
import '../../../purchase_order/domain/purchase_order_model.dart'; 

class MaterialDetailDialog extends StatefulWidget {
  final MaterialReceiptDetail? detail;
  // Danh sách chi tiết của PO đã chọn (để lọc vật tư & lấy số lượng)
  final List<PurchaseOrderDetail>? poDetails; 

  const MaterialDetailDialog({
    super.key, 
    this.detail,
    this.poDetails,
  });

  @override
  State<MaterialDetailDialog> createState() => _MaterialDetailDialogState();
}

class _MaterialDetailDialogState extends State<MaterialDetailDialog> {
  final _formKey = GlobalKey<FormState>();
  
  List<ReceiptMaterial> _availableMaterials = [];
  bool _isLoading = true;
  String? _errorMsg;

  ReceiptMaterial? _selectedMaterial;
  
  final _poQtyKgCtrl = TextEditingController(text: "0");
  final _receivedQtyKgCtrl = TextEditingController(text: "0");
  final _poQtyConesCtrl = TextEditingController(text: "0");
  final _receivedQtyConesCtrl = TextEditingController(text: "0");
  final _palletsCtrl = TextEditingController(text: "0");
  final _batchCtrl = TextEditingController();
  final _originCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  Future<void> _loadMaterials() async {
    try {
      if (widget.poDetails != null && widget.poDetails!.isNotEmpty) {
        if (mounted) {
          setState(() {
            // Map từ PurchaseOrderDetail sang ReceiptMaterial (để hiển thị trong dropdown)
            _availableMaterials = widget.poDetails!.map((d) {
              return ReceiptMaterial(
                id: d.materialId,
                code: d.material?.materialCode ?? "Item #${d.materialId}",
                unit: d.uom?.name ?? 'N/A',
              );
            }).toList();
            
            _isLoading = false;
            _initFormData();
          });
        }
      } else {
        final repo = MaterialRepository();
        final materials = await repo.getMaterials();
        
        if (mounted) {
          setState(() {
            _availableMaterials = materials.map((m) => ReceiptMaterial(
              id: m.id,
              code: m.materialCode,
              unit: m.uomBase?.name ?? 'N/A', 
            )).toList();
            _isLoading = false;
            _initFormData(); 
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMsg = e.toString();
        });
      }
    }
  }

  void _initFormData() {
    if (widget.detail != null) {
      if (widget.detail!.materialId != 0) {
        try {
          _selectedMaterial = _availableMaterials.firstWhere(
            (m) => m.id == widget.detail!.materialId
          );
        } catch (_) {
          _selectedMaterial = widget.detail!.material;
        }
      }
      _poQtyKgCtrl.text = widget.detail!.poQuantityKg.toString();
      _receivedQtyKgCtrl.text = widget.detail!.receivedQuantityKg.toString();
      _poQtyConesCtrl.text = widget.detail!.poQuantityCones.toString();
      _receivedQtyConesCtrl.text = widget.detail!.receivedQuantityCones.toString();
      _palletsCtrl.text = widget.detail!.numberOfPallets.toString();
      _batchCtrl.text = widget.detail!.supplierBatchNo ?? "";
      _originCtrl.text = widget.detail!.originCountry ?? "";
      _noteCtrl.text = widget.detail!.note ?? "";
      _locationCtrl.text = widget.detail!.location ?? "";
    }
  }

  // [LOGIC MỚI] Khi chọn vật tư -> Tự động điền số lượng KG và SỐ CUỘN từ PO
  void _onMaterialSelected(ReceiptMaterial? val) {
    setState(() {
      _selectedMaterial = val;
      
      if (val != null && widget.poDetails != null) {
        // Tìm chi tiết PO tương ứng với vật tư đã chọn
        final poDetail = widget.poDetails!.firstWhere(
          (d) => d.materialId == val.id, 
          orElse: () => PurchaseOrderDetail(
            poId: 0,
            materialId: 0, 
            quantity: 0, 
            quantityRolls: 0, // Default rolls
            unitPrice: 0
          ) 
        );

        if (poDetail.materialId != 0) {
           // 1. Tự động điền số lượng PO (Kg)
           _poQtyKgCtrl.text = poDetail.quantity.toString();
           
           // 2. [CẬP NHẬT] Tự động điền số lượng PO (Cuộn/Rolls)
           _poQtyConesCtrl.text = poDetail.quantityRolls.toString(); 
           
           // 3. Tự động điền số lượng Thực nhận bằng với PO (Auto-fill cả Kg và Rolls)
           _receivedQtyKgCtrl.text = poDetail.quantity.toString();
           _receivedQtyConesCtrl.text = poDetail.quantityRolls.toString(); 
        } else {
           _resetFields();
        }
      } else {
        _resetFields();
      }
    });
  }

  void _resetFields() {
    _poQtyKgCtrl.text = "0";
    _poQtyConesCtrl.text = "0";
    _receivedQtyKgCtrl.text = "0";
    _receivedQtyConesCtrl.text = "0";
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(widget.detail == null ? l10n.addMaterial : l10n.editMaterial),
      content: SizedBox( 
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isLoading)
                  const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())
                else if (_errorMsg != null)
                  Padding(padding: const EdgeInsets.all(8), child: Text(l10n.errorLoadMaterials(_errorMsg!), style: const TextStyle(color: Colors.red)))
                else
                  DropdownButtonFormField<ReceiptMaterial>(
                    value: _selectedMaterial,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.selectMaterialPlaceholder, 
                      border: const OutlineInputBorder(),
                      helperText: widget.poDetails != null && widget.poDetails!.isNotEmpty 
                          ? "Lọc theo PO đã chọn" 
                          : "Tất cả vật tư"
                    ),
                    items: _availableMaterials.map((m) {
                      return DropdownMenuItem(
                        value: m,
                        child: Text(
                          "${m.code} - (${m.unit})", 
                          overflow: TextOverflow.ellipsis
                        ),
                      );
                    }).toList(),
                    onChanged: widget.detail == null 
                        ? _onMaterialSelected 
                        : null, 
                    validator: (v) => v == null ? l10n.errorSelectMaterial : null,
                  ),
                
                const SizedBox(height: 16),
                
                // PO Quantities 
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _poQtyKgCtrl,
                        decoration: InputDecoration(
                          labelText: l10n.poQtyKg, 
                          border: const OutlineInputBorder(),
                          fillColor: Colors.grey.shade100, filled: true
                        ),
                        keyboardType: TextInputType.number,
                        readOnly: true, // Read-only để user đối chiếu số KG
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _poQtyConesCtrl,
                        decoration: InputDecoration(
                          labelText: l10n.poQtyCones, 
                          border: const OutlineInputBorder(),
                          fillColor: Colors.grey.shade100, filled: true
                        ),
                        keyboardType: TextInputType.number,
                        readOnly: true, // Số cuộn trên PO cũng Read-only (lấy từ PO)
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Actual Quantities (Đã được Auto-fill KG & Rolls)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3))
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.actualImportLabel, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _receivedQtyKgCtrl,
                              decoration: InputDecoration(
                                labelText: l10n.actualQtyKg, 
                                border: const OutlineInputBorder(),
                                fillColor: Colors.white, filled: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (v) => (double.tryParse(v ?? '') ?? 0) < 0 ? l10n.errorNegative : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _receivedQtyConesCtrl,
                              decoration: InputDecoration(
                                labelText: l10n.actualQtyCones, 
                                border: const OutlineInputBorder(),
                                fillColor: Colors.white, filled: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Logistics & Batch & Origin
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _palletsCtrl,
                        decoration: InputDecoration(labelText: l10n.pallets, border: const OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _batchCtrl,
                        decoration: InputDecoration(
                          labelText: l10n.supplierBatch, 
                          prefixIcon: const Icon(Icons.qr_code_2),
                          border: const OutlineInputBorder(),
                          helperText: "Batch auto-created",
                          helperStyle: const TextStyle(fontSize: 10, color: Colors.blueGrey),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _locationCtrl,
                        decoration: const InputDecoration(
                          labelText: "Location", 
                          prefixIcon: Icon(Icons.place),
                          border: OutlineInputBorder(),
                          hintText: "A-01-01",
                        ),
                        maxLength: 10,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _originCtrl,
                        decoration: const InputDecoration(
                          labelText: "Origin (Xuất xứ)", 
                          prefixIcon: Icon(Icons.public),
                          border: OutlineInputBorder(),
                          hintText: "VD: Vietnam, China...",
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                TextFormField(
                  controller: _noteCtrl,
                  decoration: InputDecoration(labelText: l10n.note, border: const OutlineInputBorder()),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate() && _selectedMaterial != null) {
              final newDetail = MaterialReceiptDetail(
                detailId: widget.detail?.detailId,
                materialId: _selectedMaterial!.id,
                material: _selectedMaterial, 
                poQuantityKg: double.tryParse(_poQtyKgCtrl.text) ?? 0,
                receivedQuantityKg: double.tryParse(_receivedQtyKgCtrl.text) ?? 0,
                poQuantityCones: int.tryParse(_poQtyConesCtrl.text) ?? 0,
                receivedQuantityCones: int.tryParse(_receivedQtyConesCtrl.text) ?? 0,
                numberOfPallets: int.tryParse(_palletsCtrl.text) ?? 0,
                supplierBatchNo: _batchCtrl.text,
                originCountry: _originCtrl.text,
                note: _noteCtrl.text,
                location: _locationCtrl.text, 
              );
              Navigator.pop(context, newDetail);
            }
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}