import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';
import '../../widgets/common_widgets.dart';

class SubmissionGradingScreen extends StatefulWidget {
  const SubmissionGradingScreen({super.key});

  @override
  State<SubmissionGradingScreen> createState() => _SubmissionGradingScreenState();
}

class _SubmissionGradingScreenState extends State<SubmissionGradingScreen> {
  List<dynamic> _submissions = [];
  bool _loading = true;
  String? _error;
  String _filter = 'pending';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.getData('exam_results',
          queryParams: {'grading_status': _filter, 'limit': '50', 'sort': '-created_at'});
      final list = res is List ? res : (res['data'] ?? []);
      setState(() { _submissions = list; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); _loading = false; });
    }
  }

  Future<void> _gradeSubmission(String id, int score, String feedback) async {
    try {
      await ApiService.put('/data/exam_results/$id', {
        'score': score,
        'feedback': feedback,
        'grading_status': 'graded',
      });
      _fetch();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Graded successfully'), backgroundColor: AppTheme.success),
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

  void _showGradeDialog(dynamic submission) {
    final scoreCtrl = TextEditingController();
    final feedbackCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Grade Submission'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: scoreCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Score (out of 100)', prefixIcon: Icon(Icons.grade)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: feedbackCtrl,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Feedback', prefixIcon: Icon(Icons.comment_outlined)),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final score = int.tryParse(scoreCtrl.text) ?? 0;
              Navigator.pop(context);
              _gradeSubmission(submission['_id'], score, feedbackCtrl.text);
            },
            child: const Text('Submit Grade'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submission Grading'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch)],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: ['pending', 'graded', 'all'].map((f) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(f[0].toUpperCase() + f.substring(1)),
                  selected: _filter == f,
                  selectedColor: AppTheme.primary,
                  labelStyle: TextStyle(color: _filter == f ? Colors.white : AppTheme.textSecondary),
                  onSelected: (_) { setState(() => _filter = f); _fetch(); },
                ),
              )).toList(),
            ),
          ),
          Expanded(
            child: _loading
                ? const LoadingWidget()
                : _error != null
                    ? ErrorWidget2(message: _error!, onRetry: _fetch)
                    : _submissions.isEmpty
                        ? EmptyState(
                            title: 'No ${_filter} submissions',
                            icon: Icons.grading_outlined,
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: _submissions.length,
                            itemBuilder: (_, i) {
                              final s = _submissions[i];
                              final student = s['student']?['profile']?['full_name'] ??
                                  s['student']?['email'] ?? 'Student';
                              final exam = s['exam']?['title'] ?? 'Exam';
                              final score = s['score'];
                              final status = s['grading_status'] ?? 'pending';
                              final date = s['created_at'] != null
                                  ? DateFormat('dd MMM yyyy').format(
                                      DateTime.tryParse(s['created_at']) ?? DateTime.now())
                                  : '';
                              return AppCard(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    Expanded(child: Text(student,
                                        style: const TextStyle(fontWeight: FontWeight.w600))),
                                    if (status == 'graded')
                                      Text('$score pts',
                                          style: const TextStyle(fontWeight: FontWeight.bold,
                                              color: AppTheme.primary)),
                                  ]),
                                  const SizedBox(height: 4),
                                  Text(exam, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                                  if (date.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(date, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                  ],
                                  const SizedBox(height: 10),
                                  if (status != 'graded')
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () => _showGradeDialog(s),
                                        icon: const Icon(Icons.grading, size: 16),
                                        label: const Text('Grade'),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          textStyle: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    )
                                  else
                                    Row(children: [
                                      const Icon(Icons.check_circle, color: AppTheme.success, size: 14),
                                      const SizedBox(width: 4),
                                      Text('Graded: ${s['feedback'] ?? ''}',
                                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                          maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ]),
                                ]),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
