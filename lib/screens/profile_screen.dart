import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isPublic = true;
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      setState(() {
        userData = doc.data();
        isPublic = userData?['isPublic'] ?? true;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading user data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void _goToEditProfile() async {
    final updatedData = await Navigator.pushNamed(
      context,
      '/edit-profile',
      arguments: userData,
    );

    if (updatedData != null && mounted) {
      setState(() {
        userData = updatedData as Map<String, dynamic>;
      });
    } else {
      _loadUserData(); // fallback refresh
    }
  }

  Future<void> _togglePublic(bool value) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    setState(() {
      isPublic = value;
    });
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'isPublic': value,
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || userData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (userData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Profile')),
        body: const Center(child: Text('User data not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _goToEditProfile),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 20),
              _buildSkillSection("Skills Offered", userData?['skillsOffered']),
              const SizedBox(height: 20),
              _buildSkillSection("Skills Wanted", userData?['skillsWanted']),
              const SizedBox(height: 20),
              _buildAvailability(),
              const SizedBox(height: 20),
              _buildPublicToggle(),
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
  }

  Widget _buildProfileHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 35,
          backgroundImage: userData?['profilePhoto'] != null
              ? NetworkImage(userData!['profilePhoto'])
              : null,
          child: userData?['profilePhoto'] == null
              ? const Icon(Icons.person, size: 40)
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(userData?['name'] ?? '',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              if (userData?['location'] != null)
                Text(userData!['location'],
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
          children: skills.map((skill) => Chip(label: Text(skill))).toList(),
        ),
      ],
    );
  }

  Widget _buildAvailability() {
    final availability = userData?['availability'] as List<dynamic>?;

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
              availability.map((slot) => Chip(label: Text(slot))).toList(),
        ),
      ],
    );
  }

  Widget _buildPublicToggle() {
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
