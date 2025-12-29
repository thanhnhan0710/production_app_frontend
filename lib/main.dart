import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:production_app_frontend/features/hr/employee/presentation/screens/employee_screen.dart';
import 'package:production_app_frontend/features/inventory/material/data/material_repository.dart';
import 'package:production_app_frontend/features/inventory/material/presentation/bloc/material_cubit.dart';
import 'package:production_app_frontend/features/inventory/material/presentation/screens/material_screen.dart';
import 'package:production_app_frontend/features/inventory/unit/data/unit_repository.dart';
import 'package:production_app_frontend/features/inventory/unit/presentation/bloc/unit_cubit.dart';
import 'package:production_app_frontend/features/inventory/unit/presentation/screens/unit_screen.dart';
import 'package:production_app_frontend/features/inventory/yarn_lot/presentation/screens/yarn_lot_screen';

// --- CORE & L10N ---
import 'core/bloc/language_cubit.dart';
// Lưu ý: Nếu bạn dùng flutter_gen mặc định thì import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// Nếu bạn cấu hình sinh file vào lib/l10n thì dùng dòng dưới:
import 'l10n/app_localizations.dart'; 

// --- AUTH FEATURE ---
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_cubit.dart';
import 'features/auth/presentation/screens/login_screen.dart';

// --- HOME FEATURE ---
import 'features/home/presentation/screens/dashboard_screen.dart';

// --- HR FEATURE (Department & Employee) ---
import 'features/hr/department/data/department_repository.dart';
import 'features/hr/department/presentation/bloc/department_cubit.dart';
import 'features/hr/department/presentation/screens/department_screen.dart';
import 'features/hr/employee/data/employee_repository.dart';
import 'features/hr/employee/presentation/bloc/employee_cubit.dart';
import 'features/hr/employee/presentation/screens/employee_department_screen.dart';

// --- INVENTORY FEATURE (Supplier, Yarn, Yarn Lot) ---
import 'features/inventory/supplier/data/supplier_repository.dart';
import 'features/inventory/supplier/presentation/bloc/supplier_cubit.dart';
import 'features/inventory/supplier/presentation/screens/supplier_screen.dart';
import 'features/inventory/yarn/data/yarn_repository.dart';
import 'features/inventory/yarn/presentation/bloc/yarn_cubit.dart';
import 'features/inventory/yarn/presentation/screens/yarn_screen.dart';
import 'features/inventory/yarn_lot/data/yarn_lot_repository.dart';
import 'features/inventory/yarn_lot/presentation/bloc/yarn_lot_cubit.dart';


void main() {
  usePathUrlStrategy();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => AuthRepository(),
      child: MultiBlocProvider(
        providers: [
          // 1. Core Providers
          BlocProvider(create: (context) => AuthCubit(context.read<AuthRepository>())),
          BlocProvider(create: (context) => LanguageCubit()),
          
          // 2. HR Providers
          BlocProvider(create: (context) => DepartmentCubit(DepartmentRepository())),
          BlocProvider(create: (context) => EmployeeCubit(EmployeeRepository())),
          
          // 3. Inventory Providers
          BlocProvider(create: (context) => SupplierCubit(SupplierRepository())),
          BlocProvider(create: (context) => YarnCubit(YarnRepository())),
          BlocProvider(create: (context) => YarnLotCubit(YarnLotRepository())),
          BlocProvider(create: (context) => MaterialCubit(MaterialRepository())),
          BlocProvider(create: (context) => UnitCubit(UnitRepository())),
        ],
        child: const AppView(),
      ),
    );
  }
}

class AppView extends StatelessWidget {
  const AppView({super.key});

  @override
  Widget build(BuildContext context) {
    final GoRouter router = GoRouter(
      initialLocation: '/login',
      routes: [
        // --- AUTH ---
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        
        // --- DASHBOARD ---
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        
        // --- HR ROUTES ---
        GoRoute(
          path: '/departments',
          builder: (context, state) => const DepartmentScreen(),
        ),
        GoRoute(
          path: '/employees',
          builder: (context, state) {
             // [MỚI] Hỗ trợ query params: /employees?departmentId=1
             final deptId = state.uri.queryParameters['departmentId'];
             if (deptId != null) {
               return EmployeeDepartmentScreen(departmentId: int.parse(deptId));
             }
             return const EmployeeScreen();
          },
        ),
        GoRoute(
          // Route chi tiết nhân viên theo phòng ban (Kiểu path param)
          path: '/employees/department/:deptId',
          builder: (context, state) {
            final deptId = int.tryParse(state.pathParameters['deptId'] ?? '0') ?? 0;
            return EmployeeDepartmentScreen(departmentId: deptId);
          },
        ),

        // --- INVENTORY ROUTES ---
        GoRoute(
          path: '/suppliers',
          builder: (context, state) => const SupplierScreen(),
        ),
        GoRoute(
          path: '/yarns',
          builder: (context, state) => const YarnScreen(),
        ),
        GoRoute(
          path: '/yarn-lots',
          builder: (context, state) => const YarnLotScreen(),
        ),
        GoRoute(path: '/materials', builder: (context, state) => const MaterialScreen()),
        GoRoute(path: '/units', builder: (context, state) => const UnitScreen()),
      ],
    );

    return BlocBuilder<LanguageCubit, Locale>(
      builder: (context, locale) {
        return MaterialApp.router(
          title: 'Production App',
          debugShowCheckedModeBanner: false,
          
          routerConfig: router,
          locale: locale,
          
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('vi'),
          ],
          
          theme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
            fontFamily: 'Roboto',
            inputDecorationTheme: const InputDecorationTheme(
              filled: true,
              fillColor: Color(0xFFF5F5F5),
            ),
          ),
        );
      },
    );
  }
}