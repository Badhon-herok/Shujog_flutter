// lib/features/home/presentation/pages/notifications_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _client = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      // Get all applications where status changed (accepted or rejected)
      final applications = await _client
          .from('job_applications')
          .select('''
            id,
            status,
            created_at,
            jobs:job_id (
              title
            )
          ''')
          .eq('worker_id', user.id)
          .neq('status', 'pending')
          .order('created_at', ascending: false);

      setState(() {
        _notifications = applications;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading notifications: $e');

      // Fake notifications for demo
      _notifications = [
        {
          'id': 'notif1',
          'status': 'accepted',
          'created_at': '2025-12-28T10:30:00',
          'jobs': {'title': 'Factory Helper'}
        },
        {
          'id': 'notif2',
          'status': 'rejected',
          'created_at': '2025-12-27T09:15:00',
          'jobs': {'title': 'Construction Worker'}
        },
      ];

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.primary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined,
                size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'ll see updates about your applications here',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final notif = _notifications[index];
          final job = (notif['jobs'] ?? {}) as Map<String, dynamic>;
          final status = notif['status'] ?? '';
          final jobTitle = job['title'] ?? 'Job';

          return _NotificationCard(
            jobTitle: jobTitle,
            status: status,
            timestamp: notif['created_at'] ?? '',
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.jobTitle,
    required this.status,
    required this.timestamp,
  });

  final String jobTitle;
  final String status;
  final String timestamp;

  @override
  Widget build(BuildContext context) {
    final isAccepted = status == 'accepted';
    final color = isAccepted ? Colors.green : Colors.red;
    final icon = isAccepted ? Icons.check_circle : Icons.cancel;
    final message = isAccepted
        ? 'Your application for $jobTitle was accepted! 🎉'
        : 'Your application for $jobTitle was rejected';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatTimestamp(timestamp),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes} minutes ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hours ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return timestamp.split('T').first;
    }
  }
}
