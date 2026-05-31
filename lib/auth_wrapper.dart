import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swap_skill/providers/auth_provider.dart';
import 'package:swap_skill/screens/home_screen.dart';
import 'package:swap_skill/screens/login_screen.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStateAsync = ref.watch(authStateProvider);

    return authStateAsync.when(
      data: (user) {
        if (user != null) {
          return const HomeScreen(); // User is logged in
        } else {
          return const LoginScreen(); // Not logged in
        }
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        body: Center(child: Text('Authentication error: $err')),
      ),
    );
  }
}
