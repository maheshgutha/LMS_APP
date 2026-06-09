import 'package:flutter/material.dart';
import '../admin/admin_users_screen.dart';
import '../admin/admin_screens.dart';
import '../shared/more_menu_screen.dart';

class ManagerShell extends StatefulWidget {
  const ManagerShell({super.key});

  @override
  State<ManagerShell> createState() => _ManagerShellState();
}

class _ManagerShellState extends State<ManagerShell> {
  int _idx = 0;

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return const AdminUsersScreen();
      case 1:
        return const AdminEnrollmentsScreen();
      case 2:
        return const AdminScoresScreen();
      case 3:
        return const AdminLeaderboardScreen();
      case 4:
        return AdminMoreMenu(isAdmin: false, onNavigate: _nav);
      default:
        return const AdminUsersScreen();
    }
  }

  void _nav(Widget w) => Navigator.push(context, MaterialPageRoute(builder: (_) => w));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildScreen(_idx),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.people_outlined), activeIcon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.school_outlined), activeIcon: Icon(Icons.school), label: 'Enrollments'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart), label: 'Scores'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events_outlined), activeIcon: Icon(Icons.emoji_events), label: 'Leaders'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), activeIcon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}
