import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

// Import Material Export modules
import '../bloc/material_export_cubit.dart';
import '../../domain/material_export_model.dart';
import 'material_export_screen.dart'; 
import 'material_export_detail_screen.dart'; 

// [IMP] Import Batch modules để lấy thông tin lô
import 'package:production_app_frontend/features/inventory/batch/presentation/bloc/batch_cubit.dart';
import 'package:production_app_frontend/features/inventory/batch/domain/batch_model.dart';

// Enum cho các loại lọc
enum FilterType { day, week, month, quarter, year, all }

class MaterialExportListScreen extends StatefulWidget {
  const MaterialExportListScreen({super.key});

  @override
  State<MaterialExportListScreen> createState() => _MaterialExportListScreenState();
}

class _MaterialExportListScreenState extends State<MaterialExportListScreen> {
  final _searchCtrl = TextEditingController();
  
  // State cho bộ lọc
  FilterType _filterType = FilterType.month;
  DateTime _selectedDate = DateTime.now();
  
  // Timer cho Debounce search
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // 1. Load danh sách phiếu xuất
    _loadData();
    // 2. [NEW] Load danh sách Batch để map ID -> Code
    context.read<BatchCubit>().loadBatches();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _loadData();
    });
  }

  void _loadData() {
    // (Logic lọc ngày tháng giữ nguyên như cũ)
    DateTime? fromDate;
    DateTime? toDate;
    final date = _selectedDate;
    
    switch (_filterType) {
      case FilterType.day:
        fromDate = date;
        toDate = date;
        break;
      case FilterType.week:
        fromDate = date.subtract(Duration(days: date.weekday - 1));
        toDate = date.add(Duration(days: 7 - date.weekday));
        break;
      case FilterType.month:
        fromDate = DateTime(date.year, date.month, 1);
        toDate = DateTime(date.year, date.month + 1, 0);
        break;
      case FilterType.quarter:
        int quarter = ((date.month - 1) / 3).floor() + 1;
        fromDate = DateTime(date.year, (quarter - 1) * 3 + 1, 1);
        toDate = DateTime(date.year, quarter * 3 + 1, 0);
        break;
      case FilterType.year:
        fromDate = DateTime(date.year, 1, 1);
        toDate = DateTime(date.year, 12, 31);
        break;
      case FilterType.all:
        fromDate = null;
        toDate = null;
        break;
    }

    context.read<MaterialExportCubit>().loadExports(
      search: _searchCtrl.text,
    );
  }

  String _getFilterText() {
    final df = DateFormat('dd/MM/yyyy');
    switch (_filterType) {
      case FilterType.day: return df.format(_selectedDate);
      case FilterType.week: return "Tuần ${((_selectedDate.day - 1) / 7).floor() + 1} - Tháng ${_selectedDate.month}"; 
      case FilterType.month: return "Tháng ${_selectedDate.month}/${_selectedDate.year}";
      case FilterType.quarter: return "Quý ${((_selectedDate.month - 1) / 3).floor() + 1}/${_selectedDate.year}";
      case FilterType.year: return "Năm ${_selectedDate.year}";
      case FilterType.all: return "Tất cả";
    }
  }

  void _changeFilterDate(int offset) {
    setState(() {
      switch (_filterType) {
        case FilterType.day: _selectedDate = _selectedDate.add(Duration(days: offset)); break;
        case FilterType.week: _selectedDate = _selectedDate.add(Duration(days: offset * 7)); break;
        case FilterType.month: _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + offset, 1); break;
        case FilterType.quarter: _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + (offset * 3), 1); break;
        case FilterType.year: _selectedDate = DateTime(_selectedDate.year + offset, 1, 1); break;
        case FilterType.all: break;
      }
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Danh sách Phiếu Xuất Sợi"),
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFC2185B),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _navigateToDetail(null),
      ),
      body: Column(
        children: [
          // 1. THANH TÌM KIẾM
          Container(
            color: const Color(0xFF003366), 
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged, 
              decoration: InputDecoration(
                hintText: "Tìm theo mã phiếu, ghi chú...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchCtrl.clear();
                    _loadData();
                  },
                ),
              ),
              onSubmitted: (_) => _loadData(),
            ),
          ),

          // 2. BỘ LỌC THỜI GIAN
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.white,
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip("Ngày", FilterType.day),
                      _buildFilterChip("Tuần", FilterType.week),
                      _buildFilterChip("Tháng", FilterType.month),
                      _buildFilterChip("Quý", FilterType.quarter),
                      _buildFilterChip("Năm", FilterType.year),
                      _buildFilterChip("Tất cả", FilterType.all),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (_filterType != FilterType.all)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeFilterDate(-1)),
                      Text(_getFilterText(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF003366))),
                      IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeFilterDate(1)),
                    ],
                  ),
              ],
            ),
          ),
          
          const Divider(height: 1),

          // 3. DANH SÁCH
          Expanded(
            // [NEW] Sử dụng MultiBlocListener hoặc lồng BlocBuilder để lấy data từ cả 2 Cubit
            child: BlocBuilder<BatchCubit, BatchState>(
              builder: (context, batchState) {
                // Tạo Map để tra cứu nhanh: batchId -> batchCode
                Map<int, String> batchMap = {};
                if (batchState is BatchLoaded) {
                  for (var b in batchState.batches) {
                    // Ưu tiên internalBatchCode, nếu rỗng thì dùng supplierBatchNo
                    batchMap[b.batchId] = b.internalBatchCode.isNotEmpty 
                        ? b.internalBatchCode 
                        : b.supplierBatchNo;
                  }
                }

                return BlocConsumer<MaterialExportCubit, MaterialExportState>(
                  listener: (context, state) {
                    if (state is MaterialExportError) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
                    }
                  },
                  builder: (context, state) {
                    if (state is MaterialExportLoading) return const Center(child: CircularProgressIndicator());
                    
                    if (state is MaterialExportListLoaded) {
                      if (state.list.isEmpty) {
                        return Center(child: Text("Không tìm thấy phiếu xuất nào", style: TextStyle(color: Colors.grey.shade500)));
                      }
                      
                      return ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: state.list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = state.list[index];
                          // Truyền batchMap vào hàm build card
                          return _buildExportCard(item, batchMap);
                        },
                      );
                    }
                    return const SizedBox();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, FilterType type) {
    final isSelected = _filterType == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {
          if (val) {
            setState(() {
              _filterType = type;
              _selectedDate = DateTime.now(); 
            });
            _loadData();
          }
        },
        selectedColor: const Color(0xFF003366).withOpacity(0.1),
        labelStyle: TextStyle(
          color: isSelected ? const Color(0xFF003366) : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
        ),
      ),
    );
  }

  // [UPDATED] Hàm nhận thêm batchMap để hiển thị tên lô
  Widget _buildExportCard(MaterialExport item, Map<int, String> batchMap) {
    // Tổng hợp thông tin từ chi tiết
    // Map batchId -> batchCode
    final batches = item.details.map((d) {
      final code = batchMap[d.batchId] ?? "Batch#${d.batchId}"; // Fallback nếu chưa load kịp
      return code;
    }).toSet().join(", ");

    final machines = item.details.map((d) => "Máy ${d.machineId}").toSet().join(", ");
    final lines = item.details.map((d) => "L${d.machineLine}").toSet().join(",");

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _navigateToDetail(item),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.output, color: Color(0xFF003366), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.exportCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(DateFormat('dd/MM/yyyy HH:mm').format(item.exportDate), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.grey),
                    onPressed: () => _confirmDelete(item),
                  ),
                ],
              ),
              
              const Divider(height: 24),

              // Body Card
              _buildInfoRow(Icons.person, "Người tạo:", item.createdBy ?? "N/A"),
              const SizedBox(height: 6),
              // [UPDATED] Hiển thị mã lô đã map
              _buildInfoRow(Icons.qr_code_2, "Lô (Batch):", batches.isNotEmpty ? batches : "--"),
              const SizedBox(height: 6),
              _buildInfoRow(Icons.precision_manufacturing, "Máy / Line:", "${machines.isNotEmpty ? machines : '--'}  |  Line: ${lines.isNotEmpty ? lines : '--'}"),
              
              const SizedBox(height: 12),
              // Footer
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        "Tổng dòng: ${item.details.length}", 
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w500)
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.blueGrey),
        const SizedBox(width: 8),
        Text("$label ", style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Expanded(
          child: Text(value, style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  void _navigateToDetail(MaterialExport? item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => item == null 
          ? const MaterialExportScreen() 
          : MaterialExportDetailScreen(export: item)), 
    ).then((shouldReload) {
      if (mounted) _loadData();
    });
  }

  void _confirmDelete(MaterialExport item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hủy phiếu xuất", style: TextStyle(color: Colors.red)),
        content: Text("Bạn có chắc chắn muốn hủy phiếu ${item.exportCode}?\n\n- Hoàn trả tồn kho.\n- Xóa các phiếu rổ dệt liên quan."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Đóng")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              if (item.id != null) {
                 context.read<MaterialExportCubit>().deleteExport(item.id!);
              }
            },
            child: const Text("Xác nhận Hủy"),
          )
        ],
      ),
    );
  }
}