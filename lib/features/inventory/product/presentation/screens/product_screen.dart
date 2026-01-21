import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// --- IMPORTS ---
// Đảm bảo đường dẫn import này đúng với cấu trúc dự án của bạn
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/widgets/responsive_layout.dart';
import '../../../../../core/constants/api_endpoints.dart'; // <--- Import quan trọng để lấy Server URL
import '../../domain/product_model.dart';
import '../bloc/product_cubit.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final _searchController = TextEditingController();
  
  // Màu sắc chủ đạo (có thể đưa vào Theme sau này)
  final Color _primaryColor = const Color(0xFF003366);
  final Color _accentColor = const Color(0xFFD81B60);
  final Color _bgLight = const Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    // Load dữ liệu khi màn hình khởi tạo
    context.read<ProductCubit>().loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: _bgLight,
      // SelectionArea cho phép user bôi đen/copy text trên màn hình (UX tốt cho Desktop)
      body: SelectionArea(
        child: BlocBuilder<ProductCubit, ProductState>(
          builder: (context, state) {
            int total = 0;
            if (state is ProductLoaded) total = state.products.length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ==========================
                // 1. HEADER & TOOLBAR
                // ==========================
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
                              color: Colors.pink.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.shopping_bag,
                                color: Colors.pink.shade800, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.productTitle,
                                  style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade800)),
                              const SizedBox(height: 2),
                              Text("Inventory > Finished Goods",
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.grey.shade500)),
                            ],
                          ),
                          const Spacer(),
                          // Nút thêm mới (Chỉ hiện trên Desktop)
                          if (isDesktop)
                            ElevatedButton.icon(
                              onPressed: () => _showEditDialog(context, null, l10n),
                              icon: const Icon(Icons.add, size: 18),
                              label: Text(l10n.addProduct.toUpperCase()),
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
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Search & Filter Row
                      Row(
                        children: [
                          if (isDesktop) ...[
                            _buildStatBadge(Icons.grid_view, "Total Products",
                                "$total", Colors.blue),
                            const SizedBox(width: 16),
                            const Spacer(),
                          ],
                          
                          // Ô Tìm kiếm
                          Expanded(
                            flex: isDesktop ? 0 : 1,
                            child: Container(
                              width: isDesktop ? 350 : double.infinity,
                              decoration: BoxDecoration(
                                  color: _bgLight,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade200)),
                              child: TextField(
                                controller: _searchController,
                                textInputAction: TextInputAction.search,
                                decoration: InputDecoration(
                                  hintText: l10n.searchProduct,
                                  hintStyle: TextStyle(
                                      color: Colors.grey.shade400, fontSize: 14),
                                  prefixIcon: Icon(Icons.search,
                                      color: Colors.grey.shade500, size: 20),
                                  border: InputBorder.none,
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.arrow_forward,
                                        color: Colors.blue),
                                    onPressed: () => context
                                        .read<ProductCubit>()
                                        .searchProducts(_searchController.text),
                                  ),
                                ),
                                onSubmitted: (value) => context
                                    .read<ProductCubit>()
                                    .searchProducts(value),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Nút Filter giả lập
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300)),
                            child: const Icon(Icons.filter_list,
                                color: Colors.grey, size: 20),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(height: 1, color: Colors.grey.shade200),

                // ==========================
                // 2. MAIN CONTENT
                // ==========================
                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (state is ProductLoading) {
                        return Center(
                            child: CircularProgressIndicator(color: _primaryColor));
                      }
                      if (state is ProductError) {
                        return Center(
                            child: Text("Error: ${state.message}",
                                style: const TextStyle(color: Colors.red)));
                      }
                      if (state is ProductLoaded) {
                        if (state.products.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inventory_2_outlined,
                                    size: 60, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(l10n.noProductFound,
                                    style: TextStyle(color: Colors.grey.shade500)),
                              ],
                            ),
                          );
                        }
                        // Responsive Switch: Table vs List
                        return isDesktop
                            ? _buildDesktopTable(context, state.products, l10n)
                            : _buildMobileList(context, state.products, l10n);
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
      // Floating Button cho Mobile
      floatingActionButton: !isDesktop
          ? FloatingActionButton(
              backgroundColor: _accentColor,
              onPressed: () => _showEditDialog(context, null, l10n),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  // --- WIDGET: DESKTOP TABLE ---
  Widget _buildDesktopTable(
      BuildContext context, List<Product> products, AppLocalizations l10n) {
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
                    headingRowColor:
                        MaterialStateProperty.all(const Color(0xFFF9FAFB)),
                    horizontalMargin: 24,
                    columnSpacing: 30,
                    dataRowMinHeight: 80,
                    dataRowMaxHeight: 80,
                    columns: [
                      DataColumn(
                          label: Text(l10n.productImage.toUpperCase(),
                              style: _headerStyle)),
                      DataColumn(
                          label: Text(l10n.itemCode.toUpperCase(),
                              style: _headerStyle)),
                      DataColumn(
                          label: Text(l10n.note.toUpperCase(),
                              style: _headerStyle)),
                      DataColumn(
                          label: Text(l10n.actions.toUpperCase(),
                              style: _headerStyle)),
                    ],
                    rows: products.map((item) {
                      return DataRow(
                        cells: [
                          DataCell(_buildImagePreview(context, item.imageUrl, 60)),
                          DataCell(Text(item.itemCode,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14))),
                          DataCell(
                              Text(item.note, overflow: TextOverflow.ellipsis)),
                          DataCell(Row(
                            children: [
                              IconButton(
                                  icon: const Icon(Icons.edit_note,
                                      color: Colors.grey),
                                  onPressed: () =>
                                      _showEditDialog(context, item, l10n)),
                              IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.redAccent),
                                  onPressed: () =>
                                      _confirmDelete(context, item, l10n)),
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

  TextStyle get _headerStyle => TextStyle(
      color: Colors.grey.shade600,
      fontWeight: FontWeight.bold,
      fontSize: 12,
      letterSpacing: 0.5);

  // --- WIDGET: MOBILE LIST ---
  Widget _buildMobileList(
      BuildContext context, List<Product> products, AppLocalizations l10n) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = products[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: _buildImagePreview(context, item.imageUrl, 50),
            title: Text(item.itemCode,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: item.note.isNotEmpty
                ? Text(item.note, maxLines: 1, overflow: TextOverflow.ellipsis)
                : null,
            trailing: PopupMenuButton(
              onSelected: (val) {
                if (val == 'edit') _showEditDialog(context, item, l10n);
                if (val == 'delete') _confirmDelete(context, item, l10n);
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      const Icon(Icons.edit, size: 18),
                      const SizedBox(width: 8),
                      Text(l10n.editProduct)
                    ])),
                PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      const Icon(Icons.delete, size: 18, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(l10n.deleteProduct)
                    ])),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- WIDGET: IMAGE PREVIEW (CÓ ZOOM) ---
  Widget _buildImagePreview(BuildContext context, String url, double size) {
    // [CLEAN CODE] Sử dụng Helper để lấy Full URL (đã xử lý logic localhost/IP)
    final fullUrl = ApiEndpoints.getImageUrl(url);

    return GestureDetector(
      onTap: () {
        if (fullUrl.isNotEmpty) {
          showDialog(
            context: context,
            builder: (ctx) => Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(10),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 4,
                    child: Image.network(
                      fullUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.error, color: Colors.white, size: 50),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      decoration: const BoxDecoration(
                          color: Colors.black54, shape: BoxShape.circle),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
      child: MouseRegion(
        cursor: fullUrl.isNotEmpty ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: fullUrl.isNotEmpty
                ? Image.network(
                    fullUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image, color: Colors.grey),
                  )
                : const Icon(Icons.image, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  // --- WIDGET: STAT BADGE ---
  Widget _buildStatBadge(
      IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        ])
      ]),
    );
  }

  // --- DIALOG: ADD/EDIT PRODUCT ---
  void _showEditDialog(
      BuildContext context, Product? item, AppLocalizations l10n) {
    final codeCtrl = TextEditingController(text: item?.itemCode ?? '');
    final noteCtrl = TextEditingController(text: item?.note ?? '');
    
    // State local để hiển thị ảnh preview khi user vừa chọn file
    PlatformFile? pickedFile;
    Uint8List? pickedBytes;

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false, // Bắt buộc user phải nhấn Cancel hoặc Save
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          
          Future<void> pickImage() async {
            try {
              // withData: true để lấy bytes (quan trọng cho Web)
              FilePickerResult? result = await FilePicker.platform
                  .pickFiles(type: FileType.image, withData: true);
              if (result != null) {
                setStateDialog(() {
                  pickedFile = result.files.first;
                  pickedBytes = result.files.first.bytes;
                });
              }
            } catch (e) {
              debugPrint("Error picking file: $e");
            }
          }

          // Xử lý ảnh preview trong Dialog
          ImageProvider? imageProvider;
          if (pickedBytes != null) {
            imageProvider = MemoryImage(pickedBytes!);
          } else if (item != null && item.imageUrl.isNotEmpty) {
             // Sử dụng Helper cho ảnh hiện có
            imageProvider = NetworkImage(ApiEndpoints.getImageUrl(item.imageUrl));
          }

          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            titlePadding: const EdgeInsets.all(24),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            title: Text(
              item == null ? l10n.addProduct : l10n.editProduct,
              style: TextStyle(
                  color: _primaryColor, fontWeight: FontWeight.bold),
            ),
            content: Form(
              key: formKey,
              child: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Upload Area
                      GestureDetector(
                        onTap: pickImage,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.grey.shade300,
                                width: 2,
                                style: BorderStyle.solid),
                            image: imageProvider != null
                                ? DecorationImage(
                                    image: imageProvider, fit: BoxFit.cover)
                                : null,
                          ),
                          child: imageProvider == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo,
                                        color: Colors.grey.shade400, size: 32),
                                    const SizedBox(height: 8),
                                    Text(l10n.uploadImage,
                                        style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 12))
                                  ],
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                          controller: codeCtrl,
                          decoration: _inputDeco(l10n.itemCode),
                          validator: (v) =>
                              v!.trim().isEmpty ? "Required" : null),
                      const SizedBox(height: 16),
                      TextFormField(
                          controller: noteCtrl,
                          decoration: _inputDeco(l10n.note),
                          maxLines: 2),
                    ],
                  ),
                ),
              ),
            ),
            actionsPadding: const EdgeInsets.all(24),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.cancel,
                      style: const TextStyle(color: Colors.grey))),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    final newItem = Product(
                      id: item?.id ?? 0,
                      itemCode: codeCtrl.text,
                      note: noteCtrl.text,
                      imageUrl: item?.imageUrl ?? '',
                    );
                    context.read<ProductCubit>().saveProduct(
                        product: newItem,
                        imageFile: pickedFile,
                        isEdit: item != null);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(item == null
                            ? l10n.successAdded
                            : l10n.successUpdated),
                        backgroundColor: Colors.green));
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                child: Text(l10n.save),
              ),
            ],
          );
        },
      ),
    );
  }

  InputDecoration _inputDeco(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  // --- DIALOG: CONFIRM DELETE ---
  void _confirmDelete(
      BuildContext context, Product item, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteProduct),
        content: Text(l10n.confirmDeleteProduct(item.itemCode)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              context.read<ProductCubit>().deleteProduct(item.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(l10n.deleteProduct),
          ),
        ],
      ),
    );
  }
}