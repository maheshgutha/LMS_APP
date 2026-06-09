import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';
import '../../widgets/common_widgets.dart';
import '../shared/profile_screen.dart';
import '../shared/chat_screen.dart';
import '../shared/notifications_screen.dart';

// ──────────────────────────────────────────────────────────────
// STUDENT SHELL
// ──────────────────────────────────────────────────────────────
class StudentShell extends StatefulWidget {
  final bool isIntern;
  const StudentShell({super.key, this.isIntern = false});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _idx = 0;

  Widget _screen(int i) {
    switch (i) {
      case 0: return const StudentDashboard();
      case 1: return const StudentCoursesScreen();
      case 2: return const StudentExamsScreen();
      case 3: return const StudentAttendanceScreen();
      case 4: return StudentMoreMenu(isIntern: widget.isIntern);
      default: return const StudentDashboard();
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
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.book_outlined), activeIcon: Icon(Icons.book), label: 'Courses'),
          BottomNavigationBarItem(icon: Icon(Icons.quiz_outlined), activeIcon: Icon(Icons.quiz), label: 'Exams'),
          BottomNavigationBarItem(icon: Icon(Icons.checklist_outlined), activeIcon: Icon(Icons.checklist), label: 'Attendance'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), activeIcon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// STUDENT DASHBOARD
// ──────────────────────────────────────────────────────────────
class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});
  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  Map<String, dynamic>? _stats;
  List<dynamic> _enrollments = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final [enrollRes, notifRes] = await Future.wait([
        ApiService.get('/courses/enrollments'),
        ApiService.getData('notifications', queryParams: {'limit': '5', 'is_read': 'false'}),
      ]);
      final enrList = enrollRes is List ? enrollRes : (enrollRes['enrollments'] ?? []);
      setState(() {
        _enrollments = enrList.take(3).toList();
        _stats = {
          'enrolled': enrList.length,
          'notifications': (notifRes is List ? notifRes : (notifRes['data'] ?? [])).length,
        };
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Dashboard'), actions: [
        IconButton(icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
      ]),
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
                    StatCard(title: 'Enrolled Courses', value: '${_stats?['enrolled'] ?? 0}',
                        icon: Icons.book_outlined),
                    StatCard(title: 'Notifications', value: '${_stats?['notifications'] ?? 0}',
                        icon: Icons.notifications_outlined, color: Colors.orange),
                  ],
                ),
                const SizedBox(height: 16),
                const SectionHeader(title: 'Continue Learning'),
                if (_enrollments.isEmpty)
                  const EmptyState(title: 'No enrolled courses', icon: Icons.book_outlined)
                else
                  ..._enrollments.map((e) {
                    final course = e['course'] ?? {};
                    final title = course['title'] ?? 'Course';
                    final progress = ((e['progress'] ?? 0) as num).toDouble();
                    return AppCard(
                      onTap: () {},
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress / 100,
                              backgroundColor: AppTheme.border,
                              valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                              minHeight: 6,
                            ),
                          )),
                          const SizedBox(width: 8),
                          Text('${progress.toStringAsFixed(0)}%',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ]),
                      ]),
                    );
                  }),
              ]),
            ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// STUDENT COURSES
// ──────────────────────────────────────────────────────────────
class StudentCoursesScreen extends StatefulWidget {
  const StudentCoursesScreen({super.key});
  @override
  State<StudentCoursesScreen> createState() => _StudentCoursesScreenState();
}

class _StudentCoursesScreenState extends State<StudentCoursesScreen> {
  List<dynamic> _courses = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/courses/enrollments');
      final list = res is List ? res : (res['enrollments'] ?? res['data'] ?? []);
      setState(() { _courses = list; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Courses'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch),
      ]),
      body: _loading
          ? const LoadingWidget()
          : _courses.isEmpty
              ? const EmptyState(title: 'No courses yet', icon: Icons.book_outlined,
                  subtitle: 'Enroll in a course to get started')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _courses.length,
                  itemBuilder: (_, i) {
                    final e = _courses[i];
                    final course = e['course'] ?? e;
                    final title = course['title'] ?? 'Course';
                    final progress = ((e['progress'] ?? 0) as num).toDouble();
                    final instructor = course['instructor']?['profile']?['full_name'] ?? '';
                    return AppCard(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => StudentCourseViewScreen(
                          course: course,
                          enrollment: e,
                        )),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        if (instructor.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(children: [
                            const Icon(Icons.person_outline, size: 13, color: AppTheme.textSecondary),
                            const SizedBox(width: 4),
                            Text(instructor, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                          ]),
                        ],
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress / 100,
                              backgroundColor: AppTheme.border,
                              valueColor: AlwaysStoppedAnimation(
                                  progress >= 100 ? AppTheme.success : AppTheme.primary),
                              minHeight: 6,
                            ),
                          )),
                          const SizedBox(width: 8),
                          Text('${progress.toStringAsFixed(0)}%',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600,
                                  color: progress >= 100 ? AppTheme.success : AppTheme.textPrimary)),
                        ]),
                      ]),
                    );
                  },
                ),
    );
  }
}

