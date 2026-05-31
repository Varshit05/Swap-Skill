import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swap_skill/providers/home_provider.dart';
import 'package:swap_skill/providers/user_provider.dart';
import 'package:swap_skill/screens/swap_request.dart';
import 'package:swap_skill/screens/user_detail.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> availabilityOptions = [
    'All',
    'Mornings',
    'Afternoons',
    'Evenings',
    'Weekends',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final firstName = userProfileAsync.maybeWhen(
      data: (data) => data?['name']?.split(' ')?.first ?? '',
      orElse: () => '',
    );

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
          ref.read(searchQueryProvider.notifier).state = value;
        },
      ),
    );
  }

  Widget _buildAvailabilityDropdown() {
    final selectedAvailability = ref.watch(selectedAvailabilityProvider);

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
                ref.read(selectedAvailabilityProvider.notifier).state = value;
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    final filteredUsersAsync = ref.watch(filteredUsersProvider);

    return filteredUsersAsync.when(
      data: (users) {
        if (users.isEmpty) {
          return const Center(child: Text("No matching users found."));
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final data = users[index];
            return _buildUserCard(data);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => const Center(child: Text("Something went wrong")),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      child: ListTile(
        title: Text(user['name'] ?? '',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Skills Offered: ${(user['skillsOffered'] as List<dynamic>?)?.join(', ') ?? ''}'),
            Text('Skills Wanted: ${(user['skillsWanted'] as List<dynamic>?)?.join(', ') ?? ''}'),
            Text('Availability: ${(user['availability'] as List<dynamic>?)?.join(', ') ?? ''}'),
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
