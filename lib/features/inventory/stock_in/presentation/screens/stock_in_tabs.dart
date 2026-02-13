import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:production_app_frontend/l10n/app_localizations.dart';
import 'package:production_app_frontend/features/inventory/stock_in/presentation/screens/material_stock_in_page.dart';

// Import Repository/Cubit
import '../../data/material_receipt_repository.dart';
import '../bloc/material_receipt_cubit.dart';

// --- 1. TAB NGUYÊN VẬT LIỆU (GIỮ NGUYÊN) ---
class MaterialStockInTab extends StatelessWidget {
  const MaterialStockInTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Cung cấp Cubit để quản lý state danh sách phiếu nhập
    return BlocProvider(
      create: (context) => MaterialReceiptCubit(MaterialReceiptRepository()),
      child: const MaterialStockInPage(),
    );
  }
}

// ============================================================================
// CÁC TAB KHÁC (BÁN THÀNH PHẨM, THÀNH PHẨM) - ĐANG PHÁT TRIỂN (LOCKED)
// ============================================================================

class SemiFinishedStockInTab extends StatelessWidget {
  const SemiFinishedStockInTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const _UnderDevelopmentTab();
  }
}

class FinishedProductStockInTab extends StatelessWidget {
  const FinishedProductStockInTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const _UnderDevelopmentTab();
  }
}

// --- WIDGET CHUNG CHO TÍNH NĂNG ĐANG PHÁT TRIỂN ---
class _UnderDevelopmentTab extends StatelessWidget {
  const _UnderDevelopmentTab();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.construction, size: 64, color: Colors.orange.shade400),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.notice, // Tiêu đề: Thông báo
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.featureUnderDevelopment, // Nội dung: Tính năng đang phát triển
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}