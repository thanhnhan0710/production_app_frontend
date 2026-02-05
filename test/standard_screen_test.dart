import 'package:bloc_test/bloc_test.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mocktail_image_network/mocktail_image_network.dart';
import 'package:production_app_frontend/features/inventory/product/presentation/bloc/product_cubit.dart';
import 'package:production_app_frontend/features/inventory/product/domain/product_model.dart';
import 'package:production_app_frontend/features/inventory/dye_color/presentation/bloc/dye_color_cubit.dart';
import 'package:production_app_frontend/features/inventory/dye_color/domain/dye_color_model.dart';
import 'package:production_app_frontend/features/production/standard/domain/standard_model.dart';
import 'package:production_app_frontend/features/production/standard/presentation/bloc/standard_cubit.dart';
import 'package:production_app_frontend/features/production/standard/presentation/screen/standard_screen.dart';
import 'package:production_app_frontend/l10n/app_localizations.dart';

// --- 1. MOCK CLASSES ---
class MockStandardCubit extends MockCubit<StandardState> implements StandardCubit {}
class MockProductCubit extends MockCubit<ProductState> implements ProductCubit {}
class MockDyeColorCubit extends MockCubit<DyeColorState> implements DyeColorCubit {}

// Fake classes để Mocktail hiểu được kiểu dữ liệu
class FakeStandard extends Fake implements Standard {}

