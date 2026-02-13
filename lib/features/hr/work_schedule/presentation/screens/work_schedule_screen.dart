import 'dart:async';
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

class _WorkScheduleScreenState extends State<WorkScheduleScreen>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  final Color _primaryColor = const Color(0xFF003366);
  final Color _accentColor = const Color(0xFF1976D2);
  final Color _bgLight = const Color(0xFFF5F7FA);

  Timer? _debounce;
  DateTime _currentDate = DateTime.now();

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);

    // Tự động chuyển Tab về ngày hiện tại
    int todayIndex = DateTime.now().weekday - 1;
    _tabController.index = todayIndex;

    context.read<WorkScheduleCubit>().loadSchedules();
    context.read<EmployeeCubit>().loadEmployees();
    context.read<ShiftCubit>().loadShifts();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // --- LOGIC NGÀY THÁNG ---
  DateTime _startOfWeek(DateTime date) =>
      date.subtract(Duration(days: date.weekday - 1));
  DateTime _endOfWeek(DateTime date) =>
      date.add(Duration(days: DateTime.daysPerWeek - date.weekday));

  void _changeWeek(int offset) {
    setState(() {
      _currentDate = _currentDate.add(Duration(days: offset * 7));
    });
  }

  // Lấy danh sách 7 ngày trong tuần hiện tại
  List<DateTime> _getDaysInWeek() {
    DateTime start = _startOfWeek(_currentDate);
    return List.generate(7, (index) => start.add(Duration(days: index)));
  }

  // Lọc lịch theo tuần
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

  // Lọc lịch theo từng ngày
  List<WorkSchedule> _filterByDate(
      List<WorkSchedule> weekSchedules, DateTime date) {
    String dateStr = DateFormat('yyyy-MM-dd').format(date);
    return weekSchedules.where((s) => s.workDate == dateStr).toList();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().isEmpty) {
        context.read<WorkScheduleCubit>().loadSchedules();
      } else {
        context.read<WorkScheduleCubit>().searchSchedules(query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    final startWeekStr = DateFormat('dd/MM').format(_startOfWeek(_currentDate));
    final endWeekStr = DateFormat('dd/MM').format(_endOfWeek(_currentDate));
    final weekDays = _getDaysInWeek();

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
                behavior: SnackBarBehavior.floating),
          );
          context.read<WorkScheduleCubit>().loadSchedules();
        }
      },
      child: Scaffold(
        backgroundColor: _bgLight,
        floatingActionButton: !isDesktop
            ? FloatingActionButton(
                backgroundColor: _accentColor,
                onPressed: () => _showQuickScheduleDialog(context, l10n),
                child: const Icon(Icons.add, color: Colors.white),
              )
            : null,
        body: BlocBuilder<WorkScheduleCubit, WorkScheduleState>(
          builder: (context, state) {
            List<WorkSchedule> weeklySchedules = [];
            bool isLoading = false;

            if (state is WorkScheduleLoading) {
              isLoading = true;
            } else if (state is WorkScheduleLoaded) {
              weeklySchedules = _filterByWeek(state.schedules);
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- HEADER & CONTROLS ---
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(10)),
                            child: Icon(Icons.calendar_month,
                                color: Colors.blue.shade800, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.scheduleTitle,
                                    style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade800)),
                                const SizedBox(height: 2),
                                Text("Weekly Roster Management",
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade500)),
                              ],
                            ),
                          ),
                          if (isDesktop) ...[
                            _buildSearchBox(l10n, width: 250),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () =>
                                  _showQuickScheduleDialog(context, l10n),
                              icon: const Icon(Icons.add_task, size: 18),
                              label: const Text("XẾP LỊCH NHANH"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ]
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (!isDesktop) ...[
                        _buildSearchBox(l10n, width: double.infinity),
                        const SizedBox(height: 12),
                      ],

                      _buildDateNavigator(startWeekStr, endWeekStr,
                          isFullWidth: !isDesktop),

                      const SizedBox(height: 16),

                      // --- TAB BAR THEO NGÀY ---
                      TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        labelColor: _primaryColor,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: _primaryColor,
                        indicatorWeight: 3,
                        labelPadding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        tabs: weekDays.map((day) {
                          int count =
                              _filterByDate(weeklySchedules, day).length;
                          String dayName = DateFormat('EEEE', 'vi').format(day);
                          String dateNum = DateFormat('dd/MM').format(day);
                          String shortDay = dayName
                              .replaceFirst("Thứ ", "T")
                              .replaceFirst("Chủ Nhật", "CN");

                          return Tab(
                            height: 60,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(shortDay,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(dateNum,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.normal)),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: count > 0
                                            ? Colors.blue.shade100
                                            : Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text("$count",
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: count > 0
                                                  ? Colors.blue.shade900
                                                  : Colors.grey,
                                              fontWeight: FontWeight.bold)),
                                    )
                                  ],
                                )
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                Container(height: 1, color: Colors.grey.shade300),

                // --- TAB CONTENT ---
                Expanded(
                  child: isLoading
                      ? Center(
                          child:
                              CircularProgressIndicator(color: _primaryColor))
                      : TabBarView(
                          controller: _tabController,
                          children: weekDays.map((day) {
                            List<WorkSchedule> dailyList =
                                _filterByDate(weeklySchedules, day);

                            dailyList.sort((a, b) {
                              String t1 = a.startTime ?? "00:00";
                              String t2 = b.startTime ?? "00:00";
                              return t1.compareTo(t2);
                            });

                            if (dailyList.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.event_busy,
                                        size: 60, color: Colors.grey.shade200),
                                    const SizedBox(height: 16),
                                    Text(
                                        "Không có lịch làm việc ngày ${DateFormat('dd/MM').format(day)}",
                                        style: TextStyle(
                                            color: Colors.grey.shade500)),
                                    const SizedBox(height: 12),
                                    if (day.weekday == 7) // Gợi ý tăng ca CN
                                      Text(
                                          "Chủ Nhật thường nghỉ. Bấm 'Xếp lịch' nếu có tăng ca.",
                                          style: TextStyle(
                                              color: Colors.orange.shade800,
                                              fontSize: 12)),
                                    const SizedBox(height: 8),
                                    OutlinedButton.icon(
                                      onPressed: () => _showQuickScheduleDialog(
                                          context, l10n),
                                      icon: const Icon(Icons.add),
                                      label: const Text("Xếp lịch"),
                                    )
                                  ],
                                ),
                              );
                            }

                            return isDesktop
                                ? _buildDesktopTable(context, dailyList, l10n)
                                : _buildMobileList(context, dailyList, l10n);
                          }).toList(),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildDateNavigator(String startStr, String endStr,
      {required bool isFullWidth}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _changeWeek(-1),
              tooltip: "Tuần trước"),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.date_range, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Text("$startStr - $endStr",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
          IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _changeWeek(1),
              tooltip: "Tuần sau"),
        ],
      ),
    );
  }

  Widget _buildSearchBox(AppLocalizations l10n, {required double width}) {
    return Container(
      width: width,
      height: 40,
      decoration: BoxDecoration(
          color: _bgLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200)),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: "Tìm nhân viên...",
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.only(top: 2),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                    setState(() {});
                  })
              : null,
        ),
      ),
    );
  }

  // --- DESKTOP TABLE ---
  Widget _buildDesktopTable(
      BuildContext context, List<WorkSchedule> items, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200)),
        child: SizedBox(
          width: double.infinity,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(const Color(0xFFF9FAFB)),
            columns: [
              DataColumn(
                  label:
                      Text(l10n.employee.toUpperCase(), style: _headerStyle)),
              DataColumn(
                  label: Text(l10n.shift.toUpperCase(), style: _headerStyle)),
              const DataColumn(
                  label: Text("TIME",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.black54))),
              DataColumn(
                  label: Text(l10n.actions.toUpperCase(), style: _headerStyle)),
            ],
            rows: items.map((item) {
              final sTime = item.startTime ?? "";
              final eTime = item.endTime ?? "";
              String startT =
                  (sTime.length >= 5) ? sTime.substring(0, 5) : sTime;
              String endT = (eTime.length >= 5) ? eTime.substring(0, 5) : eTime;

              return DataRow(cells: [
                DataCell(_EmployeeNameBadge(employeeId: item.employeeId)),
                DataCell(_ShiftBadge(
                    shiftId: item.shiftId, shiftName: item.shiftName)),
                DataCell(Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4)),
                  child: Text("$startT - $endT",
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 12)),
                )),
                DataCell(Row(
                  children: [
                    IconButton(
                        icon: const Icon(Icons.edit_note, color: Colors.grey),
                        onPressed: () => _showEditDialog(context, item, l10n)),
                    IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.redAccent),
                        onPressed: () => _confirmDelete(context, item, l10n)),
                  ],
                )),
              ]);
            }).toList(),
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

  Widget _buildMobileList(
      BuildContext context, List<WorkSchedule> items, AppLocalizations l10n) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2))
            ],
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade50,
              child: const Icon(Icons.person, color: Colors.blue),
            ),
            title: _EmployeeNameBadge(
                employeeId: item.employeeId,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: _ShiftBadge(
                  shiftId: item.shiftId,
                  shiftName: item.shiftName,
                  startTime: item.startTime,
                  endTime: item.endTime),
            ),
            trailing: PopupMenuButton(
              icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
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
                      Text(l10n.editSchedule)
                    ])),
                PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      const Icon(Icons.delete, size: 18, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(l10n.deleteSchedule)
                    ])),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // [CẬP NHẬT] XẾP LỊCH NHANH - MẶC ĐỊNH BỎ CHỦ NHẬT
  // ===========================================================================
  void _showQuickScheduleDialog(BuildContext context, AppLocalizations l10n) {
    DateTime startDate = _startOfWeek(_currentDate);
    DateTime endDate = _endOfWeek(_currentDate);
    int? selectedEmpId;
    int? selectedShiftId;

    // [QUAN TRỌNG] Chỉ chọn từ T2 (1) đến T7 (6). Bỏ CN (7).
    List<int> selectedWeekdays = [1, 2, 3, 4, 5, 6];

    final formKey = GlobalKey<FormState>();

    final employeeCubit = context.read<EmployeeCubit>();
    final shiftCubit = context.read<ShiftCubit>();
    final scheduleCubit = context.read<WorkScheduleCubit>();

    final empState = employeeCubit.state;
    if (empState is EmployeeLoaded && empState.employees.isNotEmpty) {
      selectedEmpId = empState.employees.first.id;
    }
    final shiftState = shiftCubit.state;
    if (shiftState is ShiftLoaded && shiftState.shifts.isNotEmpty) {
      selectedShiftId = shiftState.shifts.first.id;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: employeeCubit),
          BlocProvider.value(value: shiftCubit)
        ],
        child: StatefulBuilder(builder: (context, setStateDialog) {
          void toggleDay(int day) {
            setStateDialog(() {
              if (selectedWeekdays.contains(day)) {
                selectedWeekdays.remove(day);
              } else {
                selectedWeekdays.add(day);
              }
            });
          }

          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            titlePadding: const EdgeInsets.all(24),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.blue.shade50, shape: BoxShape.circle),
                  child: Icon(Icons.add_task, color: _primaryColor),
                ),
                const SizedBox(width: 12),
                const Text("Xếp Lịch Nhanh",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Form(
              key: formKey,
              child: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("1. Chọn Nhân Viên & Ca",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 12),
                      BlocBuilder<EmployeeCubit, EmployeeState>(
                          builder: (context, state) {
                        List<Employee> list =
                            (state is EmployeeLoaded) ? state.employees : [];
                        return DropdownButtonFormField<int>(
                          value: selectedEmpId,
                          decoration: _inputDeco(l10n.employee),
                          isExpanded: true,
                          items: list
                              .map((e) => DropdownMenuItem(
                                  value: e.id, child: Text(e.fullName)))
                              .toList(),
                          onChanged: (val) => selectedEmpId = val,
                          validator: (v) => v == null ? "Required" : null,
                        );
                      }),
                      const SizedBox(height: 12),
                      BlocBuilder<ShiftCubit, ShiftState>(
                          builder: (context, state) {
                        List<Shift> list =
                            (state is ShiftLoaded) ? state.shifts : [];
                        return DropdownButtonFormField<int>(
                          value: selectedShiftId,
                          decoration: _inputDeco(l10n.shift),
                          isExpanded: true,
                          items: list.map((s) {
                            // [FIX] Null check string
                            final sTime = s.startTime ?? "";
                            final eTime = s.endTime ?? "";
                            String start = (sTime.length >= 5)
                                ? sTime.substring(0, 5)
                                : sTime;
                            String end = (eTime.length >= 5)
                                ? eTime.substring(0, 5)
                                : eTime;
                            return DropdownMenuItem(
                                value: s.id,
                                child: Text("${s.name} ($start - $end)"));
                          }).toList(),
                          onChanged: (val) => selectedShiftId = val,
                          validator: (v) => v == null ? "Required" : null,
                        );
                      }),
                      const SizedBox(height: 24),
                      const Text("2. Chọn Thời Gian",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                            initialDateRange:
                                DateTimeRange(start: startDate, end: endDate),
                          );
                          if (picked != null) {
                            setStateDialog(() {
                              startDate = picked.start;
                              endDate = picked.end;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: _inputDeco("Khoảng thời gian"),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  "${DateFormat('dd/MM').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}"),
                              const Icon(Icons.date_range, color: Colors.blue),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text("Áp dụng cho các ngày (CN mặc định nghỉ):",
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildDayChip(
                              "Thứ 2", 1, selectedWeekdays, toggleDay),
                          _buildDayChip(
                              "Thứ 3", 2, selectedWeekdays, toggleDay),
                          _buildDayChip(
                              "Thứ 4", 3, selectedWeekdays, toggleDay),
                          _buildDayChip(
                              "Thứ 5", 4, selectedWeekdays, toggleDay),
                          _buildDayChip(
                              "Thứ 6", 5, selectedWeekdays, toggleDay),
                          _buildDayChip(
                              "Thứ 7", 6, selectedWeekdays, toggleDay),
                          _buildDayChip("CN", 7, selectedWeekdays, toggleDay,
                              isWeekend: true),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.cancel,
                      style: const TextStyle(color: Colors.grey))),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text("XẾP LỊCH"),
                style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                onPressed: () {
                  if (formKey.currentState!.validate() &&
                      selectedEmpId != null &&
                      selectedShiftId != null) {
                    if (selectedWeekdays.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text("Vui lòng chọn ít nhất 1 ngày!"),
                          backgroundColor: Colors.orange));
                      return;
                    }

                    Navigator.pop(ctx);
                    int count = 0;
                    for (int i = 0;
                        i <= endDate.difference(startDate).inDays;
                        i++) {
                      DateTime day = startDate.add(Duration(days: i));
                      if (selectedWeekdays.contains(day.weekday)) {
                        final newItem = WorkSchedule(
                          id: 0,
                          workDate: DateFormat('yyyy-MM-dd').format(day),
                          employeeId: selectedEmpId!,
                          shiftId: selectedShiftId!,
                        );
                        scheduleCubit.saveSchedule(
                            schedule: newItem, isEdit: false);
                        count++;
                      }
                    }
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text("Đang tạo $count lịch làm việc..."),
                        backgroundColor: Colors.blue));
                  }
                },
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildDayChip(String label, int dayValue, List<int> selectedList,
      Function(int) onToggle,
      {bool isWeekend = false}) {
    final isSelected = selectedList.contains(dayValue);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onToggle(dayValue),
      selectedColor: isWeekend ? Colors.red.shade100 : Colors.blue.shade100,
      labelStyle: TextStyle(
          color: isSelected
              ? (isWeekend ? Colors.red.shade900 : Colors.blue.shade900)
              : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
      checkmarkColor: isWeekend ? Colors.red : Colors.blue,
      backgroundColor: Colors.white,
      side: BorderSide(
          color: isSelected ? Colors.transparent : Colors.grey.shade300),
    );
  }

  InputDecoration _inputDeco(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  void _confirmDelete(
      BuildContext context, WorkSchedule item, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteSchedule),
        content: Text("Xóa lịch làm việc ngày ${item.workDate}?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              context.read<WorkScheduleCubit>().deleteSchedule(item.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(l10n.deleteSchedule),
          ),
        ],
      ),
    );
  }

  // --- DIALOG EDIT CŨ (GIỮ LẠI ĐỂ SỬA LẺ) ---
  void _showEditDialog(
      BuildContext context, WorkSchedule? item, AppLocalizations l10n) {
    DateTime selectedDate =
        item != null ? DateTime.parse(item.workDate) : DateTime.now();
    int? selectedEmpId = item?.employeeId;
    int? selectedShiftId = item?.shiftId;

    final empState = context.read<EmployeeCubit>().state;
    if (item == null &&
        empState is EmployeeLoaded &&
        empState.employees.isNotEmpty) {
      selectedEmpId = empState.employees.first.id;
    }

    final shiftState = context.read<ShiftCubit>().state;
    if (item == null &&
        shiftState is ShiftLoaded &&
        shiftState.shifts.isNotEmpty) {
      selectedShiftId = shiftState.shifts.first.id;
    }

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<WorkScheduleCubit>()),
          BlocProvider.value(value: context.read<EmployeeCubit>()),
          BlocProvider.value(value: context.read<ShiftCubit>()),
        ],
        child: StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(item == null ? l10n.addSchedule : l10n.editSchedule,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor)),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setStateDialog(() => selectedDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: _inputDeco(l10n.workDate),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                          const Icon(Icons.calendar_today, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  BlocBuilder<EmployeeCubit, EmployeeState>(
                      builder: (context, state) {
                    List<Employee> list =
                        (state is EmployeeLoaded) ? state.employees : [];
                    return DropdownButtonFormField<int>(
                      value: selectedEmpId,
                      decoration: _inputDeco(l10n.employee),
                      isExpanded: true,
                      items: list
                          .map((e) => DropdownMenuItem(
                              value: e.id, child: Text(e.fullName)))
                          .toList(),
                      onChanged: (val) => selectedEmpId = val,
                    );
                  }),
                  const SizedBox(height: 12),
                  BlocBuilder<ShiftCubit, ShiftState>(
                      builder: (context, state) {
                    List<Shift> list =
                        (state is ShiftLoaded) ? state.shifts : [];
                    return DropdownButtonFormField<int>(
                      value: selectedShiftId,
                      decoration: _inputDeco(l10n.shift),
                      isExpanded: true,
                      items: list
                          .map((s) => DropdownMenuItem(
                              value: s.id, child: Text(s.name)))
                          .toList(),
                      onChanged: (val) => selectedShiftId = val,
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.cancel)),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate() &&
                      selectedEmpId != null &&
                      selectedShiftId != null) {
                    final newItem = WorkSchedule(
                      id: item?.id ?? 0,
                      workDate: DateFormat('yyyy-MM-dd').format(selectedDate),
                      employeeId: selectedEmpId!,
                      shiftId: selectedShiftId!,
                    );
                    context
                        .read<WorkScheduleCubit>()
                        .saveSchedule(schedule: newItem, isEdit: item != null);
                    Navigator.pop(ctx);
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white),
                child: Text(l10n.save),
              )
            ],
          );
        }),
      ),
    );
  }
}

