// lib/screens/notification_screen.dart

import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:muj_drive/services/token_storage.dart';
import 'package:muj_drive/theme/app_theme.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  static const _baseUrl = 'https://mujdriveride.shivamrajdubey.tech';
  late List<Map<String, String>> _notifications;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _notifications = [];
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    final token = await TokenStorage.readToken();
    if (token == null) return;
    setState(() => _loading = true);

    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/notifications'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final list = (body['notifications'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>()
            .map((n) => {
                  'id':       n['_id'].toString(),
                  'title':    (n['title']    ?? '').toString(),
                  'subtitle': (n['subtitle'] ?? n['message'] ?? '').toString(),
                })
            .toList();
        setState(() {
          _notifications = List<Map<String, String>>.from(list);
        });
      }
    } catch (_) {
      // silently ignore
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Mark a single notification read (swipe-to-remove)
  Future<void> _markRead(String id) async {
    final token = await TokenStorage.readToken();
    if (token == null) return;
    // optimistically remove from UI
    setState(() {
      _notifications.removeWhere((n) => n['id'] == id);
    });
    // fire the backend call
    await http.put(
      Uri.parse('$_baseUrl/notifications/$id/read'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  /// Mark *all* notifications read
  Future<void> _markAllRead() async {
    final token = await TokenStorage.readToken();
    if (token == null) return;
    // snapshot the IDs first
    final ids = _notifications.map((n) => n['id']!).toList();
    // call mark-read for each
    for (final id in ids) {
      await http.put(
        Uri.parse('$_baseUrl/notifications/$id/read'),
        headers: {'Authorization': 'Bearer $token'},
      );
    }
    // then clear UI
    setState(() {
      _notifications.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: AppTheme.primary.withOpacity(0.9),
        title: const Text('Notifications'),
        centerTitle: true,
        elevation: 4,
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: const Text(
              'Mark all read',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primary, AppTheme.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.only(
          top: kToolbarHeight + 24,
          left: 16,
          right: 16,
          bottom: 16,
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _notifications.isEmpty
                ? Center(
                    child: Text(
                      'No notifications',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  )
                : ListView.separated(
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = _notifications[index];
                      final rawTitle    = item['title']    ?? '';
                      final rawSubtitle = item['subtitle'] ?? '';
                      // fallback: if title is empty, show subtitle as title
                      final displayTitle    =
                          rawTitle.isNotEmpty ? rawTitle : rawSubtitle;
                      final displaySubtitle =
                          rawTitle.isNotEmpty ? rawSubtitle : '';

                      return Dismissible(
                        key: ValueKey(item['id']),
                        direction: DismissDirection.startToEnd,
                        onDismissed: (_) => _markRead(item['id']!),
                        background: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter:
                                ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                color:
                                    Colors.white.withOpacity(0.15),
                                borderRadius:
                                    BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          Colors.white.withOpacity(0.25),
                                    ),
                                    child: const Icon(
                                      Icons.notifications_active,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          displayTitle,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (displaySubtitle.isNotEmpty)
                                          ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              displaySubtitle,
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
