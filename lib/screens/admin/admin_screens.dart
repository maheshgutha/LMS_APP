import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';
import '../../widgets/common_widgets.dart';
import 'package:intl/intl.dart';

// ──────────────────────────────────────────────────────────────
// ENROLLMENTS
// ──────────────────────────────────────────────────────────────
class AdminEnrollmentsScreen extends StatefulWidget {
  const AdminEnrollmentsScreen({super.key});
  @override
  State<AdminEnrollmentsScreen> createState() => _AdminEnrollmentsScreenState();
}

class _AdminEnrollmentsScreenState extends State<AdminEnrollmentsScreen> {
  List<dynamic> _data = [];
  bool _loading = true;
  String? _error;
  final _search = TextEditingController();
  List<dynamic> _filtered = [];

  @override
  void initState() {
    super.initState();
    _fetch();
    _search.addListener(_filter);
  }

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.get('/admin/enrollments-list');
      final list = res is List ? res : (res['enrollments'] ?? res['data'] ?? []);
      setState(() { _data = list; _filtered = list; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); _loading = false; });
    }
  }

  void _filter() {
    final q = _search.text.toLowerCase();
    setState(() {
      _filtered = _data.where((e) {
        final user = (e['user']?['email'] ?? e['user_email'] ?? '').toString().toLowerCase();
        final course = (e['course']?['title'] ?? e['course_title'] ?? '').toString().toLowerCase();
        return q.isEmpty || user.contains(q) || course.contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Enrollments'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch),
      ]),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: CustomSearchBar(controller: _search, hint: 'Search by student or course...', onChanged: (_) => _filter()),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Text('${_filtered.length} enrollments', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ]),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _loading
              ? const LoadingWidget(message: 'Loading enrollments...')
              : _error != null
                  ? ErrorWidget2(message: _error!, onRetry: _fetch)
                  : _filtered.isEmpty
                      ? const EmptyState(title: 'No enrollments found', icon: Icons.school_outlined)
                      : RefreshIndicator(
                          onRefresh: _fetch,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) {
                              final e = _filtered[i];
                              final user = e['user'] ?? {};
                              final course = e['course'] ?? {};
                              final name = user['profile']?['full_name'] ?? user['email'] ?? 'Unknown';
                              final courseTitle = course['title'] ?? e['course_title'] ?? 'Unknown Course';
                              final status = e['payment_status'] ?? e['status'] ?? 'unknown';
                              final progress = ((e['progress'] ?? 0) as num).toDouble();
                              final date = e['created_at'] != null
                                  ? DateFormat('dd MMM yyyy').format(DateTime.tryParse(e['created_at']) ?? DateTime.now())
                                  : '';
                              return AppCard(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600))),
                                    _StatusChip(status: status),
                                  ]),
                                  const SizedBox(height: 4),
                                  Text(courseTitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                                  if (date.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(date, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: progress / 100,
                                          backgroundColor: AppTheme.border,
                                          valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                                          minHeight: 6,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('${progress.toStringAsFixed(0)}%',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  ]),
                                ]),
                              );
                            },
                          ),
                        ),
        ),
      ]),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// ACADEMIC SCORES
// ──────────────────────────────────────────────────────────────
class AdminScoresScreen extends StatefulWidget {
  const AdminScoresScreen({super.key});
  @override
  State<AdminScoresScreen> createState() => _AdminScoresScreenState();
}

class _AdminScoresScreenState extends State<AdminScoresScreen> {
  List<dynamic> _data = [];
  bool _loading = true;
  String? _error;
  final _search = TextEditingController();
  List<dynamic> _filtered = [];

