import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../widgets/common_widgets.dart';
import '../../utils/theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _data = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getData('notifications',
          queryParams: {'limit': '50', 'sort': '-created_at'});
      final list = res is List ? res : (res['data'] ?? []);
      setState(() { _data = list; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch),
      ]),
      body: _loading
          ? const LoadingWidget()
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
