import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_provider.dart';
import 'utils/theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/manager/manager_shell.dart';
import 'screens/instructor/instructor_screens.dart';
import 'screens/student/student_screens.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const AotmsLmsApp(),
    ),
  );
}

class AotmsLmsApp extends StatelessWidget {
  const AotmsLmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AOTMS LMS',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().tryAutoLogin();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!auth.isLoggedIn) {
          return const LoginScreen();
        }

        final role = auth.user?.role?.toLowerCase() ?? '';

        if (role == 'admin' || role == 'super admin') {
          return const AdminShell();
        } else if (role == 'manager') {
          return const ManagerShell();
        } else if (role == 'instructor') {
          return const InstructorShell();
        } else {
          // student or intern
          return const StudentShell();
        }
      },
    );
  }
}
