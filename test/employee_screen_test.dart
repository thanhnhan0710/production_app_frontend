import 'dart:io';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:production_app_frontend/features/hr/department/domain/department_model.dart';
import 'package:production_app_frontend/features/hr/department/presentation/bloc/department_cubit.dart';
import 'package:production_app_frontend/features/hr/employee/domain/employee_model.dart';
import 'package:production_app_frontend/features/hr/employee/presentation/bloc/employee_cubit.dart';
import 'package:production_app_frontend/features/hr/employee/presentation/screens/employee_screen.dart';
import 'package:production_app_frontend/l10n/app_localizations.dart';
import 'package:mocktail_image_network/mocktail_image_network.dart';


// --- 1. MOCK CUBITS ---
class MockEmployeeCubit extends MockCubit<EmployeeState> implements EmployeeCubit {}
class MockDepartmentCubit extends MockCubit<DepartmentState> implements DepartmentCubit {}

void main() {
  late MockEmployeeCubit mockEmployeeCubit;
  late MockDepartmentCubit mockDepartmentCubit;

  // Data giả lập
  final mockDepartments = [
    Department(id: 1, name: 'IT Dept', description: 'Tech'),
    Department(id: 2, name: 'HR Dept', description: 'Human Resource'),
  ];

  final mockEmployees = [
    Employee(
      id: 1, 
      fullName: 'Nguyen Van A', 
      email: 'a@test.com', 
      phone: '0909090909', 
      departmentId: 1, 
      position: 'Developer',
      avatarUrl: 'avatars/test.jpg', address: '', note: ''
    ),
    Employee(
      id: 2, 
      fullName: 'Le Thi B', 
      email: 'b@test.com', 
      phone: '0909090908', 
      departmentId: 2, 
      position: 'Manager', address: '', note: '', avatarUrl: ''
    ),
  ];

  setUpAll(() {
    // Đăng ký fallback value cho mocktail nếu cần verify các hàm save/update
    registerFallbackValue(Employee(id: 0, fullName: '', email: '', departmentId: 0, position: '', phone: '', address: '', note: '', avatarUrl: ''));
    
    // Override HTTP requests để tránh lỗi 404 khi load NetworkImage trong test
    HttpOverrides.global = null;
  });

  setUp(() {
    mockEmployeeCubit = MockEmployeeCubit();
    mockDepartmentCubit = MockDepartmentCubit();
  });

  // Helper function để build Widget
  Widget createWidgetUnderTest() {
    return MaterialApp(
      locale: const Locale('vi'), // Test Tiếng Việt
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MultiBlocProvider( // Dùng MultiBlocProvider vì màn hình này cần 2 Cubit
        providers: [
          BlocProvider<EmployeeCubit>.value(value: mockEmployeeCubit),
          BlocProvider<DepartmentCubit>.value(value: mockDepartmentCubit),
        ],
        child: const EmployeeScreen(),
      ),
    );
  }

  group('EmployeeScreen Tests', () {
    
    // --- TEST 1: LOAD DATA & DISPLAY (DESKTOP) ---
    testWidgets('Hiển thị danh sách nhân viên dạng Bảng trên Desktop', (tester) async {
      // 1. Arrange
      tester.view.physicalSize = const Size(1366, 768); // Size Desktop
      tester.view.devicePixelRatio = 1.0;

      // Giả lập state
      when(() => mockEmployeeCubit.state).thenReturn(EmployeeLoaded(mockEmployees));
      when(() => mockDepartmentCubit.state).thenReturn(DepartmentLoaded(mockDepartments));
      
      // Giả lập hàm load được gọi khi init
      when(() => mockEmployeeCubit.loadEmployees()).thenAnswer((_) async {});
      when(() => mockDepartmentCubit.loadDepartments()).thenAnswer((_) async {});

      // 2. Act (Dùng mockNetworkImages để bọc widget test lại)
      await mockNetworkImages(() async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump(); // Rebuild UI
      });

      // 3. Assert
      expect(find.text('Nguyen Van A'), findsOneWidget);
      expect(find.text('Le Thi B'), findsOneWidget);
      expect(find.text('IT Dept'), findsOneWidget); // Check badge phòng ban mapping đúng
      expect(find.byType(DataTable), findsOneWidget); // Desktop phải hiện DataTable

      // Cleanup
      addTearDown(tester.view.resetPhysicalSize);
    });

    // --- TEST 2: MOBILE VIEW ---
    testWidgets('Hiển thị danh sách nhân viên dạng List trên Mobile', (tester) async {
      // 1. Arrange
      tester.view.physicalSize = const Size(400, 800); // Size Mobile
      tester.view.devicePixelRatio = 1.0;

      when(() => mockEmployeeCubit.state).thenReturn(EmployeeLoaded(mockEmployees));
      when(() => mockDepartmentCubit.state).thenReturn(DepartmentLoaded(mockDepartments));
      when(() => mockEmployeeCubit.loadEmployees()).thenAnswer((_) async {});
      when(() => mockDepartmentCubit.loadDepartments()).thenAnswer((_) async {});

      // 2. Act
      await mockNetworkImages(() async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();
      });

      // 3. Assert
      expect(find.byType(DataTable), findsNothing);
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byIcon(Icons.phone), findsWidgets); // Nút gọi điện trên mobile

      addTearDown(tester.view.resetPhysicalSize);
    });

    // --- TEST 3: SEARCH FUNCTION ---
    testWidgets('Nhập text search gọi hàm searchEmployees', (tester) async {
      when(() => mockEmployeeCubit.state).thenReturn(EmployeeLoaded([]));
      when(() => mockDepartmentCubit.state).thenReturn(DepartmentLoaded([]));
      when(() => mockEmployeeCubit.loadEmployees()).thenAnswer((_) async {});
      when(() => mockDepartmentCubit.loadDepartments()).thenAnswer((_) async {});
      when(() => mockEmployeeCubit.searchEmployees(any())).thenAnswer((_) async {});

      await mockNetworkImages(() async => await tester.pumpWidget(createWidgetUnderTest()));

      // Tìm TextField và nhập liệu
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Nguyen Van A');
      await tester.testTextInput.receiveAction(TextInputAction.search);

      verify(() => mockEmployeeCubit.searchEmployees('Nguyen Van A')).called(1);
    });

    // --- TEST 4: ADD EMPLOYEE DIALOG ---
    testWidgets('Mở Dialog Thêm mới và kiểm tra Validation', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;

      when(() => mockEmployeeCubit.state).thenReturn(EmployeeLoaded([]));
      // Quan trọng: Phải có DepartmentLoaded để Dropdown hiển thị dữ liệu
      when(() => mockDepartmentCubit.state).thenReturn(DepartmentLoaded(mockDepartments));
      when(() => mockEmployeeCubit.loadEmployees()).thenAnswer((_) async {});
      when(() => mockDepartmentCubit.loadDepartments()).thenAnswer((_) async {});

      await mockNetworkImages(() async => await tester.pumpWidget(createWidgetUnderTest()));

      // 1. Tap nút Add (trên Desktop có label)
      await tester.tap(find.text('THÊM NHÂN VIÊN')); // Hoặc find.byIcon(Icons.add)
      await tester.pumpAndSettle();

      // 2. Kiểm tra Dialog hiện ra
      expect(find.byType(AlertDialog), findsOneWidget);
      
      // 3. Tap nút Save mà không nhập gì -> Kiểm tra Validator lỗi
      await tester.tap(find.text('Lưu')); // Giả sử l10n.save là 'Lưu'
      await tester.pump();

      // FormValidator sẽ hiện chữ "Required" (hoặc chuỗi bạn định nghĩa)
      expect(find.text('Required'), findsWidgets); 

      // 4. Điền form
      await tester.enterText(find.widgetWithText(TextFormField, 'Họ và tên'), 'New User');
      // Chọn phòng ban (Dropdown)
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('IT Dept').last); // Chọn item trong menu
      await tester.pumpAndSettle();

      // Giả lập hàm save
      when(() => mockEmployeeCubit.saveEmployee(
        employee: any(named: 'employee'), 
        imageFile: any(named: 'imageFile'), 
        isEdit: false
      )).thenAnswer((_) async {});

      // 5. Save lại
      await tester.tap(find.text('Lưu'));
      await tester.pump();

      // Verify hàm save được gọi
      verify(() => mockEmployeeCubit.saveEmployee(
        employee: any(named: 'employee'), 
        imageFile: null, 
        isEdit: false
      )).called(1);

      addTearDown(tester.view.resetPhysicalSize);
    });

    // --- TEST 5: DELETE EMPLOYEE ---
    // --- TEST 5: DELETE EMPLOYEE ---
    testWidgets('Xóa nhân viên gọi confirm dialog và hàm delete', (tester) async {
       // Setup Desktop view để thấy nút xóa trong bảng
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;

      when(() => mockEmployeeCubit.state).thenReturn(EmployeeLoaded(mockEmployees));
      when(() => mockDepartmentCubit.state).thenReturn(DepartmentLoaded(mockDepartments));
      when(() => mockEmployeeCubit.loadEmployees()).thenAnswer((_) async {});
      when(() => mockDepartmentCubit.loadDepartments()).thenAnswer((_) async {});
      when(() => mockEmployeeCubit.deleteEmployee(any())).thenAnswer((_) async {});

      // Bọc widget trong mockNetworkImages
      await mockNetworkImages(() async => await tester.pumpWidget(createWidgetUnderTest()));

      // 1. Tap nút Delete (thùng rác) của nhân viên đầu tiên
      // find.byIcon có thể tìm thấy nhiều icon, ta chọn cái đầu tiên (.first)
      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle(); // Chờ dialog hiện ra

      // Kiểm tra Confirm Dialog hiện ra
      expect(find.byType(AlertDialog), findsOneWidget);

      // --- [ĐOẠN SỬA LỖI Ở ĐÂY] ---
      // Thay vì find.text('Xóa nhân viên'), ta dùng find.widgetWithText
      // Nghĩa là: Tìm cái ElevatedButton nào có chứa chữ 'Xóa nhân viên'
      final confirmButton = find.widgetWithText(ElevatedButton, 'Xóa nhân viên');
      
      // Kiểm tra nút đó có tồn tại không
      expect(confirmButton, findsOneWidget);

      // Tap vào nút đó
      await tester.tap(confirmButton);
      // -----------------------------
      
      // Verify hàm delete được gọi với ID = 1 (ID của nhân viên đầu tiên trong mock data)
      verify(() => mockEmployeeCubit.deleteEmployee(1)).called(1);
      
      addTearDown(tester.view.resetPhysicalSize);
    });

  });
}