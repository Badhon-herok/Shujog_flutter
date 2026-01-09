// lib/features/home/presentation/pages/employer_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../widgets/rate_worker_dialog.dart';
import 'view_worker_profile_page.dart';
import 'employer_settings_page.dart';


class EmployerDashboardPage extends StatefulWidget {
  const EmployerDashboardPage({super.key});

  @override
  State<EmployerDashboardPage> createState() => _EmployerDashboardPageState();
}

class _EmployerDashboardPageState extends State<EmployerDashboardPage> {
  final _client = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _applicationsFuture;
  String _userName = 'Employer';

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _applicationsFuture = _loadApplications();
  }

  Future<void> _loadUserName() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      final metadata = user.userMetadata;
      if (metadata != null && metadata['name'] != null) {
        setState(() {
          _userName = metadata['name'] as String;
        });
        return;
      }

      final response = await _client
          .from('users')
          .select('name')
          .eq('id', user.id)
          .single();

      setState(() {
        _userName = response['name'] as String? ?? 'Employer';
      });
    } catch (e) {
      debugPrint('Error loading user name: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _loadApplications() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    try {
      // Get all jobs posted by this employer
      final employerJobs = await _client
          .from('jobs')
          .select('id')
          .eq('employer_id', user.id);

      if (employerJobs.isEmpty) {
        debugPrint('No jobs found for employer');
        return [];
      }

      // Get job IDs
      final jobIds = employerJobs.map((job) => job['id'] as String).toList();

      // Get all applications for these jobs with job details
      final applications = await _client
          .from('job_applications')
          .select('''
            id,
            created_at,
            worker_id,
            status,
            job_id,
            jobs:job_id (
              title,
              place,
              salary,
              type
            )
          ''')
          .inFilter('job_id', jobIds)
          .order('created_at', ascending: false);

      // Get worker IDs
      final workerIds = applications
          .map((app) => app['worker_id'] as String)
          .toSet()
          .toList();

      // Fetch all worker names in one query
      final workers = await _client
          .from('users')
          .select('id, name')
          .inFilter('id', workerIds);

      // Create a map for quick lookup
      final workerMap = Map<String, String>.fromEntries(
          workers.map((w) => MapEntry(w['id'] as String, w['name'] as String)));

      // Assign worker names
      for (var app in applications) {
        app['worker_name'] = workerMap[app['worker_id']] ?? 'Worker';
      }

      debugPrint('Loaded ${applications.length} applications');
      return applications;
    } catch (e) {
      debugPrint('Error loading applications: $e');
      return [];
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _applicationsFuture = _loadApplications();
    });
  }

  Future<void> _logout() async {
    await _client.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
    );
  }

  Future<void> _acceptApplication(String appId) async {
    try {
      await _client
          .from('job_applications')
          .update({'status': 'accepted'}).eq('id', appId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application accepted!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _rejectApplication(String appId) async {
    try {
      await _client
          .from('job_applications')
          .update({'status': 'rejected'}).eq('id', appId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application rejected'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );

      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showRatingDialog(
      String workerId,
      String workerName,
      String jobId,
      String applicationId,
      ) async {
    // Check if already rated
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      final existing = await _client
          .from('ratings')
          .select()
          .eq('employer_id', user.id)
          .eq('worker_id', workerId)
          .eq('job_id', jobId)
          .maybeSingle();

      if (existing != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have already rated this worker for this job'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    } catch (e) {
      debugPrint('Error checking existing rating: $e');
    }

    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => RateWorkerDialog(
        workerId: workerId,
        workerName: workerName,
        jobId: jobId,
        applicationId: applicationId,
      ),
    );

    if (result == true) {
      _refresh(); // Refresh to update UI
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(textTheme),
            Expanded(child: _buildApplicationsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome Back!',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 26),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EmployerSettingsPage(),

                    ),
                  );
                },
                tooltip: 'Settings',
              ),

              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white, size: 24),
                onPressed: _logout,
                tooltip: 'Logout',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Applications Overview',
            style: textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Review workers who applied to your jobs',
            style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationsList() {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _applicationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load applications',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _refresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final apps = snapshot.data ?? [];

          if (apps.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 100),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.inbox_outlined,
                          size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No applications yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Workers will appear here when they apply',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: apps.length,
            itemBuilder: (context, index) {
              final app = apps[index];
              final job = (app['jobs'] ?? {}) as Map<String, dynamic>;

              return _ApplicationCard(
                appId: app['id'] ?? '',
                jobTitle: job['title'] ?? 'Job',
                place: job['place'] ?? '',
                salary: job['salary'] ?? '',
                jobType: job['type'] ?? '',
                workerId: app['worker_id'] ?? '',
                workerName: app['worker_name'] ?? 'Unknown Worker',
                status: app['status'] ?? 'pending',
                createdAt: app['created_at'] ?? '',
                jobId: app['job_id'] ?? '',
                onAccept: () => _acceptApplication(app['id'] ?? ''),
                onReject: () => _rejectApplication(app['id'] ?? ''),
                onViewProfile: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ViewWorkerProfilePage(
                        workerId: app['worker_id'] ?? '',
                        workerName: app['worker_name'] ?? 'Unknown Worker',
                      ),
                    ),
                  );
                },
                onRate: () => _showRatingDialog(
                  app['worker_id'] ?? '',
                  app['worker_name'] ?? 'Unknown Worker',
                  app['job_id'] ?? '',
                  app['id'] ?? '',
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.appId,
    required this.jobTitle,
    required this.place,
    required this.salary,
    required this.jobType,
    required this.workerId,
    required this.workerName,
    required this.status,
    required this.createdAt,
    required this.jobId,
    required this.onAccept,
    required this.onReject,
    required this.onViewProfile,
    required this.onRate,
  });

  final String appId;
  final String jobTitle;
  final String place;
  final String salary;
  final String jobType;
  final String workerId;
  final String workerName;
  final String status;
  final String createdAt;
  final String jobId;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onViewProfile;
  final VoidCallback onRate;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    jobTitle,
                    style: textTheme.titleMedium?.copyWith(
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
                Text(place, style: textTheme.bodyMedium),
                const SizedBox(width: 16),
                Icon(Icons.attach_money, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  salary,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: onViewProfile,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary.withOpacity(0.2),
                      child: Icon(
                        Icons.person,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            workerName,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Tap to view profile',
                            style: textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.grey[400]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Applied: ${_formatDate(createdAt)}',
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    jobType,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (status == 'pending')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onAccept,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              )
            else if (status == 'accepted')
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, size: 20, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          'You accepted this application',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onRate,
                      icon: const Icon(Icons.star, size: 18),
                      label: const Text('Rate Worker'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.amber[700],
                        side: BorderSide(color: Colors.amber[700]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(statusIcon, size: 20, color: statusColor),
                    const SizedBox(width: 8),
                    Text(
                      'You rejected this application',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr.split('T').first;
    }
  }
}
