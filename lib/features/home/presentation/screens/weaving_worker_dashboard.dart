import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:production_app_frontend/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:production_app_frontend/features/hr/work_schedule/presentation/bloc/work_schedule_cubit.dart';
// Giả định bạn có NotificationCubit, nếu chưa có thì dùng UI tĩnh
// import 'package:production_app_frontend/features/notification/bloc/notification_cubit.dart';

class WeavingWorkerDashboard extends StatefulWidget {
  const WeavingWorkerDashboard({super.key});

  @override
  State<WeavingWorkerDashboard> createState() => _WeavingWorkerDashboardState();
}

class _WeavingWorkerDashboardState extends State<WeavingWorkerDashboard> {
  final Color _primaryColor = const Color(0xFF003366);

  @override
  void initState() {
    super.initState();
    // Load lịch làm việc cá nhân và đồng nghiệp
    // context.read<WorkScheduleCubit>().loadMySchedule();
    // context.read<WorkScheduleCubit>().loadDepartmentSchedule();
  }

  @override
  Widget build(BuildContext context) {
    // Lấy thông tin User từ AuthCubit
    final authState = context.watch<AuthCubit>().state;
    final user = (authState is AuthAuthenticated) ? authState.user : null;
    
    // Giả định dữ liệu nếu chưa có API thực tế
    final String fullName = user?.fullName ?? "Nguyễn Văn A";
    const String area ="Khu A"; // Quan trọng: Khu vực được gán
    const String roleName = "Nhân viên Dệt";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: _primaryColor,
        elevation: 0,
        title: const Text("Dashboard", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {
              // Mở màn hình thông báo
              // context.push('/notifications');
              _showNotificationDialog(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. HEADER INFO CARD
            _buildHeaderCard(fullName, roleName, area),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. MAIN ACTIONS (Chức năng chính)
                  const Text("Chức năng chính", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Nút Vận hành máy (QUAN TRỌNG NHẤT)
                      Expanded(
                        child: _buildActionCard(
                          context,
                          title: "Vận hành Máy",
                          subtitle: "Khu vực $area",
                          icon: Icons.precision_manufacturing,
                          color: Colors.blue.shade700,
                          onTap: () {
                            // Điều hướng sang màn hình vận hành
                            // Màn hình này sẽ tự động lọc máy theo Khu A dựa trên logic Cubit đã bàn trước đó
                            context.push('/machine-operation');
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Nút Xem lịch làm việc
                      Expanded(
                        child: _buildActionCard(
                          context,
                          title: "Lịch cá nhân",
                          subtitle: "Xem ca làm việc",
                          icon: Icons.calendar_month,
                          color: Colors.orange.shade700,
                          onTap: () {
                            // context.push('/my-schedule');
                            _showScheduleDialog(context);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 3. DEPARTMENT STATUS (Đồng nghiệp trong ca)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Nhân sự trong ca (Khu A)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                      Text(DateFormat('dd/MM/yyyy').format(DateTime.now()), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildColleagueList(),

                  const SizedBox(height: 24),

                  // 4. RECENT NOTIFICATIONS
                  const Text("Thông báo mới", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 12),
                  _buildNotificationList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET COMPONENTS ---

  Widget _buildHeaderCard(String name, String role, String area) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      decoration: BoxDecoration(
        color: _primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white24,
            child: Text(
              name.isNotEmpty ? name[0] : "U",
              style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Xin chào, $name", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4)
                ),
                child: Text("$role - $area", style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, {
    required String title, 
    required String subtitle, 
    required IconData icon, 
    required Color color, 
    required VoidCallback onTap
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 2, blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildColleagueList() {
    // Dữ liệu giả lập (Sau này lấy từ WorkScheduleCubit)
    final colleagues = [
      {"name": "Trần Văn B", "status": "Đang vận hành", "machine": "Máy 01"},
      {"name": "Lê Thị C", "status": "Đang vận hành", "machine": "Máy 02"},
      {"name": "Phạm Văn D", "status": "Nghỉ giải lao", "machine": "-"},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), spreadRadius: 1, blurRadius: 5)],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: colleagues.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
        itemBuilder: (context, index) {
          final item = colleagues[index];
          final isWorking = item['status'] == "Đang vận hành";
          return ListTile(
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade200,
              child: Text(item['name']!.substring(0, 1), style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ),
            title: Text(item['name']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            subtitle: Text(item['machine']!, style: const TextStyle(fontSize: 12)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isWorking ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(4)
              ),
              child: Text(
                item['status']!, 
                style: TextStyle(fontSize: 10, color: isWorking ? Colors.green : Colors.orange, fontWeight: FontWeight.bold)
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationList() {
    final notifs = [
      {"title": "Bảo trì máy số 05", "time": "10:30 AM", "content": "Kỹ thuật sẽ bảo trì máy 05 từ 13h-14h."},
      {"title": "Thay đổi kế hoạch ca chiều", "time": "08:00 AM", "content": "Yêu cầu tăng sản lượng mã hàng A802."},
    ];

    return Column(
      children: notifs.map((n) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade50),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: Colors.blue, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(n['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(n['time']!, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(n['content']!, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                ],
              ),
            )
          ],
        ),
      )).toList(),
    );
  }

  // --- ACTIONS ---

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Đăng xuất"),
        content: const Text("Bạn có chắc muốn đăng xuất không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthCubit>().logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Đăng xuất"),
          )
        ],
      ),
    );
  }

  void _showScheduleDialog(BuildContext context) {
    // Đây là ví dụ hiển thị nhanh, thực tế nên push sang trang ScheduleScreen
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Lịch làm việc hôm nay"),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Ngày: 04/02/2026"),
            Text("Ca làm việc: Ca A (06:00 - 14:00)"),
            Text("Khu vực: A"),
            SizedBox(height: 10),
            Text("Nhiệm vụ: Vận hành máy 01, 02, 03"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Đóng")),
        ],
      ),
    );
  }

  void _showNotificationDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
            title: const Text("Thông báo"),
            content: const Text("Chức năng đang phát triển"),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Đóng"))],
        )
    );
  }
}