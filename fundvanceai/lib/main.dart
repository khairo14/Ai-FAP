import 'package:flutter/foundation.dart';
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
import 'package:fundvanceai/features/notifications/notification_provider.dart';
import 'package:fundvanceai/features/goals/goal_provider.dart';
import 'package:fundvanceai/features/debts/debt_provider.dart';
import 'package:fundvanceai/features/premium/premium_provider.dart';
import 'package:fundvanceai/features/settings/theme_provider.dart';
import 'package:fundvanceai/features/settings/settings_provider.dart';
import 'package:fundvanceai/shared/services/local_notification_service.dart';
import 'package:fundvanceai/shared/services/recurring_scheduler_service.dart';
import 'package:fundvanceai/shared/widgets/biometric_gate.dart';
import 'package:fundvanceai/features/home/home_screen.dart';
import 'package:fundvanceai/features/onboarding/onboarding_screen.dart';

import 'package:fundvanceai/shared/services/notification_service.dart';
import 'package:fundvanceai/shared/services/premium_service.dart';
import 'package:fundvanceai/shared/services/connectivity_service.dart';
import 'package:fundvanceai/features/connectivity/connectivity_provider.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseConfig.initialize();

  // Initialize local notifications (mobile/desktop only)
  if (!kIsWeb) {
    await NotificationService.init();
    await NotificationService.scheduleWeeklySummary();
  }

  // Initialize RevenueCat native SDK (mobile only; web/desktop use RC REST API)
  if (!PremiumProvider.useRCWeb) {
    await PremiumService.configure();
    // If the user is already logged in (app restart), tie RevenueCat to their
    // Supabase UID immediately — before PremiumProvider.initialize() runs.
    // Without this, getCustomerInfo() would return the anonymous RC user
    // (no subscription) and only fix itself when the auth stream fires later.
    final existingUser = SupabaseConfig.client.auth.currentUser;
    if (existingUser != null) {
      await PremiumService.logIn(existingUser.id);
    }
  }

  // Initialize connectivity monitoring
  await ConnectivityService.instance.initialize();

  // Load persisted theme (before first frame)
  final themeProvider = ThemeProvider();
  await themeProvider.load();

  // Load persisted settings
  final settingsProvider = SettingsProvider();
  await settingsProvider.load();

  // Initialize local notification scheduler
  await LocalNotificationService.instance.initialize();

  // Run daily recurring scheduler (auto-creates entries, sends reminders)
  await RecurringSchedulerService.runIfNeeded();

  // Read onboarding completion flag
  final onboardingDone = await OnboardingScreen.isComplete();

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
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => GoalProvider()),
        ChangeNotifierProvider(create: (_) => DebtProvider()),
        ChangeNotifierProvider(create: (_) => PremiumProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: settingsProvider),
      ],
      child: FundVanceApp(onboardingDone: onboardingDone),
    ),
  );
}

class FundVanceApp extends StatelessWidget {
  final bool onboardingDone;
  const FundVanceApp({super.key, required this.onboardingDone});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: themeProvider.themeData,
      // ThemeMode.light ensures the user-selected theme is always applied
      // regardless of the device's system dark/light mode setting.
      themeMode: ThemeMode.light,
      // Show onboarding on first launch; then check auth
      home: BiometricGate(
        child: onboardingDone
            ? Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  if (authProvider.isAuthenticated) {
                    return const HomePage();
                  }
                  return const LoginScreen();
                },
              )
            : const OnboardingScreen(),
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const HomePage(),
        '/onboarding': (context) => const OnboardingScreen(),
        // RC Web Billing checkout redirect landing routes.
        '/premium/success': (context) => const HomePage(),
        '/premium/cancel': (context) => const HomePage(),
      },
      // Catch-all: RC/Stripe may append query params or modify the redirect
      // URL in ways the router doesn't recognise. Always fall back to home.
      onUnknownRoute: (settings) => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const HomePage(),
      ),
    );
  }
}