class StudentCourseViewScreen extends StatefulWidget {
  final Map<String, dynamic> course;
  final Map<String, dynamic> enrollment;
  const StudentCourseViewScreen({super.key, required this.course, required this.enrollment});

  @override
  State<StudentCourseViewScreen> createState() => _StudentCourseViewScreenState();
}

class _StudentCourseViewScreenState extends State<StudentCourseViewScreen> {
  List<dynamic> _modules = [];
  List<dynamic> _videos = [];
  List<dynamic> _resources = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    final courseId = widget.course['_id'] ?? '';
    try {
      final [modRes, vidRes, resRes] = await Future.wait([
        ApiService.getData('course_modules', queryParams: {'course_id': courseId}),
        ApiService.getData('course_videos', queryParams: {'course_id': courseId}),
        ApiService.getData('course_resources', queryParams: {'course_id': courseId}),
      ]);
      setState(() {
        _modules = modRes is List ? modRes : (modRes['data'] ?? []);
        _videos = vidRes is List ? vidRes : (vidRes['data'] ?? []);
        _resources = resRes is List ? resRes : (resRes['data'] ?? []);
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.course['title'] ?? 'Course',
              maxLines: 1, overflow: TextOverflow.ellipsis),
          bottom: const TabBar(tabs: [
            Tab(text: 'Modules'),
            Tab(text: 'Videos'),
            Tab(text: 'Resources'),
          ]),
        ),
        body: _loading
            ? const LoadingWidget()
            : TabBarView(children: [
                // Modules
                _modules.isEmpty
                    ? const EmptyState(title: 'No modules', icon: Icons.folder_outlined)
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _modules.length,
                        itemBuilder: (_, i) {
                          final m = _modules[i];
                          return AppCard(child: Row(children: [
                            CircleAvatar(radius: 14, backgroundColor: AppTheme.primary.withOpacity(0.15),
                                child: Text('${i+1}', style: const TextStyle(color: AppTheme.primary, fontSize: 12))),
                            const SizedBox(width: 12),
                            Expanded(child: Text(m['title'] ?? 'Module',
                                style: const TextStyle(fontWeight: FontWeight.w600))),
                          ]));
                        }),
                // Videos
                _videos.isEmpty
                    ? const EmptyState(title: 'No videos', icon: Icons.video_library_outlined)
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _videos.length,
                        itemBuilder: (_, i) {
                          final v = _videos[i];
                          final dur = v['duration'] ?? '';
                          return AppCard(child: Row(children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.play_circle_outline, color: Colors.red),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(v['title'] ?? 'Video', style: const TextStyle(fontWeight: FontWeight.w600)),
                              if (dur.isNotEmpty) Text(dur, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                            ])),
                          ]));
                        }),
                // Resources
                _resources.isEmpty
                    ? const EmptyState(title: 'No resources', icon: Icons.folder_outlined)
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _resources.length,
                        itemBuilder: (_, i) {
                          final r = _resources[i];
                          return AppCard(child: Row(children: [
                            const Icon(Icons.insert_drive_file_outlined, color: AppTheme.primary),
                            const SizedBox(width: 12),
                            Expanded(child: Text(r['title'] ?? r['name'] ?? 'Resource',
                                style: const TextStyle(fontWeight: FontWeight.w600))),
                          ]));
                        }),
              ]),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// STUDENT EXAMS / MOCK PAPERS
// ──────────────────────────────────────────────────────────────
class StudentExamsScreen extends StatefulWidget {
  const StudentExamsScreen({super.key});
  @override
  State<StudentExamsScreen> createState() => _StudentExamsScreenState();
}

