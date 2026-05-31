import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swap_skill/providers/user_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _goToEditProfile(BuildContext context, Map<String, dynamic>? userData) {
    Navigator.pushNamed(
      context,
      '/edit-profile',
      arguments: userData,
    );
  }

  Future<void> _togglePublic(bool value) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'isPublic': value,
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);

    return userProfileAsync.when(
      data: (userData) {
        if (userData == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('My Profile')),
            body: const Center(child: Text('User data not found')),
          );
        }

        final isPublic = userData['isPublic'] ?? true;

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _goToEditProfile(context, userData),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => ref.refresh(userProfileProvider.future),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildProfileHeader(userData),
                  const SizedBox(height: 20),
                  _buildSkillSection("Skills Offered", userData['skillsOffered']),
                  const SizedBox(height: 20),
                  _buildSkillSection("Skills Wanted", userData['skillsWanted']),
                  const SizedBox(height: 20),
                  _buildAvailability(userData),
                  const SizedBox(height: 20),
                  _buildPublicToggle(isPublic),
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, '/login');
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        appBar: AppBar(title: const Text('My Profile')),
        body: Center(child: Text('Error loading profile: $err')),
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> userData) {
    return Row(
      children: [
        CircleAvatar(
          radius: 35,
          backgroundImage: userData['profilePhoto'] != null &&
                  userData['profilePhoto'].toString().isNotEmpty
              ? NetworkImage(userData['profilePhoto'])
              : null,
          child: userData['profilePhoto'] == null ||
                  userData['profilePhoto'].toString().isEmpty
              ? const Icon(Icons.person, size: 40)
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(userData['name'] ?? '',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              if (userData['location'] != null &&
                  userData['location'].toString().isNotEmpty)
                Text(userData['location'],
                    style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSkillSection(String title, List<dynamic>? skills) {
    if (skills == null || skills.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('No skills added yet.',
              style: TextStyle(color: Colors.grey)),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: skills.map((skill) => Chip(label: Text(skill.toString()))).toList(),
        ),
      ],
    );
  }

  Widget _buildAvailability(Map<String, dynamic> userData) {
    final availability = userData['availability'] as List<dynamic>?;

    if (availability == null || availability.isEmpty) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Availability',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('No availability set.', style: TextStyle(color: Colors.grey)),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Availability',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children:
              availability.map((slot) => Chip(label: Text(slot.toString()))).toList(),
        ),
      ],
    );
  }

  Widget _buildPublicToggle(bool isPublic) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Make Profile Public', style: TextStyle(fontSize: 16)),
        Switch(
          value: isPublic,
          onChanged: _togglePublic,
        ),
      ],
    );
  }
}
