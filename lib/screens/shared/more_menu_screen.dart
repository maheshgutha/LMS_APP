import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../admin/admin_screens.dart';
import '../shared/profile_screen.dart';
import '../manager/submission_grading_screen.dart';

class AdminMoreMenu extends StatelessWidget {
  final bool isAdmin;
  final Function(Widget) onNavigate;

  const AdminMoreMenu({super.key, required this.isAdmin, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final items = _buildItems(context);
    return Scaffold(
      appBar: AppBar(title: Text(isAdmin ? 'Admin Menu' : 'Manager Menu')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          final item = items[i];
          if (item == null) return const SizedBox(height: 8);
          return ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (item['color'] as Color).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 20),
            ),
            title: Text(item['label'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: item['subtitle'] != null
                ? Text(item['subtitle'] as String, style: const TextStyle(fontSize: 12))
                : null,
            trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            onTap: () => onNavigate(item['screen'] as Widget),
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>?> _buildItems(BuildContext context) {
    final adminItems = <Map<String, dynamic>?>[
      {
        'label': 'Resume Scans',
        'subtitle': 'ATS scan history',
        'icon': Icons.description_outlined,
        'color': Colors.orange,
        'screen': const AdminResumeScansScreen(),
      },
      {
        'label': 'Instructors List',
        'subtitle': 'Manage instructors',
        'icon': Icons.people_outlined,
        'color': Colors.blue,
        'screen': const AdminInstructorsScreen(),
      },
      {
        'label': 'All Courses',
        'subtitle': 'Course catalog',
        'icon': Icons.book_outlined,
        'color': Colors.purple,
        'screen': const AdminCoursesScreen(),
      },
      {
        'label': 'Chat Monitoring',
        'subtitle': 'Monitor conversations',
        'icon': Icons.chat_outlined,
        'color': Colors.teal,
        'screen': const AdminChatMonitorScreen(),
      },
      {
        'label': 'Live Monitoring',
        'subtitle': 'Platform overview',
        'icon': Icons.monitor_heart_outlined,
        'color': Colors.red,
        'screen': const AdminLiveMonitoringScreen(),
      },
      {
        'label': 'Quality Assurance',
        'subtitle': 'Ratings & feedback',
        'icon': Icons.verified_outlined,
        'color': Colors.green,
        'screen': const AdminQaScreen(),
      },
      {
        'label': 'Notifications',
        'subtitle': 'System notifications',
        'icon': Icons.notifications_outlined,
        'color': AppTheme.primary,
        'screen': const AdminNotificationsScreen(),
      },
      if (!isAdmin) ...[
        {
          'label': 'Submission Grading',
          'subtitle': 'Grade student submissions',
          'icon': Icons.grading_outlined,
          'color': Colors.indigo,
          'screen': const SubmissionGradingScreen(),
        },
      ],
      null, // divider
      {
        'label': 'My Profile',
        'subtitle': 'View and edit profile',
        'icon': Icons.person_outlined,
        'color': AppTheme.primary,
        'screen': const ProfileScreen(),
      },
    ];
    return adminItems;
  }
}
