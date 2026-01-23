import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:production_app_frontend/features/inventory/batch/data/batch_repository.dart';
import 'package:production_app_frontend/features/inventory/batch/presentation/bloc/batch_cubit.dart';
import 'package:production_app_frontend/features/inventory/batch/presentation/screens/batch_screen.dart';
import 'package:production_app_frontend/features/inventory/import_declaration/data/import_declaration_repository.dart';
import 'package:production_app_frontend/features/inventory/import_declaration/presentation/bloc/import_declaration_cubit.dart';
import 'package:production_app_frontend/features/inventory/import_declaration/presentation/screens/import_declaration_screen.dart';
import 'package:production_app_frontend/features/inventory/stock_in/presentation/screens/stock_in_screen.dart';
import 'package:production_app_frontend/features/inventory/warehouse/data/warehouse_repository.dart';
import 'package:production_app_frontend/features/inventory/warehouse/presentation/bloc/warehouse_cubit.dart';
import 'package:production_app_frontend/features/inventory/warehouse/presentation/screens/warehouse_screen.dart';
import 'package:production_app_frontend/features/inventory/yarn_lot/presentation/screens/yarn_lot_screen';

// --- CORE & L10N ---
import 'core/bloc/language_cubit.dart';
import 'l10n/app_localizations.dart'; 

// --- AUTH FEATURE ---
import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/user_repository.dart';
import 'features/auth/presentation/bloc/auth_cubit.dart';
import 'features/auth/presentation/bloc/user_cubit.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/user_screen.dart';

// --- HOME FEATURE ---
import 'features/home/presentation/screens/dashboard_screen.dart';

// --- HR FEATURE ---
import 'features/hr/department/data/department_repository.dart';
import 'features/hr/department/presentation/bloc/department_cubit.dart';
import 'features/hr/department/presentation/screens/department_screen.dart';
import 'features/hr/employee/data/employee_repository.dart';
import 'features/hr/employee/presentation/bloc/employee_cubit.dart';
import 'features/hr/employee/presentation/screens/employee_screen.dart';
import 'features/hr/employee/presentation/screens/employee_department_screen.dart';
import 'features/hr/shift/data/shift_repository.dart';
import 'features/hr/shift/presentation/bloc/shift_cubit.dart';
import 'features/hr/shift/presentation/screens/shift_screen.dart';
import 'features/hr/work_schedule/data/work_schedule_repository.dart';
import 'features/hr/work_schedule/presentation/bloc/work_schedule_cubit.dart';
import 'features/hr/work_schedule/presentation/screens/work_schedule_screen.dart';

// --- INVENTORY FEATURE ---
import 'features/inventory/supplier/data/supplier_repository.dart';
import 'features/inventory/supplier/presentation/bloc/supplier_cubit.dart';
import 'features/inventory/supplier/presentation/screens/supplier_screen.dart';
import 'features/inventory/yarn/data/yarn_repository.dart';
import 'features/inventory/yarn/presentation/bloc/yarn_cubit.dart';
import 'features/inventory/yarn/presentation/screens/yarn_screen.dart';
import 'features/inventory/yarn_lot/data/yarn_lot_repository.dart';
import 'features/inventory/yarn_lot/presentation/bloc/yarn_lot_cubit.dart';

import 'features/inventory/material/data/material_repository.dart';
import 'features/inventory/material/presentation/bloc/material_cubit.dart';
import 'features/inventory/material/presentation/screens/material_screen.dart';
import 'features/inventory/unit/data/unit_repository.dart';
import 'features/inventory/unit/presentation/bloc/unit_cubit.dart';
import 'features/inventory/unit/presentation/screens/unit_screen.dart';
import 'features/inventory/basket/data/baket_repository.dart';
import 'features/inventory/basket/presentation/bloc/baket_cubit.dart';
import 'features/inventory/basket/presentation/screens/baket_screen.dart';
import 'features/inventory/dye_color/data/dye_color_repository.dart';
import 'features/inventory/dye_color/presentation/bloc/dye_color_cubit.dart';
import 'features/inventory/dye_color/presentation/screens/dye_color_screen.dart';
import 'features/inventory/product/data/product_repository.dart';
import 'features/inventory/product/presentation/bloc/product_cubit.dart';
import 'features/inventory/product/presentation/screens/product_screen.dart';
import 'features/inventory/bom/data/bom_repository.dart';
import 'features/inventory/bom/presentation/bloc/bom_cubit.dart';
import 'features/inventory/bom/presentation/screens/bom_screen.dart';

// [NEW] Purchase Order Imports
import 'features/inventory/purchase_order/data/purchase_order_repository.dart';
import 'features/inventory/purchase_order/presentation/bloc/purchase_order_cubit.dart';
import 'features/inventory/purchase_order/presentation/screens/purchase_order_screen.dart'; // Đã sửa tên file chính xác

