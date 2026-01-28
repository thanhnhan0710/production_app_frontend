import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:production_app_frontend/features/inventory/basket/presentation/bloc/baket_cubit.dart';

// --- IMPORTS CUBITS & MODELS ---
import '../../../../../core/widgets/responsive_layout.dart';
import '../bloc/material_export_cubit.dart';
import '../../domain/material_export_model.dart';

// Inventory & Warehouse
import 'package:production_app_frontend/features/inventory/inventory/presentation/bloc/inventory_cubit.dart';
import 'package:production_app_frontend/features/inventory/inventory/domain/inventory_model.dart';
import 'package:production_app_frontend/features/inventory/warehouse/presentation/bloc/warehouse_cubit.dart';
import 'package:production_app_frontend/features/inventory/warehouse/domain/warehouse_model.dart';

// HR (Nhân viên, Ca, Lịch làm việc)
import 'package:production_app_frontend/features/hr/employee/presentation/bloc/employee_cubit.dart';
import 'package:production_app_frontend/features/hr/employee/domain/employee_model.dart';
import 'package:production_app_frontend/features/hr/shift/presentation/bloc/shift_cubit.dart';
import 'package:production_app_frontend/features/hr/shift/domain/shift_model.dart';
import 'package:production_app_frontend/features/hr/work_schedule/presentation/bloc/work_schedule_cubit.dart';
import 'package:production_app_frontend/features/hr/work_schedule/domain/work_schedule_model.dart';

// Production Master Data
import 'package:production_app_frontend/features/production/machine/presentation/bloc/machine_operation_cubit.dart';
import 'package:production_app_frontend/features/production/machine/domain/machine_model.dart';
import 'package:production_app_frontend/features/inventory/product/presentation/bloc/product_cubit.dart';
import 'package:production_app_frontend/features/inventory/product/domain/product_model.dart';
import 'package:production_app_frontend/features/production/standard/presentation/bloc/standard_cubit.dart';
import 'package:production_app_frontend/features/production/standard/domain/standard_model.dart';
import 'package:production_app_frontend/features/inventory/basket/doamain/basket_model.dart';

class MaterialExportScreen extends StatefulWidget {
  const MaterialExportScreen({super.key});

  @override
  State<MaterialExportScreen> createState() => _MaterialExportScreenState();
}