class _StudentExamsScreenState extends State<StudentExamsScreen> {
  List<dynamic> _exams = [];
  List<dynamic> _results = [];
  bool _loading = true;
  int _tab = 0;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final [examRes, resultRes] = await Future.wait([
        ApiService.getData('student_exam_access', queryParams: {'limit': '50'}),
        ApiService.getData('exam_results', queryParams: {'limit': '50', 'sort': '-created_at'}),
      ]);
      setState(() {
        _exams = examRes is List ? examRes : (examRes['data'] ?? []);
        _results = resultRes is List ? resultRes : (resultRes['data'] ?? []);
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exams & Results')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => setState(() => _tab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _tab == 0 ? AppTheme.primary : AppTheme.border,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                ),
                child: Text('Available Exams', textAlign: TextAlign.center,
                    style: TextStyle(color: _tab == 0 ? Colors.white : AppTheme.textSecondary,
                        fontWeight: FontWeight.w600)),
              ),
            )),
            Expanded(child: GestureDetector(
              onTap: () => setState(() => _tab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _tab == 1 ? AppTheme.primary : AppTheme.border,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                ),
                child: Text('My Results', textAlign: TextAlign.center,
                    style: TextStyle(color: _tab == 1 ? Colors.white : AppTheme.textSecondary,
                        fontWeight: FontWeight.w600)),
              ),
            )),
          ]),
        ),
        Expanded(
          child: _loading
              ? const LoadingWidget()
              : _tab == 0
                  ? (_exams.isEmpty
                      ? const EmptyState(title: 'No exams available', icon: Icons.quiz_outlined)
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: _exams.length,
                          itemBuilder: (_, i) {
                            final e = _exams[i];
                            final exam = e['exam'] ?? e;
                            final title = exam['title'] ?? 'Exam';
                            final duration = exam['duration'] ?? 0;
                            final marks = exam['total_marks'] ?? 100;
                            return AppCard(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                const SizedBox(height: 8),
                                Row(children: [
                                  _InfoChip(icon: Icons.timer_outlined, label: '${duration}m'),
                                  const SizedBox(width: 8),
                                  _InfoChip(icon: Icons.grade_outlined, label: '$marks marks'),
                                ]),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {},
                                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                                    child: const Text('Start Exam'),
                                  ),
                                ),
                              ]),
                            );
                          },
                        ))
                  : (_results.isEmpty
                      ? const EmptyState(title: 'No results yet', icon: Icons.bar_chart_outlined)
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: _results.length,
                          itemBuilder: (_, i) {
                            final r = _results[i];
                            final exam = r['exam'] ?? {};
                            final title = exam['title'] ?? 'Exam';
                            final score = r['score'] ?? 0;
                            final total = r['total_marks'] ?? 100;
                            final passed = r['passed'] ?? (score / total) >= 0.5;
                            final date = r['created_at'] != null
                                ? DateFormat('dd MMM yyyy').format(DateTime.tryParse(r['created_at']) ?? DateTime.now())
                                : '';
                            return AppCard(
                              child: Row(children: [
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  if (date.isNotEmpty) Text(date,
                                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                ])),
                                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                  Text('$score/$total',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: passed ? AppTheme.success.withOpacity(0.12) : AppTheme.error.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(passed ? 'PASS' : 'FAIL',
                                        style: TextStyle(
                                            color: passed ? AppTheme.success : AppTheme.error,
                                            fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ]),
                              ]),
                            );
                          },
                        )),
        ),
      ]),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ]),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// ATTENDANCE
