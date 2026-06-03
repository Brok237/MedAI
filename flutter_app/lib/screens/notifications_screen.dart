// lib/screens/notifications_screen.dart
import 'package:flutter/material.dart';
import '../models/case_model.dart';
import '../services/notification_service.dart';
import '../app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override State<NotificationsScreen> createState() => _State();
}

class _State extends State<NotificationsScreen> {
  List<NotificationModel> _notifs = [];
  bool _loading = true;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { _notifs = await NotificationService.fetchAll(); } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _markAllRead() async {
    await NotificationService.markAllRead();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final unread = _notifs.where((n) => !n.isRead).length;
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Row(children: [
          const Text('Notifications'),
          if (unread > 0) ...[
            const SizedBox(width: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
              child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
          ],
        ]),
        backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
        actions: [
          if (unread > 0)
            TextButton(onPressed: _markAllRead,
                child: const Text('Mark all read', style: TextStyle(color: Colors.white70, fontSize: 12))),
        ],
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _notifs.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.notifications_none, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text('No notifications yet', style: TextStyle(color: Colors.grey[500], fontSize: 18)),
            ]))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                itemCount: _notifs.length,
                itemBuilder: (_, i) => _NotifTile(_notifs[i], onTap: () {
                  if (!_notifs[i].isRead) {
                    NotificationService.markOneRead(_notifs[i].id).then((_) => _load());
                  }
                }),
              ),
            ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final NotificationModel n;
  final VoidCallback onTap;
  const _NotifTile(this.n, {required this.onTap});

  IconData get _icon {
    switch (n.type) {
      case 'case_approved':    return Icons.check_circle;
      case 'case_rejected':    return Icons.cancel;
      case 'case_submitted':   return Icons.inbox;
      case 'doctor_approved':  return Icons.verified;
      case 'new_doctor':       return Icons.person_add;
      default:                 return Icons.notifications;
    }
  }

  Color get _color {
    switch (n.type) {
      case 'case_approved':   return Colors.green;
      case 'case_rejected':   return Colors.red;
      case 'doctor_approved': return Colors.green;
      case 'new_doctor':      return Colors.orange;
      default:                return AppTheme.primaryBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: n.isRead ? null : _color.withOpacity(0.04),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 44, height: 44,
            decoration: BoxDecoration(color: _color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(_icon, color: _color, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(n.title,
                  style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold,
                      fontSize: 14, color: AppTheme.textDark))),
              if (!n.isRead)
                Container(width: 8, height: 8,
                    decoration: BoxDecoration(color: _color, shape: BoxShape.circle)),
            ]),
            const SizedBox(height: 4),
            Text(n.message, style: const TextStyle(fontSize: 13, color: AppTheme.textGrey)),
            const SizedBox(height: 4),
            Text(_formatTime(n.createdAt), style: const TextStyle(fontSize: 11, color: AppTheme.textLight)),
          ])),
        ]),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
