import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mocktail_image_network/mocktail_image_network.dart';


// Import code của bạn
import 'package:production_app_frontend/features/production/machine/presentation/screens/machine_history_dialog.dart';
import 'package:production_app_frontend/features/production/machine/data/machine_repository.dart';
import 'package:production_app_frontend/features/production/machine/domain/machine_model.dart';
import 'package:production_app_frontend/features/production/machine/domain/machine_log_model.dart';
import 'package:production_app_frontend/l10n/app_localizations.dart';

// Mock Repository
class MockMachineRepository extends Mock implements MachineRepository {}

void main() {
  late MockMachineRepository mockRepo;
  late Machine mockMachine;

  // Data giả lập
  final mockLogs = [
    MachineLog(
      id: 1,
      machineId: 101,
      status: 'RUNNING',
      startTime: DateTime(2023, 10, 10, 8, 0),
      endTime: DateTime(2023, 10, 10, 10, 0),
      durationMinutes: 120.0,
      imageUrl: 'logs/img1.jpg',
    ),
    MachineLog(
      id: 2,
      machineId: 101,
      status: 'STOPPED',
      startTime: DateTime(2023, 10, 10, 12, 0),
      durationMinutes: 0.0,
      reason: 'Overheat',
    ),
  ];

  setUp(() {
    mockRepo = MockMachineRepository();
    mockMachine = Machine(id: 101, name: "Machine A", status: "Active", totalLines: 2, purpose: '');
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'), // Chạy test với tiếng Anh
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => MachineHistoryDialog(
                  machine: mockMachine,
                  repo: mockRepo,
                ),
              );
            },
            child: const Text("Open Dialog"),
          ),
        ),
      ),
    );
  }

  group('MachineHistoryDialog Tests', () {
    
    // --- TEST 1: LOADING STATE ---
    testWidgets('Hiển thị Loading khi đang tải dữ liệu', (tester) async {
      var completer = Completer<List<MachineLog>>();
      when(() => mockRepo.getMachineHistory(101)).thenAnswer((_) => completer.future);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.text("Open Dialog"));
      await tester.pump(); // Start animation dialog

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

// --- TEST 2: EMPTY STATE (FIXED) ---
    testWidgets('Hiển thị thông báo khi không có dữ liệu', (tester) async {
      // 1. Mock trả về rỗng
      when(() => mockRepo.getMachineHistory(101)).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.text("Open Dialog"));
      
      // 2. Chờ render
      await tester.pump(); 
      await tester.pump(const Duration(milliseconds: 100)); 

      // [SỬA DÒNG NÀY] Thay 'No history data' thành câu bạn thấy trong Log
      expect(find.textContaining('No activity history available.'), findsOneWidget); 
    });
    // --- TEST 3: ERROR STATE (FIXED) ---
    testWidgets('Hiển thị lỗi khi API fail', (tester) async {
      // [FIX QUAN TRỌNG] Dùng Future.error thay vì throw exception trực tiếp
      when(() => mockRepo.getMachineHistory(101)).thenAnswer((_) => Future.error("Network Error"));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.text("Open Dialog"));
      
      await tester.pump(); // Mở dialog
      await tester.pump(const Duration(milliseconds: 100)); // Future complete & Error state render

      expect(find.textContaining("Network Error"), findsOneWidget);
    });

    // --- TEST 4: SUCCESS STATE (FIXED TIMEOUT) ---
    testWidgets('Hiển thị danh sách Log và hình ảnh đúng cách', (tester) async {
      when(() => mockRepo.getMachineHistory(101)).thenAnswer((_) async => mockLogs);

      await mockNetworkImages(() async {
        await tester.pumpWidget(createWidgetUnderTest());

        await tester.tap(find.text("Open Dialog"));
        
        // [FIX] Thay pumpAndSettle bằng chuỗi pump cụ thể để tránh timeout do Image loading
        await tester.pump(); // Dialog animation start
        await tester.pump(const Duration(milliseconds: 500)); // Data loaded
        await tester.pump(); // Image widget render

        // Assert 1: Kiểm tra nội dung text
        expect(find.text('RUNNING'), findsOneWidget); 
        expect(find.text('STOPPED'), findsOneWidget);
        expect(find.textContaining('Reason: Overheat'), findsOneWidget);

        // Assert 2: Kiểm tra Image
        // Tìm widget Image.network
        expect(find.byType(Image), findsWidgets);
      });
    });

    // --- TEST 5: CLOSE DIALOG ---
    testWidgets('Nút Close đóng dialog', (tester) async {
      when(() => mockRepo.getMachineHistory(101)).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.text("Open Dialog"));
      await tester.pump(); 
      await tester.pump(const Duration(milliseconds: 100));

      final closeButton = find.text("Close");
      expect(closeButton, findsOneWidget);
      
      await tester.tap(closeButton);
      await tester.pumpAndSettle(); // Chờ dialog đóng hẳn

      expect(find.text("Close"), findsNothing);
    });

  });
}