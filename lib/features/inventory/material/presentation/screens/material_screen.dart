import 'package:flutter/material.dart' hide MaterialState;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:production_app_frontend/l10n/app_localizations.dart';
import 'package:production_app_frontend/core/widgets/responsive_layout.dart';

import '../../domain/material_model.dart';
import '../bloc/material_cubit.dart';

// [QUAN TRỌNG] Import Unit Feature để dùng cho Dropdown
import 'package:production_app_frontend/features/inventory/unit/presentation/bloc/unit_cubit.dart';
// ignore: unused_import
import 'package:production_app_frontend/features/inventory/unit/domain/unit_model.dart' as inventory;

class MaterialScreen extends StatefulWidget {
  const MaterialScreen({super.key});

  @override
  State<MaterialScreen> createState() => _MaterialScreenState();
}

class _MaterialScreenState extends State<MaterialScreen> {
  final _searchController = TextEditingController();
  final Color _primaryColor = const Color(0xFF003366);
  final Color _accentColor = const Color(0xFFC2185B);
  final Color _bgLight = const Color(0xFFF5F7FA);

  // Danh sách loại vật tư gợi ý
  final List<String> _typeOptions = const ['Polyester', 'Nylon', 'Polypropylene', 'Cotton', 'Chemical'];

  @override
  void initState() {
    super.initState();
    context.read<MaterialCubit>().loadMaterials();
    // Load danh sách đơn vị tính để dùng cho Dialog
    context.read<UnitCubit>().loadUnits();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: _bgLight,
      body: BlocBuilder<MaterialCubit, MaterialState>(
        builder: (context, state) {
          int total = 0;
          if (state is MaterialLoaded) total = state.materials.length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- HEADER ---
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
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.category, color: Colors.purple.shade800, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.materialMaster, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                            const SizedBox(height: 2),
                            Text(l10n.materialBreadcrumb, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                          ],
                        ),
                        const Spacer(),
                        if (isDesktop)
                          ElevatedButton.icon(
                            onPressed: () => _showEditDialog(context, null, l10n),
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(l10n.addMaterial.toUpperCase()),
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
                    // Search Bar
                    Row(
                      children: [
                        if (isDesktop) ...[
                          _buildStatBadge(Icons.grid_view, l10n.totalMaterials, "$total", Colors.blue),
                          const SizedBox(width: 16),
                          const Spacer(),
                        ],
                        Expanded(
                          flex: isDesktop ? 0 : 1,
                          child: Container(
                            width: isDesktop ? 350 : double.infinity,
                            decoration: BoxDecoration(color: _bgLight, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                            child: TextField(
                              controller: _searchController,
                              textInputAction: TextInputAction.search,
                              decoration: InputDecoration(
                                hintText: l10n.searchMaterialHint,
                                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 20),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.arrow_forward, color: Colors.blue),
                                  onPressed: () => context.read<MaterialCubit>().searchMaterials(_searchController.text),
                                ),
                              ),
                              onSubmitted: (value) => context.read<MaterialCubit>().searchMaterials(value),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                          child: const Icon(Icons.filter_list, color: Colors.grey, size: 20),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: Colors.grey.shade200),

              // --- CONTENT ---
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (state is MaterialLoading) return Center(child: CircularProgressIndicator(color: _primaryColor));
                    if (state is MaterialError) return Center(child: Text("${l10n.errorGeneric}: ${state.message}", style: const TextStyle(color: Colors.red)));
                    if (state is MaterialLoaded) {
                      if (state.materials.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text(l10n.noMaterialFound, style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                        );
                      }
                      return isDesktop
                          ? _buildDesktopTable(context, state.materials, l10n)
                          : _buildMobileList(context, state.materials, l10n);
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
              onPressed: () => _showEditDialog(context, null, l10n),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  // --- DESKTOP TABLE ---
  Widget _buildDesktopTable(BuildContext context, List<MaterialModel> materials, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(const Color(0xFFF9FAFB)),
                    horizontalMargin: 24,
                    columnSpacing: 24,
                    dataRowMinHeight: 60,
                    dataRowMaxHeight: 60,
                    columns: [
                      _buildColHeader(l10n.materialCode),
                      _buildColHeader(l10n.materialName),
                      _buildColHeader(l10n.materialType),
                      _buildColHeader(l10n.specs),
                      _buildColHeader(l10n.hsCode),
                      _buildColHeader(l10n.minStock),
                      _buildColHeader(l10n.uomBP),
                      _buildColHeader(l10n.actions),
                    ],
                    rows: materials.map((item) {
                      return DataRow(
                        cells: [
                          DataCell(Text(item.materialCode, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
                          DataCell(ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 200),
                            child: Text(item.materialName, overflow: TextOverflow.ellipsis),
                          )),
                          DataCell(_buildTypeBadge(item.materialType)),
                          DataCell(Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.specDenier ?? '-', style: const TextStyle(fontSize: 12)),
                              if (item.specFilament != null && item.specFilament! > 0)
                                Text("${item.specFilament}F", style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                            ],
                          )),
                          DataCell(Text(item.hsCode ?? '-', style: const TextStyle(fontSize: 13))),
                          DataCell(Text("${item.minStockLevel}", style: TextStyle(fontWeight: FontWeight.bold, color: item.minStockLevel > 0 ? Colors.black : Colors.grey))),
                          DataCell(Row(
                            children: [
                              _buildUomChip(item.uomBase?.name, Colors.blue),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_right_alt, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              _buildUomChip(item.uomProduction?.name, Colors.orange),
                            ],
                          )),
                          DataCell(Row(
                            children: [
                              IconButton(icon: const Icon(Icons.edit_note, color: Colors.grey), onPressed: () => _showEditDialog(context, item, l10n)),
                              IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _confirmDelete(context, item, l10n)),
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

  DataColumn _buildColHeader(String label) => DataColumn(label: Text(label.toUpperCase(), style: _headerStyle));
  TextStyle get _headerStyle => TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5);

  // --- MOBILE LIST ---
  Widget _buildMobileList(BuildContext context, List<MaterialModel> materials, AppLocalizations l10n) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: materials.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = materials[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade50,
              child: Text(item.materialCode.substring(0, 1), style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold)),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(item.materialCode, style: const TextStyle(fontWeight: FontWeight.bold))),
                _buildTypeBadge(item.materialType, isChip: true),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(item.materialName, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.layers, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text("${item.specDenier ?? '-'} / ${item.specFilament ?? '-'}F", style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                    const Spacer(),
                    _buildUomChip(item.uomBase?.name, Colors.blue),
                  ],
                )
              ],
            ),
            onTap: () => _showEditDialog(context, item, l10n),
          ),
        );
      },
    );
  }

  // --- EDIT DIALOG ---
  void _showEditDialog(BuildContext context, MaterialModel? item, AppLocalizations l10n) {
    final codeCtrl = TextEditingController(text: item?.materialCode ?? '');
    final nameCtrl = TextEditingController(text: item?.materialName ?? '');
    final denierCtrl = TextEditingController(text: item?.specDenier ?? '');
    final filamentCtrl = TextEditingController(text: item?.specFilament?.toString() ?? '');
    final hsCtrl = TextEditingController(text: item?.hsCode ?? '');
    final minStockCtrl = TextEditingController(text: item?.minStockLevel.toString() ?? '0');

    String? selectedType = item?.materialType;
    int? selectedUomBase = item?.uomBaseId;
    int? selectedUomProd = item?.uomProductionId;

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              titlePadding: const EdgeInsets.all(24),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              title: Text(item == null ? l10n.addMaterial : l10n.editMaterial, style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
              content: Form(
                key: formKey,
                child: SizedBox(
                  width: 600, 
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Row 1: Code & Name
                        Row(
                          children: [
                            Expanded(child: TextFormField(controller: codeCtrl, decoration: _inputDeco("${l10n.materialCode} *"), validator: (v) => v!.isEmpty ? l10n.required : null)),
                            const SizedBox(width: 12),
                            Expanded(flex: 2, child: TextFormField(controller: nameCtrl, decoration: _inputDeco("${l10n.materialName} *"), validator: (v) => v!.isEmpty ? l10n.required : null)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Row 2: Type & HS Code
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _typeOptions.contains(selectedType) ? selectedType : null,
                                decoration: _inputDeco(l10n.materialType),
                                items: _typeOptions.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                                onChanged: (val) => setStateDialog(() => selectedType = val),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: TextFormField(controller: hsCtrl, decoration: _inputDeco(l10n.hsCode))),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Row 3: Specs & Min Stock
                        Row(
                          children: [
                            Expanded(child: TextFormField(controller: denierCtrl, decoration: _inputDeco(l10n.denierHint))),
                            const SizedBox(width: 12),
                            Expanded(child: TextFormField(controller: filamentCtrl, decoration: _inputDeco(l10n.filament), keyboardType: TextInputType.number)),
                            const SizedBox(width: 12),
                            Expanded(child: TextFormField(controller: minStockCtrl, decoration: _inputDeco(l10n.minStock), keyboardType: TextInputType.number)),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Row 4: Units (Base & Production)
                        BlocBuilder<UnitCubit, UnitState>(
                          builder: (context, unitState) {
                            List<dynamic> units = [];
                            if (unitState is UnitLoaded) units = unitState.units;

                            List<DropdownMenuItem<int>> unitItems = units.map((u) {
                                return DropdownMenuItem<int>(
                                  value: u.id as int, 
                                  child: Text(u.name), 
                                );
                            }).toList();

                            return Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<int>(
                                    value: selectedUomBase == 0 ? null : selectedUomBase,
                                    decoration: _inputDeco("${l10n.uomBasePurchase} *"),
                                    items: unitItems,
                                    onChanged: (val) => setStateDialog(() => selectedUomBase = val),
                                    validator: (v) => v == null ? l10n.required : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonFormField<int>(
                                    value: selectedUomProd == 0 ? null : selectedUomProd,
                                    decoration: _inputDeco("${l10n.uomProduction} *"),
                                    items: unitItems,
                                    onChanged: (val) => setStateDialog(() => selectedUomProd = val),
                                    validator: (v) => v == null ? l10n.required : null,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.all(24),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey))),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final newItem = MaterialModel(
                        id: item?.id ?? 0,
                        materialCode: codeCtrl.text,
                        materialName: nameCtrl.text,
                        materialType: selectedType,
                        specDenier: denierCtrl.text,
                        specFilament: int.tryParse(filamentCtrl.text),
                        hsCode: hsCtrl.text,
                        minStockLevel: double.tryParse(minStockCtrl.text) ?? 0.0,
                        uomBaseId: selectedUomBase!,
                        uomProductionId: selectedUomProd!,
                      );
                      context.read<MaterialCubit>().saveMaterial(material: newItem, isEdit: item != null);
                      Navigator.pop(ctx);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: Text(l10n.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDeco(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      isDense: true,
    );
  }

  Widget _buildStatBadge(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        ])
      ]),
    );
  }

  Widget _buildTypeBadge(String? type, {bool isChip = false}) {
    if (type == null || type.isEmpty) return const SizedBox();
    
    Color bg = Colors.grey.shade100;
    Color text = Colors.black87;

    if (type == 'Polyester') { bg = Colors.blue.shade50; text = Colors.blue.shade800; }
    else if (type == 'Nylon') { bg = Colors.orange.shade50; text = Colors.orange.shade800; }
    else if (type == 'Cotton') { bg = Colors.green.shade50; text = Colors.green.shade800; }

    if (isChip) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
        child: Text(type, style: TextStyle(color: text, fontSize: 10, fontWeight: FontWeight.bold)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(type, style: TextStyle(color: text, fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildUomChip(String? name, Color color) {
    if (name == null) return const SizedBox();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(4),
        color: color.withOpacity(0.05)
      ),
      child: Text(name, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
    );
  }

  void _confirmDelete(BuildContext context, MaterialModel item, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.delete), 
        content: Text(l10n.confirmDeleteMaterial(item.materialCode)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              context.read<MaterialCubit>().deleteMaterial(item.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}