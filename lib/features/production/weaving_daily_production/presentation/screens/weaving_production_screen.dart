import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Để dùng Clipboard
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:production_app_frontend/l10n/app_localizations.dart'; // Import file đa ngôn ngữ
import 'package:production_app_frontend/features/production/weaving_daily_production/services/weaving_export_service.dart';

import '../bloc/weaving_production_cubit.dart';
import '../../domain/weaving_production_model.dart';

class WeavingProductionScreen extends StatefulWidget {
  const WeavingProductionScreen({super.key});

  @override
  State<WeavingProductionScreen> createState() => _WeavingProductionScreenState();
}

class _WeavingProductionScreenState extends State<WeavingProductionScreen> {
  final _searchCtrl = TextEditingController();
  DateTime? _fromDate;
  DateTime? _toDate;
  final _currencyFormat = NumberFormat("#,##0.00", "vi_VN");

  // Thay vì lưu String tĩnh, ta lưu key để dịch trong hàm build
  String _dateFilterKey = "filter7Days"; 

  @override
  void initState() {
    super.initState();
    _applyQuickFilter('7_days');
    
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

  // Helper để lấy text từ key (vì switch case ở trên không truy cập được context để lấy l10n ngay lập tức)
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // [MỚI] Lấy đối tượng ngôn ngữ

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(l10n.prodStatsTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF003366),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.download), 
            tooltip: l10n.exportExcel,
            onPressed: () => _onExport(l10n), // Truyền l10n vào hàm export
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
          // --- HEADER BỘ LỌC ---
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.black12)),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: l10n.searchProductHint, // [MỚI] Đa ngôn ngữ
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _onSearch(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.filter_list, size: 18, color: Color(0xFF003366)),
                            const SizedBox(width: 8),
                            // [MỚI] Hiển thị label động theo ngôn ngữ
                            Text(_getFilterLabel(l10n), style: const TextStyle(color: Color(0xFF003366), fontWeight: FontWeight.bold)),
                            const Icon(Icons.arrow_drop_down, color: Color(0xFF003366)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: _pickDateRange,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month, size: 18, color: Colors.grey),
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
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            itemCount: list.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
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
          Icon(Icons.bar_chart, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(l10n.noStatsData, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(double totalKg, double totalMeters, int count, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue.shade800, Colors.blue.shade600]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem(l10n.totalProduction, _currencyFormat.format(totalKg), "kg", Colors.white),
          Container(width: 1, height: 40, color: Colors.white30),
          _buildStatItem(l10n.totalLength, _currencyFormat.format(totalMeters), "m", Colors.white),
          Container(width: 1, height: 40, color: Colors.white30),
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
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
            if(unit.isNotEmpty) ...[
              const SizedBox(width: 2),
              Text(unit, style: TextStyle(color: color.withOpacity(0.9), fontSize: 12)),
            ]
          ],
        ),
      ],
    );
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

  Widget _buildItemCard(BuildContext context, WeavingDailyProduction item, AppLocalizations l10n) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      surfaceTintColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                  child: const Icon(Icons.calendar_today, size: 14, color: Colors.blueGrey),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat("dd/MM/yyyy").format(item.date),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text(
                    "${item.activeMachineLines} ${l10n.machines}", // Sử dụng từ khóa đa ngôn ngữ
                    style: TextStyle(fontSize: 11, color: Colors.orange.shade800, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                // Nút Copy
                InkWell(
                  onTap: () {
                    final String text = 
                        "${l10n.date}: ${DateFormat('dd/MM/yyyy').format(item.date)}\n"
                        "${l10n.product}: ${item.product?.itemCode}\n"
                        "${l10n.output}: ${_currencyFormat.format(item.totalKg)} kg\n"
                        "${l10n.length}: ${_currencyFormat.format(item.totalMeters)} m";
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.copySuccess), duration: const Duration(seconds: 1)));
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(Icons.copy, size: 18, color: Colors.grey),
                  ),
                )
              ],
            ),
            const Divider(height: 20),
            
            // Body: Ảnh + Thông tin
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ảnh sản phẩm
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey.shade200,
                    child: (item.product?.imageUrl != null && item.product!.imageUrl!.isNotEmpty)
                        ? Image.network(
                            item.product!.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => const Icon(Icons.image_not_supported, color: Colors.grey),
                          )
                        : const Icon(Icons.image, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Thông tin chi tiết
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.product?.itemCode ?? "Unknown Product",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF003366)),
                      ),
                      const SizedBox(height: 4),
                      if (item.product?.note != null)
                        Text(item.product!.note!, style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                
                // Số liệu
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("${_currencyFormat.format(item.totalKg)} kg", 
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text("${_currencyFormat.format(item.totalMeters)} m", 
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13)),
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