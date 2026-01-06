import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:production_app_frontend/l10n/app_localizations.dart';
import 'package:production_app_frontend/core/widgets/responsive_layout.dart';

import '../../domain/standard_model.dart';
import '../bloc/standard_cubit.dart';

// Import related features
import 'package:production_app_frontend/features/inventory/product/domain/product_model.dart';
import 'package:production_app_frontend/features/inventory/product/presentation/bloc/product_cubit.dart';
import 'package:production_app_frontend/features/inventory/dye_color/domain/dye_color_model.dart';
import 'package:production_app_frontend/features/inventory/dye_color/presentation/bloc/dye_color_cubit.dart';

class StandardScreen extends StatefulWidget {
  const StandardScreen({super.key});

  @override
  State<StandardScreen> createState() => _StandardScreenState();
}

class _StandardScreenState extends State<StandardScreen> {
  final _searchController = TextEditingController();
  final Color _primaryColor = const Color(0xFF003366);
  final Color _accentColor = const Color(0xFF5D4037);
  final Color _bgLight = const Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    context.read<StandardCubit>().loadStandards();
    context.read<ProductCubit>().loadProducts();
    context.read<DyeColorCubit>().loadColors();
  }

  Color _hexToColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return Colors.grey;
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: _bgLight,
      body: BlocBuilder<StandardCubit, StandardState>(
        builder: (context, state) {
          int total = 0;
          if (state is StandardLoaded) total = state.standards.length;

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
                            color: Colors.brown.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.assignment, color: Colors.brown.shade800, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.standardTitle, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                            const SizedBox(height: 2),
                            Text("Production > Quality Control", style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                          ],
                        ),
                        const Spacer(),
                        if (isDesktop)
                          ElevatedButton.icon(
                            onPressed: () => _showEditDialog(context, null, l10n),
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(l10n.addStandard.toUpperCase()),
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
                          _buildStatBadge(Icons.grid_view, "Total Standards", "$total", Colors.blue),
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
                                hintText: l10n.searchStandard,
                                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 20),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.arrow_forward, color: Colors.blue),
                                  onPressed: () => context.read<StandardCubit>().searchStandards(_searchController.text),
                                ),
                              ),
                              onSubmitted: (value) => context.read<StandardCubit>().searchStandards(value),
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
                    if (state is StandardLoading) return Center(child: CircularProgressIndicator(color: _primaryColor));
                    if (state is StandardError) return Center(child: Text("Error: ${state.message}", style: const TextStyle(color: Colors.red)));
                    if (state is StandardLoaded) {
                      if (state.standards.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.assignment_late_outlined, size: 60, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text(l10n.noStandardFound, style: TextStyle(color: Colors.grey.shade500)),
                            ],
                          ),
                        );
                      }
                      return isDesktop
                          ? _buildDesktopTable(context, state.standards, l10n)
                          : _buildMobileList(context, state.standards, l10n);
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

  // --- DESKTOP TABLE (ĐÃ CẬP NHẬT FULL CỘT) ---
  Widget _buildDesktopTable(BuildContext context, List<Standard> items, AppLocalizations l10n) {
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
                    columnSpacing: 30,
                    dataRowMinHeight: 110, // Tăng chiều cao để chứa nhiều dòng
                    dataRowMaxHeight: 110,
                    columns: [
                      DataColumn(label: Text(l10n.product.toUpperCase(), style: _headerStyle)),
                      DataColumn(label: Text("${l10n.dyeColor} & DE".toUpperCase(), style: _headerStyle)), // Màu + DE
                      const DataColumn(label: Text("PHYSICAL SPECS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87))),
                      const DataColumn(label: Text("QUALITY SPECS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87))),
                      const DataColumn(label: Text("APPEARANCE & NOTE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87))), // Ngoại quan + Note
                      DataColumn(label: Text(l10n.actions.toUpperCase(), style: _headerStyle)),
                    ],
                    rows: items.map((item) {
                      return DataRow(
                        cells: [
                          // 1. Sản phẩm
                          DataCell(
                            Row(
                              children: [
                                _buildProductImage(item.productImage),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(item.productItemCode ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                                      child: Text(item.productName ?? '', style: TextStyle(fontSize: 10, color: Colors.blue.shade800, fontWeight: FontWeight.bold)),
                                    )
                                  ],
                                )
                              ],
                            )
                          ),
                          
                          // 2. Màu sắc & Delta E
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Container(width: 16, height: 16, decoration: BoxDecoration(color: _hexToColor(item.colorHex), shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300))),
                                    const SizedBox(width: 8),
                                    Text(item.colorName ?? '---', style: const TextStyle(fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                _specRow(Icons.difference, "ΔE", item.deltaE.isNotEmpty ? item.deltaE : "N/A", valueColor: Colors.purple),
                              ],
                            )
                          ),
                          
                          // 3. Thông số Vật lý (Khổ, Dày, Trọng lượng, Mật độ)
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _specRow(Icons.straighten, "Width", "${item.widthMm} mm"),
                                _specRow(Icons.line_weight, "Thick", "${item.thicknessMm} mm"),
                                _specRow(Icons.scale, "Weight", "${item.weightGm} g/m"),
                                _specRow(Icons.grid_on, "Dens", "${item.weftDensity} pick/10cm"),
                              ],
                            )
                          ),

                          // 4. Thông số Chất lượng (Lực đứt, Độ giãn, Bền màu)
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _specRow(Icons.bolt, "Str", "${item.breakingStrength} daN", valueColor: Colors.red.shade700),
                                _specRow(Icons.expand, "Elong", "${item.elongation}%", valueColor: Colors.indigo),
                                _specRow(Icons.water_drop, "Wet", item.colorFastnessWet),
                                _specRow(Icons.wb_sunny, "Dry", item.colorFastnessDry),
                              ],
                            )
                          ),

                          // 5. Ngoại quan & Ghi chú
                          DataCell(
                            SizedBox(
                              width: 200, // Giới hạn chiều rộng để text xuống dòng
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (item.appearance.isNotEmpty)
                                    Text("Appr: ${item.appearance}", style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  if (item.appearance.isNotEmpty && item.note.isNotEmpty)
                                    const SizedBox(height: 4),
                                  if (item.note.isNotEmpty)
                                    Text("Note: ${item.note}", style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic), maxLines: 2, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            )
                          ),

                          // 6. Actions
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

  // Widget hiển thị 1 dòng thông số nhỏ
  Widget _specRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade400),
          const SizedBox(width: 4),
          Text("$label: ", style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: valueColor ?? Colors.black87)),
        ],
      ),
    );
  }

  TextStyle get _headerStyle => TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5);

  // --- MOBILE LIST VIEW (Thẻ chi tiết) ---
  Widget _buildMobileList(BuildContext context, List<Standard> items, AppLocalizations l10n) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Row(
                  children: [
                    _buildProductImage(item.productImage),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.productItemCode ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 12, height: 12,
                                decoration: BoxDecoration(color: _hexToColor(item.colorHex), shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300)),
                              ),
                              const SizedBox(width: 6),
                              Text(item.colorName ?? '---', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                              const SizedBox(width: 8),
                              // Badge Delta E
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(4)),
                                child: Text("ΔE: ${item.deltaE}", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purple.shade800)),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                    PopupMenuButton(
                      icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
                      onSelected: (val) {
                        if (val == 'edit') _showEditDialog(context, item, l10n);
                        if (val == 'delete') _confirmDelete(context, item, l10n);
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem(value: 'edit', child: Text(l10n.editStandard)),
                        PopupMenuItem(value: 'delete', child: Text(l10n.deleteStandard)),
                      ],
                    ),
                  ],
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),

                // Specs Grid for Mobile
                const Text("SPECIFICATIONS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _mobileSpecChip("W", "${item.widthMm}mm"),
                    _mobileSpecChip("T", "${item.thicknessMm}mm"),
                    _mobileSpecChip("G", "${item.weightGm}g/m"),
                    _mobileSpecChip("Str", "${item.breakingStrength}daN", color: Colors.red.shade50),
                    _mobileSpecChip("Elong", "${item.elongation}%", color: Colors.indigo.shade50),
                    _mobileSpecChip("Dens", item.weftDensity),
                    _mobileSpecChip("Wet", item.colorFastnessWet, color: Colors.blue.shade50),
                    _mobileSpecChip("Dry", item.colorFastnessDry, color: Colors.orange.shade50),
                  ],
                ),
                
                const SizedBox(height: 12),
                // Appearance Section
                if (item.appearance.isNotEmpty) ...[
                   Row(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       const Icon(Icons.visibility, size: 14, color: Colors.grey),
                       const SizedBox(width: 8),
                       Expanded(child: Text(item.appearance, style: const TextStyle(fontSize: 13, color: Colors.black87))),
                     ],
                   ),
                   const SizedBox(height: 4),
                ],

                if (item.note.isNotEmpty) ...[
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Text(item.note, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontStyle: FontStyle.italic)),
                  )
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _mobileSpecChip(String label, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color ?? Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black.withOpacity(0.05))
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12, color: Colors.black87),
          children: [
            TextSpan(text: "$label: ", style: TextStyle(color: Colors.grey.shade600)),
            TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ]
        ),
      ),
    );
  }

  Widget _buildProductImage(String? url) {
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: (url != null && url.isNotEmpty)
            ? Image.network(url, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.image, size: 20, color: Colors.grey))
            : const Icon(Icons.image, size: 20, color: Colors.grey),
      ),
    );
  }

  // --- DIALOG ---
  void _showEditDialog(BuildContext context, Standard? item, AppLocalizations l10n) {
    // Không cần controller cho Code nữa
    final widthCtrl = TextEditingController(text: item?.widthMm ?? '');
    final thickCtrl = TextEditingController(text: item?.thicknessMm ?? '');
    final strengthCtrl = TextEditingController(text: item?.breakingStrength ?? '');
    final elongCtrl = TextEditingController(text: item?.elongation ?? '');
    final dryCtrl = TextEditingController(text: item?.colorFastnessDry ?? '');
    final wetCtrl = TextEditingController(text: item?.colorFastnessWet ?? '');
    final deltaCtrl = TextEditingController(text: item?.deltaE ?? '');
    final appearCtrl = TextEditingController(text: item?.appearance ?? '');
    final densityCtrl = TextEditingController(text: item?.weftDensity ?? '');
    final weightCtrl = TextEditingController(text: item?.weightGm ?? '');
    final noteCtrl = TextEditingController(text: item?.note ?? '');
    
    int? selectedProductId = item?.productId;
    int? selectedColorId = item?.dyeColorId;

    final prodState = context.read<ProductCubit>().state;
    if (item == null && prodState is ProductLoaded && prodState.products.isNotEmpty) {
      selectedProductId = prodState.products.first.id;
    }
    
    final colorState = context.read<DyeColorCubit>().state;
    if (item == null && colorState is DyeColorLoaded && colorState.colors.isNotEmpty) {
      selectedColorId = colorState.colors.first.id;
    }

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.all(24),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        title: Text(item == null ? l10n.addStandard : l10n.editStandard, style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 700,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("General Info", style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: BlocBuilder<ProductCubit, ProductState>(
                      builder: (context, state) {
                        List<Product> prods = (state is ProductLoaded) ? state.products : [];
                        return DropdownButtonFormField<int>(
                          value: selectedProductId,
                          decoration: _inputDeco(l10n.product),
                          items: prods.map((p) => DropdownMenuItem(value: p.id, child: Text(p.itemCode))).toList(),
                          onChanged: (val) => selectedProductId = val,
                          validator: (v) => v == null ? "Required" : null,
                        );
                      },
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: BlocBuilder<DyeColorCubit, DyeColorState>(
                      builder: (context, state) {
                        List<DyeColor> colors = (state is DyeColorLoaded) ? state.colors : [];
                        return DropdownButtonFormField<int>(
                          value: selectedColorId,
                          decoration: _inputDeco(l10n.dyeColor),
                          items: colors.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                          onChanged: (val) => selectedColorId = val,
                          validator: (v) => v == null ? "Required" : null,
                        );
                      },
                    )),
                  ]),
                  
                  const SizedBox(height: 24),
                  Text("Physical Properties", style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: TextFormField(controller: widthCtrl, decoration: _inputDeco(l10n.width))),
                    const SizedBox(width: 12),
                    Expanded(child: TextFormField(controller: thickCtrl, decoration: _inputDeco(l10n.thickness))),
                    const SizedBox(width: 12),
                    Expanded(child: TextFormField(controller: weightCtrl, decoration: _inputDeco(l10n.weight))),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: TextFormField(controller: strengthCtrl, decoration: _inputDeco(l10n.strength))),
                    const SizedBox(width: 12),
                    Expanded(child: TextFormField(controller: elongCtrl, decoration: _inputDeco(l10n.elongation))),
                    const SizedBox(width: 12),
                    Expanded(child: TextFormField(controller: densityCtrl, decoration: _inputDeco(l10n.weftDensity))),
                  ]),

                  const SizedBox(height: 24),
                  Text("Visual & Color", style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: TextFormField(controller: dryCtrl, decoration: _inputDeco(l10n.colorFastDry))),
                    const SizedBox(width: 12),
                    Expanded(child: TextFormField(controller: wetCtrl, decoration: _inputDeco(l10n.colorFastWet))),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: TextFormField(controller: deltaCtrl, decoration: _inputDeco(l10n.deltaE))),
                    const SizedBox(width: 12),
                    Expanded(child: TextFormField(controller: appearCtrl, decoration: _inputDeco(l10n.appearance))),
                  ]),
                  
                  const SizedBox(height: 16),
                  TextFormField(controller: noteCtrl, decoration: _inputDeco(l10n.note), maxLines: 2),
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
              if (formKey.currentState!.validate() && selectedProductId != null && selectedColorId != null) {
                final newItem = Standard(
                  id: item?.id ?? 0,
                  productId: selectedProductId!,
                  dyeColorId: selectedColorId!,
                  widthMm: widthCtrl.text,
                  thicknessMm: thickCtrl.text,
                  breakingStrength: strengthCtrl.text,
                  elongation: elongCtrl.text,
                  colorFastnessDry: dryCtrl.text,
                  colorFastnessWet: wetCtrl.text,
                  deltaE: deltaCtrl.text,
                  appearance: appearCtrl.text,
                  weftDensity: densityCtrl.text,
                  weightGm: weightCtrl.text,
                  note: noteCtrl.text,
                );
                context.read<StandardCubit>().saveStandard(standard: newItem, isEdit: item != null);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(item == null ? l10n.successAdded : l10n.successUpdated), backgroundColor: Colors.green));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13),
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

  void _confirmDelete(BuildContext context, Standard item, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteStandard),
        content: Text("Delete standard for product ${item.productItemCode}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              context.read<StandardCubit>().deleteStandard(item.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(l10n.deleteStandard),
          ),
        ],
      ),
    );
  }
}