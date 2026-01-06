import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:production_app_frontend/l10n/app_localizations.dart';
import 'package:production_app_frontend/core/widgets/responsive_layout.dart';
import '../../domain/weaving_model.dart';
import '../bloc/weaving_cubit.dart';

class WeavingScreen extends StatefulWidget {
  const WeavingScreen({super.key});

  @override
  State<WeavingScreen> createState() => _WeavingScreenState();
}

class _WeavingScreenState extends State<WeavingScreen> {
  final Color _primaryColor = const Color(0xFF003366);
  final Color _bgLight = const Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    context.read<WeavingCubit>().loadTickets();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: _bgLight,
      body: BlocBuilder<WeavingCubit, WeavingState>(
        builder: (context, state) {
          if (state is WeavingLoading) return Center(child: CircularProgressIndicator(color: _primaryColor));
          if (state is WeavingError) return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
          
          if (state is WeavingLoaded) {
            if (!isDesktop) {
              return const Center(child: Text("Mobile View Coming Soon")); // Mobile có thể dùng Navigator.push
            }

            return Row(
              children: [
                // --- LEFT PANEL: LIST TICKETS (40%) ---
                Expanded(
                  flex: 4,
                  child: Container(
                    decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.grey.shade300))),
                    child: Column(
                      children: [
                        _buildHeader(l10n.weavingTicketTitle, Icons.receipt_long, onAdd: () {
                           // Show Add Ticket Dialog
                        }),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: state.tickets.length,
                            separatorBuilder: (_,__) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final ticket = state.tickets[index];
                              final isSelected = state.selectedTicket?.id == ticket.id;
                              return _buildTicketCard(ticket, isSelected);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // --- RIGHT PANEL: DETAILS & INSPECTIONS (60%) ---
                Expanded(
                  flex: 6,
                  child: state.selectedTicket == null 
                    ? Center(child: Text(l10n.noTicketSelected, style: TextStyle(color: Colors.grey.shade500)))
                    : _buildDetailPanel(state.selectedTicket!, state.inspections, l10n),
                ),
              ],
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildHeader(String title, IconData icon, {VoidCallback? onAdd}) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: _primaryColor),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primaryColor)),
            ],
          ),
          if(onAdd != null) 
            IconButton(icon: const Icon(Icons.add_circle), color: _primaryColor, onPressed: onAdd),
        ],
      ),
    );
  }

  Widget _buildTicketCard(WeavingTicket ticket, bool isSelected) {
    return Card(
      elevation: isSelected ? 4 : 0,
      color: isSelected ? Colors.blue.shade50 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isSelected ? BorderSide(color: _primaryColor, width: 1.5) : BorderSide.none,
      ),
      child: ListTile(
        onTap: () => context.read<WeavingCubit>().selectTicket(ticket),
        title: Text(ticket.code, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text("Machine: ${ticket.machineLine}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            Text("Basket: ${ticket.basketCode ?? 'N/A'}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text("${ticket.netWeight} kg", style: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor)),
            Text("${ticket.lengthMeters} m", style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailPanel(WeavingTicket ticket, List<WeavingInspection> inspections, AppLocalizations l10n) {
    return Container(
      color: _bgLight,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Ticket Info Header
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("TICKET #${ticket.code}", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _primaryColor)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDelete(ticket)),
                    ],
                  ),
                  const Divider(),
                  Row(
                    children: [
                      _detailItem(l10n.machineInfo, ticket.machineLine),
                      _detailItem(l10n.yarnInfo, "${ticket.yarnLotId} / ${ticket.yarnLoadDate}"),
                      _detailItem(l10n.weightInfo, "${ticket.grossWeight} / ${ticket.netWeight}"),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 2. Inspections List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.inspections, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_task, size: 16),
                label: Text(l10n.addInspection),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                onPressed: () {
                   // Show Add Inspection Dialog (Bạn cần implement form này tương tự các form trước)
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Expanded(
            child: Card(
              elevation: 0,
              child: ListView.separated(
                itemCount: inspections.length,
                separatorBuilder: (_,__) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final insp = inspections[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.shade50,
                      child: const Icon(Icons.check_circle_outline, color: Colors.green),
                    ),
                    title: Text(insp.stageName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Inspector: ${insp.employeeName} • Shift: ${insp.shiftName}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _specBadge("W: ${insp.widthMm}"),
                        const SizedBox(width: 8),
                        _specBadge("D: ${insp.weftDensity}"),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _specBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
  
  void _confirmDelete(WeavingTicket ticket) {
     // Implement delete logic calling context.read<WeavingCubit>().deleteTicket(ticket.id);
  }
}