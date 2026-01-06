import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:production_app_frontend/l10n/app_localizations.dart';
import 'package:production_app_frontend/core/widgets/responsive_layout.dart';

import '../../domain/work_schedule_model.dart';
import '../bloc/work_schedule_cubit.dart';

import 'package:production_app_frontend/features/hr/employee/domain/employee_model.dart';
import 'package:production_app_frontend/features/hr/employee/presentation/bloc/employee_cubit.dart';
import 'package:production_app_frontend/features/hr/shift/domain/shift_model.dart';
import 'package:production_app_frontend/features/hr/shift/presentation/bloc/shift_cubit.dart';

class WorkScheduleScreen extends StatefulWidget {
  const WorkScheduleScreen({super.key});

  @override
  State<WorkScheduleScreen> createState() => _WorkScheduleScreenState();
}

class _WorkScheduleScreenState extends State<WorkScheduleScreen> {
  final _searchController = TextEditingController();
  final Color _primaryColor = const Color(0xFF003366);
  final Color _accentColor = const Color(0xFF1976D2);
  final Color _bgLight = const Color(0xFFF5F7FA);

  DateTime _currentDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    context.read<WorkScheduleCubit>().loadSchedules();
    context.read<EmployeeCubit>().loadEmployees();
    context.read<ShiftCubit>().loadShifts();
  }

  DateTime _startOfWeek(DateTime date) => date.subtract(Duration(days: date.weekday - 1));
  DateTime _endOfWeek(DateTime date) => date.add(Duration(days: DateTime.daysPerWeek - date.weekday));
  
  void _changeWeek(int offset) {
    setState(() {
      _currentDate = _currentDate.add(Duration(days: offset * 7));
    });
  }

  List<WorkSchedule> _filterByWeek(List<WorkSchedule> allSchedules) {
    final start = _startOfWeek(_currentDate);
    final end = _endOfWeek(_currentDate);
    final startRange = DateTime(start.year, start.month, start.day);
    final endRange = DateTime(end.year, end.month, end.day, 23, 59, 59);

    return allSchedules.where((s) {
      try {
        final date = DateFormat('yyyy-MM-dd').parse(s.workDate);
        return date.isAfter(startRange.subtract(const Duration(seconds: 1))) && 
               date.isBefore(endRange.add(const Duration(seconds: 1)));
      } catch (e) {
        return false;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    final startWeekStr = DateFormat('dd/MM').format(_startOfWeek(_currentDate));
    final endWeekStr = DateFormat('dd/MM/yyyy').format(_endOfWeek(_currentDate));

    return BlocListener<WorkScheduleCubit, WorkScheduleState>(
      listener: (context, state) {
        if (state is WorkScheduleError) {
          String message = state.message;
          if (message.contains("DUPLICATE_SCHEDULE")) {
            message = l10n.errorDuplicateSchedule;
          } else {
            message = message.replaceAll("Exception: ", "");
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
          context.read<WorkScheduleCubit>().loadSchedules();
        }
      },
      child: Scaffold(
        backgroundColor: _bgLight,
        // [FIX] floatingActionButton nằm trong Scaffold
        floatingActionButton: !isDesktop
            ? FloatingActionButton(
                backgroundColor: _accentColor,
                onPressed: () => _showEditDialog(context, null, l10n),
                child: const Icon(Icons.add, color: Colors.white),
              )
            : null,
        body: BlocBuilder<WorkScheduleCubit, WorkScheduleState>(
          builder: (context, state) {
            int total = 0;
            List<WorkSchedule> displayList = [];

            if (state is WorkScheduleLoaded) {
              displayList = _filterByWeek(state.schedules);
              total = displayList.length;
            }

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
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.calendar_month, color: Colors.blue.shade800, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.scheduleTitle, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                              const SizedBox(height: 2),
                              Text("Human Resources > Rostering", style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                            ],
                          ),
                          const Spacer(),
                          if (isDesktop)
                            ElevatedButton.icon(
                              onPressed: () => _showEditDialog(context, null, l10n),
                              icon: const Icon(Icons.add, size: 18),
                              label: Text(l10n.addSchedule.toUpperCase()),
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
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeWeek(-1), tooltip: "Previous Week"),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.date_range, size: 16, color: Colors.blue),
                                      const SizedBox(width: 8),
                                      Text("$startWeekStr - $endWeekStr", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    ],
                                  ),
                                ),
                                IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeWeek(1), tooltip: "Next Week"),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: isDesktop ? 300 : 150,
                            decoration: BoxDecoration(color: _bgLight, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                            child: TextField(
                              controller: _searchController,
                              textInputAction: TextInputAction.search,
                              decoration: InputDecoration(
                                hintText: l10n.searchSchedule,
                                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                                prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 18),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              onSubmitted: (value) => context.read<WorkScheduleCubit>().searchSchedules(value),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  color: Colors.blue.shade50,
                  child: Text("Showing $total schedules for selected week", style: TextStyle(color: Colors.blue.shade800, fontSize: 12, fontWeight: FontWeight.w500)),
                ),

                // --- CONTENT ---
                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (state is WorkScheduleLoading) return Center(child: CircularProgressIndicator(color: _primaryColor));
                      
                      if (state is WorkScheduleError) {
                         // Nếu lỗi không phải do save (đã hiện snackbar), hiển thị nút retry
                         return Center(child: Column(
                           mainAxisAlignment: MainAxisAlignment.center,
                           children: [
                             const Icon(Icons.error_outline, color: Colors.red, size: 40),
                             const SizedBox(height: 16),
                             const Text("Unable to load data"),
                             TextButton(onPressed: () => context.read<WorkScheduleCubit>().loadSchedules(), child: const Text("Retry"))
                           ],
                         ));
                      }

                      if (state is WorkScheduleLoaded) {
                        if (displayList.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.event_available, size: 60, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text("No schedules for this week", style: TextStyle(color: Colors.grey.shade500)),
                              ],
                            ),
                          );
                        }
                        return isDesktop
                            ? _buildDesktopTable(context, displayList, l10n)
                            : _buildMobileList(context, displayList, l10n);
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
    );
  }

  // ... (Phần còn lại giữ nguyên: _buildDesktopTable, _buildMobileList, _showEditDialog, _confirmDelete, Badge Widgets...)
  // Để tiết kiệm không gian, tôi chỉ liệt kê phần thay đổi quan trọng ở trên.
  // Hãy đảm bảo bạn copy các hàm helper (như _buildDesktopTable, _showEditDialog...) từ câu trả lời trước vào đây.
  
  // --- DESKTOP TABLE ---
  Widget _buildDesktopTable(BuildContext context, List<WorkSchedule> items, AppLocalizations l10n) {
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
                      DataColumn(label: Text(l10n.workDate.toUpperCase(), style: _headerStyle)),
                      DataColumn(label: Text(l10n.employee.toUpperCase(), style: _headerStyle)),
                      DataColumn(label: Text(l10n.shift.toUpperCase(), style: _headerStyle)),
                      DataColumn(label: Text(l10n.actions.toUpperCase(), style: _headerStyle)),
                    ],
                    rows: items.map((item) {
                      return DataRow(
                        cells: [
                          DataCell(Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(DateFormat('EEEE, dd/MM').format(DateTime.parse(item.workDate)), style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          )),
                          DataCell(_EmployeeNameBadge(employeeId: item.employeeId)),
                          DataCell(_ShiftBadge(shiftId: item.shiftId, shiftName: item.shiftName, startTime: item.startTime, endTime: item.endTime)),
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

  Widget _buildMobileList(BuildContext context, List<WorkSchedule> items, AppLocalizations l10n) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        final date = DateTime.parse(item.workDate);
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue.shade100)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(DateFormat('dd').format(date), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue.shade800)),
                  Text(DateFormat('MMM').format(date), style: TextStyle(fontSize: 11, color: Colors.blue.shade800)),
                ],
              ),
            ),
            title: _EmployeeNameBadge(employeeId: item.employeeId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: _ShiftBadge(shiftId: item.shiftId, shiftName: item.shiftName, startTime: item.startTime, endTime: item.endTime),
            ),
            trailing: PopupMenuButton(
              onSelected: (val) {
                if (val == 'edit') _showEditDialog(context, item, l10n);
                if (val == 'delete') _confirmDelete(context, item, l10n);
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(value: 'edit', child: Row(children: [const Icon(Icons.edit, size: 18), const SizedBox(width: 8), Text(l10n.editSchedule)])),
                PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete, size: 18, color: Colors.red), const SizedBox(width: 8), Text(l10n.deleteSchedule)])),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, WorkSchedule? item, AppLocalizations l10n) {
    final dateCtrl = TextEditingController(text: item?.workDate ?? DateFormat('yyyy-MM-dd').format(_currentDate));
    int? selectedEmpId = item?.employeeId;
    int? selectedShiftId = item?.shiftId;

    final empState = context.read<EmployeeCubit>().state;
    if (item == null && empState is EmployeeLoaded && empState.employees.isNotEmpty) {
      selectedEmpId = empState.employees.first.id;
    }
    
    final shiftState = context.read<ShiftCubit>().state;
    if (item == null && shiftState is ShiftLoaded && shiftState.shifts.isNotEmpty) {
      selectedShiftId = shiftState.shifts.first.id;
    }

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.all(24),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        title: Text(item == null ? l10n.addSchedule : l10n.editSchedule, style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: dateCtrl, 
                    decoration: _inputDeco(l10n.workDate),
                    readOnly: true,
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(context: context, initialDate: DateTime.parse(dateCtrl.text), firstDate: DateTime(2020), lastDate: DateTime(2030));
                      if(pickedDate != null) dateCtrl.text = DateFormat('yyyy-MM-dd').format(pickedDate);
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  BlocBuilder<EmployeeCubit, EmployeeState>(
                    builder: (context, state) {
                      List<Employee> list = (state is EmployeeLoaded) ? state.employees : [];
                      return DropdownButtonFormField<int>(
                        value: selectedEmpId,
                        decoration: _inputDeco(l10n.employee),
                        items: list.map((e) => DropdownMenuItem(value: e.id, child: Text(e.fullName))).toList(),
                        onChanged: (val) => selectedEmpId = val,
                        validator: (v) => v == null ? "Required" : null,
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  BlocBuilder<ShiftCubit, ShiftState>(
                    builder: (context, state) {
                      List<Shift> list = (state is ShiftLoaded) ? state.shifts : [];
                      return DropdownButtonFormField<int>(
                        value: selectedShiftId,
                        decoration: _inputDeco(l10n.shift),
                        items: list.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                        onChanged: (val) => selectedShiftId = val,
                        validator: (v) => v == null ? "Required" : null,
                      );
                    },
                  ),
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
              if (formKey.currentState!.validate() && selectedEmpId != null && selectedShiftId != null) {
                final newItem = WorkSchedule(
                  id: item?.id ?? 0,
                  workDate: dateCtrl.text,
                  employeeId: selectedEmpId!,
                  shiftId: selectedShiftId!,
                );
                context.read<WorkScheduleCubit>().saveSchedule(schedule: newItem, isEdit: item != null);
                Navigator.pop(ctx);
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
      suffixIcon: label == "Work Date" || label == "Ngày làm việc" ? const Icon(Icons.calendar_today, size: 20) : null,
    );
  }

  void _confirmDelete(BuildContext context, WorkSchedule item, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteSchedule),
        content: Text(l10n.confirmDeleteSchedule(item.employeeName ?? 'Emp', item.workDate)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              context.read<WorkScheduleCubit>().deleteSchedule(item.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(l10n.deleteSchedule),
          ),
        ],
      ),
    );
  }
}

