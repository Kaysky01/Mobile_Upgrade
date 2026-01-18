import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'dashboard_screen.dart';
import 'reports_screen.dart';
import 'more_menu_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const String BASE_URL = 'http://192.168.100.24:8000/api/v1';

  int _selectedIndex = 2;
  bool _isLoading = true;
  List<NotificationItem> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  // ================= FETCH NOTIFICATIONS =================
  Future<void> _fetchNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/notifications'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        setState(() {
          _notifications =
              data.map((e) => NotificationItem.fromJson(e)).toList();
          _notifications.sort(
              (a, b) => b.timestamp.compareTo(a.timestamp));
          _isLoading = false;
        });
      } else {
        debugPrint('Gagal load: ${response.body}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error: $e');
      setState(() => _isLoading = false);
    }
  }

  // ================= MARK ALL READ =================
  Future<void> _markAllReadAPI() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    await http.post(
      Uri.parse('$BASE_URL/notifications/read'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  int get _unreadCount =>
      _notifications.where((n) => !n.isRead).length;

  void _markAllAsRead() {
    setState(() {
      for (var n in _notifications) {
        n.isRead = true;
      }
    });
    _markAllReadAPI();
  }

  @override
  Widget build(BuildContext context) {
    final recent = _notifications
        .where((n) =>
            DateTime.now().difference(n.timestamp).inHours < 24)
        .toList();
    final older = _notifications
        .where((n) =>
            DateTime.now().difference(n.timestamp).inHours >= 24)
        .toList();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          _header(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchNotifications,
                    child: _notifications.isEmpty
                        ? const Center(
                            child: Text('Tidak ada notifikasi'))
                        : ListView(
                            // 🔥 FIX NAVBAR HILANG
                            padding: const EdgeInsets.fromLTRB(
                                16, 16, 16, 90),
                            children: [
                              if (recent.isNotEmpty) ...[
                                _section('Terbaru'),
                                ...recent.map(_card),
                              ],
                              if (older.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                _section('Sebelumnya'),
                                ...older.map(_card),
                              ],
                            ],
                          ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  // ================= UI =================
  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient:
            LinearGradient(colors: [Color(0xFF1453A3), Color(0xFF2E78D4)]),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notifikasi',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _unreadCount > 0
                        ? '$_unreadCount belum dibaca'
                        : 'Semua dibaca',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            if (_unreadCount > 0)
              IconButton(
                icon:
                    const Icon(Icons.done_all, color: Colors.white),
                onPressed: _markAllAsRead,
              ),
          ],
        ),
      ),
    );
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 12),
        child: Text(
          t,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600),
        ),
      );

  Widget _card(NotificationItem n) {
    final c = n.color;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: n.isRead ? Colors.white : c.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.withOpacity(0.25)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: c.withOpacity(0.2),
          child: Icon(n.icon, color: c),
        ),
        title: Text(n.sender,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(n.message,
            maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Text(_time(n.timestamp),
            style: const TextStyle(fontSize: 11)),
        onTap: () => setState(() => n.isRead = true),
      ),
    );
  }

  Widget _bottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (i) {
        if (i == _selectedIndex) return;
        if (i == 0) {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => const DashboardScreen()));
        } else if (i == 1) {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => const ReportsScreen()));
        } else if (i == 3) {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => const MoreMenuScreen()));
        }
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF1453A3),
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.home), label: 'Beranda'),
        BottomNavigationBarItem(
            icon: Icon(Icons.file_copy), label: 'Laporan'),
        BottomNavigationBarItem(
            icon: Icon(Icons.notifications), label: 'Notifikasi'),
        BottomNavigationBarItem(
            icon: Icon(Icons.menu), label: 'Lainnya'),
      ],
    );
  }

  String _time(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'Baru saja';
    if (d.inMinutes < 60) return '${d.inMinutes} menit lalu';
    if (d.inHours < 24) return '${d.inHours} jam lalu';
    return '${t.day}/${t.month}/${t.year}';
  }
}

// ================= MODEL =================
class NotificationItem {
  final int id;
  final String sender;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.sender,
    required this.message,
    required this.timestamp,
    required this.type,
    required this.isRead,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> j) {
    return NotificationItem(
      id: j['id'],
      sender:
          (j['sender_role'] ?? 'SISTEM').toString().toUpperCase(),
      message: j['message'] ?? '',
      timestamp: DateTime.parse(j['created_at']),
      isRead: j['is_read'] == 1,
      type: _map(j['status']),
    );
  }

  static NotificationType _map(String? s) {
    switch (s) {
      case 'approved':
        return NotificationType.approved;
      case 'pending':
        return NotificationType.pending;
      case 'processing':
        return NotificationType.processing;
      case 'rejected':
        return NotificationType.rejected;
      default:
        return NotificationType.info;
    }
  }

  Color get color {
    switch (type) {
      case NotificationType.approved:
        return Colors.green;
      case NotificationType.pending:
      case NotificationType.processing:
        return Colors.orange;
      case NotificationType.rejected:
        return Colors.red;
      default:
        return Colors.purple;
    }
  }

  IconData get icon {
    switch (type) {
      case NotificationType.approved:
        return Icons.check_circle;
      case NotificationType.pending:
        return Icons.access_time;
      case NotificationType.processing:
        return Icons.autorenew;
      case NotificationType.rejected:
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }
}

enum NotificationType {
  approved,
  pending,
  processing,
  rejected,
  info
}
