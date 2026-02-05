import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:production_app_frontend/features/hr/department/domain/department_model.dart';
import 'package:production_app_frontend/features/hr/department/presentation/bloc/department_cubit.dart';
import 'package:production_app_frontend/features/hr/department/presentation/screens/department_screen.dart';
import 'package:production_app_frontend/l10n/app_localizations.dart';

// --- BƯỚC 1: MOCK CÁC DEPENDENCY ---

// Mock Cubit để điều khiển State giả
class MockDepartmentCubit extends MockCubit<DepartmentState> implements DepartmentCubit {}

// Fake State (Nếu cần thiết cho registerFallbackValue)
class FakeDepartmentState extends Fake implements DepartmentState {}

void main() {
  late MockDepartmentCubit mockDepartmentCubit;

  setUpAll(() {
    registerFallbackValue(FakeDepartmentState());
    registerFallbackValue(Department(id: 0, name: '', description: ''));
  });

  setUp(() {
    mockDepartmentCubit = MockDepartmentCubit();
  });

  // Hàm Helper để build widget với đầy đủ môi trường (MaterialApp, BlocProvider, Localizations)
  Widget createWidgetUnderTest() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<DepartmentCubit>.value(
        value: mockDepartmentCubit,
        child: const DepartmentScreen(),
      ),
    );
  }

  group('DepartmentScreen Tests', () {
    
    // --- TEST CASE 1: INITIALIZATION & LOADING ---
    testWidgets('Gọi loadDepartments() khi khởi tạo và hiển thị Loading Indicator', (tester) async {
      // 1. Arrange: Giả lập state đang loading
      when(() => mockDepartmentCubit.state).thenReturn(DepartmentLoading());
      when(() => mockDepartmentCubit.loadDepartments()).thenAnswer((_) async {});

      // 2. Act: Build UI
      await tester.pumpWidget(createWidgetUnderTest());

      // 3. Assert: Kiểm tra hàm load được gọi
      verify(() => mockDepartmentCubit.loadDepartments()).called(1);
      
      // Kiểm tra Loading Indicator xuất hiện
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    // --- TEST CASE 2: HAPPY PATH (DESKTOP TABLE) ---
    testWidgets('Hiển thị danh sách phòng ban dạng Bảng trên Desktop', (tester) async {
      // 1. Arrange: Giả lập màn hình Desktop (Width > 600)
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      // Data giả
      final departments = [
        Department(id: 1, name: 'IT Dept', description: 'Tech Team'),
        Department(id: 2, name: 'HR Dept', description: 'Human Resource'),
      ];

      when(() => mockDepartmentCubit.state).thenReturn(DepartmentLoaded(departments));
      when(() => mockDepartmentCubit.loadDepartments()).thenAnswer((_) async {});

      // 2. Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(); // Rebuild sau khi state đổi

      // 3. Assert
      expect(find.text('IT Dept'), findsOneWidget); // Tìm thấy tên phòng ban
      expect(find.text('HR Dept'), findsOneWidget);
      expect(find.byType(DataTable), findsOneWidget); // Phải hiển thị Table chứ không phải List
      
      // Reset size về mặc định
      addTearDown(tester.view.resetPhysicalSize);
    });

    // --- TEST CASE 3: INTERACTION (SEARCH) ---
    testWidgets('Nhập text vào ô Search sẽ gọi hàm searchDepartments trong Cubit', (tester) async {
      // 1. Arrange
      when(() => mockDepartmentCubit.state).thenReturn(DepartmentLoaded([]));
      when(() => mockDepartmentCubit.loadDepartments()).thenAnswer((_) async {});
      when(() => mockDepartmentCubit.searchDepartments(any())).thenAnswer((_) async {});

      await tester.pumpWidget(createWidgetUnderTest());

      // 2. Act: Tìm ô search và nhập liệu
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Marketing');
      await tester.testTextInput.receiveAction(TextInputAction.search); // Giả lập bấm Enter trên bàn phím

      // 3. Assert
      verify(() => mockDepartmentCubit.searchDepartments('Marketing')).called(1);
    });

    // --- TEST CASE 4: UI LOGIC (ADD DIALOG) ---
   testWidgets('Bấm nút Add mở ra Dialog nhập liệu', (tester) async {
      // 1. Arrange
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      when(() => mockDepartmentCubit.state).thenReturn(DepartmentLoaded([]));
      when(() => mockDepartmentCubit.loadDepartments()).thenAnswer((_) async {});

      await tester.pumpWidget(createWidgetUnderTest());

      // 2. Act
      final addButton = find.byIcon(Icons.add_circle_outline);
      await tester.tap(addButton);
      await tester.pumpAndSettle(); // Chờ Dialog mở ra hoàn toàn

      // 3. Assert (SỬA LẠI ĐOẠN NÀY)
      
      // Kiểm tra xem có Widget Dialog không
      expect(find.byType(AlertDialog), findsOneWidget); 
      
      // Kiểm tra xem có 2 ô nhập liệu (Tên & Mô tả) không
      expect(find.byType(TextFormField), findsNWidgets(2)); 

      addTearDown(tester.view.resetPhysicalSize);
    });

    // --- TEST CASE 5: ERROR STATE ---
    testWidgets('Hiển thị thông báo lỗi và nút Reload khi có lỗi', (tester) async {
      // 1. Arrange
      when(() => mockDepartmentCubit.state).thenReturn(DepartmentError("Mất kết nối server"));
      when(() => mockDepartmentCubit.loadDepartments()).thenAnswer((_) async {});

      await tester.pumpWidget(createWidgetUnderTest());

      // 3. Assert
      expect(find.text('Mất kết nối server'), findsOneWidget);
      expect(find.text('Reload'), findsOneWidget);
    });
  });
}