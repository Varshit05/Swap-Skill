import 'package:flutter/material.dart';
import 'package:swap_skill/screens/edit_profile_screen.dart';
import 'package:swap_skill/screens/home_screen.dart';
import 'package:swap_skill/screens/profile_screen.dart';
import 'package:swap_skill/screens/swap_request.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:swap_skill/screens/login_screen.dart';
import 'package:swap_skill/screens/register_screen.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:swap_skill/auth_wrapper.dart';
import 'package:swap_skill/screens/chatbot_screen.dart';
// import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skill Swap',
      theme: ThemeData(
        scaffoldBackgroundColor:
            const Color(0xFFF5F7FA), // light grey background
        primaryColor: const Color(0xFF1976D2), // deep blue
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1976D2), // Google Blue
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1976D2),
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1976D2),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey),
          ),
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
        chipTheme: ChipThemeData.fromDefaults(
          labelStyle: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
          secondaryColor: const Color(0xFF1976D2),
          brightness: Brightness.light,
        ),
      ),
      home: const AuthWrapper(),
      routes: {
        // '/': (context) => const AuthWrapper(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/edit-profile': (context) => const EditProfileScreen(),
        '/swap-requests': (context) => const ReceivedSwapRequestsScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/chatbot': (context) => const ChatBotScreen(),
      },
    );
  }
}