  @override
  void initState() { super.initState(); _fetch(); _search.addListener(_filter); }
  @override
  void dispose() { _search.dispose(); super.dispose(); }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.getData('exam_results', queryParams: {'limit': '100'});
      final list = res is List ? res : (res['data'] ?? []);
      setState(() { _data = list; _filtered = list; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); _loading = false; });
    }
  }

  void _filter() {
    final q = _search.text.toLowerCase();
    setState(() {
      _filtered = _data.where((d) {
        final name = (d['student']?['profile']?['full_name'] ?? d['student']?['email'] ?? '').toString().toLowerCase();
        final exam = (d['exam']?['title'] ?? '').toString().toLowerCase();
        return q.isEmpty || name.contains(q) || exam.contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Academic Scores'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch),
      ]),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: CustomSearchBar(controller: _search, hint: 'Search scores...', onChanged: (_) => _filter()),
        ),
        Expanded(
          child: _loading
              ? const LoadingWidget(message: 'Loading scores...')
              : _error != null
                  ? ErrorWidget2(message: _error!, onRetry: _fetch)
                  : _filtered.isEmpty
                      ? const EmptyState(title: 'No exam results found', icon: Icons.quiz_outlined)
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) {
                            final d = _filtered[i];
                            final name = d['student']?['profile']?['full_name'] ?? d['student']?['email'] ?? 'Student';
                            final exam = d['exam']?['title'] ?? 'Exam';
                            final score = d['score'] ?? d['total_score'] ?? 0;
                            final total = d['total_marks'] ?? d['max_score'] ?? 100;
                            final pct = total > 0 ? (score / total * 100) : 0;
                            final passed = d['passed'] ?? pct >= 50;
                            return AppCard(
                              child: Row(children: [
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text(exam, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                ])),
                                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                  Text('$score/$total',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: passed
                                          ? AppTheme.success.withOpacity(0.12)
                                          : AppTheme.error.withOpacity(0.12),
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
                        ),
        ),
      ]),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// LEADERBOARD
// ──────────────────────────────────────────────────────────────
class AdminLeaderboardScreen extends StatefulWidget {
  const AdminLeaderboardScreen({super.key});
  @override
  State<AdminLeaderboardScreen> createState() => _AdminLeaderboardScreenState();
}

class _AdminLeaderboardScreenState extends State<AdminLeaderboardScreen> {
  List<dynamic> _data = [];
  bool _loading = true;
  String? _error;
  String _period = 'year';

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.getData('leaderboard_stats',
          queryParams: {'period': _period, 'limit': '50', 'sort': '-total_score'});
      final list = res is List ? res : (res['data'] ?? []);
      setState(() { _data = list; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch),
      ]),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: ['week', 'month', 'year'].map((p) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(p[0].toUpperCase() + p.substring(1)),
                selected: _period == p,
                selectedColor: AppTheme.primary,
                labelStyle: TextStyle(color: _period == p ? Colors.white : AppTheme.textSecondary),
                onSelected: (_) { setState(() => _period = p); _fetch(); },
              ),
            )).toList(),
          ),
        ),
        Expanded(
          child: _loading
              ? const LoadingWidget()
              : _error != null
                  ? ErrorWidget2(message: _error!, onRetry: _fetch)
                  : _data.isEmpty
                      ? const EmptyState(title: 'No leaderboard data', icon: Icons.emoji_events_outlined)
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: _data.length,
                          itemBuilder: (_, i) {
                            final d = _data[i];
                            final rank = i + 1;
                            final user = d['user'] ?? {};
                            final name = user['profile']?['full_name'] ?? user['email'] ?? 'Student';
                            final score = d['total_score'] ?? d['score'] ?? 0;
                            Color rankColor = AppTheme.textSecondary;
                            if (rank == 1) rankColor = const Color(0xFFFFD700);
                            if (rank == 2) rankColor = const Color(0xFFC0C0C0);
                            if (rank == 3) rankColor = const Color(0xFFCD7F32);
                            return AppCard(
                              child: Row(children: [
                                SizedBox(
                                  width: 36,
                                  child: Text('#$rank',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontWeight: FontWeight.bold, color: rankColor, fontSize: 16)),
                                ),
                                const SizedBox(width: 12),
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppTheme.primary.withOpacity(0.15),
                                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                                      style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600))),
                                Text('$score pts',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
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
// RESUME SCANS
// ──────────────────────────────────────────────────────────────
class AdminResumeScansScreen extends StatefulWidget {
  const AdminResumeScansScreen({super.key});
  @override
  State<AdminResumeScansScreen> createState() => _AdminResumeScansScreenState();
}

class _AdminResumeScansScreenState extends State<AdminResumeScansScreen> {
  List<dynamic> _data = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.getData('resumescans', queryParams: {'limit': '100', 'sort': '-created_at'});
      final list = res is List ? res : (res['data'] ?? []);
      setState(() { _data = list; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resume Scans'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch),
      ]),
      body: _loading
          ? const LoadingWidget()
          : _error != null
              ? ErrorWidget2(message: _error!, onRetry: _fetch)
              : _data.isEmpty
                  ? const EmptyState(title: 'No resume scans yet', icon: Icons.description_outlined)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _data.length,
                      itemBuilder: (_, i) {
                        final d = _data[i];
                        final user = d['user'] ?? {};
                        final name = user['profile']?['full_name'] ?? user['email'] ?? 'Unknown';
                        final score = d['ats_score'] ?? d['score'] ?? 0;
                        final date = d['created_at'] != null
                            ? DateFormat('dd MMM yyyy').format(DateTime.tryParse(d['created_at']) ?? DateTime.now())
                            : '';
                        return AppCard(
                          child: Row(children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.description_outlined, color: AppTheme.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              if (date.isNotEmpty)
                                Text(date, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                            ])),
                            Column(children: [
                              Text('$score%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: score >= 70
                                        ? AppTheme.success
                                        : score >= 50
                                            ? AppTheme.warning
                                            : AppTheme.error,
                                  )),
                              const Text('ATS Score', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                            ]),
                          ]),
                        );
                      },
                    ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// INSTRUCTORS
