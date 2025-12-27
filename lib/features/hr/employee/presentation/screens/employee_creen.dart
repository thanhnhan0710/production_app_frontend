import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/widgets/responsive_layout.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../department/domain/department_model.dart';
import '../../../department/presentation/bloc/department_cubit.dart';
import '../../domain/employee_model.dart';
import '../bloc/employee_cubit.dart';

class EmployeeScreen extends StatefulWidget {
  const EmployeeScreen({super.key});

  @override
  State<EmployeeScreen> createState() => _EmployeeScreenState();
}

class _EmployeeScreenState extends State<EmployeeScreen> {
  final _searchController = TextEditingController();
  final Color _primaryColor = const Color(0xFF003366);
  final Color _accentColor = const Color(0xFF0055AA);
  final Color _bgLight = const Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    context.read<EmployeeCubit>().loadEmployees();
    context.read<DepartmentCubit>().loadDepartments();
  }

  // --- ACTIONS ---
  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) return;
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      await launchUrl(launchUri);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot make phone call on this device')),
        );
      }
    }
  }

  Future<void> _sendEmail(String email) async {
    if (email.isEmpty) return;
    final Uri launchUri = Uri(scheme: 'mailto', path: email);
    try {
      await launchUrl(launchUri);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot find email app')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: _bgLight,
      body: BlocBuilder<EmployeeCubit, EmployeeState>(
        builder: (context, state) {
          return Column(
            children: [
              // --- HEADER SECTION ---
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
                            color: _primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.people_alt, color: _primaryColor, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.employeeTitle,
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Manage your team members",
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (isDesktop)
                          ElevatedButton.icon(
                            onPressed: () => _showEditDialog(context, null, l10n),
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(l10n.addEmployee.toUpperCase()),
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
                    
                    // --- SEARCH BAR ---
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: _bgLight,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: TextField(
                              controller: _searchController,
                              textInputAction: TextInputAction.search,
                              decoration: InputDecoration(
                                hintText: l10n.searchEmployee,
                                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 20),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                // Nút tìm kiếm thủ công
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.arrow_forward, color: Colors.blue),
                                  onPressed: () {
                                    context.read<EmployeeCubit>().searchEmployees(_searchController.text);
                                  },
                                ),
                              ),
                              onSubmitted: (value) {
                                context.read<EmployeeCubit>().searchEmployees(value);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Icon(Icons.filter_list, color: Colors.grey, size: 20),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: Colors.grey.shade200),

              // --- MAIN CONTENT ---
              Expanded(
                child: Builder(
                  builder: (context) {
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
                              Icon(Icons.person_off_outlined, size: 60, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text("No employees found", style: TextStyle(color: Colors.grey.shade500)),
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
              ),
            ],
          );
        },
      ),
      floatingActionButton: !isDesktop
          ? FloatingActionButton(
              backgroundColor: _accentColor,
              onPressed: () => _showEditDialog(context, null, l10n),
              child: const Icon(Icons.person_add, color: Colors.white),
            )
          : null,
    );
  }

  // --- DESKTOP GRID ---
  Widget _buildDesktopGrid(BuildContext context, List<Employee> employees, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(const Color(0xFFF9FAFB)),
          horizontalMargin: 24,
          columnSpacing: 30,
          dataRowMinHeight: 72,
          dataRowMaxHeight: 72,
          columns: [
            DataColumn(label: Text(l10n.fullName.toUpperCase(), style: _headerStyle)),
            DataColumn(label: Text(l10n.department.toUpperCase(), style: _headerStyle)),
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
                DataCell(_DepartmentBadge(deptId: emp.departmentId, isChip: true)),
                DataCell(Text(emp.position, style: const TextStyle(fontWeight: FontWeight.w500))),
                DataCell(Row(
                  children: [
                    _buildIconBtn(Icons.email_outlined, Colors.blue, () => _sendEmail(emp.email)),
                    const SizedBox(width: 8),
                    _buildIconBtn(Icons.phone_outlined, Colors.green, () => _makePhoneCall(emp.phone)),
                  ],
                )),
                DataCell(Row(
                  children: [
                    IconButton(icon: const Icon(Icons.edit_note, color: Colors.grey), onPressed: () => _showEditDialog(context, emp, l10n)),
                    IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _confirmDelete(context, emp, l10n)),
                  ],
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  TextStyle get _headerStyle => TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5);

  // --- MOBILE LIST ---
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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAvatar(emp.avatarUrl, emp.fullName, 28),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(emp.fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                          const SizedBox(height: 4),
                          Text(emp.position, style: TextStyle(color: _primaryColor, fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 8),
                          _DepartmentBadge(deptId: emp.departmentId, isChip: false),
                        ],
                      ),
                    ),
                    PopupMenuButton(
                      icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
                      onSelected: (val) {
                        if (val == 'edit') _showEditDialog(context, emp, l10n);
                        if (val == 'delete') _confirmDelete(context, emp, l10n);
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem(value: 'edit', child: Row(children: [const Icon(Icons.edit, size: 18), const SizedBox(width: 8), Text(l10n.editEmployee)])),
                        PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete, size: 18, color: Colors.red), const SizedBox(width: 8), Text(l10n.deleteEmployee)])),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Divider(height: 1, color: Colors.grey.shade100)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _sendEmail(emp.email),
                        child: _buildContactRow(Icons.email, emp.email),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => _makePhoneCall(emp.phone),
                        child: _buildContactRow(Icons.phone, emp.phone),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  // --- AVATAR LOGIC ---
  Widget _buildAvatar(String url, String name, double radius) {
    String initials = "?";
    if (url.isEmpty && name.isNotEmpty) {
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
      backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
      child: url.isEmpty
          ? Text(initials,
              style: TextStyle(
                  color: _primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: radius * 0.8))
          : null,
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade400),
        const SizedBox(width: 6),
        Expanded(child: Text(text.isNotEmpty ? text : "N/A", style: TextStyle(fontSize: 12, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _buildIconBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  // --- DIALOG ---
  void _showEditDialog(BuildContext context, Employee? emp, AppLocalizations l10n) {
    final fullNameCtrl = TextEditingController(text: emp?.fullName ?? '');
    final emailCtrl = TextEditingController(text: emp?.email ?? '');
    final phoneCtrl = TextEditingController(text: emp?.phone ?? '');
    final positionCtrl = TextEditingController(text: emp?.position ?? '');
    final noteCtrl = TextEditingController(text: emp?.note ?? '');
    int? selectedDeptId = emp?.departmentId;
    
    PlatformFile? pickedFile;
    Uint8List? pickedBytes;
    
    final deptState = context.read<DepartmentCubit>().state;
    if (emp == null && deptState is DepartmentLoaded && deptState.departments.isNotEmpty) {
      selectedDeptId = deptState.departments.first.id;
    }

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          Future<void> pickImage() async {
            try {
              FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
              if (result != null) {
                setStateDialog(() {
                  pickedFile = result.files.first;
                  pickedBytes = result.files.first.bytes;
                });
              }
            } catch (e) {
              print("Error picking file: $e");
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            titlePadding: const EdgeInsets.all(24),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            title: Text(emp == null ? l10n.addEmployee : l10n.editEmployee, style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
            content: Form(
              key: formKey,
              child: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Stack(
                          children: [
                            GestureDetector(
                              onTap: pickImage,
                              child: CircleAvatar(
                                radius: 40,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: pickedBytes != null 
                                    ? MemoryImage(pickedBytes!) 
                                    : (emp != null && emp.avatarUrl.isNotEmpty ? NetworkImage(emp.avatarUrl) : null) as ImageProvider?,
                                child: (pickedBytes == null && (emp == null || emp.avatarUrl.isEmpty))
                                    ? const Icon(Icons.person, size: 40, color: Colors.grey)
                                    : null,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: InkWell(
                                onTap: pickImage,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(color: _primaryColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                                  child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(controller: fullNameCtrl, decoration: _inputDeco(l10n.fullName), validator: (v) => v!.isEmpty ? "Required" : null),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: TextFormField(controller: emailCtrl, decoration: _inputDeco(l10n.email))),
                          const SizedBox(width: 12),
                          Expanded(child: TextFormField(controller: phoneCtrl, decoration: _inputDeco(l10n.phone))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        value: selectedDeptId,
                        decoration: _inputDeco(l10n.department),
                        items: (deptState is DepartmentLoaded) 
                          ? deptState.departments.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList() 
                          : [],
                        onChanged: (val) => selectedDeptId = val,
                        validator: (v) => v == null ? "Required" : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(controller: positionCtrl, decoration: _inputDeco(l10n.position)),
                      const SizedBox(height: 16),
                      TextFormField(controller: noteCtrl, decoration: _inputDeco(l10n.note), maxLines: 2),
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
                  if (formKey.currentState!.validate() && selectedDeptId != null) {
                    final newEmp = Employee(
                      id: emp?.id ?? 0,
                      fullName: fullNameCtrl.text,
                      email: emailCtrl.text,
                      phone: phoneCtrl.text,
                      address: emp?.address ?? '',
                      position: positionCtrl.text,
                      departmentId: selectedDeptId!,
                      note: noteCtrl.text,
                      avatarUrl: emp?.avatarUrl ?? '',
                    );
                    
                    context.read<EmployeeCubit>().saveEmployee(employee: newEmp, imageFile: pickedFile, isEdit: emp != null);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(emp == null ? l10n.successAdded : l10n.successUpdated), backgroundColor: Colors.green));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: Text(l10n.save),
              ),
            ],
          );
        }
      ),
    );
  }

  InputDecoration _inputDeco(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  void _confirmDelete(BuildContext context, Employee emp, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [const Icon(Icons.warning_amber_rounded, color: Colors.red), const SizedBox(width: 8), Text(l10n.deleteEmployee)]),
        content: Text(l10n.confirmDeleteEmployee(emp.fullName)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              context.read<EmployeeCubit>().deleteEmployee(emp.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(l10n.deleteEmployee),
          ),
        ],
      ),
    );
  }
}

class _DepartmentBadge extends StatelessWidget {
  final int deptId;
  final bool isChip; 
  const _DepartmentBadge({required this.deptId, required this.isChip});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DepartmentCubit, DepartmentState>(
      builder: (context, state) {
        String deptName = "Unknown";
        Color color = Colors.grey; 
        
        if (state is DepartmentLoaded) {
          final dept = state.departments.where((d) => d.id == deptId).firstOrNull;
          if (dept != null) {
            deptName = dept.name;
            final colors = [
              Colors.blue, Colors.purple, Colors.orange, Colors.teal,
              Colors.redAccent, Colors.green, Colors.indigo, Colors.pinkAccent,
              Colors.brown, Colors.deepPurple, Colors.amber.shade700,
              Colors.cyan, Colors.lime.shade800, Colors.blueGrey, Colors.lightGreen.shade700,
              Colors.deepOrangeAccent, Colors.lightBlueAccent.shade700, Colors.purpleAccent.shade700,
              Colors.yellow.shade800, Colors.grey.shade700
            ];
            color = colors[dept.id % colors.length];
          }
        }
        
        if (!isChip) {
          return Row(
            children: [
              Icon(Icons.circle, size: 8, color: color),
              const SizedBox(width: 6),
              Text(deptName, style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
          child: Text(deptName, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
        );
      },
    );
  }
}