// lib/features/home/presentation/pages/view_my_profile_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import 'edit_worker_profile_page.dart';

class ViewMyProfilePage extends StatefulWidget {
  const ViewMyProfilePage({super.key});

  @override
  State<ViewMyProfilePage> createState() => _ViewMyProfilePageState();
}

class _ViewMyProfilePageState extends State<ViewMyProfilePage> {
  final _client = Supabase.instance.client;
  bool _isLoading = true;
  Map<String, dynamic>? _profile;
  String _userName = 'Worker';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      // Get user name
      final userResponse = await _client
          .from('users')
          .select('name')
          .eq('id', user.id)
          .maybeSingle();

      if (userResponse != null) {
        _userName = userResponse['name'] ?? 'Worker';
      }

      // Get profile
      final profileResponse = await _client
          .from('worker_profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      setState(() {
        _profile = profileResponse;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditWorkerProfilePage(profile: _profile),
                ),
              );
              _loadProfile(); // Refresh after edit
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_profile == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('No profile created yet',
                style: TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EditWorkerProfilePage(profile: null),
                  ),
                );
                _loadProfile();
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
              ),
            ),
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  child: const Icon(Icons.person, size: 60, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  _userName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (_profile!['location'] != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '📍 ${_profile!['location']}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (_profile!['phone'] != null)
                  _buildCard('Contact', [
                    _buildRow('Phone', _profile!['phone']),
                  ]),
                const SizedBox(height: 16),
                if (_profile!['skills'] != null)
                  _buildCard('Skills', [
                    _buildRow('Skills', _profile!['skills']),
                    if (_profile!['experience_years'] != null)
                      _buildRow('Experience',
                          '${_profile!['experience_years']} years'),
                  ]),
                const SizedBox(height: 16),
                if (_profile!['bio'] != null)
                  _buildCard('About', [
                    Text(_profile!['bio'],
                        style: const TextStyle(fontSize: 15, height: 1.5)),
                  ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
