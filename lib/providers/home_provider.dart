import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final selectedAvailabilityProvider = StateProvider.autoDispose<String>((ref) => 'All');

final publicUsersProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .where('isPublic', isEqualTo: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['uid'] = doc.id; // Inject document ID as UID
      return data;
    }).toList();
  });
});

final filteredUsersProvider = Provider.autoDispose<AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final publicUsersAsync = ref.watch(publicUsersProvider);
  final searchQuery = ref.watch(searchQueryProvider).trim().toLowerCase();
  final selectedAvailability = ref.watch(selectedAvailabilityProvider);

  return publicUsersAsync.whenData((users) {
    return users.where((user) {
      final skillsOffered = List<String>.from(user['skillsOffered'] ?? []);
      final skillsWanted = List<String>.from(user['skillsWanted'] ?? []);
      final availability = List<String>.from(user['availability'] ?? []);

      final matchesSearch = searchQuery.isEmpty ||
          skillsOffered.any((skill) => skill.toLowerCase().contains(searchQuery)) ||
          skillsWanted.any((skill) => skill.toLowerCase().contains(searchQuery));

      final matchesAvailability = selectedAvailability == 'All' ||
          availability.contains(selectedAvailability);

      return matchesSearch && matchesAvailability;
    }).toList();
  });
});
