import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart'; 

// Models & Cubits
import '../../domain/bom_model.dart';
import '../bloc/bom_cubit.dart';
import '../../../product/domain/product_model.dart';
import '../../../product/presentation/bloc/product_cubit.dart';
import '../../../material/domain/material_model.dart';
import '../../../material/presentation/bloc/material_cubit.dart' as mat_bloc;

// L10n
import '../../../../../l10n/app_localizations.dart';

class CreateBOMScreen extends StatefulWidget {
  final BOMHeader? existingBOM; // Nếu null là tạo mới

  const CreateBOMScreen({super.key, this.existingBOM});

  @override
  State<CreateBOMScreen> createState() => _CreateBOMScreenState();
}

class _CreateBOMScreenState extends State<CreateBOMScreen> {
  final _formKey = GlobalKey<FormState>();

  // --- Header Controllers ---
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _targetWeightCtrl = TextEditingController(text: "0.0");
  final _widthCtrl = TextEditingController();
  final _picksCtrl = TextEditingController();
  final _scrapRateCtrl = TextEditingController(text: "0.0");
  final _shrinkageRateCtrl = TextEditingController(text: "0.0");
  final _versionCtrl = TextEditingController(text: "1");

  int? _selectedProductId;
  bool _isActive = true;

  // --- Details List (Local State) ---
  List<BOMDetail> _tempDetails = [];

  @override
  void initState() {
    super.initState();
    // Load data cần thiết
    context.read<ProductCubit>().loadProducts();
    context.read<mat_bloc.MaterialCubit>().loadMaterials();

    if (widget.existingBOM != null) {
      _initEditData(widget.existingBOM!);
    }
  }

