import 'package:flutter/material.dart';

// CORRECTED IMPORTS: Assuming signin_screen.dart and signup_screen.dart 
// are located directly in the lib/screens/ directory alongside auth_gate.dart.
import 'signin_screen.dart'; 
import 'signup_screen.dart'; 

/// Toggles between the SignInScreen and SignUpScreen, which are displayed
/// when the user is not authenticated.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  // State to track which view is currently shown (true = Sign In, false = Sign Up)
  bool showSignIn = true;

  void toggleView() {
    setState(() {
      showSignIn = !showSignIn;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Note: The 'const' keyword has been removed from SignInScreen and SignUpScreen 
    // because the 'onTap' (toggleView) callback is a non-constant function 
    // that changes the StatefulWidget's state.
    if (showSignIn) {
      return SignInScreen(onTap: toggleView);
    } else {
      return SignUpScreen(onTap: toggleView);
    }
  }
}
