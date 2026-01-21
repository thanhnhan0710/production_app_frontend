import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/widgets/responsive_layout.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../domain/supplier_model.dart';
import '../bloc/supplier_cubit.dart';

class SupplierScreen extends StatefulWidget {
  const SupplierScreen({super.key});

  @override
  State<SupplierScreen> createState() => _SupplierScreenState();
}

class _SupplierScreenState extends State<SupplierScreen> {
  final _searchController = TextEditingController();
  final Color _primaryColor = const Color(0xFF003366);
  final Color _bgLight = const Color(0xFFF5F7FA);

  // Define Options for Dropdowns
  final List<String> _originOptions = ['Domestic', 'Import'];
  final List<String> _currencyOptions = ['VND', 'USD', 'CNY', 'EUR'];
  
  final List<String> _paymentTermOptions = [
    'Net 30', 
    'Net 45', 
    'Net 60', 
    'T/T', 
    'L/C', 
    'COD', 
    'Immediate'
  ];

  @override
  void initState() {
    super.initState();
    context.read<SupplierCubit>().loadSuppliers();
  }

  Future<void> _launchAction(String scheme, String path) async {
    if (path.isEmpty) return;
    final Uri launchUri = Uri(scheme: scheme, path: path);
    try {
      await launchUrl(launchUri);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not launch: $path")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: _bgLight,
      body: BlocBuilder<SupplierCubit, SupplierState>(
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
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.store_mall_directory, color: Colors.orange.shade800, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.supplierTitle,
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Manage partners, origins & contracts", // Tagline giữ nguyên hoặc có thể thêm key sau
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (isDesktop)
                          ElevatedButton.icon(
                            onPressed: () => _showEditDialog(context, null, l10n),
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(l10n.addSupplier.toUpperCase()),
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
                                hintText: l10n.searchSupplier,
                                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 20),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onSubmitted: (value) {
                                context.read<SupplierCubit>().searchSuppliers(value);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                           onPressed: () => context.read<SupplierCubit>().loadSuppliers(),
                           icon: const Icon(Icons.refresh, color: Colors.grey),
                           tooltip: l10n.refreshData,
                        )
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
                    if (state is SupplierLoading) return Center(child: CircularProgressIndicator(color: _primaryColor));
                    if (state is SupplierError) {
                      return Center(child: Text("${l10n.errorGeneric}: ${state.message}", style: const TextStyle(color: Colors.red)));
                    }
                    if (state is SupplierLoaded) {
                      if (state.suppliers.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.store_mall_directory_outlined, size: 60, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text("No suppliers found", style: TextStyle(color: Colors.grey.shade500)), // Fallback text
                            ],
                          ),
                        );
                      }
                      return isDesktop
                          ? _buildDesktopGrid(context, state.suppliers, l10n)
                          : _buildMobileList(context, state.suppliers, l10n);
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
              backgroundColor: _primaryColor,
              onPressed: () => _showEditDialog(context, null, l10n),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  // --- DESKTOP TABLE ---
  Widget _buildDesktopGrid(BuildContext context, List<Supplier> suppliers, AppLocalizations l10n) {
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
                    dataRowMinHeight: 70,
                    dataRowMaxHeight: 70,
                    
                    columns: [
                      DataColumn(label: Text(l10n.generalInfo.toUpperCase(), style: _headerStyle)), // INFO
                      DataColumn(label: Text("TYPE / CODE", style: _headerStyle)), // Header cứng
                      DataColumn(label: Text(l10n.contact.toUpperCase(), style: _headerStyle)), // CONTACT
                      DataColumn(label: Text("FINANCE", style: _headerStyle)), // FINANCE
                      DataColumn(label: Text(l10n.status.toUpperCase(), style: _headerStyle)), // STATUS
                      DataColumn(label: Text(l10n.actions.toUpperCase(), style: _headerStyle)), // ACTIONS
                    ],
                    rows: suppliers.map((item) {
                      return DataRow(
                        cells: [
                          // 1. INFO: Avatar + Name + Email
                          DataCell(Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.orange.shade50,
                                child: Text(item.name.isNotEmpty ? item.name[0].toUpperCase() : '?', style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold, fontSize: 14)),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                  if(item.email.isNotEmpty)
                                    InkWell(
                                      onTap: () => _launchAction('mailto', item.email),
                                      child: Text(item.email, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                    ),
                                ],
                              ),
                            ],
                          )),

                          // 2. TYPE / CODE
                          DataCell(Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if(item.shortName != null && item.shortName!.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                                  child: Text(item.shortName!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
                                ),
                              const SizedBox(height: 4),
                              Text("${item.originType ?? '-'} • ${item.country ?? ''}", style: const TextStyle(fontSize: 12)),
                              if(item.taxCode != null) Text("${l10n.taxCode}: ${item.taxCode}", style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                            ],
                          )),

                          // 3. CONTACT
                          DataCell(Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(children: [
                                Icon(Icons.person, size: 14, color: Colors.grey.shade400),
                                const SizedBox(width: 4),
                                Text(item.contactPerson ?? '--', style: const TextStyle(fontSize: 13)),
                              ]),
                              const SizedBox(height: 2),
                              Text(item.address ?? '', style: TextStyle(fontSize: 11, color: Colors.grey.shade500), overflow: TextOverflow.ellipsis, maxLines: 1),
                            ],
                          )),

