import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swap_skill/auth_wrapper.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _isLoading = false;

  void _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Create Firestore user profile
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'location': null,
        'profilePhoto': null,
        'skillsOffered': [],
        'skillsWanted': [],
        'availability': [],
        'isPublic': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Navigate to home screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
      );
    } on FirebaseAuthException catch (e) {
      final error = e.message ?? 'Registration failed';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _goToLogin() {
    Navigator.pop(context); // Back to login screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Text('Register a New Account',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),
                _buildTextField(_nameController, 'Full Name'),
                const SizedBox(height: 16),
                _buildTextField(_emailController, 'Email'),
                const SizedBox(height: 16),
                _buildTextField(_passwordController, 'Password',
                    isPassword: true),
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _register,
                        child: const Text('Register'),
                      ),
                TextButton(
                  onPressed: _goToLogin,
                  child: const Text('Already have an account? Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool isPassword = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label is required';
        }
        if (label == 'Email' && !value.contains('@')) {
          return 'Enter a valid email';
        }
        if (label == 'Password' && value.length < 6) {
          return 'Minimum 6 characters';
        }
        return null;
      },
    );
  }
}
