import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:production_app_frontend/features/inventory/basket/doamain/basket_model.dart';
import 'package:production_app_frontend/features/inventory/basket/presentation/bloc/baket_cubit.dart';
import 'package:production_app_frontend/l10n/app_localizations.dart';
import 'package:production_app_frontend/core/widgets/responsive_layout.dart';

class BasketScreen extends StatefulWidget {
  const BasketScreen({super.key});

  @override
  State<BasketScreen> createState() => _BasketScreenState();
}

class _BasketScreenState extends State<BasketScreen> {
  final _searchController = TextEditingController();
  final Color _primaryColor = const Color(0xFF003366);
  final Color _accentColor = const Color(0xFF795548); // Màu Nâu cho Rổ/Thùng
  final Color _bgLight = const Color(0xFFF5F7FA);

  // Danh sách trạng thái
  final List<String> _statusList = ['READY', 'IN_USE', 'HOLDING', 'DAMAGED'];

  @override
  void initState() {
    super.initState();
    context.read<BasketCubit>().loadBaskets();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: _bgLight,
      body: BlocBuilder<BasketCubit, BasketState>(
        builder: (context, state) {
          int total = 0;
          if (state is BasketLoaded) total = state.baskets.length;

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
                            color: Colors.brown.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.shopping_basket, color: Colors.brown.shade800, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.basketTitle, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                            const SizedBox(height: 2),
                            Text("Inventory > Containers", style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                          ],
                        ),
                        const Spacer(),
                        if (isDesktop)
                          ElevatedButton.icon(
                            onPressed: () => _showEditDialog(context, null, l10n),
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(l10n.addBasket.toUpperCase()),
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
                          _buildStatBadge(Icons.grid_view, "Total Baskets", "$total", Colors.blue),
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
                                hintText: l10n.searchBasket,
                                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 20),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.arrow_forward, color: Colors.blue),
                                  onPressed: () => context.read<BasketCubit>().searchBaskets(_searchController.text),
                                ),
                              ),
                              onSubmitted: (value) => context.read<BasketCubit>().searchBaskets(value),
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
                    if (state is BasketLoading) return Center(child: CircularProgressIndicator(color: _primaryColor));
                    if (state is BasketError) return Center(child: Text("Error: ${state.message}", style: const TextStyle(color: Colors.red)));
                    if (state is BasketLoaded) {
                      if (state.baskets.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.remove_shopping_cart, size: 60, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text(l10n.noBasketFound, style: TextStyle(color: Colors.grey.shade500)),
                            ],
                          ),
                        );
                      }
                      return isDesktop
                          ? _buildDesktopTable(context, state.baskets, l10n)
                          : _buildMobileList(context, state.baskets, l10n);
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
  Widget _buildDesktopTable(BuildContext context, List<Basket> baskets, AppLocalizations l10n) {
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
                    dataRowMinHeight: 60,
                    dataRowMaxHeight: 60,
                    columns: [
                      DataColumn(label: Text(l10n.basketCode.toUpperCase(), style: _headerStyle)),
                      DataColumn(label: Text(l10n.status.toUpperCase(), style: _headerStyle)),
                      DataColumn(label: Text(l10n.tareWeight.toUpperCase(), style: _headerStyle)),
                      DataColumn(label: Text(l10n.note.toUpperCase(), style: _headerStyle)),
                      DataColumn(label: Text(l10n.actions.toUpperCase(), style: _headerStyle)),
                    ],
                    rows: baskets.map((item) {
                      return DataRow(
                        cells: [
                          DataCell(Text(item.code, style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(_buildStatusBadge(item.status, l10n)),
                          DataCell(Text("${item.tareWeight} kg")),
                          DataCell(Text(item.note, overflow: TextOverflow.ellipsis)),
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

  TextStyle get _headerStyle => TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5);

  // --- MOBILE LIST ---
  Widget _buildMobileList(BuildContext context, List<Basket> baskets, AppLocalizations l10n) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: baskets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = baskets[index];
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
              backgroundColor: Colors.brown.shade50,
              child: Icon(Icons.shopping_basket, color: Colors.brown.shade800, size: 20),
            ),
            title: Text(item.code, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text("${item.tareWeight} kg", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 6),
                _buildStatusBadge(item.status, l10n, isChip: false),
              ],
            ),
            trailing: PopupMenuButton(
              onSelected: (val) {
                if (val == 'edit') _showEditDialog(context, item, l10n);
                if (val == 'delete') _confirmDelete(context, item, l10n);
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(value: 'edit', child: Row(children: [const Icon(Icons.edit, size: 18), const SizedBox(width: 8), Text(l10n.editBasket)])),
                PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete, size: 18, color: Colors.red), const SizedBox(width: 8), Text(l10n.deleteBasket)])),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- DIALOG ---
  void _showEditDialog(BuildContext context, Basket? item, AppLocalizations l10n) {
    final codeCtrl = TextEditingController(text: item?.code ?? '');
    final weightCtrl = TextEditingController(text: item?.tareWeight.toString() ?? '0');
    final noteCtrl = TextEditingController(text: item?.note ?? '');
    String selectedStatus = item?.status ?? 'READY';
    
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.all(24),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        title: Text(item == null ? l10n.addBasket : l10n.editBasket, style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    Expanded(child: TextFormField(controller: codeCtrl, decoration: _inputDeco(l10n.basketCode), validator: (v) => v!.isEmpty ? "Required" : null)),
                    const SizedBox(width: 12),
                    Expanded(child: TextFormField(controller: weightCtrl, decoration: _inputDeco(l10n.tareWeight), keyboardType: TextInputType.number)),
                  ]),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: _inputDeco(l10n.status),
                    items: _statusList.map((s) => DropdownMenuItem(value: s, child: Text(_getStatusText(s, l10n)))).toList(),
                    onChanged: (val) => selectedStatus = val!,
                  ),
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
                final newItem = Basket(
                  id: item?.id ?? 0,
                  code: codeCtrl.text,
                  tareWeight: double.tryParse(weightCtrl.text) ?? 0,
                  status: selectedStatus,
                  note: noteCtrl.text,
                );
                context.read<BasketCubit>().saveBasket(basket: newItem, isEdit: item != null);
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
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

  // --- HELPER STATUS ---
  String _getStatusText(String status, AppLocalizations l10n) {
    switch (status) {
      case 'READY': return l10n.stReady;
      case 'IN_USE': return l10n.stInUse;
      case 'HOLDING': return l10n.stHolding;
      case 'DAMAGED': return l10n.stDamaged;
      default: return status;
    }
  }

  Widget _buildStatusBadge(String status, AppLocalizations l10n, {bool isChip = true}) {
    Color color;
    switch (status) {
      case 'READY': color = Colors.green; break;
      case 'IN_USE': color = Colors.blue; break;
      case 'HOLDING': color = Colors.orange; break;
      case 'DAMAGED': color = Colors.red; break;
      default: color = Colors.grey;
    }

    String label = _getStatusText(status, l10n);

    if (!isChip) {
      return Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12));
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  void _confirmDelete(BuildContext context, Basket item, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteBasket),
        content: Text(l10n.confirmDeleteBasket(item.code)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              context.read<BasketCubit>().deleteBasket(item.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(l10n.deleteBasket),
          ),
        ],
      ),
    );
  }
}