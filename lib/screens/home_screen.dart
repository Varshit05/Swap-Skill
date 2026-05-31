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
      appBar: AppBar(
        title: Text('Hi $firstName 👋'),
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
          const SizedBox(height: 16),
          _buildSearchBar(),
          const SizedBox(height: 12),
          _buildAvailabilityDropdown(),
          const SizedBox(height: 12),
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
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
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
        decoration: const InputDecoration(
          hintText: 'Search by skill...',
          prefixIcon: Icon(Icons.search, color: Color(0xFF64748B)),
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
          const Text(
            'Availability:',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedAvailability,
                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
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
            ),
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
          return const Center(
            child: Text(
              "No matching users found.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          itemCount: users.length,
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemBuilder: (context, index) {
            final data = users[index];
            return _buildUserCard(data);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => const Center(
        child: Text("Something went wrong", style: TextStyle(color: Colors.red)),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final List<String> skillsOffered = List<String>.from(user['skillsOffered'] ?? []);
    final List<String> skillsWanted = List<String>.from(user['skillsWanted'] ?? []);
    final List<String> availability = List<String>.from(user['availability'] ?? []);
    final String? photoUrl = user['profilePhoto'] as String?;
    final String? location = user['location'] as String?;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UserDetailScreen(userData: user),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                        ? NetworkImage(photoUrl)
                        : null,
                    child: photoUrl == null || photoUrl.isEmpty
                        ? const Icon(Icons.person, size: 30, color: Color(0xFF64748B))
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['name'] ?? '',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (location != null && location.isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 14, color: Color(0xFF64748B)),
                              const SizedBox(width: 4),
                              Text(
                                location,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF94A3B8)),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 12),
              if (skillsOffered.isNotEmpty) ...[
                const Text(
                  'SKILLS OFFERED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4F46E5),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: skillsOffered.map((skill) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      skill,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 10),
              ],
              if (skillsWanted.isNotEmpty) ...[
                const Text(
                  'SKILLS WANTED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D9488),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: skillsWanted.map((skill) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDFA),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      skill,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0D9488),
                      ),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 10),
              ],
              if (availability.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(
                      'Available: ${availability.join(', ')}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
