import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:production_app_frontend/features/production/machine/presentation/bloc/machine_cubit.dart';

// --- IMPORTS CUBITS & MODELS ---
import '../../../../../core/widgets/responsive_layout.dart';
import '../bloc/material_export_cubit.dart';
import '../../domain/material_export_model.dart';

// Inventory & Warehouse
import 'package:production_app_frontend/features/inventory/inventory/presentation/bloc/inventory_cubit.dart';
import 'package:production_app_frontend/features/inventory/inventory/domain/inventory_model.dart';
import 'package:production_app_frontend/features/inventory/warehouse/presentation/bloc/warehouse_cubit.dart';
import 'package:production_app_frontend/features/inventory/warehouse/domain/warehouse_model.dart';

// HR
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

// Auth
import 'package:production_app_frontend/features/auth/presentation/bloc/auth_cubit.dart';

class MaterialExportScreen extends StatefulWidget {
  final MaterialExport? existingExport; 

  const MaterialExportScreen({super.key, this.existingExport});

  @override
  State<MaterialExportScreen> createState() => _MaterialExportScreenState();
}

class _MaterialExportScreenState extends State<MaterialExportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _creatorCtrl = TextEditingController();
  
  // Ngày xuất mặc định là hôm nay
  final _dateCtrl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
  
  // Header State
  int? _selectedWarehouseId;
  int? _selectedReceiverId;
  int? _selectedShiftId;
  
  // List Details
  final List<MaterialExportDetail> _details = [];

  // [AUTO-SAVE STATE]
  bool _hasUnsavedChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // 1. Load Master Data
    context.read<WarehouseCubit>().loadWarehouses();
    context.read<EmployeeCubit>().loadEmployees();
    context.read<ShiftCubit>().loadShifts();
    context.read<WorkScheduleCubit>().loadSchedules();
    context.read<MachineOperationCubit>().loadDashboard(); // Load trạng thái máy
    
    context.read<ProductCubit>().loadProducts();

    // 2. Init Data (Kiểm tra xem là Tạo mới hay Sửa)
    if (widget.existingExport != null) {
      _initEditData();
    } else {
      _initCreateData();
    }
  }

  // [Hàm fill dữ liệu khi sửa]
  void _initEditData() {
    final item = widget.existingExport!;
    _codeCtrl.text = item.exportCode;
    _dateCtrl.text = DateFormat('yyyy-MM-dd').format(item.exportDate);
    _selectedWarehouseId = item.warehouseId;
    _selectedReceiverId = item.receiverId;
    _selectedShiftId = item.shiftId;
    _noteCtrl.text = item.note ?? "";
    _creatorCtrl.text = item.createdBy ?? "";
    
    // Fill list chi tiết
    _details.addAll(item.details);
    
    // Load tồn kho của kho đã chọn để sẵn sàng thêm chi tiết mới nếu cần
    context.read<InventoryCubit>().loadInventories(warehouseId: item.warehouseId);
  }

  // [Hàm init khi tạo mới]
  Future<void> _initCreateData() async {
    // Lấy thông tin user
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      if (mounted) _creatorCtrl.text = authState.user.employeeName ?? authState.user.fullName;
    }
    // Lấy mã phiếu tự động
    final newCode = await context.read<MaterialExportCubit>().fetchNewCode();
    if (mounted) setState(() => _codeCtrl.text = newCode);
  }

  // Helper so sánh ngày
  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // [AUTO-SAVE LOGIC]
  void _markAsDirty() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<void> _handleAutoSaveAndExit() async {
    if (!_hasUnsavedChanges || _isSaving) return;

    if (_selectedWarehouseId == null || _selectedReceiverId == null) {
      debugPrint("Auto-save skipped: Missing required fields");
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _saveDataInternal();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tự động lưu phiếu xuất kho."), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      debugPrint("Auto-save failed: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _hasUnsavedChanges = false;
        });
      }
    }
  }

  Future<void> _saveDataInternal() async {
    final exportData = MaterialExport(
      id: widget.existingExport?.id, // Giữ ID nếu đang sửa
      exportCode: _codeCtrl.text,
      exportDate: DateFormat('yyyy-MM-dd').parse(_dateCtrl.text),
      warehouseId: _selectedWarehouseId!,
      receiverId: _selectedReceiverId!,
      shiftId: _selectedShiftId,
      note: _noteCtrl.text,
      createdBy: _creatorCtrl.text,
      details: _details,
    );

    if (widget.existingExport == null) {
        await context.read<MaterialExportCubit>().createExport(exportData);
    } else {
        await context.read<MaterialExportCubit>().createExport(exportData); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_hasUnsavedChanges) {
          await _handleAutoSaveAndExit();
        }
        if (context.mounted) {
          Navigator.of(context).pop(result);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Text(widget.existingExport == null ? "Tạo phiếu xuất kho" : "Sửa phiếu xuất kho"),
              if (_hasUnsavedChanges) 
                const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Text("(Chưa lưu)", style: TextStyle(fontSize: 12, color: Colors.orangeAccent)),
                )
            ],
          ),
          backgroundColor: const Color(0xFF003366),
          foregroundColor: Colors.white,
        ),
        body: MultiBlocListener(
          listeners: [
            // Listener tự động chọn kho B3
            BlocListener<WarehouseCubit, WarehouseState>(
              listener: (context, state) {
                // Chỉ tự chọn khi tạo mới và chưa chọn kho nào
                if (state is WarehouseLoaded && _selectedWarehouseId == null && widget.existingExport == null) {
                  try {
                    final b3Warehouse = state.warehouses.firstWhere(
                      (w) => w.name.toUpperCase().contains("B3"),
                    );
                    setState(() {
                      _selectedWarehouseId = b3Warehouse.id;
                      // Không mark dirty ở đây để tránh auto-save khi vừa vào
                    });
                    context.read<InventoryCubit>().loadInventories(warehouseId: b3Warehouse.id);
                  } catch (_) {}
                }
              },
            ),
            BlocListener<MaterialExportCubit, MaterialExportState>(
              listener: (context, state) {
                if (state is MaterialExportError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Lỗi: ${state.message}"), backgroundColor: Colors.red)
                  );
                }
              },
            ),
          ],
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
                    onPressed: _submitExportManual,
                    icon: const Icon(Icons.save),
                    label: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text("XÁC NHẬN / LƯU", style: TextStyle(fontSize: 16)),
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
      ),
    );
  }

  // --- HEADER SECTION ---
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
                    decoration: const InputDecoration(
                      labelText: "Mã phiếu", 
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.edit, size: 16, color: Colors.grey)
                    ),
                    readOnly: false, // Cho phép sửa mã
                    onChanged: (_) => _markAsDirty(),
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
                          _selectedReceiverId = null; 
                          _markAsDirty();
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
                      _details.clear();
                      _markAsDirty();
                    });
                    if (val != null) {
                      context.read<InventoryCubit>().loadInventories(warehouseId: val);
                    }
                  },
                  validator: (v) => v == null ? "Chọn kho" : null,
                );
              },
            ),
            const SizedBox(height: 16),

            // Người tạo phiếu (Read-only)
            TextFormField(
              controller: _creatorCtrl,
              decoration: const InputDecoration(
                labelText: "Người tạo phiếu", 
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
                filled: true,
                fillColor: Color(0xFFF5F5F5)
              ),
              readOnly: true,
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
                                helperText: "Chỉ hiện NV có lịch làm việc"
                              ),
                            ),
                            popupProps: const PopupProps.menu(showSearchBox: true),
                            onChanged: (val) {
                                setState(() {
                                    _selectedReceiverId = val?.id;
                                    _markAsDirty();
                                });
                            },
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
                        onChanged: (val) {
                            setState(() {
                                _selectedShiftId = val;
                                _markAsDirty();
                            });
                        },
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
              onChanged: (_) => _markAsDirty(),
            ),
          ],
        ),
      ),
    );
  }

  // --- DETAIL LIST SECTION ---
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
                    title: Text("Qty: ${item.quantity} kg | Loại: ${item.componentType ?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("BatchID: ${item.batchId}"),
                        Text("Máy: ${item.machineId} (Line ${item.machineLine}) - SP: ${item.productId}"),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                          setState(() {
                              _details.removeAt(index);
                              _markAsDirty();
                          });
                      },
                    ),
                  );
                },
              )
          ],
        ),
      ),
    );
  }

  // --- DIALOG: ADD DETAIL ---
  Future<void> _openAddDetailDialog() async {
    InventoryStock? selectedStock;
    double inputQty = 0;
    
    Machine? selectedMachine;
    int selectedLine = 1;
    Product? selectedProduct;
    String? selectedComponentType; 

    final List<String> componentTypes = [
      "GROUND", "GRD. MARKER", "EDGE", "BINDER", "STUFFER",
      "STUFFER MAKER", "LOCK", "CATCH CORD", "FILLING", "2ND FILLING"
    ];

    final dialogFormKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {

            // Helper để kiểm tra máy đang chạy & tự chọn sản phẩm
            // ignore: no_leading_underscores_for_local_identifiers
            void _checkAndSelectActiveProduct(Machine? machine, int line) {
              if (machine == null) return;
              
              final machineOpState = context.read<MachineOperationCubit>().state;
              final productState = context.read<ProductCubit>().state;
              
              if (machineOpState is MachineOpLoaded && productState is ProductLoaded) {
                 // Check active ticket
                 final checkKey = "${machine.id}_$line";
                 if (machineOpState.activeTickets.containsKey(checkKey)) {
                     final ticket = machineOpState.activeTickets[checkKey];
                     if (ticket != null) {
                         // Tìm sản phẩm đang chạy
                         final activeProduct = productState.products.where((p) => p.id == ticket.productId).firstOrNull;
                         if (activeProduct != null) {
                            setStateDialog(() {
                               selectedProduct = activeProduct;
                            });
                         }
                     }
                 }
              }
            }

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
                        // 1. CHỌN LÔ SỢI
                        const Text("1. CHỌN LÔ SỢI (TỪ KHO)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        BlocBuilder<InventoryCubit, InventoryState>(
                          builder: (context, state) {
                            List<InventoryStock> stocks = (state is InventoryListLoaded) ? state.stocks : [];
                            stocks = stocks.where((s) => s.availableQuantity > 0).toList();
                            
                            return DropdownSearch<InventoryStock>(
                              items: (filter, props) => stocks,
                              itemAsString: (s) => "${s.material?.materialCode} - ${s.batch?.supplierBatchNo} (${s.availableQuantity} kg)",
                              compareFn: (i, s) => i.id == s.id,
                              onChanged: (val) => setStateDialog(() => selectedStock = val),
                              validator: (v) => v == null ? "Chọn lô" : null,
                              decoratorProps: const DropDownDecoratorProps(decoration: InputDecoration(labelText: "Lô Sợi (Tồn kho)")),
                              popupProps: PopupProps.menu(
                                showSearchBox: true,
                                searchFieldProps: const TextFieldProps(
                                  decoration: InputDecoration(hintText: "Tìm theo mã sợi, lô...", prefixIcon: Icon(Icons.search)),
                                ),
                                itemBuilder: (context, item, isSelected, isDisabled) {
                                    return ListTile(
                                        selected: isSelected,
                                        title: Text("${item.material?.materialCode ?? 'N/A'}}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        subtitle: Text("Qty: ${item.availableQuantity} kg | Loc: ${item.batch?.location ?? '--'}"),
                                    );
                                }
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        
                        DropdownButtonFormField<String>(
                          value: selectedComponentType,
                          decoration: const InputDecoration(labelText: "Loại sợi (Mục đích sử dụng) *"),
                          items: componentTypes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (val) => setStateDialog(() => selectedComponentType = val),
                          validator: (v) => v == null ? "Vui lòng chọn loại sợi" : null,
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

                        // 2. THÔNG TIN SẢN XUẤT
                        const Text("2. THÔNG TIN SẢN XUẤT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
                                    onChanged: (val) {
                                        setStateDialog(() => selectedMachine = val);
                                        // [AUTO-FILL] Kiểm tra nếu máy đang chạy, tự điền sản phẩm
                                        _checkAndSelectActiveProduct(val, selectedLine);
                                    },
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
                                onChanged: (val) {
                                   setStateDialog(() => selectedLine = val!);
                                   // [AUTO-FILL] Check lại khi đổi line
                                   _checkAndSelectActiveProduct(selectedMachine, val!);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        
                        BlocBuilder<ProductCubit, ProductState>(
                          builder: (context, state) {
                             List<Product> products = (state is ProductLoaded) ? state.products : [];
                             return DropdownSearch<Product>(
                               items: (filter, props) => products,
                               itemAsString: (p) => p.itemCode,
                               compareFn: (i, s) => i.id == s.id,
                               selectedItem: selectedProduct, // Tự động bind nếu đã được set từ _checkActive
                               onChanged: (val) => setStateDialog(() => selectedProduct = val),
                               validator: (v) => v == null ? "Chọn sản phẩm" : null,
                               decoratorProps: const DropDownDecoratorProps(decoration: InputDecoration(labelText: "Sản phẩm")),
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
                      
                      // [MỚI] KIỂM TRA DUY NHẤT LOẠI SỢI TRONG DANH SÁCH CHI TIẾT
                      // Với cùng 1 Máy & Line & Phiếu xuất này, mỗi loại sợi chỉ xuất 1 lô.
                      bool isDuplicateType = _details.any((d) => 
                          d.machineId == selectedMachine!.id &&
                          d.machineLine == selectedLine &&
                          d.componentType == selectedComponentType
                      );

                      if (isDuplicateType) {
                          ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(
                               content: Text("Loại sợi '$selectedComponentType' đã được chọn cho Máy ${selectedMachine!.name} Line $selectedLine rồi!"), 
                               backgroundColor: Colors.orange
                             )
                          );
                          return;
                      }

                      // [ĐÃ SỬA] Xóa bỏ đoạn code chặn "Máy đang chạy" ở đây.
                      // Cho phép thêm bình thường dù máy có Active Ticket hay không.

                      final newDetail = MaterialExportDetail(
                        materialId: selectedStock!.materialId,
                        batchId: selectedStock!.batchId,
                        quantity: inputQty,
                        componentType: selectedComponentType, 
                        machineId: selectedMachine!.id,
                        machineLine: selectedLine,
                        productId: selectedProduct!.id,
                        standardId: null, 
                        basketId: null, 
                      );
                      
                      setState(() {
                        _details.add(newDetail);
                        _markAsDirty();
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

  void _submitExportManual() async {
    if (_formKey.currentState!.validate()) {
      if (_details.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chưa có chi tiết hàng hóa!")));
        return;
      }

      setState(() {
        _hasUnsavedChanges = false;
      });

      await _saveDataInternal();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Thao tác thành công!"), backgroundColor: Colors.green)
        );
        Navigator.pop(context);
      }
    }
  }
}