// ──────────────────────────────────────────────────────────────
class AdminInstructorsScreen extends StatefulWidget {
  const AdminInstructorsScreen({super.key});
  @override
  State<AdminInstructorsScreen> createState() => _AdminInstructorsScreenState();
}

class _AdminInstructorsScreenState extends State<AdminInstructorsScreen> {
  List<dynamic> _data = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.get('/admin/instructors');
      final list = res is List ? res : (res['instructors'] ?? res['data'] ?? []);
      setState(() { _data = list; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Instructors List'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch),
      ]),
      body: _loading
          ? const LoadingWidget()
          : _error != null
              ? ErrorWidget2(message: _error!, onRetry: _fetch)
              : _data.isEmpty
                  ? const EmptyState(title: 'No instructors found', icon: Icons.person_outlined)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _data.length,
                      itemBuilder: (_, i) {
                        final d = _data[i];
                        final profile = d['profile'] ?? {};
                        final name = profile['full_name'] ?? d['email'] ?? 'Instructor';
                        final email = d['email'] ?? '';
                        final courses = (d['assigned_courses'] as List?)?.length ?? 0;
                        final avatar = profile['avatar_url'];
                        return AppCard(
                          child: Row(children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                              backgroundColor: AppTheme.primary.withOpacity(0.15),
                              child: avatar == null
                                  ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'I',
                                      style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold))
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text(email, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                              Text('$courses courses assigned',
                                  style: const TextStyle(color: AppTheme.primary, fontSize: 12)),
                            ])),
                          ]),
                        );
                      },
                    ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// ALL COURSES
// ──────────────────────────────────────────────────────────────
class AdminCoursesScreen extends StatefulWidget {
  const AdminCoursesScreen({super.key});
  @override
  State<AdminCoursesScreen> createState() => _AdminCoursesScreenState();
}

class _AdminCoursesScreenState extends State<AdminCoursesScreen> {
  List<dynamic> _data = [];
  bool _loading = true;
  String? _error;
  final _search = TextEditingController();
  List<dynamic> _filtered = [];

