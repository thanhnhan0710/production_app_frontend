import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';

// Import Models & Cubits
import '../../domain/purchase_order_model.dart';
import '../bloc/purchase_order_cubit.dart';
import '../../../material/domain/material_model.dart';
import '../../../material/presentation/bloc/material_cubit.dart' as mat_bloc;
import '../../../unit/domain/unit_model.dart';
import '../../../unit/presentation/bloc/unit_cubit.dart';
import '../../../supplier/domain/supplier_model.dart';
import '../../../supplier/presentation/bloc/supplier_cubit.dart';

// L10n
import '../../../../../l10n/app_localizations.dart';

class CreatePurchaseOrderScreen extends StatefulWidget {
  final PurchaseOrderHeader? existingPO;

  const CreatePurchaseOrderScreen({super.key, this.existingPO});

  @override
  State<CreatePurchaseOrderScreen> createState() => _CreatePurchaseOrderScreenState();
}

class _CreatePurchaseOrderScreenState extends State<CreatePurchaseOrderScreen> {
  // Controllers
  final _poNumberCtrl = TextEditingController();
  final _currencyCtrl = TextEditingController(text: 'VND');
  final _rateCtrl = TextEditingController(text: '1');
  final _noteCtrl = TextEditingController();

  // State Header
  int? _selectedVendorId;
  DateTime _selectedDate = DateTime.now();
  DateTime? _selectedEta;
  IncotermType _selectedIncoterm = IncotermType.EXW;
  POStatus _selectedStatus = POStatus.Draft;

  // State Details
  List<PurchaseOrderDetail> _tempDetails = [];

