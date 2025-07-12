import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReceivedSwapRequestsScreen extends StatelessWidget {
  const ReceivedSwapRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Center(child: Text('You need to be logged in.'));
    }

    final requestsQuery = FirebaseFirestore.instance
        .collection('swap_requests')
        .where('to', isEqualTo: currentUser.uid)
        .orderBy('timestamp', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text("Received Swap Requests")),
      body: StreamBuilder<QuerySnapshot>(
        stream: requestsQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text("No swap requests received."));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text('Swap request from ${data['from']}'),
                subtitle: Text('Status: ${data['status']}'),
                trailing: Text(
                    (data['timestamp'] as Timestamp).toDate().toString()),
              );
            },
          );
        },
      ),
    );
  }
}
