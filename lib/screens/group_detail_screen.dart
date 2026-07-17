import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

class GroupDetailScreen extends StatefulWidget {
  final Map<String, dynamic> group;

  const GroupDetailScreen({Key? key, required this.group}) : super(key: key);

  @override
  State<GroupDetailScreen> createState() => GroupDetailScreenState();
}

class GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {

  int selectedTab = 0;
  List<Map<String, dynamic>> messages = [];
  List<Map<String, dynamic>> members = [];
  bool loadingMessages = true;
  bool sendingMessage = false;

  final messageController = TextEditingController();
  final scrollController = ScrollController();

  late TabController tabController;
  RealtimeChannel? realtimeChannel;

  String? currentUserName;
  String? currentUserAvatar;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    tabController.addListener(() {
      setState(() => selectedTab = tabController.index);
      if (tabController.index == 1) loadMembers();
    });
    loadCurrentUser();
    loadMessages();
    subscribeToMessages();
  }

  @override
  void dispose() {
    tabController.dispose();
    messageController.dispose();
    scrollController.dispose();
    realtimeChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> loadCurrentUser() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final member = await Supabase.instance.client
          .from('group_members')
          .select()
          .eq('group_id', widget.group['id'])
          .eq('user_id', user.id)
          .maybeSingle();
      if (mounted && member != null) {
        setState(() {
          currentUserName = '${member['first_name']} ${member['last_name']}';
          currentUserAvatar = member['avatar_url'];
        });
      }
    } catch (e) {
      debugPrint('loadCurrentUser error: $e');
    }
  }

  Future<void> loadMessages() async {
    try {
      final data = await Supabase.instance.client
          .from('group_messages')
          .select()
          .eq('group_id', widget.group['id'])
          .order('created_at', ascending: true)
          .limit(100);
      if (mounted) {
        setState(() {
          messages = List<Map<String, dynamic>>.from(data);
          loadingMessages = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => scrollToBottom());
      }
    } catch (e) {
      debugPrint('loadMessages error: $e');
      if (mounted) setState(() => loadingMessages = false);
    }
  }

  Future<void> loadMembers() async {
    try {
      final data = await Supabase.instance.client
          .from('group_members')
          .select()
          .eq('group_id', widget.group['id'])
          .order('joined_at', ascending: true);
      if (mounted) {
        setState(() => members = List<Map<String, dynamic>>.from(data));
      }
    } catch (e) {
      debugPrint('loadMembers error: $e');
    }
  }

  void subscribeToMessages() {
    realtimeChannel = Supabase.instance.client
        .channel('group_${widget.group['id']}')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'group_messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'group_id',
        value: widget.group['id'],
      ),
      callback: (payload) {
        if (!mounted) return;
        final newMsg = Map<String, dynamic>.from(payload.newRecord);
        // only add if not already in list
        final exists = messages.any((m) => m['id'] == newMsg['id']);
        if (!exists) {
          setState(() => messages.add(newMsg));
          WidgetsBinding.instance.addPostFrameCallback((_) => scrollToBottom());
        }
      },
    ).subscribe();
  }

  void scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    messageController.clear();
    setState(() => sendingMessage = true);

    try {
      await Supabase.instance.client.from('group_messages').insert({
        'group_id':      widget.group['id'],
        'user_id':       user.id,
        'sender_name':   currentUserName ?? 'Anonymous',
        'sender_avatar': currentUserAvatar,
        'message':       text,
      });
      // reload messages after send
      await loadMessages();
    } catch (e) {
      if (mounted) {
        messageController.text = text;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ));
      }
    } finally {
      if (mounted) setState(() => sendingMessage = false);
    }
  }

  bool isMe(Map<String, dynamic> msg) {
    final user = Supabase.instance.client.auth.currentUser;
    return user != null && msg['user_id'] == user.id;
  }

  String formatTime(String? isoDate) {
    if (isoDate == null) return '';
    final dt = DateTime.parse(isoDate).toLocal();
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.surface,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: c.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c.divider),
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded, color: c.white, size: 16),
          ),
        ),
        title: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: c.greenDim, borderRadius: BorderRadius.circular(10)),
            child: Center(
              child: Text(
                widget.group['name']?.isNotEmpty == true
                    ? widget.group['name'][0].toUpperCase() : 'G',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: c.green),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.group['name'] ?? '',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.white),
                  overflow: TextOverflow.ellipsis),
              Text('${messages.length} messages',
                  style: TextStyle(fontSize: 11, color: c.subtext)),
            ]),
          ),
        ]),
        actions: [
          GestureDetector(
            onTap: loadMessages,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(Icons.refresh_rounded, color: c.subtext, size: 22),
            ),
          ),
        ],
        bottom: TabBar(
          controller: tabController,
          labelColor: c.green,
          unselectedLabelColor: c.subtext,
          indicatorColor: c.green,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
          tabs: const [Tab(text: 'Chat'), Tab(text: 'Leaderboard')],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          // chat tab
          Column(children: [
            Expanded(
              child: loadingMessages && messages.isEmpty
                  ? Center(child: CircularProgressIndicator(color: c.green))
                  : messages.isEmpty
                  ? Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('💬', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text('No messages yet',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.white)),
                  const SizedBox(height: 4),
                  Text('Be the first to say something!',
                      style: TextStyle(fontSize: 13, color: c.subtext)),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: loadMessages,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(color: c.greenDim, borderRadius: BorderRadius.circular(12)),
                      child: Text('Refresh', style: TextStyle(color: c.green, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ]),
              )
                  : ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final mine = isMe(msg);
                  final showName = !mine &&
                      (index == 0 || messages[index - 1]['user_id'] != msg['user_id']);
                  return MessageBubble(
                      message: msg, isMe: mine, showName: showName,
                      time: formatTime(msg['created_at']));
                },
              ),
            ),

            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
              decoration: BoxDecoration(
                color: c.surface,
                boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.05), blurRadius: 10,
                    offset: const Offset(0, -2))],
              ),
              child: Row(children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: c.surfaceAlt,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: c.divider),
                    ),
                    child: TextField(
                      controller: messageController,
                      maxLines: null,
                      style: TextStyle(fontSize: 14, color: c.white),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(fontSize: 14, color: c.subtext),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                      onSubmitted: (_) => sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: sendingMessage ? null : sendMessage,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: c.green, shape: BoxShape.circle,
                      boxShadow: [BoxShadow(
                          color: c.green.withOpacity(0.3), blurRadius: 10,
                          offset: const Offset(0, 3))],
                    ),
                    child: sendingMessage
                        ? const Center(child: SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ]),
            ),
          ]),

          // leaderboard tab
          members.isEmpty
              ? Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              CircularProgressIndicator(color: c.green),
              const SizedBox(height: 12),
              Text('Loading members...', style: TextStyle(color: c.subtext, fontSize: 13)),
            ]),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              final name = '${member['first_name']} ${member['last_name']}';
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 300 + (index * 60)),
                curve: Curves.easeOut,
                builder: (context, val, child) => Opacity(
                    opacity: val,
                    child: Transform.translate(
                        offset: Offset(0, 15 * (1 - val)), child: child)),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: c.divider),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.04), blurRadius: 8,
                        offset: const Offset(0, 2))],
                  ),
                  child: Row(children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: index == 0
                            ? const Color(0xFFF59E0B).withOpacity(0.15)
                            : index == 1 ? c.surfaceAlt
                            : index == 2 ? const Color(0xFFF97316).withOpacity(0.15)
                            : c.surfaceAlt,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          index == 0 ? '🥇' : index == 1 ? '🥈' : index == 2 ? '🥉' : '${index + 1}',
                          style: TextStyle(
                              fontSize: index < 3 ? 16 : 13,
                              fontWeight: FontWeight.w700, color: c.subtext),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    MemberAvatar(name: name, avatarUrl: member['avatar_url'], size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(name, style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600, color: c.white)),
                        Text('Member', style: TextStyle(fontSize: 12, color: c.subtext)),
                      ]),
                    ),
                  ]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isMe;
  final bool showName;
  final String time;

  const MessageBubble({Key? key, required this.message, required this.isMe,
    required this.showName, required this.time}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final name = message['sender_name'] ?? 'Unknown';
    final text = message['message'] ?? '';
    final avatarUrl = message['sender_avatar'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            MemberAvatar(name: name, avatarUrl: avatarUrl, size: 32),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (showName && !isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 4),
                    child: Text(name, style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600, color: c.subtext)),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? c.green : c.surfaceAlt,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.05), blurRadius: 6,
                        offset: const Offset(0, 2))],
                  ),
                  child: Text(text, style: TextStyle(
                      fontSize: 14,
                      color: isMe ? Colors.white : c.white,
                      height: 1.4)),
                ),
                const SizedBox(height: 3),
                Text(time, style: TextStyle(fontSize: 10, color: c.subtext)),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class MemberAvatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final double size;

  const MemberAvatar({Key? key, required this.name, required this.avatarUrl,
    required this.size}) : super(key: key);

  Color get color {
    final colors = [
      const Color(0xFF3B82F6), const Color(0xFF10B981), const Color(0xFFF59E0B),
      const Color(0xFFEF4444), const Color(0xFF8B5CF6)
    ];
    return colors[name.length % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.15),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        image: avatarUrl != null
            ? DecorationImage(image: NetworkImage(avatarUrl!), fit: BoxFit.cover)
            : null,
      ),
      child: avatarUrl == null
          ? Center(child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
              fontSize: size * 0.38, fontWeight: FontWeight.w800, color: color)))
          : null,
    );
  }
}