  @override
  void initState() { super.initState(); _fetch(); _search.addListener(_filter); }
  @override
  void dispose() { _search.dispose(); super.dispose(); }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.get('/admin/courses-with-instructors');
      final list = res is List ? res : (res['courses'] ?? res['data'] ?? []);
      setState(() { _data = list; _filtered = list; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); _loading = false; });
    }
  }

  void _filter() {
    final q = _search.text.toLowerCase();
    setState(() {
      _filtered = _data.where((d) =>
          (d['title'] ?? '').toString().toLowerCase().contains(q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Courses'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch),
      ]),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: CustomSearchBar(controller: _search, hint: 'Search courses...', onChanged: (_) => _filter()),
        ),
        Expanded(
          child: _loading
              ? const LoadingWidget()
              : _error != null
                  ? ErrorWidget2(message: _error!, onRetry: _fetch)
                  : _filtered.isEmpty
                      ? const EmptyState(title: 'No courses found', icon: Icons.book_outlined)
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) {
                            final d = _filtered[i];
                            final title = d['title'] ?? 'Untitled';
                            final isActive = d['is_active'] ?? false;
                            final isApproved = d['is_approved'] ?? false;
                            final instructors = (d['instructors'] as List?)
                                ?.map((ins) => ins['profile']?['full_name'] ?? ins['email'] ?? '')
                                .where((s) => s.isNotEmpty)
                                .join(', ') ?? '';
                            final students = d['enrollment_count'] ?? 0;
                            return AppCard(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Expanded(child: Text(title,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
                                  if (isApproved)
                                    const Icon(Icons.verified, color: AppTheme.success, size: 16),
                                ]),
                                const SizedBox(height: 6),
                                if (instructors.isNotEmpty)
                                  Row(children: [
                                    const Icon(Icons.person_outlined, size: 14, color: AppTheme.textSecondary),
                                    const SizedBox(width: 4),
                                    Expanded(child: Text(instructors,
                                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                        maxLines: 1, overflow: TextOverflow.ellipsis)),
                                  ]),
                                const SizedBox(height: 6),
                                Row(children: [
                                  Icon(Icons.people_outlined, size: 14, color: AppTheme.primary),
                                  const SizedBox(width: 4),
                                  Text('$students students', style: const TextStyle(fontSize: 12)),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isActive ? AppTheme.success.withOpacity(0.12) : AppTheme.error.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(isActive ? 'Active' : 'Inactive',
                                        style: TextStyle(
                                            color: isActive ? AppTheme.success : AppTheme.error,
                                            fontSize: 11, fontWeight: FontWeight.w600)),
                                  ),
                                ]),
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
// CHAT MONITOR
// ──────────────────────────────────────────────────────────────
class AdminChatMonitorScreen extends StatefulWidget {
  const AdminChatMonitorScreen({super.key});
  @override
  State<AdminChatMonitorScreen> createState() => _AdminChatMonitorScreenState();
}

class _AdminChatMonitorScreenState extends State<AdminChatMonitorScreen> {
  List<dynamic> _data = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.get('/admin/conversations');
      final list = res is List ? res : (res['conversations'] ?? res['data'] ?? []);
      setState(() { _data = list; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat Monitoring'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch),
      ]),
      body: _loading
          ? const LoadingWidget()
          : _error != null
              ? ErrorWidget2(message: _error!, onRetry: _fetch)
              : _data.isEmpty
                  ? const EmptyState(title: 'No conversations', icon: Icons.chat_outlined)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _data.length,
                      itemBuilder: (_, i) {
                        final d = _data[i];
                        final participants = (d['participants'] as List?) ?? [];
                        final names = participants
                            .map((p) => p['profile']?['full_name'] ?? p['email'] ?? 'User')
                            .join(' ↔ ');
                        final lastMsg = d['last_message'] ?? '';
                        final msgCount = d['message_count'] ?? 0;
                        return AppCard(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => _ChatDetailScreen(
                              conversationId: d['_id'],
                              title: names,
                            )),
                          ),
                          child: Row(children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.chat_outlined, color: AppTheme.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(names, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              if (lastMsg.isNotEmpty)
                                Text(lastMsg, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                            ])),
                            Text('$msgCount msgs', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                          ]),
                        );
                      },
                    ),
    );
  }
}

