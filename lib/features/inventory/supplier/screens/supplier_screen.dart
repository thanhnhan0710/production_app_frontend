import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:production_app_frontend/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/widgets/responsive_layout.dart';
import '../domain/supplier_model.dart';
import '../presentation/bloc/supplier_cubit.dart';

class SupplierScreen extends StatefulWidget {
  const SupplierScreen({super.key});

  @override
  State<SupplierScreen> createState() => _SupplierScreenState();
}

class _SupplierScreenState extends State<SupplierScreen> {
  final _searchController = TextEditingController();
  final Color _primaryColor = const Color(0xFF003366);
  final Color _accentColor = const Color(0xFFE65100); // Màu Cam đậm cho Supplier
  final Color _bgLight = const Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    // Load dữ liệu ngay khi vào màn hình
    context.read<SupplierCubit>().loadSuppliers();
  }

  // Hàm gọi điện/email an toàn
  Future<void> _launchAction(String scheme, String path) async {
    if (path.isEmpty) return;
    final Uri launchUri = Uri(scheme: scheme, path: path);
    try {
      await launchUrl(launchUri);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Không thể mở liên kết: $path")),
      );
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
            children: [
              // --- HEADER SECTION ---
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  children: [
                    // Title Row
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
                              "Manage external partners & vendors",
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
                    
                    // [FIX SEARCH] Search Bar
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
                              // [FIX] Thêm action search cho bàn phím
                              textInputAction: TextInputAction.search,
                              decoration: InputDecoration(
                                hintText: l10n.searchSupplier,
                                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 20),
                                // [FIX] Thêm nút bấm tìm kiếm thủ công
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.arrow_forward, color: Colors.blue),
                                  onPressed: () {
                                    context.read<SupplierCubit>().searchSuppliers(_searchController.text);
                                  },
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              // [FIX] Sự kiện Enter
                              onSubmitted: (value) {
                                context.read<SupplierCubit>().searchSuppliers(value);
                              },
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
                    if (state is SupplierLoading) {
                      return Center(child: CircularProgressIndicator(color: _primaryColor));
                    } 
                    if (state is SupplierError) {
                      return Center(child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 40),
                          const SizedBox(height: 10),
                          Text(state.message, style: const TextStyle(color: Colors.red)),
                          TextButton(onPressed: () => context.read<SupplierCubit>().loadSuppliers(), child: const Text("Thử lại"))
                        ],
                      ));
                    } 
                    if (state is SupplierLoaded) {
                      if (state.suppliers.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.store_mall_directory_outlined, size: 60, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text("No suppliers found", style: TextStyle(color: Colors.grey.shade500)),
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
              backgroundColor: _accentColor,
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
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(const Color(0xFFF9FAFB)),
          horizontalMargin: 24,
          columnSpacing: 30,
          dataRowMinHeight: 72,
          dataRowMaxHeight: 72,
          columns: [
            DataColumn(label: Text(l10n.supplierName.toUpperCase(), style: _headerStyle)),
            DataColumn(label: Text(l10n.contact.toUpperCase(), style: _headerStyle)), // Fallback text nếu null
            DataColumn(label: Text(l10n.address.toUpperCase(), style: _headerStyle)),
            DataColumn(label: Text(l10n.note.toUpperCase(), style: _headerStyle)),
            DataColumn(label: Text(l10n.actions.toUpperCase(), style: _headerStyle)),
          ],
          rows: suppliers.map((item) {
            return DataRow(
              cells: [
                // Name & Avatar
                DataCell(Row(
                  children: [
                    _buildAvatar(item.name),
                    const SizedBox(width: 16),
                    Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14)),
                  ],
                )),
                // Contact Info
                DataCell(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if(item.email.isNotEmpty) 
                      InkWell(
                        onTap: () => _launchAction('mailto', item.email),
                        child: Row(children: [const Icon(Icons.email, size: 14, color: Colors.blue), const SizedBox(width: 6), Text(item.email, style: TextStyle(fontSize: 12, color: Colors.grey.shade700))]),
                      ),
                    if(item.phone.isNotEmpty) 
                      InkWell(
                        onTap: () => _launchAction('tel', item.phone),
                        child: Row(children: [const Icon(Icons.phone, size: 14, color: Colors.green), const SizedBox(width: 6), Text(item.phone, style: TextStyle(fontSize: 12, color: Colors.grey.shade700))]),
                      ),
                  ],
                )),
                // Address
                DataCell(Text(item.address, overflow: TextOverflow.ellipsis)),
                // Note
                DataCell(Text(item.note, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade500))),
                // Actions
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
  }

  TextStyle get _headerStyle => TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5);

  // --- MOBILE LIST ---
  Widget _buildMobileList(BuildContext context, List<Supplier> suppliers, AppLocalizations l10n) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: suppliers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final item = suppliers[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAvatar(item.name),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                          const SizedBox(height: 4),
                          if(item.address.isNotEmpty)
                            Row(children: [
                              Icon(Icons.location_on, size: 14, color: Colors.grey.shade400),
                              const SizedBox(width: 4),
                              Expanded(child: Text(item.address, style: TextStyle(color: Colors.grey.shade600, fontSize: 13), overflow: TextOverflow.ellipsis))
                            ]),
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
                        PopupMenuItem(value: 'edit', child: Row(children: [const Icon(Icons.edit, size: 18), const SizedBox(width: 8), Text(l10n.editSupplier)])),
                        PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete, size: 18, color: Colors.red), const SizedBox(width: 8), Text(l10n.deleteSupplier)])),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Divider(height: 1, color: Colors.grey.shade100)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _launchAction('mailto', item.email),
                        child: Row(children: [
                          Icon(Icons.email, size: 14, color: Colors.grey.shade400),
                          const SizedBox(width: 6),
                          Expanded(child: Text(item.email.isNotEmpty ? item.email : "N/A", style: TextStyle(fontSize: 12, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis)),
                        ]),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => _launchAction('tel', item.phone),
                        child: Row(children: [
                          Icon(Icons.phone, size: 14, color: Colors.grey.shade400),
                          const SizedBox(width: 6),
                          Expanded(child: Text(item.phone.isNotEmpty ? item.phone : "N/A", style: TextStyle(fontSize: 12, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis)),
                        ]),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  // --- AVATAR LOGIC (Lấy chữ cái đầu tên công ty) ---
  Widget _buildAvatar(String name) {
    String initial = "?";
    if (name.isNotEmpty) {
      initial = name[0].toUpperCase();
    }
    // Random màu nhẹ nhàng cho doanh nghiệp
    final colors = [
      Colors.orange.shade800,
      Colors.blue.shade800,
      Colors.teal.shade800,
      Colors.indigo.shade800,
    ];
    final color = colors[name.hashCode.abs() % colors.length];

    return CircleAvatar(
      radius: 20,
      backgroundColor: color.withOpacity(0.1),
      child: Text(initial, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  // --- DIALOG ---
  void _showEditDialog(BuildContext context, Supplier? item, AppLocalizations l10n) {
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final emailCtrl = TextEditingController(text: item?.email ?? '');
    final phoneCtrl = TextEditingController(text: item?.phone ?? '');
    final addressCtrl = TextEditingController(text: item?.address ?? '');
    final noteCtrl = TextEditingController(text: item?.note ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.all(24),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        title: Text(item == null ? l10n.addSupplier : l10n.editSupplier, style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(controller: nameCtrl, decoration: _inputDeco(l10n.supplierName), validator: (v) => v!.isEmpty ? "Required" : null),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: emailCtrl, decoration: _inputDeco(l10n.email))),
                      const SizedBox(width: 12),
                      Expanded(child: TextFormField(controller: phoneCtrl, decoration: _inputDeco(l10n.phone))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(controller: addressCtrl, decoration: _inputDeco(l10n.address)),
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
              if (formKey.currentState!.validate()) {
                final newItem = Supplier(
                  id: item?.id ?? 0,
                  name: nameCtrl.text,
                  email: emailCtrl.text,
                  phone: phoneCtrl.text,
                  address: addressCtrl.text,
                  note: noteCtrl.text,
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
      ),
    );
  }

  InputDecoration _inputDeco(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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