// --- WIDGETS HIỂN THỊ TÊN & CA (GIỮ NGUYÊN) ---
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
          final e =
              state.employees.where((x) => x.id == employeeId).firstOrNull;
          if (e != null) name = e.fullName;
        }
        return Text(name,
            style: style ??
                const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.black87));
      },
    );
  }
}

class _ShiftBadge extends StatelessWidget {
  final int shiftId;
  final String? shiftName;
  final String? startTime;
  final String? endTime;
  const _ShiftBadge(
      {required this.shiftId, this.shiftName, this.startTime, this.endTime});

  @override
  Widget build(BuildContext context) {
    String displayText = shiftName ?? "Shift $shiftId";

    // [FIX NULL LENGTH]
    final sTime = startTime ?? "";
    final eTime = endTime ?? "";
    String start = (sTime.length >= 5) ? sTime.substring(0, 5) : sTime;
    String end = (eTime.length >= 5) ? eTime.substring(0, 5) : eTime;

    if (start.isNotEmpty && end.isNotEmpty) displayText += " ($start - $end)";

    if (shiftName == null) {
      return BlocBuilder<ShiftCubit, ShiftState>(
        builder: (context, state) {
          if (state is ShiftLoaded) {
            final s = state.shifts.where((x) => x.id == shiftId).firstOrNull;
            if (s != null) {
              String sStart = (s.startTime != null && s.startTime.length >= 5)
                  ? s.startTime.substring(0, 5)
                  : s.startTime;
              String sEnd = (s.endTime != null && s.endTime.length >= 5)
                  ? s.endTime.substring(0, 5)
                  : s.endTime;
              displayText = "${s.name} ($sStart - $sEnd)";
            }
          }
          return _buildChip(displayText);
        },
      );
    }
    return _buildChip(displayText);
  }

  Widget _buildChip(String text) {
    Color bg = Colors.grey.shade100;
    Color textCol = Colors.black87;
    String lower = text.toLowerCase();
    if (lower.contains('sáng') ||
        lower.contains('morning') ||
        lower.contains('ca a')) {
      bg = Colors.orange.shade50;
      textCol = Colors.orange.shade900;
    } else if (lower.contains('chiều') ||
        lower.contains('afternoon') ||
        lower.contains('ca b')) {
      bg = Colors.blue.shade50;
      textCol = Colors.blue.shade900;
    } else if (lower.contains('đêm') ||
        lower.contains('night') ||
        lower.contains('ca c')) {
      bg = Colors.indigo.shade50;
      textCol = Colors.indigo.shade900;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(text,
          style: TextStyle(
              fontSize: 12, color: textCol, fontWeight: FontWeight.w600)),
    );
  }
}
