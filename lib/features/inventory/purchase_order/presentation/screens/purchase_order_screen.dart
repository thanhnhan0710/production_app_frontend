import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

// --- IMPORTS ---
import '../../../../../core/widgets/responsive_layout.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/network/websocket_service.dart';

import '../../domain/purchase_order_model.dart';
import '../bloc/purchase_order_cubit.dart';
import '../../../supplier/domain/supplier_model.dart';
import '../../../supplier/presentation/bloc/supplier_cubit.dart';
import 'purchase_order_detail_screen.dart';
import 'create_purchase_order_screen.dart';

class PurchaseOrderScreen extends StatefulWidget {
  final int? filterProductId;
  const PurchaseOrderScreen({super.key, this.filterProductId});

  @override
  State<PurchaseOrderScreen> createState() => _PurchaseOrderScreenState();
}

class _PurchaseOrderScreenState extends State<PurchaseOrderScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  final Color _primaryColor = const Color(0xFF003366);
  final Color _accentColor = const Color(0xFF0055AA);
  final Color _bgLight = const Color(0xFFF5F7FA);

  final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _loadData();
    context.read<SupplierCubit>().loadSuppliers();

    // Lắng nghe WebSocket
    WebSocketService().connect();
    WebSocketService().addListener(_onWebSocketMessage);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();

    // Hủy lắng nghe WebSocket
    WebSocketService().removeListener(_onWebSocketMessage);
    super.dispose();
  }

  // Xử lý khi nhận tín hiệu từ WebSocket
  void _onWebSocketMessage(String message) {
    if (message == "REFRESH_PURCHASE_ORDERS") {
      debugPrint("WebSocket: Làm mới danh sách Purchase Orders.");
      if (mounted) _loadData();
    }
  }

  void _loadData() {
    context.read<PurchaseOrderCubit>().loadPurchaseOrders();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<PurchaseOrderCubit>().loadPurchaseOrders(search: query);
    });
  }

  void _navigateToForm({PurchaseOrderHeader? po}) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => CreatePurchaseOrderScreen(existingPO: po)),
    ).then((_) {
      _loadData();
    });
  }

  void _navigateToDetail(int poId) {
    Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => PurchaseOrderDetailScreen(poId: poId)))
        .then((_) => _loadData());
  }

  // Hàm xử lý chọn file Excel và Import
  void _onImportExcelPressed() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xls', 'xlsx'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty && mounted) {
      context.read<PurchaseOrderCubit>().importExcel(result.files.first);
    }
  }

  // Hàm hiển thị kết quả Import chi tiết (Dialog)
  void _showImportResultDialog(
      BuildContext context, String title, String message, Color color) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
                color == Colors.green
                    ? Icons.check_circle
                    : Icons.warning_amber_rounded,
                color: color),
            const SizedBox(width: 10),
            Text(title,
                style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Text(message,
                style: const TextStyle(fontSize: 14, height: 1.5)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Đóng"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: _bgLight,
      body: SelectionArea(
        child: BlocConsumer<PurchaseOrderCubit, PurchaseOrderState>(
          listener: (context, state) {
            if (state is POError) {
              if (state.message.contains("Đã import thành công")) {
                // Có lỗi cảnh báo từ Import -> Show Dialog
                _showImportResultDialog(context, "Kết quả Import (Có lỗi)",
                    state.message, Colors.orange);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating),
                );
              }
            } else if (state is POSuccess) {
              if (state.message.contains("Đã import thành công")) {
                _showImportResultDialog(
                    context, "Thành công", state.message, Colors.green);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating),
                );
              }
            }
          },
          builder: (context, state) {
            List<PurchaseOrderHeader> items = [];
            bool isLoading = false;

            if (state is POLoading) {
              isLoading = true;
            } else if (state is POListLoaded) {
              items = state.list;
              if (widget.filterProductId != null) {
                items = items
                    .where((b) => b.details
                        .any((d) => d.materialId == widget.filterProductId))
                    .toList();
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- HEADER SECTION ---
                Container(
                  color: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: _primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10)),
                            child: Icon(Icons.shopping_cart_outlined,
                                color: _primaryColor, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.purchaseOrderTitle,
                                  style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade800)),
                              const SizedBox(height: 2),
                              Text(l10n.purchaseOrderSubtitle,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade500)),
                            ],
                          ),
                          const Spacer(),
                          if (isDesktop) ...[
                            // NÚT IMPORT EXCEL
                            OutlinedButton.icon(
                              onPressed: _onImportExcelPressed,
                              icon: const Icon(Icons.upload_file, size: 18),
                              label: const Text('IMPORT EXCEL'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _primaryColor,
                                side: BorderSide(color: _primaryColor),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // NÚT CREATE PO
                            ElevatedButton.icon(
                              onPressed: () => _navigateToForm(),
                              icon: const Icon(Icons.add, size: 18),
                              label: Text(l10n.createPO),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 16),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ]
                        ],
                      ),
                      const SizedBox(height: 24),

                      // --- SEARCH ---
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                  color: _bgLight,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.grey.shade200)),
                              child: TextField(
                                controller: _searchController,
                                textInputAction: TextInputAction.search,
                                decoration: InputDecoration(
                                  hintText: l10n.searchPO,
                                  hintStyle: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 14),
                                  prefixIcon: Icon(Icons.search,
                                      color: Colors.grey.shade500, size: 20),
                                  border: InputBorder.none,
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon:
                                              const Icon(Icons.clear, size: 18),
                                          onPressed: () {
                                            _searchController.clear();
                                            _onSearchChanged('');
                                            setState(() {});
                                          })
                                      : null,
                                ),
                                onChanged: _onSearchChanged,
                                onSubmitted: (value) {
                                  if (_debounce?.isActive ?? false) {
                                    _debounce!.cancel();
                                  }
                                  context
                                      .read<PurchaseOrderCubit>()
                                      .loadPurchaseOrders(search: value);
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
                                border:
                                    Border.all(color: Colors.grey.shade300)),
                            child: const Icon(Icons.filter_list,
                                color: Colors.grey, size: 20),
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
                      if (isLoading) {
                        return Center(
                            child: CircularProgressIndicator(
                                color: _primaryColor));
                      }
                      if (state is POListLoaded) {
                        if (items.isEmpty) {
                          return Center(
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                Icon(Icons.remove_shopping_cart_outlined,
                                    size: 60, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(l10n.noStatsData,
                                    style:
                                        TextStyle(color: Colors.grey.shade500))
                              ]));
                        }
                        return isDesktop
                            ? _buildDesktopTable(context, items, l10n)
                            : _buildMobileList(context, items, l10n);
                      }
                      return const SizedBox();
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: !isDesktop
          ? FloatingActionButton(
              backgroundColor: _accentColor,
              onPressed: () => _navigateToForm(),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  // --- DESKTOP TABLE ---
  Widget _buildDesktopTable(BuildContext context,
      List<PurchaseOrderHeader> items, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200)),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    showCheckboxColumn: false,
                    headingRowColor:
                        WidgetStateProperty.all(const Color(0xFFF9FAFB)),
                    horizontalMargin: 24,
                    columnSpacing: 24,
                    dataRowMinHeight: 64,
                    dataRowMaxHeight: double.infinity,
                    columns: [
                      DataColumn(
                          label: Text(l10n.poNumber.toUpperCase(),
                              style: _headerStyle)),
                      DataColumn(
                          label: Text(l10n.vendor.toUpperCase(),
                              style: _headerStyle)),
                      DataColumn(
                          label: Text(l10n.orderDate.toUpperCase(),
                              style: _headerStyle)),
                      DataColumn(
                          label: Text(l10n.eta.toUpperCase(),
                              style: _headerStyle)),
                      DataColumn(label: Text("TỔNG CUỘN", style: _headerStyle)),
                      DataColumn(
                          label: Text(l10n.incoterm.toUpperCase(),
                              style: _headerStyle)),
                      DataColumn(
                          label: Text(l10n.totalAmount.toUpperCase(),
                              style: _headerStyle)),
                      DataColumn(
                          label: Text(l10n.status.toUpperCase(),
                              style: _headerStyle)),
                      DataColumn(
                          label: Text(l10n.actions.toUpperCase(),
                              style: _headerStyle)),
                    ],
                    rows: items.map((po) {
                      return DataRow(
                        onSelectChanged: (_) => _navigateToDetail(po.poId),
                        cells: [
                          DataCell(Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(po.poNumber,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87)))),
                          DataCell(_VendorName(
                              vendorId: po.vendorId, vendorObj: po.vendor)),
                          DataCell(Text(_dateFormat.format(po.orderDate))),
                          DataCell(Text(po.expectedArrivalDate != null
                              ? _dateFormat.format(po.expectedArrivalDate!)
                              : "-")),

                          // Hiển thị Tổng cuộn
                          DataCell(Text("${po.totalRolls}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey))),

                          DataCell(Text(po.incoterm.name)),

                          // Hiển thị tiền theo VND quy đổi
                          DataCell(Text(
                            NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
                                .format(po.totalAmount * po.exchangeRate),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          )),

                          DataCell(_buildStatusBadge(po.status)),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Tooltip(
                                  message: l10n.edit,
                                  child: IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        color: Colors.orange, size: 20),
                                    onPressed: () => _navigateToForm(po: po),
                                    splashRadius: 20,
                                  ),
                                ),
                                if (po.status == POStatus.Draft)
                                  Tooltip(
                                    message: l10n.delete,
                                    child: IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.redAccent, size: 20),
                                      onPressed: () =>
                                          _confirmDelete(context, po, l10n),
                                      splashRadius: 20,
                                    ),
                                  )
                                else
                                  const SizedBox(width: 40),
                              ],
                            ),
                          ),
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

  TextStyle get _headerStyle => TextStyle(
      color: Colors.grey.shade600,
      fontWeight: FontWeight.bold,
      fontSize: 12,
      letterSpacing: 0.5);

  // --- MOBILE LIST ---
  Widget _buildMobileList(BuildContext context, List<PurchaseOrderHeader> items,
      AppLocalizations l10n) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final po = items[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _navigateToDetail(po.poId),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(po.poNumber,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                      PopupMenuButton<String>(
                        icon:
                            Icon(Icons.more_vert, color: Colors.grey.shade400),
                        padding: EdgeInsets.zero,
                        onSelected: (value) {
                          if (value == 'edit') _navigateToForm(po: po);
                          if (value == 'delete') {
                            _confirmDelete(context, po, l10n);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                              value: 'edit',
                              child: Row(children: [
                                const Icon(Icons.edit, size: 18),
                                const SizedBox(width: 8),
                                Text(l10n.edit)
                              ])),
                          if (po.status == POStatus.Draft)
                            PopupMenuItem(
                                value: 'delete',
                                child: Row(children: [
                                  const Icon(Icons.delete_outline,
                                      size: 18, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Text(l10n.delete,
                                      style: const TextStyle(color: Colors.red))
                                ])),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [_buildStatusBadge(po.status)]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Icon(Icons.store, size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    Expanded(
                        child: _VendorName(
                            vendorId: po.vendorId,
                            vendorObj: po.vendor,
                            style:
                                const TextStyle(fontWeight: FontWeight.w500)))
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.calendar_today,
                        size: 14, color: Colors.grey.shade400),
                    const SizedBox(width: 6),
                    Text("${l10n.date}: ${_dateFormat.format(po.orderDate)}",
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600))
                  ]),
                  const Divider(height: 20),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${po.incoterm.name} - ${po.currency}",
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text("Tổng cuộn: ${po.totalRolls}",
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.blueGrey,
                                    fontStyle: FontStyle.italic)),
                          ],
                        ),
                        Text(
                            NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
                                .format(po.totalAmount * po.exchangeRate),
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _primaryColor)),
                      ]),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(POStatus status) {
    Color color;
    switch (status) {
      case POStatus.Draft:
        color = Colors.grey;
        break;
      case POStatus.Sent:
        color = Colors.blue;
        break;
      case POStatus.Confirmed:
        color = Colors.indigo;
        break;
      case POStatus.Partial:
        color = Colors.orange;
        break;
      case POStatus.Completed:
        color = Colors.green;
        break;
      case POStatus.Cancelled:
        color = Colors.red;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withOpacity(0.2))),
      child: Text(status.name.toUpperCase(),
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _confirmDelete(
      BuildContext context, PurchaseOrderHeader po, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red),
          const SizedBox(width: 8),
          Text(l10n.deletePO)
        ]),
        content: Text(l10n.confirmDeletePO(po.poNumber)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<PurchaseOrderCubit>().deletePurchaseOrder(po.poId);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}

class _VendorName extends StatelessWidget {
  final int vendorId;
  final Supplier? vendorObj;
  final TextStyle? style;
  const _VendorName({required this.vendorId, this.vendorObj, this.style});

  @override
  Widget build(BuildContext context) {
    if (vendorObj != null) {
      return Text(vendorObj!.name,
          style: style ?? const TextStyle(fontWeight: FontWeight.w500));
    }
    return BlocBuilder<SupplierCubit, SupplierState>(builder: (context, state) {
      String name = "ID: $vendorId";
      if (state is SupplierLoaded) {
        final s = state.suppliers.where((e) => e.id == vendorId).firstOrNull;
        if (s != null) name = s.name;
      }
      return Text(name,
          style: style ?? const TextStyle(fontWeight: FontWeight.w500));
    });
  }
}
