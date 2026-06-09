import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';
import '../../widgets/common_widgets.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<dynamic> _conversations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/chat/conversations');
      final list = res is List ? res : (res['conversations'] ?? res['data'] ?? []);
      setState(() { _conversations = list; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch),
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const NewChatScreen())),
          ),
        ],
      ),
      body: _loading
          ? const LoadingWidget()
          : _conversations.isEmpty
              ? const EmptyState(title: 'No messages yet', icon: Icons.chat_bubble_outline,
                  subtitle: 'Start a conversation with a student or instructor')
              : ListView.builder(
                  itemCount: _conversations.length,
                  itemBuilder: (_, i) {
                    final c = _conversations[i];
                    final participants = (c['participants'] as List?) ?? [];
                    final others = participants.where((p) => true).toList();
                    final name = others.isNotEmpty
                        ? (others[0]['profile']?['full_name'] ?? others[0]['email'] ?? 'User')
                        : 'Conversation';
                    final lastMsg = c['last_message'] ?? '';
                    final unread = c['unread_count'] ?? 0;
                    final time = c['updated_at'] != null
                        ? DateFormat('HH:mm').format(DateTime.tryParse(c['updated_at']) ?? DateTime.now())
                        : '';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primary.withOpacity(0.15),
                        child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U',
                            style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13)),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(time, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                          if (unread > 0) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                              child: Text('$unread',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ChatDetailScreen(
                          conversationId: c['_id'],
                          recipientName: name,
                        )),
                      ),
                    );
                  },
                ),
    );
  }
}

class ChatDetailScreen extends StatefulWidget {
  final String conversationId;
  final String recipientName;
  const ChatDetailScreen({super.key, required this.conversationId, required this.recipientName});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  List<dynamic> _messages = [];
  bool _loading = true;
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() { super.initState(); _fetch(); }

  @override
  void dispose() { _msgCtrl.dispose(); _scrollCtrl.dispose(); super.dispose(); }

  Future<void> _fetch() async {
    try {
      final res = await ApiService.get('/chat/messages/${widget.conversationId}');
      final list = res is List ? res : (res['messages'] ?? res['data'] ?? []);
      setState(() { _messages = list; _loading = false; });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
        }
      });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _send() async {
    final msg = _msgCtrl.text.trim();
    if (msg.isEmpty) return;
    _msgCtrl.clear();
    try {
      await ApiService.post('/chat/send', {
        'conversation_id': widget.conversationId,
        'content': msg,
        'type': 'text',
      });
      _fetch();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.recipientName)),
      body: Column(children: [
        Expanded(
          child: _loading
              ? const LoadingWidget()
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) {
                    final m = _messages[i];
                    final isMe = m['is_mine'] ?? false;
                    final content = m['content'] ?? '';
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isMe ? AppTheme.primary : AppTheme.border,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(content,
                            style: TextStyle(color: isMe ? Colors.white : AppTheme.textPrimary)),
                      ),
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            border: Border(top: BorderSide(color: AppTheme.border)),
          ),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _msgCtrl,
              decoration: const InputDecoration(hintText: 'Type a message...', border: InputBorder.none),
              onSubmitted: (_) => _send(),
            )),
            IconButton(icon: const Icon(Icons.send, color: AppTheme.primary), onPressed: _send),
          ]),
        ),
      ]),
    );
  }
}

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});
  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  List<dynamic> _contacts = [];
  bool _loading = true;
  final _search = TextEditingController();
  List<dynamic> _filtered = [];

  @override
  void initState() { super.initState(); _fetch(); _search.addListener(_filter); }
  @override
  void dispose() { _search.dispose(); super.dispose(); }

  Future<void> _fetch() async {
    try {
      final res = await ApiService.get('/chat/contacts');
      final list = res is List ? res : (res['contacts'] ?? res['data'] ?? []);
      setState(() { _contacts = list; _filtered = list; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  void _filter() {
    final q = _search.text.toLowerCase();
    setState(() {
      _filtered = _contacts.where((c) =>
          (c['profile']?['full_name'] ?? c['email'] ?? '').toString().toLowerCase().contains(q)).toList();
    });
  }

  Future<void> _startChat(String userId) async {
    try {
      final res = await ApiService.post('/chat/start', {'recipient_id': userId});
      if (mounted) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChatDetailScreen(
            conversationId: res['conversation_id'] ?? res['_id'] ?? '',
            recipientName: 'Chat',
          )),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Message')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: CustomSearchBar(controller: _search, hint: 'Search contacts...', onChanged: (_) => _filter()),
        ),
        Expanded(
          child: _loading
              ? const LoadingWidget()
              : ListView.builder(
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) {
                    final c = _filtered[i];
                    final name = c['profile']?['full_name'] ?? c['email'] ?? 'User';
                    final role = c['role'] ?? '';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primary.withOpacity(0.15),
                        child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U',
                            style: const TextStyle(color: AppTheme.primary)),
                      ),
                      title: Text(name),
                      subtitle: Text(role),
                      onTap: () => _startChat(c['_id']),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
