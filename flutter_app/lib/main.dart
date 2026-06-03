// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/case_provider.dart';
import 'screens/login_screen.dart';
import 'screens/patient_home_screen.dart';
import 'screens/doctor_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MedAIApp());
}

class MedAIApp extends StatelessWidget {
  const MedAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => CaseProvider()),
      ],
      child: MaterialApp(
        title: 'MedAI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const _AppRouter(),
      ),
    );
  }
}

/// Routes to the correct screen based on auth state + role.
class _AppRouter extends StatelessWidget {
  const _AppRouter();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        switch (auth.status) {
          case AuthStatus.unknown:
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          case AuthStatus.unauthenticated:
            return const LoginScreen();
          case AuthStatus.authenticated:
            final user = auth.user!;
            if (user.isDoctor) return const DoctorDashboardScreen();
            return const PatientHomeScreen();
        }
      },
    );
  }
}
