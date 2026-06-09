import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../widgets/common_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get(AppConstants.profileEndpoint);
      final profile = res['profile'] ?? res['user'] ?? res;
      setState(() {
        _profile = profile is Map ? profile as Map<String, dynamic> : {};
        _nameCtrl.text = _profile?['full_name'] ?? _profile?['name'] ?? '';
        _phoneCtrl.text = _profile?['phone'] ?? '';
        _bioCtrl.text = _profile?['bio'] ?? '';
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      await ApiService.put('/user/profile', {
        'full_name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
      });
      await context.read<AuthProvider>().refreshProfile();
      setState(() { _editing = false; _saving = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated'), backgroundColor: AppTheme.success),
        );
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          if (!_editing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _editing = true),
            )
          else ...[
            TextButton(
              onPressed: () => setState(() => _editing = false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: _saving ? null : _saveProfile,
              child: _saving
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
      body: _loading
          ? const LoadingWidget()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundImage: _profile?['avatar_url'] != null
                            ? NetworkImage(_profile!['avatar_url'])
                            : null,
                        backgroundColor: AppTheme.primary.withOpacity(0.15),
                        child: _profile?['avatar_url'] == null
                            ? Text(
                                (user?.name ?? 'U').isNotEmpty
                                    ? (user?.name ?? 'U')[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                    fontSize: 36,
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(user?.name ?? 'User',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(user?.email ?? '',
                          style: const TextStyle(color: AppTheme.textSecondary)),
                      const SizedBox(height: 8),
                      if (user != null) RoleBadge(role: user.role),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _SectionCard(
                  title: 'Personal Information',
                  children: [
                    _ProfileField(label: 'Full Name', controller: _nameCtrl, enabled: _editing, icon: Icons.person_outline),
                    _ProfileField(label: 'Phone', controller: _phoneCtrl, enabled: _editing, icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
                    _ProfileField(label: 'Bio', controller: _bioCtrl, enabled: _editing, icon: Icons.info_outline, maxLines: 3),
                  ],
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Account Details',
                  children: [
                    _StaticField(label: 'Email', value: user?.email ?? '', icon: Icons.email_outlined),
                    _StaticField(label: 'Role', value: user?.role ?? '', icon: Icons.badge_outlined),
                    _StaticField(
                        label: 'Status',
                        value: user?.isApproved == true ? 'Active' : 'Pending',
                        icon: Icons.circle,
                        valueColor: user?.isApproved == true ? AppTheme.success : AppTheme.warning),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    await context.read<AuthProvider>().logout();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.error,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(title,
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textSecondary, fontSize: 12)),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;

  const _ProfileField({
    required this.label,
    required this.controller,
    required this.enabled,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        const SizedBox(height: 4),
        enabled
            ? TextField(
                controller: controller,
                keyboardType: keyboardType,
                maxLines: maxLines,
                decoration: InputDecoration(
                  prefixIcon: Icon(icon, size: 18),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              )
            : Row(children: [
                Icon(icon, size: 18, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Expanded(child: Text(controller.text.isEmpty ? '—' : controller.text,
                    style: const TextStyle(fontSize: 15))),
              ]),
      ]),
    );
  }
}

class _StaticField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _StaticField({required this.label, required this.value, required this.icon, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          Text(value, style: TextStyle(fontSize: 15, color: valueColor)),
        ])),
      ]),
    );
  }
}