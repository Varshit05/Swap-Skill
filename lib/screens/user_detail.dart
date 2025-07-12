import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserDetailScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const UserDetailScreen({super.key, required this.userData});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  bool requestSent = false; // You can set this based on actual swap status

  void _sendSwapRequest() async {
    setState(() {
      requestSent = true;
    });

    // Optional: Store swap request in Firestore
    
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await FirebaseFirestore.instance.collection('swap_requests').add({
        'from': currentUser.uid,
        'to': widget.userData['uid'], // assuming you have this in userData
        'timestamp': Timestamp.now(),
      });
    }
    

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Swap request sent')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.userData;

    if (user['isPublic'] == false) {
      return Scaffold(
        appBar: AppBar(title: const Text('User Details')),
        body: const Center(child: Text('This profile is private')),
      );
    }

    // ✅ Safely cast all list fields
    final List<String> skillsOffered =
        List<String>.from(user['skillsOffered'] ?? []);
    final List<String> skillsWanted =
        List<String>.from(user['skillsWanted'] ?? []);
    final List<String> availability =
        List<String>.from(user['availability'] ?? []);

    return Scaffold(
      appBar: AppBar(
        title: Text(user['name'] ?? 'User Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(user),
            const SizedBox(height: 16),
            _buildSkillSection("Skills Offered", skillsOffered),
            const SizedBox(height: 16),
            _buildSkillSection("Skills Wanted", skillsWanted),
            const SizedBox(height: 16),
            _buildAvailability(availability),
            const SizedBox(height: 30),
            _buildSwapButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> user) {
    return Row(
      children: [
        CircleAvatar(
          radius: 35,
          backgroundImage: user['profilePhoto'] != null &&
                  user['profilePhoto'].toString().isNotEmpty
              ? NetworkImage(user['profilePhoto'])
              : null,
          child: user['profilePhoto'] == null ||
                  user['profilePhoto'].toString().isEmpty
              ? const Icon(Icons.person, size: 40)
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user['name'] ?? '',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              if (user['location'] != null &&
                  user['location'].toString().isNotEmpty)
                Text(user['location'],
                    style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSkillSection(String title, List<String> skills) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (skills.isEmpty) const Text("No skills listed."),
        Wrap(
          spacing: 8,
          children: skills.map((skill) => Chip(label: Text(skill))).toList(),
        ),
      ],
    );
  }

  Widget _buildAvailability(List<String> availability) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Availability',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (availability.isEmpty) const Text("No availability listed."),
        Wrap(
          spacing: 8,
          children:
              availability.map((slot) => Chip(label: Text(slot))).toList(),
        ),
      ],
    );
  }

  Widget _buildSwapButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.swap_horiz),
      label: Text(requestSent ? 'Request Sent' : 'Request Swap'),
      onPressed: requestSent ? null : _sendSwapRequest,
      style: ElevatedButton.styleFrom(
        backgroundColor: requestSent ? Colors.grey : Colors.teal,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        textStyle: const TextStyle(fontSize: 16),
      ),
    );
  }
}
