// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:production_app_frontend/core/constants/api_endpoints.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/widgets/responsive_layout.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../department/domain/department_model.dart';
import '../../../department/presentation/bloc/department_cubit.dart';
import '../../domain/employee_model.dart';
import '../bloc/employee_cubit.dart';

class EmployeeDepartmentScreen extends StatefulWidget {
  final int departmentId;

  const EmployeeDepartmentScreen({super.key, required this.departmentId});

  @override
  State<EmployeeDepartmentScreen> createState() => _EmployeeDepartmentScreenState();
}

class _EmployeeDepartmentScreenState extends State<EmployeeDepartmentScreen> {
  final Color _primaryColor = const Color(0xFF003366);
  final Color _bgLight = const Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    // Load nhân viên theo ID phòng ban
    context.read<EmployeeCubit>().loadEmployeesByDepartment(widget.departmentId);
    // Load thông tin phòng ban để lấy tên hiển thị
    context.read<DepartmentCubit>().loadDepartments();
  }

  Future<void> _launchAction(String scheme, String path) async {
    if (path.isEmpty) return;
    final Uri launchUri = Uri(scheme: scheme, path: path);
    try {
      await launchUrl(launchUri);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot launch action')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        title: BlocBuilder<DepartmentCubit, DepartmentState>(
          builder: (context, state) {
            String deptName = "Department Employees";
            if (state is DepartmentLoaded) {
              final dept = state.departments.where((d) => d.id == widget.departmentId).firstOrNull;
              if (dept != null) deptName = dept.name;
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(deptName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                if (deptName != "Department Employees")
                  const Text("Employee List", style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            );
          },
        ),
        backgroundColor: _primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
             // Logic quay lại thông minh: Nếu có thể pop thì pop, không thì về danh sách phòng ban
             if (Navigator.canPop(context)) {
               context.pop();
             } else {
               context.go('/departments');
             }
          },
        ),
      ),
      body: BlocBuilder<EmployeeCubit, EmployeeState>(
        builder: (context, state) {
          if (state is EmployeeLoading) {
            return Center(child: CircularProgressIndicator(color: _primaryColor));
          } else if (state is EmployeeError) {
            return Center(child: Text("Error: ${state.message}", style: const TextStyle(color: Colors.red)));
          } else if (state is EmployeeLoaded) {
            if (state.employees.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.group_off, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text("No employees in this department", style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                  ],
                ),
              );
            }
            return isDesktop
                ? _buildDesktopGrid(context, state.employees, l10n)
                : _buildMobileList(context, state.employees, l10n);
          }
          return const SizedBox();
        },
      ),
    );
  }

  // --- DESKTOP GRID (FULL WIDTH FIX) ---
  Widget _buildDesktopGrid(BuildContext context, List<Employee> employees, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      // [FIX 1] Container width infinity để Card bung hết cỡ
      // ignore: sized_box_for_whitespace
      child: Container(
        width: double.infinity,
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          // [FIX 2] LayoutBuilder để lấy chiều rộng màn hình
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  // [FIX 3] Ép bảng rộng tối thiểu bằng chiều rộng container
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(const Color(0xFFF9FAFB)),
                    horizontalMargin: 24,
                    columnSpacing: 30,
                    dataRowMinHeight: 72,
                    dataRowMaxHeight: 72,
                    columns: [
                      DataColumn(label: Text(l10n.fullName.toUpperCase(), style: _headerStyle)),
                      DataColumn(label: Text(l10n.position.toUpperCase(), style: _headerStyle)),
                      DataColumn(label: Text(l10n.contact.toUpperCase(), style: _headerStyle)),
                      DataColumn(label: Text(l10n.actions.toUpperCase(), style: _headerStyle)),
                    ],
                    rows: employees.map((emp) {
                      return DataRow(
                        cells: [
                          DataCell(Row(
                            children: [
                              _buildAvatar(emp.avatarUrl, emp.fullName, 20),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(emp.fullName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14)),
                                  Text(emp.email, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                ],
                              ),
                            ],
                          )),
                          DataCell(Text(emp.position, style: const TextStyle(fontWeight: FontWeight.w500))),
                          DataCell(Row(
                            children: [
                              _buildIconBtn(Icons.email_outlined, Colors.blue, () => _launchAction('mailto', emp.email)),
                              const SizedBox(width: 8),
                              _buildIconBtn(Icons.phone_outlined, Colors.green, () => _launchAction('tel', emp.phone)),
                            ],
                          )),
                          DataCell(Row(
                            children: [
                              IconButton(icon: const Icon(Icons.info_outline, color: Colors.grey), onPressed: () {
                                // Có thể hiện dialog chi tiết ở đây
                              }), 
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

  Widget _buildMobileList(BuildContext context, List<Employee> employees, AppLocalizations l10n) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: employees.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final emp = employees[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: _buildAvatar(emp.avatarUrl, emp.fullName, 28),
            title: Text(emp.fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            subtitle: Text(emp.position, style: TextStyle(color: _primaryColor, fontWeight: FontWeight.w600, fontSize: 13)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildIconBtn(Icons.email, Colors.blue, () => _launchAction('mailto', emp.email)),
                const SizedBox(width: 8),
                _buildIconBtn(Icons.phone, Colors.green, () => _launchAction('tel', emp.phone)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatar(String url, String name, double radius) {
    // 1. Lấy Full URL từ Helper
    final fullUrl = ApiEndpoints.getImageUrl(url);

    String initials = "?";
    if (fullUrl.isEmpty && name.isNotEmpty) {
      List<String> parts = name.trim().split(' ');
      if (parts.length >= 2) {
        initials = "${parts.first[0]}${parts.last[0]}".toUpperCase();
      } else if (parts.isNotEmpty) {
        initials = parts[0][0].toUpperCase();
        if (parts[0].length > 1) {
           initials += parts[0][1].toUpperCase();
        }
      }
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: _primaryColor.withOpacity(0.1),
      // 2. Sử dụng fullUrl thay vì url gốc
      backgroundImage: fullUrl.isNotEmpty ? NetworkImage(fullUrl) : null,
      child: fullUrl.isEmpty
          ? Text(initials,
              style: TextStyle(
                  color: _primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: radius * 0.8))
          : null,
    );
  }

  Widget _buildIconBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}