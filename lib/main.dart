import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:production_app_frontend/features/inventory/supplier/presentation/screens/supplier_screen.dart';

import 'core/bloc/language_cubit.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_cubit.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/home/presentation/screens/dashboard_screen.dart';

// [IMPORT MỚI] Import các file Department
import 'features/hr/department/data/department_repository.dart';
import 'features/hr/department/presentation/bloc/department_cubit.dart';
import 'features/hr/department/presentation/screens/department_screen.dart';
import 'features/hr/employee/data/employee_repository.dart';
import 'features/hr/employee/presentation/bloc/employee_cubit.dart';
import 'features/hr/employee/presentation/screens/employee_creen.dart';
import 'features/inventory/supplier/data/supplier_repository.dart';
import 'features/inventory/supplier/presentation/bloc/supplier_cubit.dart';
import 'l10n/app_localizations.dart';

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
          BlocProvider(create: (context) => AuthCubit(context.read<AuthRepository>())),
          BlocProvider(create: (context) => LanguageCubit()),
          // [PROVIDER MỚI] Đăng ký DepartmentCubit
          BlocProvider(create: (context) => DepartmentCubit(DepartmentRepository())),
          BlocProvider(create: (context) => EmployeeCubit(EmployeeRepository())),
          BlocProvider(create: (context) => SupplierCubit(SupplierRepository())),
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
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        // [ROUTE MỚI] Đăng ký đường dẫn cho trang Department
        GoRoute(
          path: '/departments',
          builder: (context, state) => const DepartmentScreen(),
        ),
        GoRoute(
          path: '/employees',
          builder: (context, state) => const EmployeeScreen(),
        ),
        GoRoute(
          path: '/suppliers',
          builder: (context, state) => const SupplierScreen(),
        ),
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