  // Formatter
  final _currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '');
  final _vndFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
  final _dateFormat = DateFormat('dd/MM/yyyy');
  final _formKey = GlobalKey<FormState>();

  bool get _isEditMode => widget.existingPO != null;

  // Cờ đánh dấu
  bool _hasUnsavedChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    context.read<SupplierCubit>().loadSuppliers();
    context.read<mat_bloc.MaterialCubit>().loadMaterials();
    context.read<UnitCubit>().loadUnits();

    if (_isEditMode) {
      _initEditData();
    } else {
      _initCreateData();
    }
  }

  void _initEditData() {
    final po = widget.existingPO!;
    _poNumberCtrl.text = po.poNumber;
    _currencyCtrl.text = po.currency;
    _rateCtrl.text = po.exchangeRate.toString();
    _noteCtrl.text = po.note ?? '';

    _selectedVendorId = po.vendorId;
    _selectedDate = po.orderDate;
    _selectedEta = po.expectedArrivalDate;
    _selectedIncoterm = po.incoterm;
    _selectedStatus = po.status;

    _tempDetails = List.from(po.details);
  }

  void _initCreateData() {
    context.read<PurchaseOrderCubit>().fetchNextPONumber().then((val) {
      if (mounted && val.isNotEmpty) {
        setState(() {
          _poNumberCtrl.text = val;
        });
      }
    });
  }

  void _markAsDirty() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  double get _exchangeRate {
    double? rate = double.tryParse(_rateCtrl.text.replaceAll(',', ''));
    return (rate != null && rate > 0) ? rate : 1.0;
  }

  double get _totalAmount => _tempDetails.fold(0, (sum, item) => sum + item.lineTotal);

  double get _totalAmountVND => _totalAmount * _exchangeRate;

  // Auto-save logic
  Future<void> _handleAutoSaveAndExit() async {
    if (!_hasUnsavedChanges || _isSaving) return;

    if (_selectedVendorId == null) {
      debugPrint('Auto-save skipped: Missing Vendor');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _saveDataInternal(status: _selectedStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("Auto-saved draft successfully"), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      debugPrint("Auto-save failed: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _hasUnsavedChanges = false;
        });
      }
    }
  }

  Future<void> _saveDataInternal({required POStatus status}) async {
    final newPO = PurchaseOrderHeader(
      poId: _isEditMode ? widget.existingPO!.poId : 0,
      poNumber: _poNumberCtrl.text,
      vendorId: _selectedVendorId!,
      orderDate: _selectedDate,
      expectedArrivalDate: _selectedEta,
      incoterm: _selectedIncoterm,
      currency: _currencyCtrl.text,
      exchangeRate: _exchangeRate,
      status: status,
      note: _noteCtrl.text,
      totalAmount: _totalAmount,
      details: _tempDetails,
    );

    await context.read<PurchaseOrderCubit>().savePurchaseOrder(po: newPO, isEdit: _isEditMode);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false, 
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_hasUnsavedChanges) {
           await _handleAutoSaveAndExit();
        }
        if (context.mounted) {
          Navigator.of(context).pop(result);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: Text(_isEditMode ? "Edit Purchase Order" : l10n.createPO),
          backgroundColor: const Color(0xFF003366),
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            if (_hasUnsavedChanges)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Center(child: Text("Unsaved", style: TextStyle(fontSize: 10, color: Colors.orangeAccent))),
              ),
            TextButton.icon(
              onPressed: () => _submitOrder(context, l10n),
              icon: const Icon(Icons.save, color: Colors.white),
              label: Text(l10n.save, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildHeaderForm(l10n),

              Expanded(
                child: Container(
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${l10n.orderItems} (${_tempDetails.length})",
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF003366)),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _showAddItemDialog(context, l10n),
                              icon: const Icon(Icons.add, size: 16),
                              label: Text(l10n.addItem),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE3F2FD),
                                foregroundColor: const Color(0xFF0055AA),
                                elevation: 0,
                              ),
                            )
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: _tempDetails.isEmpty
                            ? _buildEmptyState(l10n)
                            : ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: _tempDetails.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  return _buildTempDetailItem(index, _tempDetails[index], l10n);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- FOOTER TOTAL ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.totalAmount, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "${_currencyFormat.format(_totalAmount)} ${_currencyCtrl.text}",
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF003366)),
                        ),
                        if (_currencyCtrl.text.toUpperCase() != 'VND')
                          Text(
                            "≈ ${_vndFormat.format(_totalAmountVND)}",
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic),
                          ),
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderForm(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _poNumberCtrl,
                  decoration: _inputDeco(l10n.poNumber, icon: Icons.tag),
                  validator: (v) => v!.isEmpty ? l10n.required : null,
                  readOnly: _isEditMode,
                  onChanged: (_) => _markAsDirty(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: BlocBuilder<SupplierCubit, SupplierState>(
                  builder: (context, state) {
                    List<Supplier> suppliers = (state is SupplierLoaded) ? state.suppliers : [];
                    return DropdownSearch<Supplier>(
                      items: (filter, loadProps) {
                        if (filter.isEmpty) return suppliers;
                        return suppliers.where((s) => s.name.toLowerCase().contains(filter.toLowerCase())).toList();
                      },
                      itemAsString: (Supplier s) => s.name,
                      selectedItem: suppliers.any((s) => s.id == _selectedVendorId)
                          ? suppliers.firstWhere((s) => s.id == _selectedVendorId)
                          : null,
                      compareFn: (i, s) => i.id == s.id,
                      decoratorProps: DropDownDecoratorProps(
                        decoration: _inputDeco(l10n.vendor, icon: Icons.store),
                      ),
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        searchFieldProps: TextFieldProps(
                          decoration: InputDecoration(
                            hintText: "Search vendor...",
                            prefixIcon: const Icon(Icons.search),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        itemBuilder: (ctx, item, isDisabled, isSelected) {
                          return ListTile(
                            title: Text(item.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                            subtitle: Text(item.shortName ?? ''),
                            selected: isSelected,
                            selectedTileColor: Colors.blue.withOpacity(0.1),
                          );
                        },
                        menuProps: MenuProps(borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (Supplier? data) {
                        setState(() {
                          _selectedVendorId = data?.id;
                          _markAsDirty();
                        });
                      },
                      validator: (Supplier? item) => item == null ? l10n.required : null,
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context, false),
                  child: InputDecorator(
                    decoration: _inputDeco(l10n.orderDate, icon: Icons.calendar_today),
                    child: Text(_dateFormat.format(_selectedDate)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context, true),
                  child: InputDecorator(
                    decoration: _inputDeco("ETA", icon: Icons.local_shipping),
                    child: Text(_selectedEta != null ? _dateFormat.format(_selectedEta!) : "--/--"),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<IncotermType>(
                  value: _selectedIncoterm,
                  decoration: _inputDeco(l10n.incoterm, icon: Icons.handshake),
                  items: IncotermType.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(),
                  onChanged: (val) {
                    setState(() => _selectedIncoterm = val!);
                    _markAsDirty();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                // Dropdown chọn Status
                child: DropdownButtonFormField<POStatus>(
                  value: _selectedStatus,
                  decoration: _inputDeco("Status", icon: Icons.flag),
                  items: POStatus.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(),
                  onChanged: (val) {
                    setState(() => _selectedStatus = val!);
                    _markAsDirty();
                  },
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
                  controller: _currencyCtrl,
                  decoration: _inputDeco(l10n.currency, icon: Icons.attach_money),
                  onChanged: (_) {
                    setState(() {});
                    _markAsDirty();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _rateCtrl,
                  decoration: _inputDeco(l10n.exchangeRate, icon: Icons.currency_exchange),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) {
                    setState(() {});
                    _markAsDirty();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _noteCtrl,
            decoration: _inputDeco(l10n.note, icon: Icons.note),
            maxLines: 1,
            onChanged: (_) => _markAsDirty(),
          ),
        ],
      ),
    );
  }

  // [UPDATED] Hiển thị chi tiết item trong danh sách
  Widget _buildTempDetailItem(int index, PurchaseOrderDetail item, AppLocalizations l10n) {
    double convertedLineTotal = item.lineTotal * _exchangeRate;
    
    // Đơn vị tính giá để hiển thị
    String pricingUnitStr = item.isPricingByRoll ? "Roll" : (item.uom?.name ?? 'Unit');

    return Dismissible(
      key: ValueKey(item.hashCode),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.redAccent,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        setState(() {
          _tempDetails.removeAt(index);
          _markAsDirty();
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
              child: Text("${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.material?.materialCode ?? "Item",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    "${item.material?.materialType ?? ''} • ${item.material?.specDenier ?? ''}",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${_currencyFormat.format(item.lineTotal)} ${_currencyCtrl.text}",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003366)),
                ),
                if (_currencyCtrl.text.toUpperCase() != 'VND')
                  Text(
                    "≈ ${_vndFormat.format(convertedLineTotal)}",
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                  ),
                const SizedBox(height: 2),
                
                // Hiển thị chi tiết số lượng
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${_currencyFormat.format(item.quantity)} ${item.uom?.name ?? 'Unit'}",
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    if (item.quantityRolls > 0)
                      Text(
                        " (${item.quantityRolls} rolls)",
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                      ),
                  ],
                ),
                // Hiển thị đơn giá theo đơn vị tính đã chọn
                Text(
                  "@ ${_currencyFormat.format(item.unitPrice)} / $pricingUnitStr",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
              onPressed: () {
                setState(() {
                  _tempDetails.removeAt(index);
                  _markAsDirty();
                });
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_shopping_cart, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(l10n.noItemsPO, style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, size: 18, color: Colors.grey) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      isDense: true,
    );
  }

  Future<void> _selectDate(BuildContext context, bool isEta) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isEta ? (_selectedEta ?? DateTime.now()) : _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isEta) {
          _selectedEta = picked;
        } else {
          _selectedDate = picked;
        }
        _markAsDirty();
      });
    }
  }

  // --- DIALOG THÊM CHI TIẾT ---
  void _showAddItemDialog(BuildContext context, AppLocalizations l10n) {
    int? selectedMaterialId;
    int? selectedUomId;
    MaterialModel? selectedMaterial;
    ProductUnit? selectedUom;

    final qtyCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final rollsCtrl = TextEditingController(text: '0'); 
    
    // [NEW] Biến chọn cách tính giá
    bool isPricePerRoll = false; 

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          
          double qty = double.tryParse(qtyCtrl.text) ?? 0;
          double rolls = double.tryParse(rollsCtrl.text) ?? 0;
          double price = double.tryParse(priceCtrl.text) ?? 0;
          
          // [NEW] Logic tính tổng tiền dựa trên lựa chọn
          double total = isPricePerRoll ? (rolls * price) : (qty * price);
          double totalVND = total * _exchangeRate;

          // Xác định label đơn vị tiền tệ
          String unitLabel = isPricePerRoll ? " / Roll" : " / Unit";

          return AlertDialog(
            title: Text(l10n.addItem),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BlocBuilder<mat_bloc.MaterialCubit, mat_bloc.MaterialState>(
                      builder: (context, state) {
                        List<MaterialModel> materials = (state is mat_bloc.MaterialLoaded) ? state.materials : [];
                        return InkWell(
                          onTap: () async {
                            final result = await _showMaterialSearch(context, materials, l10n);
                            if (result != null) {
                              setStateDialog(() {
                                selectedMaterial = result;
                                selectedMaterialId = result.id;
                                selectedUomId = result.uomBaseId; 
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: _inputDeco(l10n.materialInfo, icon: Icons.search),
                            child: Text(selectedMaterial?.materialCode ?? l10n.tapToSearch, 
                              style: TextStyle(color: selectedMaterial == null ? Colors.grey : Colors.black)
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: qtyCtrl,
                                decoration: _inputDeco("Số lượng (Kg)"),
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setStateDialog((){}), 
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: rollsCtrl,
                                decoration: _inputDeco("Số cuộn (Rolls)"),
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setStateDialog((){}), 
                              ),
                              const SizedBox(height: 12),
                              BlocBuilder<UnitCubit, UnitState>(
                                builder: (context, state) {
                                  List<ProductUnit> units = (state is UnitLoaded) ? state.units : [];
                                  if (selectedUomId != null && units.isNotEmpty) {
                                    selectedUom = units.firstWhere((u) => u.id == selectedUomId, orElse: () => units.first);
                                  }
                                  return DropdownButtonFormField<int>(
                                    value: selectedUomId,
                                    decoration: _inputDeco("Tính giá theo"),
                                    items: units.map((u) => DropdownMenuItem(value: u.id, child: Text(u.name))).toList(),
                                    onChanged: (val) => setStateDialog(() => selectedUomId = val),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: priceCtrl,
                                keyboardType: TextInputType.number,
                                decoration: _inputDeco(l10n.unitPrice, icon: Icons.attach_money),
                                onChanged: (_) => setStateDialog((){}),
                              ),
                              const SizedBox(height: 8),
                              
                              // [NEW] Switch chọn cách tính giá
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text("Tính theo Cuộn?", style: TextStyle(fontSize: 13, color: Colors.grey.shade800, fontWeight: FontWeight.w500)),
                                subtitle: Text(isPricePerRoll ? "Giá áp dụng cho 1 Cuộn" : "Giá áp dụng cho 1 Đơn vị (Kg)", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                value: isPricePerRoll,
                                onChanged: (val) => setStateDialog(() => isPricePerRoll = val),
                                activeColor: const Color(0xFF003366),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Hiển thị tổng tiền tạm tính
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Thành tiền:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(isPricePerRoll ? "${rolls.toInt()} rolls x $price" : "$qty ${selectedUom?.name ?? 'unit'} x $price", style: TextStyle(fontSize: 11, color: Colors.grey.shade600))
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text("${_currencyFormat.format(total)} ${_currencyCtrl.text}", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
                              if (_currencyCtrl.text != 'VND')
                                Text("≈ ${_vndFormat.format(totalVND)}", style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
              ElevatedButton(
                onPressed: () {
                  if (selectedMaterialId != null && qtyCtrl.text.isNotEmpty) {
                    final qty = double.tryParse(qtyCtrl.text) ?? 0;
                    final price = double.tryParse(priceCtrl.text) ?? 0;
                    final rolls = int.tryParse(rollsCtrl.text) ?? 0;
                    
                    // Tính lại lineTotal chính xác
                    final lineTotal = isPricePerRoll ? (rolls * price) : (qty * price);

                    final newItem = PurchaseOrderDetail(
                      poId: _isEditMode ? widget.existingPO!.poId : 0,
                      materialId: selectedMaterialId!,
                      quantity: qty,
                      quantityRolls: rolls,
                      unitPrice: price,
                      lineTotal: lineTotal,
                      uomId: selectedUomId,
                      material: selectedMaterial,
                      uom: selectedUom,
                      isPricingByRoll: isPricePerRoll, // [NEW] Lưu lựa chọn
                    );

                    setState(() {
                      _tempDetails.add(newItem);
                      _markAsDirty();
                    });
                    Navigator.pop(ctx);
                  }
                },
                child: Text(l10n.confirmAdd),
              )
            ],
          );
        });
      },
    );
  }

  Future<MaterialModel?> _showMaterialSearch(BuildContext context, List<MaterialModel> list, AppLocalizations l10n) async {
    return showDialog<MaterialModel>(
      context: context,
      builder: (ctx) {
        List<MaterialModel> filtered = List.from(list);
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.searchMaterial),
              content: SizedBox(
                width: 500, height: 400,
                child: Column(
                  children: [
                    TextField(
                      autofocus: true,
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: "Search code..."),
                      onChanged: (val) {
                        setState(() {
                          if (val.isEmpty) {
                            filtered = List.from(list);
                          } else {
                            final k = val.toLowerCase();
                            filtered = list.where((m) => 
                              m.materialCode.toLowerCase().contains(k) ||
                              (m.materialType?.toLowerCase().contains(k) ?? false)
                            ).toList();
                          }
                        });
                      },
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) => ListTile(
                          title: Text(filtered[i].materialCode),
                          subtitle: Text(filtered[i].materialType ?? ''),
                          onTap: () => Navigator.pop(ctx, filtered[i]),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.close))
              ],
            );
          },
        );
      },
    );
  }

  void _submitOrder(BuildContext context, AppLocalizations l10n) {
    if (_formKey.currentState!.validate() && _selectedVendorId != null) {
      if (_tempDetails.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please add at least one item"), backgroundColor: Colors.orange));
        return;
      }
      
      setState(() {
        _hasUnsavedChanges = false; 
      });

      _saveDataInternal(status: _selectedStatus); // Lưu theo status đang chọn

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.processing), backgroundColor: Colors.blue));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${l10n.required}: Vendor"), backgroundColor: Colors.red));
    }
  }
}