// Widget Badge hiển thị Tên nhân viên từ ID (Nếu model chưa có nested object)
class _EmployeeNameBadge extends StatelessWidget {
  final int employeeId;
  final TextStyle? style;
  const _EmployeeNameBadge({required this.employeeId, this.style});
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EmployeeCubit, EmployeeState>(
      builder: (context, state) {
        String name = "---";
        if (state is EmployeeLoaded) {
          final e = state.employees.where((x) => x.id == employeeId).firstOrNull;
          if (e != null) name = e.fullName;
        }
        return Text(name, style: style ?? const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87));
      },
    );
  }
}

class _ShiftBadge extends StatelessWidget {
  final int shiftId;
  final String? shiftName; 
  final String? startTime;
  final String? endTime;
  const _ShiftBadge({required this.shiftId, this.shiftName, this.startTime, this.endTime});

  @override
  Widget build(BuildContext context) {
    String displayText = shiftName ?? "Shift $shiftId";
    if (startTime != null && endTime != null) displayText += " ($startTime - $endTime)";
    if (shiftName != null) return _buildChip(displayText);
    return BlocBuilder<ShiftCubit, ShiftState>(
      builder: (context, state) {
        if (state is ShiftLoaded) {
          final s = state.shifts.where((x) => x.id == shiftId).firstOrNull;
          if (s != null) displayText = s.name; 
        }
        return _buildChip(displayText);
      },
    );
  }

  Widget _buildChip(String text) {
    Color bg = Colors.grey.shade100;
    Color textCol = Colors.black87;
    if (text.toLowerCase().contains('sáng') || text.toLowerCase().contains('morning')) {
      bg = Colors.orange.shade50; textCol = Colors.orange.shade900;
    } else if (text.toLowerCase().contains('chiều') || text.toLowerCase().contains('afternoon')) {
      bg = Colors.blue.shade50; textCol = Colors.blue.shade900;
    } else if (text.toLowerCase().contains('đêm') || text.toLowerCase().contains('night')) {
      bg = Colors.indigo.shade50; textCol = Colors.indigo.shade900;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(fontSize: 12, color: textCol, fontWeight: FontWeight.w600)),
    );
  }
}