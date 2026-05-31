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
  bool requestSent = false;
  String? requestStatus;
  bool isLoadingStatus = true;

  @override
  void initState() {
    super.initState();
    _checkSwapRequestStatus();
  }

  void _checkSwapRequestStatus() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final query = await FirebaseFirestore.instance
          .collection('swap_requests')
          .where('from', isEqualTo: currentUser.uid)
          .where('to', isEqualTo: widget.userData['uid'])
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        if (mounted) {
          setState(() {
            requestSent = true;
            requestStatus = doc.data()['status'] ?? 'pending';
            isLoadingStatus = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isLoadingStatus = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingStatus = false;
        });
      }
    }
  }

  void _sendSwapRequest() async {
    setState(() {
      requestSent = true;
      requestStatus = 'pending';
    });

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        await FirebaseFirestore.instance.collection('swap_requests').add({
          'from': currentUser.uid,
          'to': widget.userData['uid'],
          'timestamp': Timestamp.now(),
          'status': 'pending',
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send request: $e')),
          );
        }
        setState(() {
          requestSent = false;
          requestStatus = null;
        });
        return;
      }
    }

    if (!mounted) return;
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
        body: const Center(
          child: Text(
            'This profile is private',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    final List<String> skillsOffered = List<String>.from(user['skillsOffered'] ?? []);
    final List<String> skillsWanted = List<String>.from(user['skillsWanted'] ?? []);
    final List<String> availability = List<String>.from(user['availability'] ?? []);

    return Scaffold(
      appBar: AppBar(
        title: Text(user['name'] ?? 'User Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(user),
            const SizedBox(height: 24),
            _buildSectionCard(
              title: "Skills Offered",
              child: _buildSkillTags(skillsOffered, isOffer: true),
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: "Skills Wanted",
              child: _buildSkillTags(skillsWanted, isOffer: false),
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: "Availability",
              child: _buildAvailabilityTags(availability),
            ),
            const SizedBox(height: 32),
            Center(child: _buildSwapButton()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> user) {
    final String? photoUrl = user['profilePhoto'] as String?;
    final String? location = user['location'] as String?;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          )
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                ? NetworkImage(photoUrl)
                : null,
            child: photoUrl == null || photoUrl.isEmpty
                ? const Icon(Icons.person, size: 40, color: Color(0xFF64748B))
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['name'] ?? '',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                if (location != null && location.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        location,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildSkillTags(List<String> skills, {required bool isOffer}) {
    if (skills.isEmpty) {
      return const Text(
        "No skills listed.",
        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
      );
    }

    final Color bgColor = isOffer ? const Color(0xFFEEF2FF) : const Color(0xFFF0FDFA);
    final Color textColor = isOffer ? const Color(0xFF4F46E5) : const Color(0xFF0D9488);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: skills.map((skill) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          skill,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildAvailabilityTags(List<String> availability) {
    if (availability.isEmpty) {
      return const Text(
        "No availability listed.",
        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: availability.map((slot) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.schedule, size: 14, color: Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(
              slot,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildSwapButton() {
    if (isLoadingStatus) {
      return const CircularProgressIndicator();
    }

    String buttonText = 'Request Swap';
    Color buttonColor = const Color(0xFF6366F1);
    IconData icon = Icons.swap_horiz;

    if (requestSent) {
      icon = Icons.done;
      if (requestStatus == 'pending') {
        buttonText = 'Request Pending';
        buttonColor = Colors.orange;
      } else if (requestStatus == 'accepted') {
        buttonText = 'Swap Accepted';
        buttonColor = Colors.green;
      } else if (requestStatus == 'rejected') {
        buttonText = 'Swap Rejected';
        buttonColor = Colors.red;
      } else {
        buttonText = 'Request Sent';
        buttonColor = Colors.grey;
      }
    }

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 20),
        label: Text(buttonText),
        onPressed: requestSent ? null : _sendSwapRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: Colors.white,
          // ignore: deprecated_member_use
          disabledBackgroundColor: buttonColor.withOpacity(0.6),
          // ignore: deprecated_member_use
          disabledForegroundColor: Colors.white.withOpacity(0.9),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
