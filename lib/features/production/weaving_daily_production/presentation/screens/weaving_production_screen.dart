import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Để dùng Clipboard
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:production_app_frontend/l10n/app_localizations.dart'; 
import 'package:production_app_frontend/features/production/weaving_daily_production/services/weaving_export_service.dart';

import '../bloc/weaving_production_cubit.dart';
import '../../domain/weaving_production_model.dart';

class WeavingProductionScreen extends StatefulWidget {
  // [MỚI] Tham số để xác định chế độ hiển thị (độc lập hay nhúng trong TabBar)
  final bool isEmbedded;
  
  const WeavingProductionScreen({super.key, this.isEmbedded = false});

  @override
  State<WeavingProductionScreen> createState() => _WeavingProductionScreenState();
}

class _WeavingProductionScreenState extends State<WeavingProductionScreen> {
  final _searchCtrl = TextEditingController();
  DateTime? _fromDate;
  DateTime? _toDate;
  final _currencyFormat = NumberFormat("#,##0.00", "vi_VN");

  // Lưu key để dịch đa ngôn ngữ trong hàm build
  String _dateFilterKey = "filter7Days"; 

  @override
  void initState() {
    super.initState();
    // Mặc định lọc 7 ngày gần nhất
    _applyQuickFilter('7_days');
    
    // Đảm bảo widget đã build xong trước khi load data
    WidgetsBinding.instance.addPostFrameCallback((_) {
       _onSearch();
    });
  }

  void _onSearch() {
    context.read<WeavingProductionCubit>().loadData(
      keyword: _searchCtrl.text,
      fromDate: _fromDate,
      toDate: _toDate,
    );
  }

  void _applyQuickFilter(String type) {
    final now = DateTime.now();
    DateTime start;
    DateTime end = now;
    String filterKey = "";

    switch (type) {
      case 'today':
        start = now;
        filterKey = "filterToday";
        break;
      case 'yesterday':
        start = now.subtract(const Duration(days: 1));
        end = now.subtract(const Duration(days: 1));
        filterKey = "filterYesterday";
        break;
      case '7_days':
        start = now.subtract(const Duration(days: 7));
        filterKey = "filter7Days";
        break;
      case 'this_month':
        start = DateTime(now.year, now.month, 1);
        filterKey = "filterThisMonth";
        break;
      case 'last_month':
        start = DateTime(now.year, now.month - 1, 1);
        end = DateTime(now.year, now.month, 0); 
        filterKey = "filterLastMonth";
        break;
      case 'this_quarter':
        int quarter = ((now.month - 1) / 3).floor() + 1;
        int firstMonthOfQuarter = (quarter - 1) * 3 + 1;
        start = DateTime(now.year, firstMonthOfQuarter, 1);
        filterKey = "filterThisQuarter"; 
        break;
      case 'this_year':
        start = DateTime(now.year, 1, 1);
        filterKey = "filterThisYear";
        break;
      default:
        start = now;
        filterKey = "filterToday";
    }

    setState(() {
      _fromDate = start;
      _toDate = end;
      _dateFilterKey = filterKey;
    });
    _onSearch();
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: (_fromDate != null && _toDate != null) 
          ? DateTimeRange(start: _fromDate!, end: _toDate!) 
          : null,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color(0xFF003366),
            colorScheme: const ColorScheme.light(primary: Color(0xFF003366)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
        _dateFilterKey = "filterCustom";
      });
      _onSearch();
    }
  }

  // Helper lấy label từ key
  String _getFilterLabel(AppLocalizations l10n) {
    switch (_dateFilterKey) {
      case "filterToday": return l10n.filterToday;
      case "filterYesterday": return l10n.filterYesterday;
      case "filter7Days": return l10n.filter7Days;
      case "filterThisMonth": return l10n.filterThisMonth;
      case "filterLastMonth": return l10n.filterLastMonth;
      case "filterThisQuarter": return l10n.filterThisQuarter;
      case "filterThisYear": return l10n.filterThisYear;
      case "filterCustom": return l10n.filterCustom;
      default: return l10n.filter7Days;
    }
  }

  void _onExport(AppLocalizations l10n) async {
    final state = context.read<WeavingProductionCubit>().state;
    
    if (state is WeavingProductionLoaded && state.productions.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exporting), duration: const Duration(seconds: 1)),
      );

      try {
        await WeavingExportService.exportToExcel(state.productions);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.exportError(e.toString())), backgroundColor: Colors.red),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noStatsData)),
      );
    }
  }

