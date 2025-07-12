import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:swap_skill/screens/swap_request.dart';
import 'package:swap_skill/screens/user_detail.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  String selectedAvailability = 'All';

  final List<String> availabilityOptions = [
    'All',
    'Mornings',
    'Afternoons',
    'Evenings',
    'Weekends',
  ];

  String firstName = '';

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  void _fetchUserName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final name = doc.data()?['name'] ?? '';
      setState(() {
        firstName = name.split(' ').first;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        backgroundColor: Colors.blue.shade800,
        title: Text('Hi $firstName 👋', style: const TextStyle(fontSize: 20)),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_calls),
            tooltip: 'Swap Requests',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ReceivedSwapRequestsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: 'My Profile',
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          _buildSearchBar(),
          const SizedBox(height: 8),
          _buildAvailabilityDropdown(),
          const SizedBox(height: 8),
          Expanded(child: _buildUserList()),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/chatbot');
              },
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text("Need Help? Chat with AI"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by skill...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onChanged: (value) {
          setState(() {
            searchQuery = value.trim();
          });
        },
      ),
    );
  }

  Widget _buildAvailabilityDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          const Text('Availability:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: selectedAvailability,
            items: availabilityOptions.map((String value) {
              return DropdownMenuItem(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedAvailability = value;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('isPublic', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Something went wrong"));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;

          final skillsOffered = List<String>.from(data['skillsOffered'] ?? []);
          final skillsWanted = List<String>.from(data['skillsWanted'] ?? []);
          final availability = List<String>.from(data['availability'] ?? []);

          final matchesSearch = searchQuery.isEmpty ||
              skillsOffered.any((skill) =>
                  skill.toLowerCase().contains(searchQuery.toLowerCase())) ||
              skillsWanted.any((skill) =>
                  skill.toLowerCase().contains(searchQuery.toLowerCase()));

          final matchesAvailability = selectedAvailability == 'All' ||
              availability.contains(selectedAvailability);

          return matchesSearch && matchesAvailability;
        }).toList();

        if (users.isEmpty) {
          return const Center(child: Text("No matching users found."));
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final data = users[index].data() as Map<String, dynamic>;
            return _buildUserCard(data);
          },
        );
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      child: ListTile(
        title: Text(user['name'],
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Skills Offered: ${user['skillsOffered'].join(', ')}'),
            Text('Skills Wanted: ${user['skillsWanted'].join(', ')}'),
            Text('Availability: ${user['availability'].join(', ')}'),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UserDetailScreen(userData: user),
            ),
          );
        },
      ),
    );
  }
}
