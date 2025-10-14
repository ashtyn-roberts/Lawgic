import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// IMPORTANT: This file must be located in the main lib/ directory
import 'firebase_options.dart'; 

// IMPORTANT: These screens must be located in lib/screens/
import 'screens/auth_gate.dart'; 
import 'screens/home_screen.dart'; 


void main() async {
  // Required for Firebase to initialize before runApp
  WidgetsFlutterBinding.ensureInitialized(); 

  // Initialize Firebase using the generated options file
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SW Development App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Use a color scheme for a modern look
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        
        // Define standard styles for the whole app
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50), // Full width button
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
        ),
      ),
      // AuthPage is the primary screen shown at launch
      home: const AuthPage(), 
    );
  }
}

/// Listens to Firebase Auth state changes and directs the user to the correct screen.
class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder listens to the Firebase Auth state changes (logged in or out)
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while connection is established
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // If snapshot has data (User object), they are logged in.
        if (snapshot.hasData) {
          return const HomeScreen();
        } 
        
        // If snapshot has no data, they are logged out.
        else {
          // AuthGate handles the choice between Sign In and Sign Up screens.
          return const AuthGate();
        }
      },
    );
  }
}
