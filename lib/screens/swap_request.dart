import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReceivedSwapRequestsScreen extends StatelessWidget {
  const ReceivedSwapRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Swap Requests")),
        body: const Center(child: Text('You need to be logged in.')),
      );
    }

    final requestsQuery = FirebaseFirestore.instance
        .collection('swap_requests')
        .where(Filter.or(
          Filter('from', isEqualTo: currentUser.uid),
          Filter('to', isEqualTo: currentUser.uid),
        ));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Swap Requests & Collabs"),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.call_received), text: "Received"),
              Tab(icon: Icon(Icons.call_made), text: "Sent"),
              Tab(icon: Icon(Icons.handshake), text: "Collaborations"),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: requestsQuery.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error loading requests: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = List<QueryDocumentSnapshot>.from(snapshot.data?.docs ?? []);

            // Sort in memory by timestamp descending
            docs.sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              final aTime = aData['timestamp'] as Timestamp?;
              final bTime = bData['timestamp'] as Timestamp?;
              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return 1;
              if (bTime == null) return -1;
              return bTime.compareTo(aTime); // descending
            });

            final receivedRequests = docs
                .where((doc) =>
                    (doc.data() as Map<String, dynamic>)['to'] == currentUser.uid &&
                    (doc.data() as Map<String, dynamic>)['status'] != 'accepted')
                .toList();

            final sentRequests = docs
                .where((doc) =>
                    (doc.data() as Map<String, dynamic>)['from'] == currentUser.uid &&
                    (doc.data() as Map<String, dynamic>)['status'] != 'accepted')
                .toList();

            final collaborations = docs
                .where((doc) =>
                    (doc.data() as Map<String, dynamic>)['status'] == 'accepted')
                .toList();

            return TabBarView(
              children: [
                _buildRequestsList(receivedRequests, isIncoming: true),
                _buildRequestsList(sentRequests, isIncoming: false),
                _buildCollaborationsList(collaborations, currentUser.uid),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRequestsList(List<QueryDocumentSnapshot> list, {required bool isIncoming}) {
    if (list.isEmpty) {
      return Center(
        child: Text(
          isIncoming ? "No received requests." : "No sent requests.",
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: list.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        return SwapRequestItem(doc: list[index]);
      },
    );
  }

  Widget _buildCollaborationsList(List<QueryDocumentSnapshot> list, String currentUid) {
    if (list.isEmpty) {
      return const Center(
        child: Text(
          "No ongoing collaborations yet.",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: list.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        return CollaborationItem(doc: list[index], currentUid: currentUid);
      },
    );
  }
}

class SwapRequestItem extends StatelessWidget {
  final QueryDocumentSnapshot doc;

  const SwapRequestItem({super.key, required this.doc});

  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('swap_requests')
          .doc(doc.id)
          .update({'status': newStatus});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Swap request $newStatus')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating request: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox();

    final data = doc.data() as Map<String, dynamic>;
    final isIncoming = data['to'] == currentUser.uid;
    final otherUserId = isIncoming ? (data['from'] as String? ?? '') : (data['to'] as String? ?? '');
    final status = data['status'] as String? ?? 'pending';
    final timestamp = data['timestamp'] as Timestamp?;

    final formattedDate = timestamp != null
        ? timestamp.toDate().toString().split('.').first
        : 'Unknown time';

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
      builder: (context, userSnapshot) {
        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
        final otherName = userData?['name'] ?? 'Loading name...';
        final otherPhoto = userData?['profilePhoto'] as String?;
        final otherLocation = userData?['location'] as String?;

        Color statusColor;
        switch (status) {
          case 'accepted':
            statusColor = Colors.green;
            break;
          case 'rejected':
            statusColor = Colors.red;
            break;
          case 'pending':
          default:
            statusColor = Colors.orange;
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundImage: otherPhoto != null && otherPhoto.isNotEmpty
                          ? NetworkImage(otherPhoto)
                          : null,
                      child: otherPhoto == null || otherPhoto.isEmpty
                          ? const Icon(Icons.person, size: 28)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            otherName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (otherLocation != null && otherLocation.isNotEmpty)
                            Text(
                              otherLocation,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        // ignore: deprecated_member_use
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor, width: 1),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                if (userData != null) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 6),
                  Text(
                    'Skills Offered: ${(userData['skillsOffered'] as List<dynamic>?)?.join(', ') ?? 'None'}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Skills Wanted: ${(userData['skillsWanted'] as List<dynamic>?)?.join(', ') ?? 'None'}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                ],
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        isIncoming
                            ? 'Received: $formattedDate'
                            : 'Sent: $formattedDate',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                    if (status == 'pending')
                      if (isIncoming)
                        Row(
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () => _updateStatus(context, 'accepted'),
                              child: const Text('Accept', style: TextStyle(fontSize: 13)),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () => _updateStatus(context, 'rejected'),
                              child: const Text('Reject', style: TextStyle(fontSize: 13)),
                            ),
                          ],
                        )
                      else
                        const Text(
                          'Pending',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        )
                    else
                      Text(
                        status == 'accepted' ? 'Accepted' : 'Rejected',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: status == 'accepted' ? Colors.green : Colors.red,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class CollaborationItem extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final String currentUid;

  const CollaborationItem({super.key, required this.doc, required this.currentUid});

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final otherUserId = data['from'] == currentUid ? data['to'] : data['from'];
    final timestamp = data['timestamp'] as Timestamp?;

    final formattedDate = timestamp != null
        ? timestamp.toDate().toString().split('.').first
        : 'Unknown time';

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
      builder: (context, userSnapshot) {
        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
        final otherName = userData?['name'] ?? 'Loading name...';
        final otherPhoto = userData?['profilePhoto'] as String?;
        final otherLocation = userData?['location'] as String?;
        final otherEmail = userData?['email'] as String?;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.green.shade300, width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundImage: otherPhoto != null && otherPhoto.isNotEmpty
                          ? NetworkImage(otherPhoto)
                          : null,
                      child: otherPhoto == null || otherPhoto.isEmpty
                          ? const Icon(Icons.person, size: 28)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            otherName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (otherLocation != null && otherLocation.isNotEmpty)
                            Text(
                              otherLocation,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        // ignore: deprecated_member_use
                        color: Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green, width: 1),
                      ),
                      child: const Text(
                        'COLLABORATING',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                if (userData != null) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 6),
                  Text(
                    'Skills Offered: ${(userData['skillsOffered'] as List<dynamic>?)?.join(', ') ?? 'None'}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Skills Wanted: ${(userData['skillsWanted'] as List<dynamic>?)?.join(', ') ?? 'None'}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  if (otherEmail != null && otherEmail.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.email, color: Colors.blue.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Contact Email',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                                Text(
                                  otherEmail,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
                const Divider(),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Connected on $formattedDate',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