@override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;

  return Scaffold(
    backgroundColor: const Color(0xFFF5F7FA),
    // [CẬP NHẬT] AppBar ẩn nếu nhúng, hiện nếu độc lập
    appBar: widget.isEmbedded 
        ? null 
        : AppBar(
            title: Text(
              l10n.prodStatsTitle, 
              style: const TextStyle(
                color: Colors.white, 
                fontWeight: FontWeight.bold, 
                fontSize: 16 // [Đồng nhất]
              )
            ),
            backgroundColor: const Color(0xFF003366),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.download), 
                tooltip: l10n.exportExcel,
                onPressed: () => _onExport(l10n),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: l10n.refreshData,
                onPressed: _onSearch,
              ),
              IconButton(
                icon: const Icon(Icons.calculate_outlined),
                tooltip: l10n.recalculateToday,
                onPressed: () => context.read<WeavingProductionCubit>().recalculateToday(),
              )
            ],
          ),
    body: Column(
      children: [
        // [CẬP NHẬT] Toolbar phụ cho chế độ Embedded
        if (widget.isEmbedded)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.black12)), // Thêm đường kẻ dưới
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Nút Export Excel
                  OutlinedButton.icon(
                    onPressed: () => _onExport(l10n),
                    icon: const Icon(Icons.download, size: 18),
                    label: Text(l10n.exportExcel),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF003366),
                      side: const BorderSide(color: Color(0xFF003366)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Nút Refresh
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.grey),
                    tooltip: l10n.refreshData,
                    onPressed: _onSearch,
                  ),
                  // Nút Tính toán lại
                  IconButton(
                    icon: const Icon(Icons.calculate_outlined, color: Colors.blue),
                    tooltip: l10n.recalculateToday,
                    onPressed: () => context.read<WeavingProductionCubit>().recalculateToday(),
                  )
                ],
              ),
            ),

        // --- HEADER BỘ LỌC ---
        Container(
          padding: const EdgeInsets.all(10), // Compact padding
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.black12)),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 40,
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: l10n.searchProductHint,
                    prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 14),
                  onSubmitted: (_) => _onSearch(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Filter Chip (Date Preset)
                  PopupMenuButton<String>(
                    onSelected: _applyQuickFilter,
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'today', child: Text(l10n.filterToday)),
                      PopupMenuItem(value: 'yesterday', child: Text(l10n.filterYesterday)),
                      PopupMenuItem(value: '7_days', child: Text(l10n.filter7Days)),
                      const PopupMenuDivider(),
                      PopupMenuItem(value: 'this_month', child: Text(l10n.filterThisMonth)),
                      PopupMenuItem(value: 'last_month', child: Text(l10n.filterLastMonth)),
                      PopupMenuItem(value: 'this_quarter', child: Text(l10n.filterThisQuarter)),
                      PopupMenuItem(value: 'this_year', child: Text(l10n.filterThisYear)),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.filter_list, size: 16, color: Color(0xFF003366)),
                          const SizedBox(width: 6),
                          Text(_getFilterLabel(l10n), style: const TextStyle(color: Color(0xFF003366), fontWeight: FontWeight.bold, fontSize: 13)),
                          const Icon(Icons.arrow_drop_down, color: Color(0xFF003366), size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Custom Date Range Picker
                  Expanded(
                    child: InkWell(
                      onTap: _pickDateRange,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                (_fromDate != null && _toDate != null)
                                    ? "${DateFormat('dd/MM').format(_fromDate!)} - ${DateFormat('dd/MM').format(_toDate!)}"
                                    : l10n.filterCustom,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // --- KẾT QUẢ ---
        Expanded(
          child: BlocBuilder<WeavingProductionCubit, WeavingProductionState>(
            builder: (context, state) {
              if (state is WeavingProductionLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is WeavingProductionError) {
                return Center(child: Text("Error: ${state.message}", style: const TextStyle(color: Colors.red)));
              }

              if (state is WeavingProductionLoaded) {
                final list = state.productions;
                if (list.isEmpty) {
                  return _buildEmptyState(l10n);
                }

                double sumKg = list.fold(0, (sum, item) => sum + item.totalKg);
                double sumMeters = list.fold(0, (sum, item) => sum + item.totalMeters);

                return SelectionArea(
                  child: Column(
                    children: [
                      _buildSummaryCard(sumKg, sumMeters, list.length, l10n),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          itemCount: list.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            return _buildItemCard(context, list[index], l10n);
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ],
    ),
  );
}

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(l10n.noStatsData, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(double totalKg, double totalMeters, int count, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue.shade800, Colors.blue.shade600]),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem(l10n.totalProduction, _currencyFormat.format(totalKg), "kg", Colors.white),
          Container(width: 1, height: 30, color: Colors.white30),
          _buildStatItem(l10n.totalLength, _currencyFormat.format(totalMeters), "m", Colors.white),
          Container(width: 1, height: 30, color: Colors.white30),
          _buildStatItem(l10n.itemCount, "$count", "", Colors.white),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String unit, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: color.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
            if(unit.isNotEmpty) ...[
              const SizedBox(width: 2),
              Text(unit, style: TextStyle(color: color.withOpacity(0.9), fontSize: 11)),
            ]
          ],
        ),
      ],
    );
  }

  Widget _buildItemCard(BuildContext context, WeavingDailyProduction item, AppLocalizations l10n) {
    return Card(
      elevation: 1,
      shadowColor: Colors.black12,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      surfaceTintColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            // Header Item
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                  child: const Icon(Icons.calendar_today, size: 12, color: Colors.blueGrey),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat("dd/MM/yyyy").format(item.date),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.orange.shade200, width: 0.5),
                  ),
                  child: Text(
                    "${item.activeMachineLines} ${l10n.machines}", 
                    style: TextStyle(fontSize: 10, color: Colors.orange.shade800, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    final String text = "${l10n.date}: ${DateFormat('dd/MM/yyyy').format(item.date)}\n${l10n.product}: ${item.product?.itemCode}\n${l10n.output}: ${_currencyFormat.format(item.totalKg)} kg";
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.copySuccess), duration: const Duration(seconds: 1)));
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(2.0),
                    child: Icon(Icons.copy, size: 16, color: Colors.grey),
                  ),
                )
              ],
            ),
            
            const Divider(height: 12, thickness: 0.5),
            
            // Body Item
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ảnh sản phẩm
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: 48, 
                    height: 48,
                    color: Colors.grey.shade200,
                    child: (item.product?.imageUrl != null && item.product!.imageUrl!.isNotEmpty)
                        ? Image.network(item.product!.imageUrl!, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.image_not_supported, color: Colors.grey, size: 18))
                        : const Icon(Icons.image, color: Colors.grey, size: 18),
                  ),
                ),
                const SizedBox(width: 10),
                
                // Thông tin chi tiết
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.product?.itemCode ?? "Unknown Product",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF003366)),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      if (item.product?.note != null)
                        Text(item.product!.note!, style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                
                // Số liệu
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("${_currencyFormat.format(item.totalKg)} kg", 
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text("${_currencyFormat.format(item.totalMeters)} m", 
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 11)),
                  ],
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}