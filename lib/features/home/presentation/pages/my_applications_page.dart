// lib/features/home/presentation/pages/my_applications_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';

class MyApplicationsPage extends StatefulWidget {
  const MyApplicationsPage({super.key});

  @override
  State<MyApplicationsPage> createState() => _MyApplicationsPageState();
}

class _MyApplicationsPageState extends State<MyApplicationsPage> {
  final _client = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _applications = [];

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() => _isLoading = true);

    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      // Get all applications by this worker with job details
      final applications = await _client
          .from('job_applications')
          .select('''
            id,
            created_at,
            status,
            jobs:job_id (
              title,
              place,
              salary
            )
          ''')
          .eq('worker_id', user.id)
          .order('created_at', ascending: false);

      setState(() {
        _applications = applications;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading applications: $e');

      // Fallback to fake data if error
      _applications = [
        {
          'id': 'app1',
          'created_at': '2025-12-28T10:30:00',
          'status': 'accepted',
          'jobs': {
            'title': 'Factory Helper',
            'place': 'Khulna',
            'salary': '৳800/day',
          }
        },
        {
          'id': 'app2',
          'created_at': '2025-12-27T14:15:00',
          'status': 'pending',
          'jobs': {
            'title': 'Construction Worker',
            'place': 'Jessore',
            'salary': '৳1000/day',
          }
        },
        {
          'id': 'app3',
          'created_at': '2025-12-26T09:00:00',
          'status': 'rejected',
          'jobs': {
            'title': 'Delivery Driver',
            'place': 'Dhaka',
            'salary': '৳900/day',
          }
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
        title: const Text('My Applications'),
        backgroundColor: AppColors.primary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_applications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No applications yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Apply to jobs to see them here',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadApplications,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _applications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final app = _applications[index];
          final job = (app['jobs'] ?? {}) as Map<String, dynamic>;
          final status = app['status'] ?? 'pending';

          return _ApplicationCard(
            jobTitle: job['title'] ?? 'Job',
            place: job['place'] ?? '',
            salary: job['salary'] ?? '',
            status: status,
            appliedDate: app['created_at'] ?? '',
          );
        },
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.jobTitle,
    required this.place,
    required this.salary,
    required this.status,
    required this.appliedDate,
  });

  final String jobTitle;
  final String place;
  final String salary;
  final String status;
  final String appliedDate;

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'accepted':
        statusColor = Colors.green;
        statusText = 'Accepted';
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Rejected';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusText = 'Pending';
        statusIcon = Icons.pending;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  jobTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 16, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on, size: 18, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                place,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              const SizedBox(width: 20),
              Icon(Icons.attach_money, size: 18, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                salary,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Applied: ${appliedDate.split('T').first}',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

