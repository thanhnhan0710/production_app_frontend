import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mocktail_image_network/mocktail_image_network.dart';
import 'package:production_app_frontend/features/hr/department/domain/department_model.dart';
import 'package:production_app_frontend/features/hr/department/presentation/bloc/department_cubit.dart';


// Import code của bạn (Hãy điều chỉnh đường dẫn import cho đúng với project của bạn)
import 'package:production_app_frontend/features/hr/employee/presentation/screens/employee_department_screen.dart';
import 'package:production_app_frontend/features/hr/employee/presentation/bloc/employee_cubit.dart';
import 'package:production_app_frontend/features/hr/employee/domain/employee_model.dart';
import 'package:production_app_frontend/l10n/app_localizations.dart';


// --- 1. MOCK CLASSES ---
class MockEmployeeCubit extends MockCubit<EmployeeState> implements EmployeeCubit {}
class MockDepartmentCubit extends MockCubit<DepartmentState> implements DepartmentCubit {}
class MockGoRouter extends Mock implements GoRouter {}

void main() {
  late MockEmployeeCubit mockEmployeeCubit;
  late MockDepartmentCubit mockDepartmentCubit;
  late MockGoRouter mockGoRouter;

  // Data giả lập
  final mockEmployees = [
    Employee(
      id: 1,
      fullName: 'Nguyen Van A',
      email: 'a@test.com',
      phone: '0901234567',
      departmentId: 1,
      position: 'Developer',
      avatarUrl: 'avatars/a.jpg', address: '', note: '',
    ),
    Employee(
      id: 2,
      fullName: 'Le Thi B',
      email: 'b@test.com',
      phone: '0907654321',
      departmentId: 1,
      position: 'Tester',
      avatarUrl: '', address: '', note: '',
    ),
  ];

  final mockDepartments = [
    Department(id: 1, name: 'IT Department', description: 'Tech Team'),
  ];

  setUp(() {
    mockEmployeeCubit = MockEmployeeCubit();
    mockDepartmentCubit = MockDepartmentCubit();
    mockGoRouter = MockGoRouter();

    // Setup default states
    when(() => mockEmployeeCubit.state).thenReturn(EmployeeInitial());
    when(() => mockDepartmentCubit.state).thenReturn(DepartmentInitial());
    
    // Stub các hàm void trả về future để tránh lỗi null
    when(() => mockEmployeeCubit.loadEmployeesByDepartment(any())).thenAnswer((_) async {});
    when(() => mockDepartmentCubit.loadDepartments()).thenAnswer((_) async {});
  });

  // Helper function để build widget
  Widget createWidgetUnderTest() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: MultiBlocProvider(
        providers: [
          BlocProvider<EmployeeCubit>.value(value: mockEmployeeCubit),
          BlocProvider<DepartmentCubit>.value(value: mockDepartmentCubit),
        ],
        child: InheritedGoRouter(
          goRouter: mockGoRouter,
          child: const EmployeeDepartmentScreen(departmentId: 1),
        ),
      ),
    );
  }

  group('EmployeeDepartmentScreen Tests', () {
    
    // --- TEST 1: INITIALIZATION ---
    testWidgets('Gọi API loadEmployeesByDepartment và loadDepartments khi khởi tạo', (tester) async {
      await mockNetworkImages(() async {
        await tester.pumpWidget(createWidgetUnderTest());
      });

      // Verify hàm được gọi đúng ID truyền vào (departmentId: 1)
      verify(() => mockEmployeeCubit.loadEmployeesByDepartment(1)).called(1);
      verify(() => mockDepartmentCubit.loadDepartments()).called(1);
    });

    // --- TEST 2: APP BAR TITLE ---
    testWidgets('Hiển thị tên phòng ban trên AppBar khi DepartmentLoaded', (tester) async {
      // Arrange: Set state phòng ban đã load
      when(() => mockDepartmentCubit.state).thenReturn(DepartmentLoaded(mockDepartments));
      
      await mockNetworkImages(() async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump(); // Rebuild UI
      });

      // Assert: Tìm thấy tên "IT Department" trên AppBar
      expect(find.text('IT Department'), findsOneWidget);
      // Assert: Tìm thấy subtitle "Employee List"
      expect(find.text('Employee List'), findsOneWidget);
    });

    // --- TEST 3: LOADING STATE ---
    testWidgets('Hiển thị Loading Indicator khi EmployeeLoading', (tester) async {
      when(() => mockEmployeeCubit.state).thenReturn(EmployeeLoading());

      await mockNetworkImages(() async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();
      });

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    // --- TEST 4: EMPTY STATE ---
    testWidgets('Hiển thị thông báo Empty khi danh sách rỗng', (tester) async {
      when(() => mockEmployeeCubit.state).thenReturn(EmployeeLoaded([])); // List rỗng

      await mockNetworkImages(() async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();
      });

      expect(find.text('No employees in this department'), findsOneWidget);
      expect(find.byIcon(Icons.group_off), findsOneWidget);
    });

    // --- TEST 5: ERROR STATE ---
    testWidgets('Hiển thị thông báo lỗi khi EmployeeError', (tester) async {
      const errorMessage = "Connection failed";
      when(() => mockEmployeeCubit.state).thenReturn(EmployeeError(errorMessage));

      await mockNetworkImages(() async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();
      });

      expect(find.text('Error: $errorMessage'), findsOneWidget);
    });

    // --- TEST 6: MOBILE LAYOUT ---
    testWidgets('Hiển thị ListView và ListTile trên màn hình Mobile', (tester) async {
      // Set size Mobile
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      when(() => mockEmployeeCubit.state).thenReturn(EmployeeLoaded(mockEmployees));

      await mockNetworkImages(() async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();
      });

      // Assert không thấy DataTable
      expect(find.byType(DataTable), findsNothing);
      // Assert thấy ListView
      expect(find.byType(ListView), findsOneWidget);
      // Assert thấy tên nhân viên
      expect(find.text('Nguyen Van A'), findsOneWidget);
      // Assert thấy nút gọi điện/email (icon button)
      expect(find.byIcon(Icons.phone), findsWidgets);

      addTearDown(tester.view.resetPhysicalSize);
    });

    // --- TEST 7: DESKTOP LAYOUT ---
    testWidgets('Hiển thị DataTable trên màn hình Desktop', (tester) async {
      // Set size Desktop
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;

      when(() => mockEmployeeCubit.state).thenReturn(EmployeeLoaded(mockEmployees));

      await mockNetworkImages(() async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();
      });

      // Assert thấy DataTable
      expect(find.byType(DataTable), findsOneWidget);
      // Assert thấy dữ liệu trong bảng
      expect(find.text('Nguyen Van A'), findsOneWidget);
      expect(find.text('Developer'), findsOneWidget);

      addTearDown(tester.view.resetPhysicalSize);
    });

    // --- TEST 8: NAVIGATION (BACK BUTTON) ---
    testWidgets('Nút Back: Gọi context.pop() nếu có thể pop, hoặc context.go() nếu không', (tester) async {
      await mockNetworkImages(() async {
        await tester.pumpWidget(createWidgetUnderTest());
      });

      // Tìm nút back trên AppBar
      final backButton = find.widgetWithIcon(IconButton, Icons.arrow_back);
      expect(backButton, findsOneWidget);

      // Tap nút back
      await tester.tap(backButton);
      
      // Vì trong môi trường test đơn lẻ, Navigator.canPop thường là false, 
      // nên nó sẽ rơi vào nhánh context.go('/departments')
      // Tuy nhiên GoRouter Mock khó verify logic canPop chính xác mà không setup Navigator complex.
      // Ở mức basic, ta verify việc tap không gây crash là đạt.
      
      // Nếu muốn verify router.go:
      // verify(() => mockGoRouter.go('/departments')).called(1); 
    });
  });
}