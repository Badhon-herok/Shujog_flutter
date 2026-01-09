// lib/features/home/presentation/pages/worker_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/pages/login_page.dart';
import 'view_my_profile_page.dart';
import 'edit_worker_profile_page.dart';
import 'my_applications_page.dart';
import 'notifications_page.dart';

class WorkerDashboardPage extends StatefulWidget {
  const WorkerDashboardPage({super.key});

  @override
  State<WorkerDashboardPage> createState() => _WorkerDashboardPageState();
}

class _WorkerDashboardPageState extends State<WorkerDashboardPage> {
  final _client = Supabase.instance.client;
  List<Map<String, dynamic>> _jobs = [];
  List<Map<String, dynamic>> _filteredJobs = [];
  bool _isLoading = true;
  String _userName = 'Worker';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadJobs();
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
        _userName = response['name'] as String? ?? 'Worker';
      });
    } catch (e) {
      debugPrint('Error loading user name: $e');
    }
  }

  Future<void> _loadJobs() async {
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 800));

    // Sample job listings for demonstration
    final sampleJobs = [
      {
        'id': '00000000-0000-0000-0000-000000000001',
        'title': 'Factory Helper',
        'place': 'Khulna',
        'salary': '৳800/day',
        'type': 'Full-time',
      },
      {
        'id': '00000000-0000-0000-0000-000000000002',
        'title': 'Construction Worker',
        'place': 'Jessore',
        'salary': '৳1000/day',
        'type': 'Contract',
      },
      {
        'id': '00000000-0000-0000-0000-000000000003',
        'title': 'Warehouse Assistant',
        'place': 'Rajshahi',
        'salary': '৳700/day',
        'type': 'Part-time',
      },
      {
        'id': '00000000-0000-0000-0000-000000000004',
        'title': 'Delivery Driver',
        'place': 'Dhaka',
        'salary': '৳900/day',
        'type': 'Full-time',
      },
    ];

    setState(() {
      _jobs = sampleJobs;
      _filteredJobs = sampleJobs;
      _isLoading = false;
    });
  }

  void _filterJobs(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredJobs = _jobs;
      } else {
        _filteredJobs = _jobs.where((job) {
          final title = (job['title'] ?? '').toLowerCase();
          final place = (job['place'] ?? '').toLowerCase();
          final type = (job['type'] ?? '').toLowerCase();
          final searchLower = query.toLowerCase();

          return title.contains(searchLower) ||
              place.contains(searchLower) ||
              type.contains(searchLower);
        }).toList();
      }
    });
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.search, color: AppColors.primary),
                  const SizedBox(width: 12),
                  const Text(
                    'Search Jobs',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search by title, location, or type...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _filterJobs('');
                      Navigator.pop(context);
                    },
                  )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  _filterJobs(value);
                  if (value.isNotEmpty) {
                    Navigator.pop(context);
                  }
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Try: "Factory", "Khulna", "Full-time"',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _applyToJob(String jobId, String title) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final existing = await _client
          .from('job_applications')
          .select()
          .eq('job_id', jobId)
          .eq('worker_id', user.id)
          .maybeSingle();

      if (existing != null) {
        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have already applied to this job'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      await _client.from('job_applications').insert({
        'job_id': jobId,
        'worker_id': user.id,
        'status': 'pending',
      });

      if (!mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Applied to $title successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error applying: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _logout() async {
    await _client.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildJobsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
              // View Profile Button
              IconButton(
                icon: const Icon(Icons.account_circle,
                    color: Colors.white, size: 26),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ViewMyProfilePage(),
                    ),
                  );
                },
                tooltip: 'View Profile',
              ),
              // Edit Profile Button
              IconButton(
                icon: const Icon(Icons.edit_note, color: Colors.white, size: 26),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditWorkerProfilePage(profile: null),
                    ),
                  );
                },
                tooltip: 'Edit Profile',
              ),
              // My Applications
              IconButton(
                icon: const Icon(Icons.assignment_outlined,
                    color: Colors.white, size: 26),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MyApplicationsPage(),
                    ),
                  );
                },
                tooltip: 'My Applications',
              ),
              // Notifications
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: Colors.white, size: 26),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsPage(),
                    ),
                  );
                },
                tooltip: 'Notifications',
              ),
              // Logout
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white, size: 24),
                onPressed: _logout,
              ),
            ],
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _showSearchDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.grey[600]),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'Search jobs...'
                          : 'Searching: $_searchQuery',
                      style: TextStyle(
                        color: _searchQuery.isEmpty
                            ? Colors.grey[600]
                            : Colors.black87,
                        fontSize: 16,
                        fontWeight: _searchQuery.isEmpty
                            ? FontWeight.normal
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () => _filterJobs(''),
                      child: Icon(Icons.close, color: Colors.grey[600]),
                    )
                  else
                    Icon(Icons.tune, color: Colors.grey[600]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredJobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'No jobs available'
                  : 'No jobs found for "$_searchQuery"',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _filterJobs(''),
                child: const Text('Clear search'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadJobs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredJobs.length,
        itemBuilder: (context, index) {
          final job = _filteredJobs[index];
          return _buildJobCard(job);
        },
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.work_outline,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job['title'] ?? '',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            job['type'] ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.bolt, size: 16, color: Colors.green[700]),
                          const SizedBox(width: 4),
                          Text(
                            'Hiring',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      job['place'] ?? '',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    const SizedBox(width: 20),
                    Icon(Icons.attach_money, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      job['salary'] ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _applyToJob(
                      job['id'] ?? '',
                      job['title'] ?? '',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Apply Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