class _ChatDetailScreen extends StatefulWidget {
  final String conversationId;
  final String title;
  const _ChatDetailScreen({required this.conversationId, required this.title});
  @override
  State<_ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<_ChatDetailScreen> {
  List<dynamic> _messages = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    try {
      final res = await ApiService.get('/admin/conversations/${widget.conversationId}/messages');
      final list = res is List ? res : (res['messages'] ?? res['data'] ?? []);
      setState(() { _messages = list; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: _loading
          ? const LoadingWidget()
          : _messages.isEmpty
              ? const EmptyState(title: 'No messages', icon: Icons.chat_bubble_outline)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) {
                    final m = _messages[i];
                    final sender = m['sender']?['profile']?['full_name'] ?? m['sender']?['email'] ?? 'User';
                    final content = m['content'] ?? '';
                    final time = m['created_at'] != null
                        ? DateFormat('HH:mm').format(DateTime.tryParse(m['created_at']) ?? DateTime.now())
                        : '';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        CircleAvatar(radius: 14,
                            backgroundColor: AppTheme.primary.withOpacity(0.15),
                            child: Text(sender.isNotEmpty ? sender[0].toUpperCase() : '?',
                                style: const TextStyle(fontSize: 11, color: AppTheme.primary))),
                        const SizedBox(width: 8),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Text(sender, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                            const SizedBox(width: 6),
                            Text(time, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                          ]),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.border,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(content, style: const TextStyle(fontSize: 13)),
                          ),
                        ])),
                      ]),
                    );
                  },
                ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// LIVE MONITORING
// ──────────────────────────────────────────────────────────────
class AdminLiveMonitoringScreen extends StatefulWidget {
  const AdminLiveMonitoringScreen({super.key});
  @override
  State<AdminLiveMonitoringScreen> createState() => _AdminLiveMonitoringScreenState();
}

class _AdminLiveMonitoringScreenState extends State<AdminLiveMonitoringScreen> {
  Map<String, dynamic>? _summary;
  List<dynamic> _liveSessions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final summaryRes = await ApiService.get('/admin/data-summary');
      final liveRes = await ApiService.getData('live_classes',
          queryParams: {'status': 'live', 'limit': '20'});
      final sessions = liveRes is List ? liveRes : (liveRes['data'] ?? []);
      setState(() {
        _summary = summaryRes is Map ? summaryRes as Map<String, dynamic> : {};
        _liveSessions = sessions;
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Monitoring'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch),
      ]),
      body: _loading
          ? const LoadingWidget()
          : _error != null
              ? ErrorWidget2(message: _error!, onRetry: _fetch)
              : RefreshIndicator(
                  onRefresh: _fetch,
                  child: ListView(padding: const EdgeInsets.all(16), children: [
                    if (_summary != null) ...[
                      const SectionHeader(title: 'Platform Overview'),
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          StatCard(title: 'Total Users', value: '${_summary!['users'] ?? 0}', icon: Icons.people_outlined),
                          StatCard(title: 'Active Courses', value: '${_summary!['courses'] ?? 0}', icon: Icons.book_outlined, color: AppTheme.secondary),
                          StatCard(title: 'Enrollments', value: '${_summary!['enrollments'] ?? 0}', icon: Icons.school_outlined, color: Colors.orange),
                          StatCard(title: 'Exam Results', value: '${_summary!['examResults'] ?? 0}', icon: Icons.quiz_outlined, color: Colors.purple),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    SectionHeader(
                      title: 'Live Sessions (${_liveSessions.length})',
                    ),
                    if (_liveSessions.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(children: [
                            Icon(Icons.live_tv, size: 48, color: AppTheme.border),
                            SizedBox(height: 8),
                            Text('No live sessions right now', style: TextStyle(color: AppTheme.textSecondary)),
                          ]),
                        ),
                      )
                    else
                      ..._liveSessions.map((s) => AppCard(
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.live_tv, color: Colors.red),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(s['title'] ?? 'Live Session',
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text(s['instructor']?['profile']?['full_name'] ?? 'Instructor',
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                          ])),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(children: [
                              Icon(Icons.circle, color: Colors.red, size: 8),
                              SizedBox(width: 4),
                              Text('LIVE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11)),
                            ]),
                          ),
                        ]),
                      )),
                  ]),
                ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// QUALITY ASSURANCE
