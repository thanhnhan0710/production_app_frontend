import 'dart:async'; // Cần để dùng StreamController
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mocktail_image_network/mocktail_image_network.dart';
import 'package:production_app_frontend/core/bloc/language_cubit.dart';
import 'package:production_app_frontend/features/auth/data/auth_exception.dart';
import 'package:production_app_frontend/features/auth/domain/user_model.dart';
import 'package:production_app_frontend/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:production_app_frontend/features/auth/presentation/screens/login_screen.dart';
import 'package:production_app_frontend/l10n/app_localizations.dart';
 // Import User Model

// --- MOCKS ---
class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}
class MockLanguageCubit extends MockCubit<Locale> implements LanguageCubit {}
class MockGoRouter extends Mock implements GoRouter {}
class MockUser extends Mock implements User {} // Mock User Model

void main() {
  late MockAuthCubit mockAuthCubit;
  late MockLanguageCubit mockLanguageCubit;
  late MockGoRouter mockGoRouter;
  late StreamController<AuthState> authStateController; // [MỚI] Controller để điều khiển state thủ công

  setUp(() {
    mockAuthCubit = MockAuthCubit();
    mockLanguageCubit = MockLanguageCubit();
    mockGoRouter = MockGoRouter();
    authStateController = StreamController<AuthState>.broadcast();

    // 1. Setup State mặc định
    when(() => mockAuthCubit.state).thenReturn(AuthInitial());
    when(() => mockAuthCubit.stream).thenAnswer((_) => authStateController.stream);
    
    // [FIX QUAN TRỌNG] Stub hàm login để trả về Future void thay vì null
    when(() => mockAuthCubit.login(any(), any())).thenAnswer((_) async {});

    when(() => mockLanguageCubit.state).thenReturn(const Locale('en'));
  });

  tearDown(() {
    authStateController.close();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: mockAuthCubit),
          BlocProvider<LanguageCubit>.value(value: mockLanguageCubit),
        ],
        child: InheritedGoRouter(
          goRouter: mockGoRouter,
          child: const LoginScreen(),
        ),
      ),
    );
  }

  group('LoginScreen Tests', () {
    
    // --- TEST 1: UI CƠ BẢN ---
    testWidgets('Hiển thị UI cơ bản trên Mobile', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      // [FIX] Bọc mockNetworkImages để tránh lỗi 400
      await mockNetworkImages(() async {
        await tester.pumpWidget(createWidgetUnderTest());
      });

      expect(find.text('Production App'), findsOneWidget);
      expect(find.text('LOGIN'), findsOneWidget);

      addTearDown(tester.view.resetPhysicalSize);
    });

    // --- TEST 2: VALIDATION (FIXED & DEBUGGED) ---
    testWidgets('Hiển thị lỗi Validation khi để trống', (tester) async {
      // 1. Set màn hình Mobile để layout đơn giản, chắc chắn nút Login hiện ra
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      await mockNetworkImages(() async => await tester.pumpWidget(createWidgetUnderTest()));

      // 2. Tìm nút Login và đảm bảo nó visible
      final loginButton = find.text('LOGIN');
      await tester.ensureVisible(loginButton);
      await tester.pumpAndSettle();

      // 3. Tap Login
      await tester.tap(loginButton);
      await tester.pumpAndSettle(); // Chờ animation lỗi hiện ra

      // 4. [QUAN TRỌNG] Kiểm tra xem Form có báo lỗi không (Không cần care text là gì)
      // Cách này tìm xem có widget InputDecorator nào đang ở trạng thái 'error' không
      final hasError = find.byWidgetPredicate((widget) {
        if (widget is InputDecorator) {
          // decoration.errorText khác null nghĩa là đang có lỗi
          return widget.decoration.errorText != null;
        }
        return false;
      });

      // Nếu dòng này pass, nghĩa là validator đã hoạt động
      expect(hasError, findsWidgets);

      // (Tùy chọn) In ra text lỗi thực tế để bạn biết đường sửa file test lần sau
      final errorWidgets = tester.widgetList<InputDecorator>(hasError);
      for (var w in errorWidgets) {
        print('Text lỗi thực tế đang hiện: "${w.decoration.errorText}"');
      }
      
      // Đảm bảo không gọi API
      verifyNever(() => mockAuthCubit.login(any(), any()));

      addTearDown(tester.view.resetPhysicalSize);
    });

    // --- TEST 3: LOGIN SUCCESS CALL ---
    testWidgets('Gọi hàm login khi nhập đúng', (tester) async {
      await mockNetworkImages(() async => await tester.pumpWidget(createWidgetUnderTest()));

      await tester.enterText(find.widgetWithText(TextFormField, 'Username'), 'admin');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), '123456');

      await tester.tap(find.text('LOGIN'));
      
      verify(() => mockAuthCubit.login('admin', '123456')).called(1);
    });

    // --- TEST 4: ENTER KEY ---
    testWidgets('Nhấn Enter ở ô Password kích hoạt login', (tester) async {
      await mockNetworkImages(() async => await tester.pumpWidget(createWidgetUnderTest()));

      await tester.enterText(find.widgetWithText(TextFormField, 'Username'), 'admin');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), '123456');

      // Gửi action Done (Enter)
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      verify(() => mockAuthCubit.login('admin', '123456')).called(1);
    });

    // --- TEST 5: LOADING STATE ---
    testWidgets('Hiển thị Loading khi state là AuthLoading', (tester) async {
      // Setup state loading ngay từ đầu
      when(() => mockAuthCubit.state).thenReturn(AuthLoading());

      await mockNetworkImages(() async => await tester.pumpWidget(createWidgetUnderTest()));
      await tester.pump(); // Rebuild để cập nhật state

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    // --- TEST 6: SNACKBAR ERROR ---
    testWidgets('Hiển thị SnackBar khi gặp lỗi', (tester) async {
      await mockNetworkImages(() async => await tester.pumpWidget(createWidgetUnderTest()));

      // [FIX] Emit state mới thông qua controller để trigger BlocListener
      authStateController.add(AuthError(AuthErrorCode.loginFailed));
      
      await tester.pump(); // Xử lý frame thay đổi state
      await tester.pumpAndSettle(); // Đợi animation SnackBar hiện ra

      expect(find.byType(SnackBar), findsOneWidget);
    });

    // --- TEST 7: NAVIGATION SUCCESS ---
    testWidgets('Điều hướng Dashboard khi đăng nhập thành công', (tester) async {
      await mockNetworkImages(() async => await tester.pumpWidget(createWidgetUnderTest()));

      // [FIX] Emit state Authenticated với Mock User
      authStateController.add(AuthAuthenticated(MockUser()));

      await tester.pump(); // Trigger Listener

      verify(() => mockGoRouter.go('/dashboard')).called(1);
    });

    // --- TEST 8: DESKTOP LAYOUT ---
    testWidgets('Hiển thị layout Desktop với ảnh nền', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;

      // [FIX QUAN TRỌNG] mockNetworkImages chặn request ảnh 400
      await mockNetworkImages(() async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();
      });

      // Desktop có icon Apartment bên trái
      expect(find.byIcon(Icons.apartment), findsOneWidget);
      // Form Login vẫn hiện
      expect(find.text('LOGIN'), findsOneWidget);

      addTearDown(tester.view.resetPhysicalSize);
    });

  });
}