// ──────────────────────────────────────────────────────────────
class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key});
  @override
  State<StudentAttendanceScreen> createState() => _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  List<dynamic> _data = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/student/my-attendance');
      final list = res is List ? res : (res['attendance'] ?? res['data'] ?? []);
      setState(() { _data = list; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _markAttendance() async {
    try {
      await ApiService.post('/student/mark-attendance', {'type': 'manual'});
      _fetch();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance marked!'), backgroundColor: AppTheme.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final present = _data.where((a) => a['status'] == 'present').length;
    final total = _data.length;
    final pct = total > 0 ? (present / total * 100) : 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance'), actions: [
        TextButton(onPressed: _markAttendance, child: const Text('Mark Present')),
      ]),
      body: _loading
          ? const LoadingWidget()
          : Column(children: [
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.primary, Color(0xFF9C8FFF)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Attendance Rate', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text('${pct.toStringAsFixed(1)}%',
                        style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                    Text('$present of $total sessions',
                        style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ])),
                  const Icon(Icons.checklist_rtl, color: Colors.white38, size: 60),
                ]),
              ),
              Expanded(
                child: _data.isEmpty
                    ? const EmptyState(title: 'No attendance records', icon: Icons.checklist_outlined)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: _data.length,
                        itemBuilder: (_, i) {
                          final a = _data[i];
                          final status = a['status'] ?? 'absent';
                          final isPresent = status == 'present';
                          final date = a['date'] ?? a['created_at'] ?? '';
                          final formatted = date.isNotEmpty
                              ? DateFormat('dd MMM yyyy').format(DateTime.tryParse(date) ?? DateTime.now())
                              : 'Unknown date';
                          return AppCard(
                            child: Row(children: [
                              Icon(isPresent ? Icons.check_circle : Icons.cancel_outlined,
                                  color: isPresent ? AppTheme.success : AppTheme.error),
                              const SizedBox(width: 12),
                              Expanded(child: Text(formatted, style: const TextStyle(fontWeight: FontWeight.w500))),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isPresent ? AppTheme.success.withOpacity(0.12) : AppTheme.error.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(status.toUpperCase(),
                                    style: TextStyle(
                                        color: isPresent ? AppTheme.success : AppTheme.error,
                                        fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
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
// STUDENT MORE MENU
// ──────────────────────────────────────────────────────────────
class StudentMoreMenu extends StatelessWidget {
  final bool isIntern;
  const StudentMoreMenu({super.key, this.isIntern = false});

  @override
  Widget build(BuildContext context) {
    void nav(Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

    final items = [
      _MenuItem(Icons.live_tv_outlined, 'Live Classes', Colors.red, () => nav(const StudentLiveClassesScreen())),
      _MenuItem(Icons.description_outlined, 'Resume ATS', Colors.orange, () => nav(const ResumeATSScreen())),
      _MenuItem(Icons.emoji_events_outlined, 'Leaderboard', Colors.amber, () => nav(const StudentLeaderboardScreen())),
      _MenuItem(Icons.chat_outlined, 'Messages', Colors.blue, () => nav(const ChatScreen())),
      _MenuItem(Icons.notifications_outlined, 'Notifications', AppTheme.primary, () => nav(const NotificationsScreen())),
      _MenuItem(Icons.history, 'History', Colors.purple, () => nav(const StudentHistoryScreen())),
      _MenuItem(Icons.folder_outlined, 'Resources', Colors.teal, () => nav(const StudentResourcesScreen())),
      if (!isIntern) ...[
        _MenuItem(Icons.badge_outlined, 'Interview Exam', Colors.indigo, () => nav(const InterviewDashboardScreen())),
      ],
      _MenuItem(Icons.person_outlined, 'My Profile', Colors.green, () => nav(const ProfileScreen())),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(isIntern ? 'More' : 'More')),
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
}

class _MenuItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  _MenuItem(this.icon, this.label, this.color, this.onTap);
}



// ──────────────────────────────────────────────────────────────
// LIVE CLASSES (STUDENT VIEW)
// ──────────────────────────────────────────────────────────────
class StudentLiveClassesScreen extends StatefulWidget {
  const StudentLiveClassesScreen({super.key});
  @override
  State<StudentLiveClassesScreen> createState() => _StudentLiveClassesScreenState();
}

class _StudentLiveClassesScreenState extends State<StudentLiveClassesScreen> {
  List<dynamic> _classes = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getData('live_classes', queryParams: {'limit': '30', 'sort': '-created_at'});
      final list = res is List ? res : (res['data'] ?? []);
      setState(() { _classes = list; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Classes')),
      body: _loading
          ? const LoadingWidget()
          : _classes.isEmpty
              ? const EmptyState(title: 'No live classes', icon: Icons.live_tv_outlined)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _classes.length,
                  itemBuilder: (_, i) {
                    final c = _classes[i];
                    final isLive = c['status'] == 'live';
                    final title = c['title'] ?? 'Session';
                    final date = c['scheduled_at'] != null
                        ? DateFormat('dd MMM, HH:mm').format(DateTime.tryParse(c['scheduled_at']) ?? DateTime.now())
                        : '';
                    return AppCard(
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isLive ? Colors.red.withOpacity(0.12) : AppTheme.border,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.live_tv, color: isLive ? Colors.red : AppTheme.textSecondary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                          if (date.isNotEmpty) Text(date,
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        ])),
                        if (isLive)
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            ),
                            child: const Text('Join', style: TextStyle(fontSize: 12)),
                          ),
                      ]),
                    );
                  },
                ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// RESUME ATS SCREEN
// ──────────────────────────────────────────────────────────────
class ResumeATSScreen extends StatefulWidget {
  const ResumeATSScreen({super.key});
  @override
  State<ResumeATSScreen> createState() => _ResumeATSScreenState();
}

class _ResumeATSScreenState extends State<ResumeATSScreen> {
  List<dynamic> _history = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getData('resumescans',
          queryParams: {'limit': '20', 'sort': '-created_at'});
      final list = res is List ? res : (res['data'] ?? []);
      setState(() { _history = list; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resume ATS Scanner')),
      body: Column(children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
          ),
          child: Column(children: [
            const Icon(Icons.upload_file_outlined, color: AppTheme.primary, size: 40),
            const SizedBox(height: 8),
            const Text('Upload your resume to get an ATS compatibility score',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Use the web app to upload resumes')),
                );
              },
              icon: const Icon(Icons.upload_outlined),
              label: const Text('Upload Resume'),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: const SectionHeader(title: 'Scan History'),
        ),
        Expanded(
          child: _loading
              ? const LoadingWidget()
              : _history.isEmpty
                  ? const EmptyState(title: 'No scans yet', icon: Icons.description_outlined)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: _history.length,
                      itemBuilder: (_, i) {
                        final h = _history[i];
                        final score = h['ats_score'] ?? h['score'] ?? 0;
                        final date = h['created_at'] != null
                            ? DateFormat('dd MMM yyyy').format(DateTime.tryParse(h['created_at']) ?? DateTime.now())
                            : '';
                        Color scoreColor = score >= 70 ? AppTheme.success : score >= 50 ? AppTheme.warning : AppTheme.error;
                        return AppCard(
                          child: Row(children: [
                            const Icon(Icons.description_outlined, color: AppTheme.primary),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(h['resume_name'] ?? 'Resume', style: const TextStyle(fontWeight: FontWeight.w600)),
                              if (date.isNotEmpty) Text(date,
                                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                            ])),
                            Text('$score%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: scoreColor)),
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
// STUDENT LEADERBOARD
// ──────────────────────────────────────────────────────────────
class StudentLeaderboardScreen extends StatefulWidget {
  const StudentLeaderboardScreen({super.key});
  @override
  State<StudentLeaderboardScreen> createState() => _StudentLeaderboardScreenState();
}

class _StudentLeaderboardScreenState extends State<StudentLeaderboardScreen> {
  List<dynamic> _data = [];
  bool _loading = true;
  String _period = 'year';

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getData('leaderboard_stats',
          queryParams: {'period': _period, 'limit': '50', 'sort': '-total_score'});
      final list = res is List ? res : (res['data'] ?? []);
      setState(() { _data = list; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: ['week', 'month', 'year'].map((p) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(p[0].toUpperCase() + p.substring(1)),
              selected: _period == p,
              selectedColor: AppTheme.primary,
              labelStyle: TextStyle(color: _period == p ? Colors.white : AppTheme.textSecondary),
              onSelected: (_) { setState(() => _period = p); _fetch(); },
            ),
          )).toList()),
        ),
        Expanded(
          child: _loading
              ? const LoadingWidget()
              : _data.isEmpty
                  ? const EmptyState(title: 'No leaderboard data', icon: Icons.emoji_events_outlined)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: _data.length,
                      itemBuilder: (_, i) {
                        final d = _data[i];
                        final user = d['user'] ?? {};
                        final name = user['profile']?['full_name'] ?? user['email'] ?? 'Student';
                        final score = d['total_score'] ?? 0;
                        final rank = i + 1;
                        Color rankColor = AppTheme.textSecondary;
                        if (rank == 1) rankColor = const Color(0xFFFFD700);
                        if (rank == 2) rankColor = const Color(0xFFC0C0C0);
                        if (rank == 3) rankColor = const Color(0xFFCD7F32);
                        return AppCard(
                          child: Row(children: [
                            SizedBox(width: 36, child: Text('#$rank', textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold, color: rankColor, fontSize: 16))),
                            const SizedBox(width: 12),
                            CircleAvatar(radius: 18, backgroundColor: AppTheme.primary.withOpacity(0.15),
                                child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold))),
                            const SizedBox(width: 12),
                            Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600))),
                            Text('$score pts', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
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
// HISTORY SCREEN
// ──────────────────────────────────────────────────────────────
class StudentHistoryScreen extends StatefulWidget {
  const StudentHistoryScreen({super.key});
  @override
  State<StudentHistoryScreen> createState() => _StudentHistoryScreenState();
}

class _StudentHistoryScreenState extends State<StudentHistoryScreen> {
  List<dynamic> _data = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getData('exam_results', queryParams: {'limit': '50', 'sort': '-created_at'});
      final list = res is List ? res : (res['data'] ?? []);
      setState(() { _data = list; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exam History')),
      body: _loading
          ? const LoadingWidget()
          : _data.isEmpty
              ? const EmptyState(title: 'No history yet', icon: Icons.history)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _data.length,
                  itemBuilder: (_, i) {
                    final r = _data[i];
                    final exam = r['exam'] ?? {};
                    final title = exam['title'] ?? 'Exam';
                    final score = r['score'] ?? 0;
                    final total = r['total_marks'] ?? 100;
                    final date = r['created_at'] != null
                        ? DateFormat('dd MMM yyyy').format(DateTime.tryParse(r['created_at']) ?? DateTime.now())
                        : '';
                    return AppCard(
                      child: Row(children: [
                        const Icon(Icons.history_edu_outlined, color: AppTheme.primary),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                          if (date.isNotEmpty) Text(date,
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        ])),
                        Text('$score/$total', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ]),
                    );
                  },
                ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// RESOURCES SCREEN
// ──────────────────────────────────────────────────────────────
class StudentResourcesScreen extends StatefulWidget {
  const StudentResourcesScreen({super.key});
  @override
  State<StudentResourcesScreen> createState() => _StudentResourcesScreenState();
}

class _StudentResourcesScreenState extends State<StudentResourcesScreen> {
  List<dynamic> _data = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getData('course_resources', queryParams: {'limit': '50'});
      final list = res is List ? res : (res['data'] ?? []);
      setState(() { _data = list; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resources')),
      body: _loading
          ? const LoadingWidget()
          : _data.isEmpty
              ? const EmptyState(title: 'No resources', icon: Icons.folder_outlined)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _data.length,
                  itemBuilder: (_, i) {
                    final r = _data[i];
                    return AppCard(
                      child: Row(children: [
                        const Icon(Icons.insert_drive_file_outlined, color: AppTheme.primary),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(r['title'] ?? r['name'] ?? 'Resource',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          if (r['type'] != null) Text(r['type'],
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        ])),
                        const Icon(Icons.download_outlined, color: AppTheme.primary),
                      ]),
                    );
                  },
                ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// INTERVIEW DASHBOARD
// ──────────────────────────────────────────────────────────────
class InterviewDashboardScreen extends StatefulWidget {
  const InterviewDashboardScreen({super.key});
  @override
  State<InterviewDashboardScreen> createState() => _InterviewDashboardScreenState();
}

class _InterviewDashboardScreenState extends State<InterviewDashboardScreen> {
  List<dynamic> _exams = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getData('interview_exam_schedules',
          queryParams: {'status': 'active', 'limit': '20'});
      final list = res is List ? res : (res['data'] ?? []);
      setState(() { _exams = list; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Interview Exams')),
      body: _loading
          ? const LoadingWidget()
          : _exams.isEmpty
              ? const EmptyState(title: 'No interview exams available', icon: Icons.badge_outlined,
                  subtitle: 'Check back when an exam is scheduled')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _exams.length,
                  itemBuilder: (_, i) {
                    final e = _exams[i];
                    final title = e['title'] ?? 'Interview Exam';
                    final duration = e['duration'] ?? 60;
                    final date = e['scheduled_at'] != null
                        ? DateFormat('dd MMM yyyy, HH:mm')
                            .format(DateTime.tryParse(e['scheduled_at']) ?? DateTime.now())
                        : '';
                    return AppCard(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: 8),
                        Row(children: [
                          _InfoChip(icon: Icons.timer_outlined, label: '${duration}m'),
                          const SizedBox(width: 8),
                          if (date.isNotEmpty) _InfoChip(icon: Icons.calendar_today_outlined, label: date),
                        ]),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Use the web browser for full exam experience')),
                              );
                            },
                            child: const Text('View Exam Details'),
                          ),
                        ),
                      ]),
                    );
                  },
                ),
    );
  }
}