// ──────────────────────────────────────────────────────────────
class AdminQaScreen extends StatefulWidget {
  const AdminQaScreen({super.key});
  @override
  State<AdminQaScreen> createState() => _AdminQaScreenState();
}

class _AdminQaScreenState extends State<AdminQaScreen> {
  List<dynamic> _ratings = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.getData('course_ratings', queryParams: {'limit': '100', 'sort': '-created_at'});
      final list = res is List ? res : (res['data'] ?? []);
      setState(() { _ratings = list; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quality Assurance'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch),
      ]),
      body: _loading
          ? const LoadingWidget()
          : _error != null
              ? ErrorWidget2(message: _error!, onRetry: _fetch)
              : _ratings.isEmpty
                  ? const EmptyState(title: 'No ratings yet', icon: Icons.star_outline)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _ratings.length,
                      itemBuilder: (_, i) {
                        final r = _ratings[i];
                        final course = r['course']?['title'] ?? 'Course';
                        final student = r['student']?['profile']?['full_name'] ?? r['student']?['email'] ?? 'Student';
                        final rating = (r['rating'] ?? 0) as num;
                        final feedback = r['feedback'] ?? '';
                        return AppCard(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(child: Text(course, style: const TextStyle(fontWeight: FontWeight.w600))),
                              Row(children: List.generate(5, (j) => Icon(
                                j < rating.round() ? Icons.star : Icons.star_outline,
                                color: Colors.amber, size: 16,
                              ))),
                            ]),
                            const SizedBox(height: 4),
                            Text(student, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                            if (feedback.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(feedback, style: const TextStyle(fontSize: 13)),
                            ],
                          ]),
                        );
                      },
                    ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// NOTIFICATIONS
// ──────────────────────────────────────────────────────────────
class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});
  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  List<dynamic> _data = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.getData('notifications', queryParams: {'limit': '50', 'sort': '-created_at'});
      final list = res is List ? res : (res['data'] ?? []);
      setState(() { _data = list; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch),
      ]),
      body: _loading
          ? const LoadingWidget()
          : _error != null
              ? ErrorWidget2(message: _error!, onRetry: _fetch)
              : _data.isEmpty
                  ? const EmptyState(title: 'No notifications', icon: Icons.notifications_off_outlined)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _data.length,
                      itemBuilder: (_, i) {
                        final n = _data[i];
                        final title = n['title'] ?? '';
                        final msg = n['message'] ?? n['body'] ?? '';
                        final isRead = n['is_read'] ?? true;
                        final date = n['created_at'] != null
                            ? DateFormat('dd MMM, HH:mm').format(DateTime.tryParse(n['created_at']) ?? DateTime.now())
                            : '';
                        return AppCard(
                          color: isRead ? null : AppTheme.primary.withOpacity(0.04),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.notifications_outlined, color: AppTheme.primary, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              if (title.isNotEmpty) Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text(msg, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                              if (date.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(date, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                              ],
                            ])),
                            if (!isRead)
                              Container(
                                width: 8, height: 8,
                                decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                              ),
                          ]),
                        );
                      },
                    ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// HELPER WIDGET
// ──────────────────────────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color c;
    switch (status.toLowerCase()) {
      case 'paid':
      case 'active':
      case 'approved':
        c = AppTheme.success;
        break;
      case 'pending':
        c = AppTheme.warning;
        break;
      default:
        c = AppTheme.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
      child: Text(status.toUpperCase(),
          style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
