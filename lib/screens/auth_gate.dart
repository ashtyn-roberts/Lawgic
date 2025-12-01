import 'package:flutter/material.dart';
import 'signin_screen.dart'; 
import 'signup_screen.dart'; 

// toggles btwn the sigin_screen and signup_screen
// displayed when the user is not authenticated
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  // track which view is currently shown (true = sign in, false = sign up)
  bool showSignIn = true;

  void toggleView() {
    setState(() {
      showSignIn = !showSignIn;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showSignIn) {
      return SignInScreen(onTap: toggleView);
    } else {
      return SignUpScreen(onTap: toggleView);
    }
  }
}