// --- PRODUCTION FEATURE ---
import 'features/production/machine/data/machine_repository.dart';
import 'features/production/machine/presentation/bloc/machine_cubit.dart';
import 'features/production/machine/presentation/bloc/machine_operation_cubit.dart';
import 'features/production/machine/presentation/screens/machine_screen.dart';
import 'features/production/machine/presentation/screens/machine_opperation_screen.dart';
import 'features/production/standard/data/standard_repository.dart';
import 'features/production/standard/presentation/bloc/standard_cubit.dart';
import 'features/production/standard/presentation/screen/standard_screen.dart';
import 'features/production/weaving/data/weaving_repository.dart';
import 'features/production/weaving/presentation/bloc/weaving_cubit.dart';
import 'features/production/weaving/presentation/screens/weaving_screen.dart';
import 'features/production/weaving_daily_production/data/weaving_production_repository.dart';
import 'features/production/weaving_daily_production/presentation/bloc/weaving_production_cubit.dart';
import 'features/production/weaving_daily_production/presentation/screens/weaving_production_screen.dart';

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
          BlocProvider(create: (context) => ShiftCubit(ShiftRepository())),
          BlocProvider(create: (context) => WorkScheduleCubit(WorkScheduleRepository())),
          BlocProvider(create: (context) => UserCubit(UserRepository())),
          
          // 3. Inventory Providers
          BlocProvider(create: (context) => SupplierCubit(SupplierRepository())),
          BlocProvider(create: (context) => YarnCubit(YarnRepository())),
          BlocProvider(create: (context) => YarnLotCubit(YarnLotRepository())),
          BlocProvider(create: (context) => MaterialCubit(MaterialRepository())),
          BlocProvider(create: (context) => UnitCubit(UnitRepository())),
          BlocProvider(create: (context) => BasketCubit(BasketRepository())),
          BlocProvider(create: (context) => DyeColorCubit(DyeColorRepository())),
          BlocProvider(create: (context) => ProductCubit(ProductRepository())),
          BlocProvider(create: (context) => BOMCubit(BOMRepository())),
          BlocProvider(create: (context) => PurchaseOrderCubit(PurchaseOrderRepository())),
          BlocProvider(create: (context) => ImportDeclarationCubit(ImportDeclarationRepository())),
          BlocProvider(create: (context) => WarehouseCubit(WarehouseRepository())),
          BlocProvider(create: (context) => BatchCubit(BatchRepository())),
          
          // 4. Production Providers
          BlocProvider(create: (context) => MachineCubit(MachineRepository())),
          BlocProvider(create: (context) => StandardCubit(StandardRepository())),
          BlocProvider(create: (context) => WeavingCubit(WeavingRepository())),
          BlocProvider(create: (context) => WeavingProductionCubit(WeavingProductionRepository())),
          BlocProvider(
            create: (context) => MachineOperationCubit(
              MachineRepository(),
              WeavingRepository(),
              BasketRepository(),
            ),
          ),
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
        GoRoute(path: '/departments', builder: (context, state) => const DepartmentScreen()),
        GoRoute(
          path: '/employees',
          builder: (context, state) {
             final deptId = state.uri.queryParameters['departmentId'];
             if (deptId != null) {
               return EmployeeDepartmentScreen(departmentId: int.parse(deptId));
             }
             return const EmployeeScreen();
          },
        ),
        GoRoute(
          path: '/employees/department/:deptId',
          builder: (context, state) {
            final deptId = int.tryParse(state.pathParameters['deptId'] ?? '0') ?? 0;
            return EmployeeDepartmentScreen(departmentId: deptId);
          },
        ),
        GoRoute(path: '/schedules', builder: (context, state) => const WorkScheduleScreen()),
        GoRoute(path: '/shifts', builder: (context, state) => const ShiftScreen()),
        GoRoute(path: '/users', builder: (context, state) => const UserScreen()),

        // --- INVENTORY ROUTES ---
        GoRoute(path: '/suppliers', builder: (context, state) => const SupplierScreen()),
        GoRoute(path: '/yarns', builder: (context, state) => const YarnScreen()),
        GoRoute(path: '/yarn-lots', builder: (context, state) => const YarnLotScreen()),
        GoRoute(path: '/materials', builder: (context, state) => const MaterialScreen()),
        GoRoute(path: '/units', builder: (context, state) => const UnitScreen()),
        GoRoute(path: '/baskets', builder: (context, state) => const BasketScreen()),
        GoRoute(path: '/dye-colors', builder: (context, state) => const DyeColorScreen()),
        GoRoute(path: '/products', builder: (context, state) => const ProductScreen()),
        GoRoute(path: '/boms', builder: (context, state) => const BOMScreen()),
        GoRoute(path: '/import-declarations', builder: (context, state) => const ImportDeclarationScreen()),
        GoRoute(path: '/warehouses', builder: (context, state) => const WarehouseScreen()),
        GoRoute(path: '/stock-in', builder: (context, state) => const StockInScreen()),
        GoRoute(path: '/batches', builder: (context, state) => const BatchScreen()),
        
        
        // [NEW] Purchase Order Route
        GoRoute(path: '/purchase-orders', builder: (context, state) => const PurchaseOrderScreen()),

        // --- PRODUCTION ROUTES ---
        GoRoute(path: '/machines', builder: (context, state) => const MachineScreen()),
        GoRoute(path: '/standards', builder: (context, state) => const StandardScreen()),
        GoRoute(path: '/machine-operation',builder: (context, state) => const MachineOperationScreen()),
        GoRoute(path: '/weaving', builder: (context, state) => const WeavingScreen()),
        GoRoute(path: '/weaving-productions', builder: (context, state) => const WeavingProductionScreen()),
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