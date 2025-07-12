import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Navigate to Home screen
      Navigator.pushReplacementNamed(context, '/');
    } on FirebaseAuthException catch (e) {
      final error = e.message ?? 'Login failed';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _goToRegister() {
    Navigator.pushNamed(context, '/register');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Text(
                  'Login to Your Account',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                _buildTextField(_emailController, 'Email'),
                const SizedBox(height: 16),
                _buildTextField(_passwordController, 'Password',
                    isPassword: true),
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _login,
                        child: const Text('Login'),
                      ),
                TextButton(
                  onPressed: _goToRegister,
                  child: const Text("Don't have an account? Register"),
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
      keyboardType: isPassword
          ? TextInputType.visiblePassword
          : TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label is required';
        }
        if (!isPassword && !value.contains('@')) {
          return 'Enter a valid email';
        }
        return null;
      },
    );
  }
}
