import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/widgets/responsive_layout.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../domain/department_model.dart';
import '../bloc/department_cubit.dart';

class DepartmentScreen extends StatefulWidget {
  const DepartmentScreen({super.key});

  @override
  State<DepartmentScreen> createState() => _DepartmentScreenState();
}

class _DepartmentScreenState extends State<DepartmentScreen> {
  final _searchController = TextEditingController();
  final Color _primaryColor = const Color(0xFF003366);
  final Color _accentColor = const Color(0xFF0055AA);

  @override
  void initState() {
    super.initState();
    context.read<DepartmentCubit>().loadDepartments();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: BlocBuilder<DepartmentCubit, DepartmentState>(
        builder: (context, state) {
          int totalDepts = 0;
          if (state is DepartmentLoaded) {
            totalDepts = state.departments.length;
          }

          return Column(
            children: [
              // --- HEADER SECTION ---
              Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      offset: const Offset(0, 2),
                      blurRadius: 10,
                    )
                  ],
                ),
                child: Column(
                  children: [
                    // Title Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.departmentTitle,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: _primaryColor,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Human Resources Management",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        if (isDesktop)
                          ElevatedButton.icon(
                            onPressed: () => _showEditDialog(context, null, l10n),
                            icon: const Icon(Icons.add_circle_outline, size: 18),
                            label: Text(l10n.addDept.toUpperCase()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              textStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Stats & Search Row
                    Row(
                      children: [
                        if (isDesktop) ...[
                          _buildStatBadge(Icons.domain, "Total", "$totalDepts", Colors.blue),
                          const SizedBox(width: 16),
                          _buildStatBadge(Icons.check_circle, "Active", "$totalDepts", Colors.green),
                          const Spacer(),
                        ],
                        
                        // Search Bar
                        Expanded(
                          flex: isDesktop ? 0 : 1,
                          child: Container(
                            width: isDesktop ? 300 : double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: TextField(
                              controller: _searchController,
                              textInputAction: TextInputAction.search,
                              decoration: InputDecoration(
                                hintText: l10n.searchDept,
                                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                                // Nút tìm kiếm thủ công
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.arrow_forward, color: Colors.blue),
                                  onPressed: () {
                                    context.read<DepartmentCubit>().searchDepartments(_searchController.text);
                                  },
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              // Sự kiện Enter
                              onSubmitted: (value) {
                                context.read<DepartmentCubit>().searchDepartments(value);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // --- CONTENT SECTION ---
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Builder(
                    builder: (context) {
                      if (state is DepartmentLoading) {
                        return Center(child: CircularProgressIndicator(color: _primaryColor));
                      } else if (state is DepartmentError) {
                        return _buildErrorState(state.message);
                      } else if (state is DepartmentLoaded) {
                        if (state.departments.isEmpty) {
                          return _buildEmptyState();
                        }
                        return isDesktop
                            ? _buildDesktopTable(context, state.departments, l10n)
                            : _buildMobileListView(context, state.departments, l10n);
                      }
                      return const SizedBox();
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: !isDesktop
          ? FloatingActionButton(
              backgroundColor: _accentColor,
              elevation: 4,
              child: const Icon(Icons.add, color: Colors.white),
              onPressed: () => _showEditDialog(context, null, l10n),
            )
          : null,
    );
  }

  // --- WIDGETS CON ---

  Widget _buildStatBadge(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
            child: Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text("No departments found", style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => context.read<DepartmentCubit>().loadDepartments(),
            child: const Text("Retry"),
          )
        ],
      ),
    );
  }

  // --- DESKTOP TABLE VIEW ---
  Widget _buildDesktopTable(BuildContext context, List<Department> departments, AppLocalizations l10n) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: double.infinity,
        color: Colors.white,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.grey.shade100),
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(const Color(0xFFF9FAFB)),
            headingRowHeight: 52,
            dataRowMinHeight: 60,
            dataRowMaxHeight: 60,
            horizontalMargin: 24,
            columnSpacing: 24,
            columns: [
              DataColumn(label: Text("ID", style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 13))),
              DataColumn(label: Text(l10n.deptName.toUpperCase(), style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 13))),
              DataColumn(label: Text(l10n.deptDesc.toUpperCase(), style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 13))),
              DataColumn(label: Text(l10n.actions.toUpperCase(), style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 13))),
            ],
            rows: departments.asMap().entries.map((entry) {
              final index = entry.key;
              final dept = entry.value;
              final color = MaterialStateProperty.all(
                index % 2 == 0 ? Colors.white : const Color(0xFFF9FAFB).withOpacity(0.5),
              );

              return DataRow(
                color: color,
                cells: [
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                      child: Text("#${dept.id}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontFamily: 'Monospace')),
                    ),
                  ),
                  DataCell(
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: _primaryColor.withOpacity(0.1),
                          child: Text(dept.name.substring(0, 1).toUpperCase(), style: TextStyle(fontSize: 12, color: _primaryColor, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        Text(dept.name, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                      ],
                    )
                  ),
                  DataCell(
                    Text(dept.description, style: TextStyle(color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  DataCell(Row(
                    children: [
                      _buildActionButton(Icons.edit_outlined, Colors.blue, () => _showEditDialog(context, dept, l10n)),
                      const SizedBox(width: 8),
                      _buildActionButton(Icons.delete_outline, Colors.red, () => _confirmDelete(context, dept, l10n)),
                    ],
                  )),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  // --- MOBILE LIST VIEW ---
  Widget _buildMobileListView(BuildContext context, List<Department> departments, AppLocalizations l10n) {
    return ListView.separated(
      itemCount: departments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final dept = departments[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showEditDialog(context, dept, l10n),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _accentColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dept.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 4),
                        Text(
                          dept.description,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  PopupMenuButton(
                    icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (value) {
                      if (value == 'edit') _showEditDialog(context, dept, l10n);
                      if (value == 'delete') _confirmDelete(context, dept, l10n);
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(children: [Icon(Icons.edit, size: 18, color: Colors.blue.shade400), const SizedBox(width: 12), Text(l10n.editDept)]),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red.shade400), const SizedBox(width: 12), Text(l10n.deleteDept)]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- DIALOG ---
  void _showEditDialog(BuildContext context, Department? department, AppLocalizations l10n) {
    final nameController = TextEditingController(text: department?.name ?? '');
    final descController = TextEditingController(text: department?.description ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.all(24),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        actionsPadding: const EdgeInsets.all(24),
        title: Text(
          department == null ? l10n.addDept : l10n.editDept,
          style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: l10n.deptName,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  validator: (v) => v!.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: l10n.deptDesc,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final newDept = Department(
                  id: department?.id ?? 0,
                  name: nameController.text,
                  description: descController.text,
                );

                if (department == null) {
                  context.read<DepartmentCubit>().addDepartment(newDept);
                } else {
                  context.read<DepartmentCubit>().updateDepartment(newDept);
                }
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(department == null ? l10n.successAdded : l10n.successUpdated),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.green,
                ));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Department dept, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            Text(l10n.deleteDept),
          ],
        ),
        content: Text(l10n.confirmDelete(dept.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              context.read<DepartmentCubit>().deleteDepartment(dept.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(l10n.successDeleted),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.redAccent,
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(l10n.deleteDept),
          ),
        ],
      ),
    );
  }
}