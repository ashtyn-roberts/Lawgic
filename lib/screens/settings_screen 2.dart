import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';
import 'terms_of_service.dart';
import 'privacy_policy.dart';
import 'support_screen.dart';
import 'rate_app_screen.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool darkMode = false;
  String appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() => appVersion = info.version);
  }

  void _showComingSoon(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title coming soon!')),
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        children: [
          // Dark mode toggle
          /*SwitchListTile(
            title: const Text('Dark Mode'),
            value: darkMode,
            onChanged: (value) {
              setState(() => darkMode = value);
            },
            secondary: const Icon(Icons.dark_mode),
          ),

          const Divider(),*/

          ListTile(
            title: const Text('Terms of Service'),
            leading: const Icon(Icons.description_outlined),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TermsOfServiceScreen()),
              );
            }
          ),

          ListTile(
            title: const Text('Privacy Policy'),
            leading: const Icon(Icons.privacy_tip_outlined),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PrivacyPolicyScreen()),
              );
            }
          ),

          ListTile(
            title: const Text('Support'),
            leading: const Icon(Icons.support_agent),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SupportScreen()),
              );
            }
          ),

          ListTile(
            title: const Text('Rate App'),
            leading: const Icon(Icons.star_rate),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RateAppScreen()),
              );
            }
          ),

          const Divider(),

          ListTile(
            title: Text('Version: $appVersion'),
            leading: const Icon(Icons.info_outline),
          ),

          ListTile(
            title: const Text(
              'Log Out',
              style: TextStyle(color: Colors.red),
            ),
            leading: const Icon(Icons.logout, color: Colors.red),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}
