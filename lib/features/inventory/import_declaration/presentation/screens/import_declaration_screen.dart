import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

// --- IMPORTS ---
import '../../../../../core/widgets/responsive_layout.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../domain/import_declaration_model.dart';
import '../bloc/import_declaration_cubit.dart';

import 'import_declaration_detail_screen.dart';

class ImportDeclarationScreen extends StatefulWidget {
  const ImportDeclarationScreen({super.key});

  @override
  State<ImportDeclarationScreen> createState() => _ImportDeclarationScreenState();
}

class _ImportDeclarationScreenState extends State<ImportDeclarationScreen> {
  final _searchController = TextEditingController();
  final Color _primaryColor = const Color(0xFF003366);
  final Color _accentColor = const Color(0xFF0055AA);
  final Color _bgLight = const Color(0xFFF5F7FA);

  // Formatters
  final _dateFormat = DateFormat('dd/MM/yyyy');
  final _currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '');

  @override
  void initState() {
    super.initState();
    context.read<ImportDeclarationCubit>().loadDeclarations();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: _bgLight,
      body: BlocBuilder<ImportDeclarationCubit, ImportDeclState>(
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
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.description_outlined, color: Colors.teal.shade800, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.importDeclarationTitle,
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.importDeclarationSubtitle,
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (isDesktop)
                          ElevatedButton.icon(
                            onPressed: () => _showEditDialog(context, null, l10n),
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(l10n.newDeclaration),
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
                                hintText: l10n.searchDeclarationHint,
                                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 20),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                suffixIcon: _searchController.text.isNotEmpty 
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        context.read<ImportDeclarationCubit>().loadDeclarations();
                                      },
                                    )
                                  : null,
                              ),
                              onSubmitted: (value) => context.read<ImportDeclarationCubit>().loadDeclarations(search: value),
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
                    if (state is ImportDeclLoading) {
                      return Center(child: CircularProgressIndicator(color: _primaryColor));
                    } else if (state is ImportDeclError) {
                      return Center(child: Text("${l10n.errorGeneric}: ${state.message}", style: const TextStyle(color: Colors.red)));
                    } else if (state is ImportDeclListLoaded) {
                      if (state.list.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.folder_off_outlined, size: 60, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text(l10n.noDeclarationFound, style: TextStyle(color: Colors.grey.shade500)),
                            ],
                          ),
                        );
                      }
                      return isDesktop
                          ? _buildDesktopTable(context, state.list, l10n)
                          : _buildMobileList(context, state.list, l10n);
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
  Widget _buildDesktopTable(BuildContext context, List<ImportDeclaration> items, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
            horizontalMargin: 24,
            columnSpacing: 20,
            dataRowMinHeight: 60,
            dataRowMaxHeight: 60,
            columns: [
              DataColumn(label: Text(l10n.declarationNo.toUpperCase(), style: _headerStyle)),
              DataColumn(label: Text(l10n.declarationDate.toUpperCase(), style: _headerStyle)),
              DataColumn(label: Text(l10n.declarationType.toUpperCase(), style: _headerStyle)),
              DataColumn(label: Text(l10n.invoiceBill.toUpperCase(), style: _headerStyle)),
              DataColumn(label: Text(l10n.totalTax.toUpperCase(), style: _headerStyle)),
              DataColumn(label: Text(l10n.actions.toUpperCase(), style: _headerStyle)),
            ],
            rows: items.map((item) {
              return DataRow(
                cells: [
                  DataCell(
                    Text(item.declarationNo, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                    onTap: () => _navigateToDetail(item.id),
                  ),
                  DataCell(Text(_dateFormat.format(item.declarationDate))),
                  DataCell(_buildTypeBadge(item.type)),
                  DataCell(Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.invoiceNo != null) Text("${l10n.invoiceAbbr}: ${item.invoiceNo}", style: const TextStyle(fontSize: 12)),
                      if (item.billOfLading != null) Text("${l10n.billOfLadingAbbr}: ${item.billOfLading}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  )),
                  DataCell(Text(
                    item.totalTaxAmount > 0 ? "${_currencyFormat.format(item.totalTaxAmount)} VND" : "-",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  )),
                  DataCell(Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility, color: Colors.blue), 
                        onPressed: () => _navigateToDetail(item.id)
                      ),
                      IconButton(icon: const Icon(Icons.edit_note, color: Colors.grey), onPressed: () => _showEditDialog(context, item, l10n)),
                      IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => _confirmDelete(context, item, l10n),
                      ),
                    ],
                  )),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  TextStyle get _headerStyle => TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5);

  // --- MOBILE LIST ---
  Widget _buildMobileList(BuildContext context, List<ImportDeclaration> items, AppLocalizations l10n) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          child: InkWell(
            onTap: () => _navigateToDetail(item.id),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(item.declarationNo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                      ),
                      _buildTypeBadge(item.type),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade400),
                      const SizedBox(width: 6),
                      Text("${l10n.date}: ${_dateFormat.format(item.declarationDate)}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.invoiceNo, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                              Text(item.invoiceNo ?? "-", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 24, color: Colors.grey.shade300),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.billOfLading, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                              Text(item.billOfLading ?? "-", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypeBadge(ImportType type) {
    Color color;
    switch (type) {
      case ImportType.E31: color = Colors.blue; break;
      case ImportType.A11: color = Colors.orange; break;
      case ImportType.E21: color = Colors.purple; break;
      default: color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(type.name, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  void _navigateToDetail(int id) {
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => ImportDeclarationDetailScreen(id: id))
    ).then((_) {
      context.read<ImportDeclarationCubit>().loadDeclarations();
    });
  }

  // --- DIALOG THÊM / SỬA ---
  void _showEditDialog(BuildContext context, ImportDeclaration? decl, AppLocalizations l10n) {
    final noCtrl = TextEditingController(text: decl?.declarationNo ?? '');
    final invoiceCtrl = TextEditingController(text: decl?.invoiceNo ?? '');
    final billCtrl = TextEditingController(text: decl?.billOfLading ?? '');
    final taxCtrl = TextEditingController(text: decl?.totalTaxAmount.toString() ?? '0');
    final noteCtrl = TextEditingController(text: decl?.note ?? '');
    
    DateTime selectedDate = decl?.declarationDate ?? DateTime.now();
    ImportType selectedType = decl?.type ?? ImportType.E31;

    final formKey = GlobalKey<FormState>();

    Future<void> selectDate(BuildContext ctx, Function(DateTime) onPicked) async {
      final picked = await showDatePicker(
        context: ctx,
        initialDate: selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
      );
      if (picked != null) onPicked(picked);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final width = MediaQuery.of(ctx).size.width;
        final isSmallScreen = width < 600;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.all(24),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          title: Text(decl == null ? l10n.createDeclaration : l10n.editDeclaration, style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: isSmallScreen ? double.maxFinite : 600,
              child: SingleChildScrollView(
                child: StatefulBuilder(
                  builder: (context, setState) {
                    Widget responsiveRow({required Widget child1, required Widget child2}) {
                      if (isSmallScreen) return Column(children: [child1, const SizedBox(height: 16), child2]);
                      return Row(children: [Expanded(child: child1), const SizedBox(width: 16), Expanded(child: child2)]);
                    }

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        responsiveRow(
                          child1: TextFormField(
                            controller: noCtrl,
                            decoration: _inputDeco(l10n.declarationNo, icon: Icons.tag),
                            validator: (v) => v!.isEmpty ? l10n.required : null,
                            enabled: decl == null,
                          ),
                          child2: InkWell(
                            onTap: () => selectDate(ctx, (d) => setState(() => selectedDate = d)),
                            child: InputDecorator(
                              decoration: _inputDeco(l10n.declarationDate, icon: Icons.calendar_today),
                              child: Text(_dateFormat.format(selectedDate)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        responsiveRow(
                          child1: DropdownButtonFormField<ImportType>(
                            value: selectedType,
                            decoration: _inputDeco(l10n.declarationType, icon: Icons.category),
                            items: ImportType.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(),
                            onChanged: (val) => setState(() => selectedType = val!),
                          ),
                          child2: TextFormField(
                            controller: taxCtrl,
                            decoration: _inputDeco(l10n.totalTaxAmount, icon: Icons.monetization_on),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(height: 16),
                        responsiveRow(
                          child1: TextFormField(
                            controller: invoiceCtrl,
                            decoration: _inputDeco(l10n.invoiceNo, icon: Icons.receipt),
                          ),
                          child2: TextFormField(
                            controller: billCtrl,
                            decoration: _inputDeco(l10n.billOfLading, icon: Icons.directions_boat),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: noteCtrl,
                          decoration: _inputDeco(l10n.note, icon: Icons.note),
                          maxLines: 2,
                        ),
                      ],
                    );
                  }
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
                  final newDecl = ImportDeclaration(
                    id: decl?.id ?? 0,
                    declarationNo: noCtrl.text,
                    declarationDate: selectedDate,
                    type: selectedType,
                    billOfLading: billCtrl.text,
                    invoiceNo: invoiceCtrl.text,
                    totalTaxAmount: double.tryParse(taxCtrl.text) ?? 0.0,
                    note: noteCtrl.text,
                    details: decl?.details ?? [],
                  );
                  // Gọi hàm Save (Create/Update)
                  context.read<ImportDeclarationCubit>().saveDeclaration(declaration: newDecl, isEdit: decl != null);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.processing), backgroundColor: Colors.blue));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: Text(l10n.save),
            ),
          ],
        );
      }
    );
  }

  InputDecoration _inputDeco(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, size: 18, color: Colors.grey) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  // [FIX] Hàm Xóa Tờ khai
  void _confirmDelete(BuildContext context, ImportDeclaration item, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteDeclaration),
        content: Text(l10n.confirmDeleteDeclaration(item.declarationNo)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              // Gọi hàm deleteDeclaration từ Cubit
              context.read<ImportDeclarationCubit>().deleteDeclaration(item.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(l10n.delete),
          )
        ],
      )
    );
  }
}