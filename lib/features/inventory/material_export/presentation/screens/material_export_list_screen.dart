import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/material_export_cubit.dart';
import '../../domain/material_export_model.dart';
import 'material_export_screen.dart'; // Màn hình form tạo mới

class MaterialExportListScreen extends StatefulWidget {
  const MaterialExportListScreen({super.key});

  @override
  State<MaterialExportListScreen> createState() => _MaterialExportListScreenState();
}

class _MaterialExportListScreenState extends State<MaterialExportListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<MaterialExportCubit>().loadExports();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Danh sách Phiếu Xuất Sợi"),
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFC2185B),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MaterialExportScreen()),
          ).then((_) {
            // Reload list after coming back from create screen
            if (mounted) context.read<MaterialExportCubit>().loadExports();
          });
        },
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: "Tìm theo mã phiếu...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    context.read<MaterialExportCubit>().loadExports(search: _searchCtrl.text);
                  },
                ),
              ),
              onSubmitted: (val) => context.read<MaterialExportCubit>().loadExports(search: val),
            ),
          ),
          Expanded(
            child: BlocConsumer<MaterialExportCubit, MaterialExportState>(
              listener: (context, state) {
                if (state is MaterialExportError) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
                }
                 if (state is MaterialExportSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Thao tác thành công"), backgroundColor: Colors.green));
                }
              },
              // [FIXED] Sửa tên tham số (prev, curr) thành (previous, current) để khớp với logic bên trong
              buildWhen: (previous, current) => current is MaterialExportListLoaded || current is MaterialExportLoading,
              builder: (context, state) {
                if (state is MaterialExportLoading) return const Center(child: CircularProgressIndicator());
                
                if (state is MaterialExportListLoaded) {
                  if (state.list.isEmpty) return const Center(child: Text("Chưa có phiếu xuất nào"));
                  
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = state.list[index];
                      return _buildExportCard(item);
                    },
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

  Widget _buildExportCard(MaterialExport item) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade50,
          child: const Icon(Icons.output, color: Colors.blue),
        ),
        title: Text(item.exportCode, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text("Ngày: ${DateFormat('dd/MM/yyyy').format(item.exportDate)}"),
            Text("Kho: #${item.warehouseId} - Người nhận: #${item.receiverId}"),
            if (item.details.isNotEmpty)
              Text("Chi tiết: ${item.details.length} dòng", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _confirmDelete(item),
        ),
      ),
    );
  }

  void _confirmDelete(MaterialExport item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hủy phiếu xuất"),
        content: Text("Bạn có chắc chắn muốn hủy phiếu ${item.exportCode}?\n\nHành động này sẽ:\n- Hoàn trả số lượng về kho.\n- Xóa phiếu rổ dệt tương ứng (nếu chưa sản xuất)."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
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