class _MaterialExportScreenState extends State<MaterialExportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  
  // Ngày xuất mặc định là hôm nay
  final _dateCtrl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
  
  // Header State
  int? _selectedWarehouseId;
  int? _selectedReceiverId;
  int? _selectedShiftId;
  
  // List Details
  final List<MaterialExportDetail> _details = [];

  @override
  void initState() {
    super.initState();
    // 1. Load Master Data
    context.read<WarehouseCubit>().loadWarehouses();
    
    // Load nhân sự & Lịch làm việc để lọc người đứng máy
    context.read<EmployeeCubit>().loadEmployees();
    context.read<ShiftCubit>().loadShifts();
    context.read<WorkScheduleCubit>().loadSchedules();
    
    // 2. Load Production Data (cho dialog chi tiết)
    context.read<MachineOperationCubit>().loadDashboard();
    context.read<ProductCubit>().loadProducts();
    context.read<StandardCubit>().loadStandards();
    context.read<BasketCubit>().loadBaskets(); 

    // 3. Gen Code
    _codeCtrl.text = context.read<MaterialExportCubit>().getNewCode();
  }

  // Helper so sánh ngày
  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Xuất kho Sợi & Tạo phiếu Rổ"),
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
      ),
      body: BlocListener<MaterialExportCubit, MaterialExportState>(
        listener: (context, state) {
          if (state is MaterialExportSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Xuất kho thành công! Đã tạo phiếu rổ dệt."), backgroundColor: Colors.green)
            );
            Navigator.pop(context);
          } else if (state is MaterialExportError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Lỗi: ${state.message}"), backgroundColor: Colors.red)
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderSection(),
                const SizedBox(height: 20),
                _buildDetailListSection(),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _submitExport,
                  icon: const Icon(Icons.save),
                  label: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text("XÁC NHẬN XUẤT KHO", style: TextStyle(fontSize: 16)),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003366),
                    foregroundColor: Colors.white,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- HEADER: Thông tin chung ---
  Widget _buildHeaderSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("THÔNG TIN CHUNG", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _codeCtrl,
                    decoration: const InputDecoration(labelText: "Mã phiếu", border: OutlineInputBorder()),
                    readOnly: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _dateCtrl,
                    decoration: const InputDecoration(
                      labelText: "Ngày xuất", 
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today)
                    ),
                    readOnly: true,
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          _dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
                          // Reset người nhận khi đổi ngày vì lịch làm việc thay đổi
                          _selectedReceiverId = null;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Chọn Kho
            BlocBuilder<WarehouseCubit, WarehouseState>(
              builder: (context, state) {
                List<Warehouse> list = (state is WarehouseLoaded) ? state.warehouses : [];
                return DropdownButtonFormField<int>(
                  value: _selectedWarehouseId,
                  decoration: const InputDecoration(labelText: "Xuất từ Kho *", border: OutlineInputBorder()),
                  items: list.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name))).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedWarehouseId = val;
                      _details.clear(); // Xóa chi tiết nếu đổi kho
                    });
                    // Load tồn kho của kho này để chọn ở detail
                    if (val != null) {
                      context.read<InventoryCubit>().loadInventories(warehouseId: val);
                    }
                  },
                  validator: (v) => v == null ? "Chọn kho" : null,
                );
              },
            ),
            const SizedBox(height: 16),

            // Người nhận & Ca
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: BlocBuilder<WorkScheduleCubit, WorkScheduleState>(
                    builder: (context, scheduleState) {
                      return BlocBuilder<EmployeeCubit, EmployeeState>(
                        builder: (context, empState) {
                          List<Employee> availableEmployees = [];
                          
                          // Logic lọc nhân viên theo lịch làm việc
                          if (scheduleState is WorkScheduleLoaded && empState is EmployeeLoaded) {
                            DateTime selectedDate = DateFormat('yyyy-MM-dd').parse(_dateCtrl.text);
                            final validEmpIds = scheduleState.schedules
                                .where((s) => _isSameDay(DateTime.tryParse(s.workDate), selectedDate))
                                .map((s) => s.employeeId)
                                .toSet(); 
                            
                            availableEmployees = empState.employees
                                .where((e) => validEmpIds.contains(e.id))
                                .toList();
                          } else if (empState is EmployeeLoaded) {
                            availableEmployees = empState.employees;
                          }

                          return DropdownSearch<Employee>(
                            items: (filter, props) => availableEmployees,
                            itemAsString: (u) => u.fullName,
                            compareFn: (i, s) => i.id == s.id,
                            selectedItem: availableEmployees.where((e) => e.id == _selectedReceiverId).firstOrNull,
                            decoratorProps: const DropDownDecoratorProps(
                              decoration: InputDecoration(
                                labelText: "Người nhận (Đứng máy) *", 
                                border: OutlineInputBorder(),
                                helperText: "Chỉ hiển thị nhân viên có lịch làm việc ngày này"
                              ),
                            ),
                            popupProps: const PopupProps.menu(showSearchBox: true),
                            onChanged: (val) => setState(() => _selectedReceiverId = val?.id),
                            validator: (v) => v == null ? "Chọn người nhận" : null,
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: BlocBuilder<ShiftCubit, ShiftState>(
                    builder: (context, state) {
                      List<Shift> list = (state is ShiftLoaded) ? state.shifts : [];
                      return DropdownButtonFormField<int>(
                        value: _selectedShiftId,
                        decoration: const InputDecoration(labelText: "Ca làm việc", border: OutlineInputBorder()),
                        items: list.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name))).toList(),
                        onChanged: (val) => _selectedShiftId = val,
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteCtrl,
              decoration: const InputDecoration(labelText: "Ghi chú", border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
    );
  }

  // --- DETAILS: Danh sách vật tư ---
  Widget _buildDetailListSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("CHI TIẾT VẬT TƯ & ĐÍCH ĐẾN", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                ElevatedButton.icon(
                  onPressed: _selectedWarehouseId == null 
                    ? null 
                    : () => _openAddDetailDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text("Thêm dòng"),
                )
              ],
            ),
            const SizedBox(height: 10),
            if (_selectedWarehouseId == null)
              const Center(child: Text("Vui lòng chọn Kho trước", style: TextStyle(color: Colors.red))),
            
            if (_details.isNotEmpty)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _details.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final item = _details[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text("Batch :${item.basketId} - Qty: ${item.quantity}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Máy: ${item.machineId} (Line ${item.machineLine})"),
                        Text("SP: ${item.productId} - Rổ: ${item.basketId}"),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => setState(() => _details.removeAt(index)),
                    ),
                  );
                },
              )
          ],
        ),
      ),
    );
  }

  // --- DIALOG: Thêm chi tiết ---
  Future<void> _openAddDetailDialog() async {
    // Các biến tạm để lưu giá trị trong Dialog
    InventoryStock? selectedStock;
    double inputQty = 0;
    
    Machine? selectedMachine;
    int selectedLine = 1; // Default Line 1
    
    Product? selectedProduct;
    Standard? selectedStandard;
    Basket? selectedBasket;

    final dialogFormKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Thêm chi tiết xuất"),
              content: Form(
                key: dialogFormKey,
                child: SizedBox(
                  width: 500,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // --- 1. CHỌN LÔ SỢI (TỪ KHO) ---
                        const Text("1. CHỌN LÔ SỢI (TỪ KHO)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        BlocBuilder<InventoryCubit, InventoryState>(
                          builder: (context, state) {
                            List<InventoryStock> stocks = (state is InventoryListLoaded) ? state.stocks : [];
                            // Lọc những lô có số lượng > 0
                            stocks = stocks.where((s) => s.availableQuantity > 0).toList();
                            
                            return DropdownSearch<InventoryStock>(
                              items: (filter, props) => stocks,
                              // [UPDATED] Hiển thị đầy đủ thông tin: Mã vật tư, Lô NCC, Lô hệ thống, Vị trí, Tồn kho
                              itemAsString: (s) => "${s.material?.materialCode} - ${s.batch?.supplierBatchNo} (${s.availableQuantity} kg)",
                              compareFn: (i, s) => i.id == s.id,
                              onChanged: (val) => setStateDialog(() => selectedStock = val),
                              validator: (v) => v == null ? "Chọn lô" : null,
                              decoratorProps: const DropDownDecoratorProps(decoration: InputDecoration(labelText: "Lô Sợi (Tồn kho)")),
                              popupProps: PopupProps.menu(
                                showSearchBox: true,
                                searchFieldProps: const TextFieldProps(
                                  decoration: InputDecoration(
                                    hintText: "Tìm theo mã sợi, lô...",
                                    prefixIcon: Icon(Icons.search),
                                  ),
                                ),
                                itemBuilder: (context, item, isSelected, isDisabled) {
                                  return ListTile(
                                    selected: isSelected,
                                    title: Text(
                                      "${item.material?.materialCode ?? 'N/A'}}",
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.qr_code_2, size: 14, color: Colors.blueGrey),
                                            const SizedBox(width: 4),
                                            // Hiển thị Lô NCC
                                            Text("Sup: ${item.batch?.internalBatchCode}", style: const TextStyle(color: Colors.black87, fontSize: 12)),
                                            const SizedBox(width: 8),
                                            // Hiển thị Lô Hệ thống
                                            Text("Sys: ${item.batch?.supplierBatchNo}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Icon(Icons.place, size: 14, color: Colors.orange.shade700),
                                            const SizedBox(width: 4),
                                            // Hiển thị Vị trí kho
                                            Text(item.batch?.location ?? '--', style: const TextStyle(color: Colors.black87, fontSize: 12)),
                                            const Spacer(),
                                            // Hiển thị Số lượng tồn
                                            Text(
                                              "${item.availableQuantity} kg",
                                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          decoration: const InputDecoration(labelText: "Số lượng xuất (Kg)"),
                          keyboardType: TextInputType.number,
                          onChanged: (val) => inputQty = double.tryParse(val) ?? 0,
                          validator: (v) {
                            if (v == null || v.isEmpty) return "Nhập số lượng";
                            double? val = double.tryParse(v);
                            if (val == null || val <= 0) return "Số lượng phải > 0";
                            if (selectedStock != null && val > selectedStock!.availableQuantity) {
                              return "Vượt quá tồn kho (${selectedStock!.availableQuantity})";
                            }
                            return null;
                          },
                        ),
                        const Divider(height: 30, thickness: 2),

                        // --- 2. THÔNG TIN SẢN XUẤT ---
                        const Text("2. THÔNG TIN SẢN XUẤT (ĐỂ TẠO PHIẾU RỔ)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: BlocBuilder<MachineOperationCubit, MachineOpState>(
                                builder: (context, state) {
                                  List<Machine> machines = (state is MachineOpLoaded) ? state.machines : [];
                                  return DropdownSearch<Machine>(
                                    items: (filter, props) => machines,
                                    itemAsString: (m) => m.name,
                                    compareFn: (i, s) => i.id == s.id,
                                    onChanged: (val) => setStateDialog(() => selectedMachine = val),
                                    validator: (v) => v == null ? "Chọn máy" : null,
                                    decoratorProps: const DropDownDecoratorProps(decoration: InputDecoration(labelText: "Máy dệt")),
                                    popupProps: const PopupProps.menu(showSearchBox: true),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: selectedLine,
                                decoration: const InputDecoration(labelText: "Line"),
                                items: const [
                                  DropdownMenuItem(value: 1, child: Text("Line 1")),
                                  DropdownMenuItem(value: 2, child: Text("Line 2")),
                                ],
                                onChanged: (val) => setStateDialog(() => selectedLine = val!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        
                        // Sản phẩm & Tiêu chuẩn
                        BlocBuilder<ProductCubit, ProductState>(
                          builder: (context, state) {
                             List<Product> products = (state is ProductLoaded) ? state.products : [];
                             return DropdownSearch<Product>(
                               items: (filter, props) => products,
                               itemAsString: (p) => p.itemCode,
                               compareFn: (i, s) => i.id == s.id,
                               onChanged: (val) => setStateDialog(() {
                                 selectedProduct = val;
                                 selectedStandard = null; // Reset standard
                               }),
                               validator: (v) => v == null ? "Chọn sản phẩm" : null,
                               decoratorProps: const DropDownDecoratorProps(decoration: InputDecoration(labelText: "Sản phẩm")),
                               popupProps: const PopupProps.menu(showSearchBox: true),
                             );
                          },
                        ),
                        const SizedBox(height: 10),
                        
                        BlocBuilder<StandardCubit, StandardState>(
                          builder: (context, state) {
                             List<Standard> standards = [];
                             if (state is StandardLoaded && selectedProduct != null) {
                               standards = state.standards.where((s) => s.productId == selectedProduct!.id).toList();
                             }
                             return DropdownButtonFormField<Standard>(
                               value: selectedStandard,
                               decoration: const InputDecoration(labelText: "Tiêu chuẩn"),
                               items: standards.map((s) => DropdownMenuItem(value: s, child: Text("W:${s.widthMm} | T:${s.thicknessMm}"))).toList(),
                               onChanged: (val) => setStateDialog(() => selectedStandard = val),
                               validator: (v) => v == null ? "Chọn tiêu chuẩn" : null,
                             );
                          },
                        ),
                        const SizedBox(height: 10),

                        // Rổ (Chỉ hiện rổ READY)
                        BlocBuilder<BasketCubit, BasketState>(
                          builder: (context, state) {
                            List<Basket> baskets = [];
                            if (state is BasketLoaded) {
                              // Filter chỉ lấy rổ READY
                              baskets = state.baskets.where((b) => b.status == "READY").toList();
                            }
                            return DropdownSearch<Basket>(
                               items: (filter, props) => baskets,
                               itemAsString: (b) => "${b.code} (${b.tareWeight}kg)",
                               compareFn: (i, s) => i.id == s.id,
                               onChanged: (val) => setStateDialog(() => selectedBasket = val),
                               validator: (v) => v == null ? "Chọn rổ (READY)" : null,
                               decoratorProps: const DropDownDecoratorProps(decoration: InputDecoration(labelText: "Rổ chứa")),
                               popupProps: const PopupProps.menu(showSearchBox: true),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
                ElevatedButton(
                  onPressed: () {
                    if (dialogFormKey.currentState!.validate()) {
                      // Tạo object detail
                      final newDetail = MaterialExportDetail(
                        materialId: selectedStock!.materialId,
                        batchId: selectedStock!.batchId,
                        quantity: inputQty,
                        
                        machineId: selectedMachine!.id,
                        machineLine: selectedLine,
                        productId: selectedProduct!.id,
                        standardId: selectedStandard!.id,
                        basketId: selectedBasket!.id,
                      );
                      
                      setState(() {
                        _details.add(newDetail);
                      });
                      Navigator.pop(ctx);
                    }
                  }, 
                  child: const Text("Thêm")
                ),
              ],
            );
          }
        );
      },
    );
  }

  // --- SUBMIT ---
  void _submitExport() {
    if (_formKey.currentState!.validate()) {
      if (_details.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chưa có chi tiết hàng hóa!")));
        return;
      }

      final exportData = MaterialExport(
        exportCode: _codeCtrl.text,
        exportDate: DateFormat('yyyy-MM-dd').parse(_dateCtrl.text),
        warehouseId: _selectedWarehouseId!,
        receiverId: _selectedReceiverId!,
        shiftId: _selectedShiftId,
        note: _noteCtrl.text,
        details: _details,
      );

      context.read<MaterialExportCubit>().createExport(exportData);
    }
  }
}