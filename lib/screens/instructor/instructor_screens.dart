import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';
import '../../widgets/common_widgets.dart';
import '../shared/profile_screen.dart';
import '../shared/chat_screen.dart';
import '../shared/notifications_screen.dart';

// ──────────────────────────────────────────────────────────────
// INSTRUCTOR SHELL
// ──────────────────────────────────────────────────────────────
class InstructorShell extends StatefulWidget {
  const InstructorShell({super.key});

  @override
  State<InstructorShell> createState() => _InstructorShellState();
}

class _InstructorShellState extends State<InstructorShell> {
  int _idx = 0;

  Widget _screen(int i) {
    switch (i) {
      case 0: return const InstructorDashboard();
      case 1: return const InstructorCoursesScreen();
      case 2: return const InstructorStudentsScreen();
      case 3: return const InstructorLiveScreen();
      case 4: return const InstructorMoreMenu();
      default: return const InstructorDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screen(_idx),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.book_outlined), activeIcon: Icon(Icons.book), label: 'My Courses'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outlined), activeIcon: Icon(Icons.people), label: 'Students'),
          BottomNavigationBarItem(icon: Icon(Icons.live_tv_outlined), activeIcon: Icon(Icons.live_tv), label: 'Live'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), activeIcon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// INSTRUCTOR DASHBOARD
// ──────────────────────────────────────────────────────────────
class InstructorDashboard extends StatefulWidget {
  const InstructorDashboard({super.key});
  @override
  State<InstructorDashboard> createState() => _InstructorDashboardState();
}

class _InstructorDashboardState extends State<InstructorDashboard> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final courses = await ApiService.get('/instructor/courses');
      final courseList = courses is List ? courses : (courses['courses'] ?? []);
      setState(() {
        _stats = {
          'courses': courseList.length,
          'students': courseList.fold(0, (sum, c) => sum + ((c['enrollment_count'] ?? 0) as num)),
        };
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Instructor Dashboard')),
      body: _loading
          ? const LoadingWidget()
          : RefreshIndicator(
              onRefresh: _fetch,
              child: ListView(padding: const EdgeInsets.all(16), children: [
                const SectionHeader(title: 'Overview'),
                GridView.count(
                  crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10,
                  childAspectRatio: 1.4, shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    StatCard(title: 'My Courses', value: '${_stats?['courses'] ?? 0}', icon: Icons.book_outlined),
                    StatCard(title: 'Total Students', value: '${_stats?['students'] ?? 0}',
                        icon: Icons.people_outlined, color: AppTheme.secondary),
                  ],
                ),
                const SizedBox(height: 16),
                const SectionHeader(title: 'Quick Actions'),
                _QuickActionCard(
                  icon: Icons.add_circle_outline,
                  title: 'Create Live Session',
                  subtitle: 'Start a Zoom meeting',
                  color: Colors.blue,
                  onTap: () {},
                ),
                _QuickActionCard(
                  icon: Icons.quiz_outlined,
                  title: 'Add Questions',
                  subtitle: 'Build question bank',
                  color: Colors.purple,
                  onTap: () {},
                ),
              ]),
            ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({required this.icon, required this.title, required this.subtitle,
    required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ])),
        const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
      ]),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// INSTRUCTOR COURSES
// ──────────────────────────────────────────────────────────────
class InstructorCoursesScreen extends StatefulWidget {
  const InstructorCoursesScreen({super.key});
  @override
  State<InstructorCoursesScreen> createState() => _InstructorCoursesScreenState();
}

