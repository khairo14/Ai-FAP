import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fundvanceai/core/config/supabase_config.dart';
import 'package:fundvanceai/core/constants/app_constants.dart';
import 'package:fundvanceai/features/auth/auth_provider.dart';
import 'package:fundvanceai/features/auth/screens/login_screen.dart';
import 'package:fundvanceai/features/auth/screens/signup_screen.dart';
import 'package:fundvanceai/features/expenses/expense_provider.dart';
import 'package:fundvanceai/features/budgets/budget_provider.dart';
import 'package:fundvanceai/features/accounts/account_provider.dart';
import 'package:fundvanceai/features/transfers/transfer_provider.dart';
import 'package:fundvanceai/features/categories/category_provider.dart';
import 'package:fundvanceai/features/home/home_provider.dart';
import 'package:fundvanceai/features/income/income_provider.dart';
import 'package:fundvanceai/features/home/home_screen.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await SupabaseConfig.initialize();
  
  runApp(
    /// Wrap app with providers
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => AccountProvider()),
        ChangeNotifierProvider(create: (_) => TransferProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => IncomeProvider()),
      ],
      child: const FundVanceApp(),
    ),
  );
}

class FundVanceApp extends StatelessWidget {
  const FundVanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4ECDC4),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      // Check auth state and route accordingly
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.isAuthenticated) {
            return const HomePage();
          }
          return const LoginScreen();
        },
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}