  void _initEditData(BOMHeader bom) {
    _selectedProductId = bom.productId;
    _codeCtrl.text = bom.bomCode;
    _nameCtrl.text = bom.bomName;
    _targetWeightCtrl.text = bom.targetWeightGm.toString();
    _widthCtrl.text = bom.widthBehindLoom?.toString() ?? "";
    _picksCtrl.text = bom.picks?.toString() ?? "";
    _scrapRateCtrl.text = bom.totalScrapRate.toString();
    _shrinkageRateCtrl.text = bom.totalShrinkageRate.toString();
    _versionCtrl.text = bom.version.toString();
    _isActive = bom.isActive;
    
    // Copy list để chỉnh sửa không ảnh hưởng data gốc ngay
    _tempDetails = List.from(bom.bomDetails);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(widget.existingBOM == null ? l10n.newBOM : l10n.editBOM),
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: () => _submitBOM(context, l10n),
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
            // 1. HEADER INFO
            _buildHeaderForm(l10n),

            // 2. DETAILS LIST
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
                          // [FIX] Thay l10n.bomComponents bằng text cứng
                          Text(
                            "Components (${_tempDetails.length})", 
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF003366))
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _showAddComponentDialog(context, null, l10n),
                            icon: const Icon(Icons.add, size: 16),
                            // [FIX] Thay l10n.addComponent bằng text cứng
                            label: const Text("Add Component"), 
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
                        ? Center(child: Text(l10n.noItemsPO, style: const TextStyle(color: Colors.grey))) 
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _tempDetails.length,
                            separatorBuilder: (_,__) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              return _buildDetailItem(index, _tempDetails[index], l10n);
                            },
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildHeaderForm(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white,
      child: Column(
        children: [
          // Row 1: Product & Code
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: BlocBuilder<ProductCubit, ProductState>(
                  builder: (context, state) {
                    List<Product> products = [];
                    if (state is ProductLoaded) products = state.products;
                    
                    return DropdownSearch<Product>(
                      items: (filter, props) {
                         if (filter.isEmpty) return products;
                         return products.where((p) => p.itemCode.toLowerCase().contains(filter.toLowerCase())).toList();
                      },
                      itemAsString: (Product p) => p.itemCode,
                      selectedItem: products.any((p) => p.id == _selectedProductId) 
                          ? products.firstWhere((p) => p.id == _selectedProductId) 
                          : null,
                      compareFn: (i, s) => i.id == s.id,
                      decoratorProps: DropDownDecoratorProps(
                        decoration: _inputDeco(l10n.product, icon: Icons.inventory_2),
                      ),
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        itemBuilder: (ctx, item, isDisabled, isSelected) => ListTile(
                          title: Text(item.itemCode, style: const TextStyle(fontWeight: FontWeight.bold)),
                          // [FIX] Bỏ subtitle itemName vì model không có, hoặc dùng itemCode
                          // subtitle: Text(item.itemName ?? ''), 
                          selected: isSelected,
                        ),
                      ),
                      onChanged: (p) => setState(() => _selectedProductId = p?.id),
                      validator: (p) => p == null ? l10n.required : null,
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _codeCtrl,
                  decoration: _inputDeco(l10n.bomCode, icon: Icons.tag),
                  validator: (v) => v!.isEmpty ? l10n.required : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 2: Name & Target Weight
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _nameCtrl,
                  decoration: _inputDeco(l10n.bomName, icon: Icons.description),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _targetWeightCtrl,
                  decoration: _inputDeco("Target (g/m)", icon: Icons.scale),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 3: Technical Specs
          Row(
            children: [
              Expanded(child: TextFormField(controller: _widthCtrl, decoration: _inputDeco("Width (mm)"), keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(controller: _picksCtrl, decoration: _inputDeco("Picks"), keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(controller: _scrapRateCtrl, decoration: _inputDeco("Scrap %"), keyboardType: TextInputType.number)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(int index, BOMDetail item, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade50,
          child: Text(item.componentType.name[0].toUpperCase(), 
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
        ),
        title: Text(item.yarnTypeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(
          "${item.componentType.name} | ${item.threads} ends | ${item.yarnDtex.toInt()} dtex",
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12)
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.orange, size: 20),
              onPressed: () => _showAddComponentDialog(context, index, l10n),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: () {
                setState(() {
                  _tempDetails.removeAt(index);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- DIALOG ADD/EDIT COMPONENT ---
  void _showAddComponentDialog(BuildContext context, int? index, AppLocalizations l10n) {
    final isEdit = index != null;
    final existingItem = isEdit ? _tempDetails[index] : null;

    int? selectedMatId = existingItem?.materialId;
    BOMComponentType selectedType = existingItem?.componentType ?? BOMComponentType.ground;
    
    final yarnNameCtrl = TextEditingController(text: existingItem?.yarnTypeName ?? '');
    final threadsCtrl = TextEditingController(text: existingItem?.threads.toString() ?? '0');
    final twistCtrl = TextEditingController(text: existingItem?.twisted.toString() ?? '1.0');
    final lenCtrl = TextEditingController(text: existingItem?.actualLengthCm.toString() ?? '10.0');
    final crossCtrl = TextEditingController(text: existingItem?.crossweaveRate.toString() ?? '0.0');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              // [FIX] Thay l10n.addComponent bằng text cứng
              title: Text(isEdit ? "Edit Component" : "Add Component"),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Type
                      DropdownButtonFormField<BOMComponentType>(
                        value: selectedType,
                        decoration: _inputDeco("Type"),
                        items: BOMComponentType.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(),
                        onChanged: (v) => setStateDialog(() => selectedType = v!),
                      ),
                      const SizedBox(height: 12),

                      // Material Select
                      BlocBuilder<mat_bloc.MaterialCubit, mat_bloc.MaterialState>(
                        builder: (context, state) {
                          List<MaterialModel> materials = [];
                          if (state is mat_bloc.MaterialLoaded) materials = state.materials;
                          
                          return DropdownSearch<MaterialModel>(
                            items: (filter, props) {
                               if (filter.isEmpty) return materials;
                               return materials.where((m) => m.materialCode.toLowerCase().contains(filter.toLowerCase())).toList();
                            },
                            itemAsString: (m) => m.materialCode,
                            selectedItem: materials.where((m) => m.id == selectedMatId).firstOrNull,
                            compareFn: (i, s) => i.id == s.id,
                            decoratorProps: DropDownDecoratorProps(
                              decoration: _inputDeco("Material", icon: Icons.search),
                            ),
                            popupProps: PopupProps.menu(
                              showSearchBox: true,
                              itemBuilder: (ctx, item, isDisabled, isSelected) => ListTile(
                                title: Text(item.materialCode, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text("${item.specDenier ?? '-'} / ${item.specFilament ?? '-'}"),
                                selected: isSelected,
                              ),
                            ),
                            onChanged: (m) {
                              if (m != null) {
                                setStateDialog(() {
                                  selectedMatId = m.id;
                                  // Auto-fill tên sợi từ Material
                                  yarnNameCtrl.text = "${m.materialCode} ${m.specDenier ?? ''}";
                                });
                              }
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: yarnNameCtrl,
                        decoration: _inputDeco("Yarn Name / Code"),
                      ),
                      const SizedBox(height: 12),

                      Row(children: [
                        Expanded(child: TextFormField(controller: threadsCtrl, decoration: _inputDeco("Threads"), keyboardType: TextInputType.number)),
                        const SizedBox(width: 12),
                        Expanded(child: TextFormField(controller: twistCtrl, decoration: _inputDeco("Twist"), keyboardType: TextInputType.number)),
                      ]),
                      const SizedBox(height: 12),
                      
                      Row(children: [
                        Expanded(child: TextFormField(controller: lenCtrl, decoration: _inputDeco("Length (cm)"), keyboardType: TextInputType.number)),
                        const SizedBox(width: 12),
                        Expanded(child: TextFormField(controller: crossCtrl, decoration: _inputDeco("Crossweave"), keyboardType: TextInputType.number)),
                      ]),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
                ElevatedButton(
                  onPressed: () {
                    if (yarnNameCtrl.text.isNotEmpty) {
                      final newItem = BOMDetail(
                        detailId: existingItem?.detailId ?? 0, // Giữ ID nếu edit
                        bomId: widget.existingBOM?.bomId ?? 0,
                        materialId: selectedMatId ?? 1, // Default 1
                        componentType: selectedType,
                        threads: int.tryParse(threadsCtrl.text) ?? 0,
                        yarnTypeName: yarnNameCtrl.text,
                        twisted: double.tryParse(twistCtrl.text) ?? 1.0,
                        actualLengthCm: double.tryParse(lenCtrl.text) ?? 0.0,
                        crossweaveRate: double.tryParse(crossCtrl.text) ?? 0.0,
                        note: "",
                        // Các trường tính toán để 0, server sẽ tính lại
                        yarnDtex: 0, weightPerYarnGm: 0, actualWeightCal: 0, weightPercentage: 0, bomGm: 0,
                      );

                      setState(() {
                        if (isEdit) {
                          _tempDetails[index] = newItem;
                        } else {
                          _tempDetails.add(newItem);
                        }
                      });
                      Navigator.pop(ctx);
                    }
                  },
                  child: Text(isEdit ? l10n.save : l10n.addBOM),
                )
              ],
            );
          }
        );
      }
    );
  }

  void _submitBOM(BuildContext context, AppLocalizations l10n) {
    if (_formKey.currentState!.validate() && _selectedProductId != null) {
      final newBOM = BOMHeader(
        bomId: widget.existingBOM?.bomId ?? 0,
        productId: _selectedProductId!,
        bomCode: _codeCtrl.text,
        bomName: _nameCtrl.text,
        targetWeightGm: double.tryParse(_targetWeightCtrl.text) ?? 0.0,
        widthBehindLoom: double.tryParse(_widthCtrl.text),
        picks: int.tryParse(_picksCtrl.text),
        totalScrapRate: double.tryParse(_scrapRateCtrl.text) ?? 0.0,
        totalShrinkageRate: double.tryParse(_shrinkageRateCtrl.text) ?? 0.0,
        version: int.tryParse(_versionCtrl.text) ?? 1,
        isActive: _isActive,
        bomDetails: _tempDetails, // Gửi kèm danh sách chi tiết
      );

      // Gọi Cubit lưu
      context.read<BOMCubit>().saveBOMHeader(bom: newBOM, isEdit: widget.existingBOM != null);
      
      Navigator.pop(context); // Quay về màn hình danh sách
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.productRequired), backgroundColor: Colors.red));
    }
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
}