class _InstructorCoursesScreenState extends State<InstructorCoursesScreen> {
  List<dynamic> _courses = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.get('/instructor/courses');
      final list = res is List ? res : (res['courses'] ?? res['data'] ?? []);
      setState(() { _courses = list; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Courses'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch),
      ]),
      body: _loading
          ? const LoadingWidget()
          : _error != null
              ? ErrorWidget2(message: _error!, onRetry: _fetch)
              : _courses.isEmpty
                  ? const EmptyState(title: 'No courses assigned', icon: Icons.book_outlined)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _courses.length,
                      itemBuilder: (_, i) {
                        final c = _courses[i];
                        final title = c['title'] ?? 'Untitled';
                        final students = c['enrollment_count'] ?? 0;
                        final isActive = c['is_active'] ?? false;
                        return AppCard(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => InstructorCourseDetailScreen(course: c)),
                          ),
                          child: Row(children: [
                            Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.book_outlined, color: AppTheme.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(title, style: const TextStyle(fontWeight: FontWeight.w600),
                                  maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Row(children: [
                                Icon(Icons.people_outline, size: 13, color: AppTheme.textSecondary),
                                const SizedBox(width: 3),
                                Text('$students students', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                              ]),
                            ])),
                            Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(
                                color: isActive ? AppTheme.success : AppTheme.error,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ]),
                        );
                      },
                    ),
    );
  }
}

class InstructorCourseDetailScreen extends StatelessWidget {
  final Map<String, dynamic> course;
  const InstructorCourseDetailScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    final modules = (course['modules'] as List?) ?? [];
    return Scaffold(
      appBar: AppBar(title: Text(course['title'] ?? 'Course')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppTheme.primary, Color(0xFF9C8FFF)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(course['title'] ?? '',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text(course['description'] ?? '',
                style: const TextStyle(color: Colors.white70, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
          ]),
        ),
        const SizedBox(height: 16),
        const SectionHeader(title: 'Course Modules'),
        if (modules.isEmpty)
          const EmptyState(title: 'No modules yet', icon: Icons.folder_outlined)
        else
          ...modules.asMap().entries.map((entry) {
            final mod = entry.value;
            return AppCard(
              child: Row(children: [
                CircleAvatar(radius: 14, backgroundColor: AppTheme.primary.withOpacity(0.15),
                    child: Text('${entry.key + 1}', style: const TextStyle(color: AppTheme.primary, fontSize: 12))),
                const SizedBox(width: 12),
                Expanded(child: Text(mod['title'] ?? 'Module', style: const TextStyle(fontWeight: FontWeight.w600))),
              ]),
            );
          }),
      ]),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// STUDENT ROSTER
// ──────────────────────────────────────────────────────────────
class InstructorStudentsScreen extends StatefulWidget {
  const InstructorStudentsScreen({super.key});
  @override
  State<InstructorStudentsScreen> createState() => _InstructorStudentsScreenState();
}

class _InstructorStudentsScreenState extends State<InstructorStudentsScreen> {
  List<dynamic> _students = [];
  bool _loading = true;
  String? _error;
  List<dynamic> _courses = [];
  String? _selectedCourse;

  @override
  void initState() { super.initState(); _fetchCourses(); }

  Future<void> _fetchCourses() async {
    try {
      final res = await ApiService.get('/instructor/courses');
      final list = res is List ? res : (res['courses'] ?? []);
      setState(() { _courses = list; });
      if (list.isNotEmpty) {
        _selectedCourse = list[0]['_id'];
        _fetchStudents(_selectedCourse!);
      } else {
        setState(() => _loading = false);
      }
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _fetchStudents(String courseId) async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.get('/instructor/courses/$courseId/batch/regular/students');
      final list = res is List ? res : (res['students'] ?? res['data'] ?? []);
      setState(() { _students = list; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Roster')),
      body: Column(children: [
        if (_courses.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              value: _selectedCourse,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Select Course', prefixIcon: Icon(Icons.book_outlined)),
              items: _courses.map((c) => DropdownMenuItem(
                value: c['_id'].toString(),
                child: Text(c['title'] ?? 'Course', overflow: TextOverflow.ellipsis),
              )).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedCourse = val);
                  _fetchStudents(val);
                }
              },
            ),
          ),
        Expanded(
          child: _loading
              ? const LoadingWidget()
              : _error != null
                  ? ErrorWidget2(message: _error!, onRetry: () => _fetchStudents(_selectedCourse ?? ''))
                  : _students.isEmpty
                      ? const EmptyState(title: 'No students enrolled', icon: Icons.people_outlined)
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: _students.length,
                          itemBuilder: (_, i) {
                            final s = _students[i];
                            final user = s['user'] ?? s;
                            final name = user['profile']?['full_name'] ?? user['email'] ?? 'Student';
                            final email = user['email'] ?? '';
                            final progress = ((s['progress'] ?? 0) as num).toDouble();
                            return AppCard(
                              child: Row(children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppTheme.primary.withOpacity(0.15),
                                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'S',
                                      style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text(email, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  LinearProgressIndicator(
                                    value: progress / 100,
                                    backgroundColor: AppTheme.border,
                                    valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                                  ),
                                ])),
                                const SizedBox(width: 8),
                                Text('${progress.toStringAsFixed(0)}%',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                              ]),
                            );
                          },
                        ),
        ),
      ]),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// LIVE BROADCAST
