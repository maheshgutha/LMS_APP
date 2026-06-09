import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';
import '../../widgets/common_widgets.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<dynamic> _users = [];
  List<dynamic> _filtered = [];
  bool _loading = true;
  String? _error;
  final _searchCtrl = TextEditingController();
  String _roleFilter = 'all';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.get('/admin/users');
      final users = res is List ? res : (res['users'] ?? res['data'] ?? []);
      setState(() { _users = users; _filtered = users; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); _loading = false; });
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _users.where((u) {
        final name = (u['profile']?['full_name'] ?? u['name'] ?? u['email'] ?? '').toString().toLowerCase();
        final email = (u['email'] ?? '').toString().toLowerCase();
        final role = (u['role'] ?? '').toString().toLowerCase();
        final matchesQuery = q.isEmpty || name.contains(q) || email.contains(q);
        final matchesRole = _roleFilter == 'all' || role == _roleFilter;
        return matchesQuery && matchesRole;
      }).toList();
    });
  }

  Future<void> _updateRole(String userId, String newRole) async {
    try {
      await ApiService.put('/admin/update-user-role', {'userId': userId, 'role': newRole});
      _fetchUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Role updated'), backgroundColor: AppTheme.success),
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

  Future<void> _toggleStatus(String userId, bool currentStatus) async {
    try {
      await ApiService.put('/admin/update-user-status', {
        'userId': userId,
        'is_approved': !currentStatus,
      });
      _fetchUsers();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchUsers),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: CustomSearchBar(
              controller: _searchCtrl,
              hint: 'Search users...',
              onChanged: (_) => _applyFilter(),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: ['all', 'student', 'intern', 'instructor', 'manager', 'admin']
                  .map((r) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(r.toUpperCase(), style: const TextStyle(fontSize: 11)),
                          selected: _roleFilter == r,
                          selectedColor: AppTheme.primary,
                          labelStyle: TextStyle(
                              color: _roleFilter == r ? Colors.white : AppTheme.textSecondary),
                          onSelected: (_) {
                            setState(() => _roleFilter = r);
                            _applyFilter();
                          },
                        ),
                      ))
                  .toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text('${_filtered.length} users',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const LoadingWidget(message: 'Loading users...')
                : _error != null
                    ? ErrorWidget2(message: _error!, onRetry: _fetchUsers)
                    : _filtered.isEmpty
                        ? const EmptyState(title: 'No users found', icon: Icons.person_off_outlined)
                        : RefreshIndicator(
                            onRefresh: _fetchUsers,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: _filtered.length,
                              itemBuilder: (ctx, i) => _UserCard(
                                user: _filtered[i],
                                onRoleChange: (role) => _updateRole(_filtered[i]['_id'], role),
                                onToggleStatus: () => _toggleStatus(
                                    _filtered[i]['_id'], _filtered[i]['is_approved'] ?? false),
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final ValueChanged<String> onRoleChange;
  final VoidCallback onToggleStatus;

  const _UserCard({required this.user, required this.onRoleChange, required this.onToggleStatus});

  @override
  Widget build(BuildContext context) {
    final profile = user['profile'] as Map<String, dynamic>?;
    final name = profile?['full_name'] ?? user['name'] ?? user['email'] ?? 'Unknown';
    final email = user['email'] ?? '';
    final role = user['role'] ?? 'student';
    final approved = user['is_approved'] ?? false;
    final avatar = profile?['avatar_url'];

    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundImage: avatar != null ? NetworkImage(avatar) : null,
            backgroundColor: AppTheme.primary.withOpacity(0.15),
            child: avatar == null
                ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(email,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    RoleBadge(role: role),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: approved
                            ? AppTheme.success.withOpacity(0.12)
                            : AppTheme.error.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        approved ? 'Active' : 'Pending',
                        style: TextStyle(
                          color: approved ? AppTheme.success : AppTheme.error,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'toggle', child: Text('Toggle Status')),
              const PopupMenuDivider(),
              ...['student', 'intern', 'instructor', 'manager', 'admin'].map(
                (r) => PopupMenuItem(value: 'role:$r', child: Text('Set as $r')),
              ),
            ],
            onSelected: (val) {
              if (val == 'toggle') {
                onToggleStatus();
              } else if (val.startsWith('role:')) {
                onRoleChange(val.substring(5));
              }
            },
          ),
        ],
      ),
    );
  }
}