void main() {
  late MockStandardCubit mockStandardCubit;
  late MockProductCubit mockProductCubit;
  late MockDyeColorCubit mockDyeColorCubit;

  // Data giả lập
  final mockStandards = [
    Standard(
      id: 1,
      productId: 101,
      productItemCode: "PROD-001",
      productName: "Belt A",
      productImage: "http://example.com/img.jpg",
      dyeColorId: 201,
      colorName: "Red",
      colorHex: "#FF0000",
      deltaE: "0.5",
      widthMm: "50",
      thicknessMm: "2.0",
      weightGm: "100",
      breakingStrength: "5000",
      elongation: "15",
      weftDensity: "20",
      colorFastnessDry: "4-5",
      colorFastnessWet: "4",
      appearance: "Good",
      note: "Standard note",
    )
  ];

  final mockProducts = [
    Product(id: 101, itemCode: "PROD-001", note: '', imageUrl: '' ),
    Product(id: 102, itemCode: "PROD-002", note: '', imageUrl: ''),
  ];

  final mockColors = [
    DyeColor(id: 201, name: "Red", hexCode: "#FF0000", note: ''),
    DyeColor(id: 202, name: "Blue", hexCode: "#0000FF", note: ''),
  ];

  setUpAll(() {
    registerFallbackValue(FakeStandard());
  });

  setUp(() {
    mockStandardCubit = MockStandardCubit();
    mockProductCubit = MockProductCubit();
    mockDyeColorCubit = MockDyeColorCubit();

    // Setup default states (Happy path)
    when(() => mockStandardCubit.state).thenReturn(StandardLoaded(mockStandards));
    when(() => mockProductCubit.state).thenReturn(ProductLoaded(mockProducts));
    when(() => mockDyeColorCubit.state).thenReturn(DyeColorLoaded(mockColors));

    // Stub void methods
    when(() => mockStandardCubit.loadStandards()).thenAnswer((_) async {});
    when(() => mockProductCubit.loadProducts()).thenAnswer((_) async {});
    when(() => mockDyeColorCubit.loadColors()).thenAnswer((_) async {});
    when(() => mockStandardCubit.saveStandard(standard: any(named: 'standard'), isEdit: any(named: 'isEdit'))).thenAnswer((_) async {});
    when(() => mockStandardCubit.deleteStandard(any())).thenAnswer((_) async {});
    when(() => mockStandardCubit.searchStandards(any())).thenAnswer((_) async {});
  });

  Widget createWidgetUnderTest() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<StandardCubit>.value(value: mockStandardCubit),
        BlocProvider<ProductCubit>.value(value: mockProductCubit),
        BlocProvider<DyeColorCubit>.value(value: mockDyeColorCubit),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('en'),
        home: StandardScreen(),
      ),
    );
  }

  group('StandardScreen Tests', () {
    
    // --- TEST 1: INITIALIZATION ---
    testWidgets('Gọi load data cho cả 3 Cubit khi màn hình mở', (tester) async {
      await mockNetworkImages(() async {
        await tester.pumpWidget(createWidgetUnderTest());
      });

      verify(() => mockStandardCubit.loadStandards()).called(1);
      verify(() => mockProductCubit.loadProducts()).called(1);
      verify(() => mockDyeColorCubit.loadColors()).called(1);
    });

    // --- TEST 2: DESKTOP VIEW (TABLE) ---
    testWidgets('Hiển thị DataTable trên màn hình Desktop', (tester) async {
      // Set size Desktop
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;

      await mockNetworkImages(() async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();
      });

      // Kiểm tra các thành phần của bảng
      expect(find.byType(DataTable), findsOneWidget);
      expect(find.text('PROD-001'), findsOneWidget);
      expect(find.text('Red'), findsOneWidget);
      expect(find.text('50 mm'), findsOneWidget); // width
      
      // Kiểm tra logic hiển thị màu Hex
      // Tìm Container có decoration là box shape circle
      final colorBox = find.byWidgetPredicate((widget) => 
        widget is Container && 
        widget.decoration is BoxDecoration && 
        (widget.decoration as BoxDecoration).shape == BoxShape.circle &&
        (widget.decoration as BoxDecoration).color == const Color(0xFFFF0000) // Red Hex
      );
      expect(colorBox, findsWidgets);

      addTearDown(tester.view.resetPhysicalSize);
    });

    // --- TEST 3: MOBILE VIEW (LIST) ---
    testWidgets('Hiển thị ListView trên màn hình Mobile', (tester) async {
      // Set size Mobile
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      await mockNetworkImages(() async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();
      });

      expect(find.byType(DataTable), findsNothing);
      expect(find.byType(ListView), findsOneWidget);
      
      // [FIX] Sử dụng Finder tùy chỉnh (Predicate) để tìm trong RichText
      // Cách này lấy toàn bộ text thô (Vd: "W: 50mm") ra để so sánh
      final richTextFinder = find.byWidgetPredicate((widget) {
        if (widget is RichText) {
          final String plainText = widget.text.toPlainText();
          // Kiểm tra xem text có chứa "W: " hay không
          return plainText.contains('W: '); 
        }
        return false;
      });

      // Kiểm tra xem có tìm thấy ít nhất 1 widget thỏa mãn không
      expect(richTextFinder, findsWidgets);  

      // Kiểm tra thêm một thông số khác cho chắc ăn
      final densFinder = find.byWidgetPredicate((widget) {
        if (widget is RichText) {
          return widget.text.toPlainText().contains('Dens:'); 
        }
        return false;
      });
      expect(densFinder, findsWidgets);

      addTearDown(tester.view.resetPhysicalSize);
    });

    // --- TEST 4: SEARCH ---
    testWidgets('Nhập text search kích hoạt hàm searchStandards', (tester) async {
      await mockNetworkImages(() async => await tester.pumpWidget(createWidgetUnderTest()));

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'PROD');
      await tester.testTextInput.receiveAction(TextInputAction.search);

      verify(() => mockStandardCubit.searchStandards('PROD')).called(1);
    });

    // --- TEST 5: ADD DIALOG & VALIDATION ---
    testWidgets('Mở Dialog Thêm mới, nhập liệu và lưu', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;

      await mockNetworkImages(() async => await tester.pumpWidget(createWidgetUnderTest()));

      // 1. Mở Dialog
      await tester.tap(find.text('ADD STANDARD')); // Desktop button label
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('General Info'), findsOneWidget);

      // 2. Nhập liệu các trường Text
      await tester.enterText(find.widgetWithText(TextFormField, 'Width (mm)'), '60');
      await tester.enterText(find.widgetWithText(TextFormField, 'Thickness (mm)'), '3.0');
      // ... nhập thêm các trường khác nếu cần kiểm tra kỹ

      // 3. Chọn Dropdown Product (DropdownSearch)
      // DropdownSearch khá phức tạp để test interaction, ta thường tìm widget đó và tap
      final productDropdown = find.byType(DropdownSearch<Product>);
      expect(productDropdown, findsOneWidget);
      // Giả lập chọn giá trị bằng cách set trực tiếp vào state nếu UI test quá khó
      // Hoặc tap vào dropdown -> tap vào item 'Belt A'
      await tester.tap(productDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('PROD-001').last); // Chọn item trong popup
      await tester.pumpAndSettle();

      // 4. Bấm Save
      await tester.tap(find.text('Save'));
      await tester.pump();

      // 5. Verify Cubit save được gọi
      verify(() => mockStandardCubit.saveStandard(
        standard: any(named: 'standard'), 
        isEdit: false
      )).called(1);

      addTearDown(tester.view.resetPhysicalSize);
    });

    // --- TEST 6: DELETE FLOW ---
    testWidgets('Xóa Standard hiển thị Confirm Dialog và gọi delete', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;

      await mockNetworkImages(() async => await tester.pumpWidget(createWidgetUnderTest()));

      // Tìm nút xóa (thùng rác)
      final deleteButton = find.byIcon(Icons.delete_outline).first;
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      // Kiểm tra Dialog confirm
      expect(find.textContaining('Delete standard'), findsOneWidget);

      // Bấm Confirm (nút Delete màu đỏ trong dialog)
      // Tìm nút ElevatedButton có chứa text 'Delete Standard' (hoặc key l10n tương ứng)
      final confirmButton = find.widgetWithText(ElevatedButton, 'Delete Standard'); 
      await tester.tap(confirmButton);
      
      verify(() => mockStandardCubit.deleteStandard(1)).called(1);

      addTearDown(tester.view.resetPhysicalSize);
    });

    // --- TEST 7: ERROR SNACKBAR ---
    testWidgets('Hiển thị SnackBar khi có lỗi', (tester) async {
      // Arrange
      whenListen(
        mockStandardCubit,
        Stream.fromIterable([StandardError("Network failed")]),
        initialState: StandardInitial(),
      );

      await mockNetworkImages(() async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump(); // Trigger listener
        await tester.pump(); // Animation SnackBar
      });

      expect(find.text("Network failed"), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}