// ──────────────────────────────────────────────────────────────
class InstructorLiveScreen extends StatefulWidget {
  const InstructorLiveScreen({super.key});
  @override
  State<InstructorLiveScreen> createState() => _InstructorLiveScreenState();
}

class _InstructorLiveScreenState extends State<InstructorLiveScreen> {
  List<dynamic> _sessions = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getData('live_classes', queryParams: {'limit': '30', 'sort': '-created_at'});
      final list = res is List ? res : (res['data'] ?? []);
      setState(() { _sessions = list; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Broadcast'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _showCreateDialog(),
        ),
      ]),
      body: _loading
          ? const LoadingWidget()
          : _sessions.isEmpty
              ? const EmptyState(title: 'No live sessions', subtitle: 'Tap + to create one', icon: Icons.live_tv_outlined)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _sessions.length,
                  itemBuilder: (_, i) {
                    final s = _sessions[i];
                    final title = s['title'] ?? 'Session';
                    final status = s['status'] ?? 'scheduled';
                    final isLive = status == 'live';
                    final date = s['scheduled_at'] != null
                        ? DateFormat('dd MMM, HH:mm').format(DateTime.tryParse(s['scheduled_at']) ?? DateTime.now())
                        : '';
                    return AppCard(
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isLive ? Colors.red.withOpacity(0.12) : AppTheme.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.live_tv, color: isLive ? Colors.red : AppTheme.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                          if (date.isNotEmpty) Text(date,
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        ])),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isLive ? Colors.red.withOpacity(0.12) : AppTheme.border,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(status.toUpperCase(),
                              style: TextStyle(
                                  color: isLive ? Colors.red : AppTheme.textSecondary,
                                  fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ]),
                    );
                  },
                ),
    );
  }

  void _showCreateDialog() {
    final titleCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create Live Session'),
        content: TextField(
          controller: titleCtrl,
          decoration: const InputDecoration(labelText: 'Session Title'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ApiService.post('/zoom/meetings', {'topic': titleCtrl.text, 'type': 1});
                _fetch();
              } catch (_) {}
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// INSTRUCTOR MORE MENU
// ──────────────────────────────────────────────────────────────
class InstructorMoreMenu extends StatelessWidget {
  const InstructorMoreMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _MenuItem(Icons.chat_outlined, 'Messages', Colors.blue, () => _nav(context, const ChatScreen())),
      _MenuItem(Icons.notifications_outlined, 'Notifications', AppTheme.primary, () => _nav(context, const NotificationsScreen())),
      _MenuItem(Icons.person_outlined, 'My Profile', Colors.green, () => _nav(context, const ProfileScreen())),
    ];

    return Scaffold(
      appBar: const CupertinoAppBar(title: 'More'),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) => ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: items[i].color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(items[i].icon, color: items[i].color, size: 20),
          ),
          title: Text(items[i].label, style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          onTap: items[i].onTap,
        ),
      ),
    );
  }

  void _nav(BuildContext ctx, Widget screen) =>
      Navigator.push(ctx, MaterialPageRoute(builder: (_) => screen));
}

class _MenuItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  _MenuItem(this.icon, this.label, this.color, this.onTap);
}

class CupertinoAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const CupertinoAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext ctx) => AppBar(title: Text(title));

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
