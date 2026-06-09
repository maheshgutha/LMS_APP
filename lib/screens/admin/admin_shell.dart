import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import 'admin_users_screen.dart';
import 'admin_enrollments_screen.dart';
import 'admin_scores_screen.dart';
import 'admin_leaderboard_screen.dart';
import 'admin_resume_scans_screen.dart';
import 'admin_instructors_screen.dart';
import 'admin_courses_screen.dart';
import 'admin_chat_monitor_screen.dart';
import 'admin_live_monitoring_screen.dart';
import 'admin_qa_screen.dart';
import 'admin_notifications_screen.dart';
import '../shared/profile_screen.dart';
import '../shared/more_menu_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _idx = 0;

  final List<_NavItem> _navItems = [
    _NavItem(icon: Icons.people_outlined, activeIcon: Icons.people, label: 'Users'),
    _NavItem(icon: Icons.school_outlined, activeIcon: Icons.school, label: 'Enrollments'),
    _NavItem(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, label: 'Scores'),
    _NavItem(icon: Icons.emoji_events_outlined, activeIcon: Icons.emoji_events, label: 'Leaderboard'),
    _NavItem(icon: Icons.more_horiz, activeIcon: Icons.more_horiz, label: 'More'),
  ];

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
        return AdminMoreMenu(isAdmin: true, onNavigate: _navigateTo);
      default:
        return const AdminUsersScreen();
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildScreen(_idx),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
        items: _navItems
            .map((n) => BottomNavigationBarItem(
                  icon: Icon(n.icon),
                  activeIcon: Icon(n.activeIcon),
                  label: n.label,
                ))
            .toList(),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  _NavItem({required this.icon, required this.activeIcon, required this.label});
}
