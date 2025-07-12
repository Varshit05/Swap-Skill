import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _photoUrlController;

  List<String> skillsOffered = [];
  List<String> skillsWanted = [];
  List<String> availability = [];
  bool isPublic = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userData =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

    _nameController = TextEditingController(text: userData?['name'] ?? '');
    _locationController =
        TextEditingController(text: userData?['location'] ?? '');
    _photoUrlController =
        TextEditingController(text: userData?['profilePhoto'] ?? '');
    skillsOffered = List<String>.from(userData?['skillsOffered'] ?? []);
    skillsWanted = List<String>.from(userData?['skillsWanted'] ?? []);
    availability = List<String>.from(userData?['availability'] ?? []);
    isPublic = userData?['isPublic'] ?? true;
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name': _nameController.text.trim(),
        'location': _locationController.text.trim(),
        'profilePhoto': _photoUrlController.text.trim(),
        'skillsOffered': skillsOffered,
        'skillsWanted': skillsWanted,
        'availability': availability,
        'isPublic': isPublic,
      });
      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }

  final TextEditingController _offeredSkillController = TextEditingController();
  final TextEditingController _wantedSkillController = TextEditingController();

  void _addSkill(List<String> list, TextEditingController controller) {
    final text = controller.text.trim();
    if (text.isNotEmpty && !list.contains(text)) {
      setState(() {
        list.add(text);
      });
      controller.clear();
    }
  }

  void _toggleAvailability(String value) {
    setState(() {
      if (availability.contains(value)) {
        availability.remove(value);
      } else {
        availability.add(value);
      }
    });
  }

  // void _saveProfile() {
  //   if (_formKey.currentState!.validate()) {
  //     // Normally save to backend here
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Profile updated')),
  //     );
  //     Navigator.pop(context); // Go back to profile screen
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProfile,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(_nameController, 'Name'),
              const SizedBox(height: 12),
              _buildTextField(_locationController, 'Location'),
              const SizedBox(height: 12),
              _buildTextField(_photoUrlController, 'Profile Photo URL',
                  isRequired: false),
              const SizedBox(height: 20),
              _buildSkillInput(
                  "Skills Offered", skillsOffered, _offeredSkillController),
              const SizedBox(height: 20),
              _buildSkillInput(
                  "Skills Wanted", skillsWanted, _wantedSkillController),
              const SizedBox(height: 20),
              _buildAvailabilitySelector(),
              const SizedBox(height: 20),
              _buildPublicToggle(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool isRequired = true}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: isRequired
          ? (value) => value == null || value.isEmpty ? 'Required field' : null
          : null,
    );
  }

  Widget _buildSkillInput(
      String title, List<String> list, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 8,
          children: list
              .map((skill) => Chip(
                    label: Text(skill),
                    onDeleted: () {
                      setState(() {
                        list.remove(skill);
                      });
                    },
                  ))
              .toList(),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(hintText: 'Add skill...'),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _addSkill(list, controller),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildAvailabilitySelector() {
    const List<String> options = [
      'Mornings',
      'Afternoons',
      'Evenings',
      'Weekends'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Availability',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 8,
          children: options.map((option) {
            final isSelected = availability.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (_) => _toggleAvailability(option),
            );
          }).toList(),
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
          onChanged: (value) {
            setState(() {
              isPublic = value;
            });
          },
        ),
      ],
    );
  }
}