                          // 4. FINANCE
                          DataCell(Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Text(item.currencyDefault, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(3)),
                                    child: Text(item.paymentTerm, style: const TextStyle(fontSize: 10, color: Colors.black87)),
                                  )
                                ],
                              ),
                              Text("${l10n.leadTime}: ${item.leadTimeDays} ${l10n.days}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            ],
                          )),

                          // 5. STATUS
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: item.isActive ? Colors.green.shade50 : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: item.isActive ? Colors.green.shade100 : Colors.red.shade100),
                              ),
                              child: Text(
                                item.isActive ? l10n.active : l10n.inactive,
                                style: TextStyle(fontSize: 11, color: item.isActive ? Colors.green : Colors.red, fontWeight: FontWeight.w500),
                              ),
                            )
                          ),

                          // 6. ACTIONS
                          DataCell(Row(
                            children: [
                              IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.grey, size: 20), onPressed: () => _showEditDialog(context, item, l10n)),
                              IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20), onPressed: () => _confirmDelete(context, item, l10n)),
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

  TextStyle get _headerStyle => TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5);

  // --- MOBILE LIST ---
  Widget _buildMobileList(BuildContext context, List<Supplier> suppliers, AppLocalizations l10n) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: suppliers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = suppliers[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: item.isActive ? Colors.green.shade50 : Colors.grey.shade100,
              child: Icon(Icons.store, color: item.isActive ? Colors.green.shade700 : Colors.grey),
            ),
            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    if(item.shortName != null) 
                      Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)), child: Text(item.shortName!, style: const TextStyle(fontSize: 10, color: Colors.blue))),
                    Text("${item.country ?? ''} • ${item.currencyDefault}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
                if(item.contactPerson != null)
                   Padding(
                     padding: const EdgeInsets.only(top: 4.0),
                     child: Row(children: [const Icon(Icons.person, size: 12, color: Colors.grey), const SizedBox(width: 4), Text(item.contactPerson!, style: const TextStyle(fontSize: 12))]),
                   )
              ],
            ),
            children: [
               Padding(
                 padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                 child: Column(
                   children: [
                     const Divider(),
                     _infoRow(Icons.email, l10n.email, item.email),
                     _infoRow(Icons.location_on, l10n.address, item.address ?? '--'),
                     _infoRow(Icons.receipt, l10n.taxCode, item.taxCode ?? '--'),
                     _infoRow(Icons.category, l10n.originType, item.originType ?? '--'),
                     _infoRow(Icons.payment, l10n.paymentTerm, item.paymentTerm),
                     _infoRow(Icons.schedule, l10n.leadTime, "${item.leadTimeDays} ${l10n.days}"),
                     const SizedBox(height: 12),
                     Row(
                       mainAxisAlignment: MainAxisAlignment.end,
                       children: [
                         TextButton.icon(onPressed: () => _confirmDelete(context, item, l10n), icon: const Icon(Icons.delete, color: Colors.red, size: 18), label: Text(l10n.deleteSupplier, style: const TextStyle(color: Colors.red))),
                         const SizedBox(width: 8),
                         ElevatedButton.icon(onPressed: () => _showEditDialog(context, item, l10n), icon: const Icon(Icons.edit, size: 18), label: Text(l10n.editSupplier), style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white)),
                       ],
                     )
                   ],
                 ),
               )
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade400),
          const SizedBox(width: 8),
          SizedBox(width: 110, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))), // Tăng width cho label dài
          Expanded(child: Text(value, style: const TextStyle(color: Colors.black87, fontSize: 13))),
        ],
      ),
    );
  }

  // --- DIALOG (CREATE / EDIT) ---
  void _showEditDialog(BuildContext context, Supplier? item, AppLocalizations l10n) {
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final shortNameCtrl = TextEditingController(text: item?.shortName ?? '');
    final emailCtrl = TextEditingController(text: item?.email ?? '');
    final contactCtrl = TextEditingController(text: item?.contactPerson ?? '');
    final taxCtrl = TextEditingController(text: item?.taxCode ?? '');
    final addressCtrl = TextEditingController(text: item?.address ?? '');
    final countryCtrl = TextEditingController(text: item?.country ?? '');
    final leadTimeCtrl = TextEditingController(text: (item?.leadTimeDays ?? 7).toString());
    
    String selectedCurrency = item?.currencyDefault ?? 'VND';
    String selectedPaymentTerm = item?.paymentTerm ?? 'Net 30';
    String? selectedOrigin = item?.originType;
    bool isActive = item?.isActive ?? true;

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              titlePadding: const EdgeInsets.all(24),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              title: Text(item == null ? l10n.addSupplier : l10n.editSupplier, style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
              content: Form(
                key: formKey,
                child: SizedBox(
                  width: 650,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1
                        Row(
                          children: [
                            Expanded(flex: 2, child: TextFormField(controller: nameCtrl, decoration: _inputDeco(l10n.supplierName), validator: (v) => v!.isEmpty ? l10n.required : null)),
                            const SizedBox(width: 12),
                            Expanded(flex: 1, child: TextFormField(controller: shortNameCtrl, decoration: _inputDeco(l10n.shortName))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Row 2
                        Row(
                          children: [
                            Expanded(child: TextFormField(controller: emailCtrl, decoration: _inputDeco(l10n.email), validator: (v) => v!.isEmpty ? l10n.required : null)),
                            const SizedBox(width: 12),
                            Expanded(child: TextFormField(controller: contactCtrl, decoration: _inputDeco(l10n.contactPerson))),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Row 3
                        Row(
                          children: [
                            Expanded(flex: 2, child: TextFormField(controller: taxCtrl, decoration: _inputDeco(l10n.taxCode))),
                            const SizedBox(width: 12),
                            Expanded(flex: 1, child: TextFormField(controller: countryCtrl, decoration: _inputDeco("Country"))),
                            const SizedBox(width: 12),
                            Expanded(flex: 1, child: TextFormField(
                              controller: leadTimeCtrl, 
                              decoration: _inputDeco(l10n.days), 
                              keyboardType: TextInputType.number,
                              validator: (v) => int.tryParse(v!) == null ? "Invalid" : null,
                            )),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Row 4
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedOrigin,
                                decoration: _inputDeco(l10n.originType),
                                items: _originOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                onChanged: (val) => setState(() => selectedOrigin = val),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedCurrency,
                                decoration: _inputDeco(l10n.currency),
                                items: _currencyOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                onChanged: (val) => setState(() => selectedCurrency = val!),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedPaymentTerm,
                                decoration: _inputDeco(l10n.paymentTerm),
                                items: _paymentTermOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                onChanged: (val) => setState(() => selectedPaymentTerm = val!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Address
                        TextFormField(controller: addressCtrl, decoration: _inputDeco(l10n.address), maxLines: 2),
                        const SizedBox(height: 16),

                        // Is Active
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(l10n.isActiveProvider, style: const TextStyle(fontWeight: FontWeight.w500)),
                              Switch(
                                value: isActive, 
                                onChanged: (val) => setState(() => isActive = val),
                                activeColor: Colors.green,
                              ),
                            ],
                          ),
                        )
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
                      final newItem = Supplier(
                        id: item?.id ?? 0,
                        name: nameCtrl.text,
                        email: emailCtrl.text,
                        shortName: shortNameCtrl.text.isEmpty ? null : shortNameCtrl.text,
                        originType: selectedOrigin,
                        country: countryCtrl.text.isEmpty ? null : countryCtrl.text,
                        currencyDefault: selectedCurrency,
                        paymentTerm: selectedPaymentTerm,
                        taxCode: taxCtrl.text.isEmpty ? null : taxCtrl.text,
                        contactPerson: contactCtrl.text.isEmpty ? null : contactCtrl.text,
                        address: addressCtrl.text.isEmpty ? null : addressCtrl.text,
                        leadTimeDays: int.tryParse(leadTimeCtrl.text) ?? 7,
                        isActive: isActive,
                      );
                      
                      context.read<SupplierCubit>().saveSupplier(supplier: newItem, isEdit: item != null);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(item == null ? l10n.successAdded : l10n.successUpdated), backgroundColor: Colors.green));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: Text(l10n.save),
                ),
              ],
            );
          }
        );
      },
    );
  }

  InputDecoration _inputDeco(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      isDense: true,
    );
  }

  void _confirmDelete(BuildContext context, Supplier item, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [const Icon(Icons.warning_amber_rounded, color: Colors.red), const SizedBox(width: 8), Text(l10n.deleteSupplier)]),
        content: Text(l10n.confirmDeleteSupplier(item.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              context.read<SupplierCubit>().deleteSupplier(item.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(l10n.deleteSupplier),
          ),
        ],
      ),
    );
  }
}