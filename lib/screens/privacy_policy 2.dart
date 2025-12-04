import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Privacy Policy"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Privacy Policy",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              _sectionTitle("1. Information We Collect"),
              _sectionText(
                  "We collect only the information needed to provide Lawgic features, including:\n"
                  "- Your name and email (for login)\n"
                  "- Voter parish (to show relevant propositions)\n"
                  "- Optional profile and settings data"),

              _sectionTitle("2. How Your Data Is Used"),
              _sectionText(
                  "Your data is used solely to personalize your experience inside the app. "
                  "We do not sell or share your information with third parties."),

              _sectionTitle("3. Third-Party Services"),
              _sectionText(
                  "Lawgic uses Firebase Authentication, Firebase Firestore, and Google Gemini AI for bill summaries. "
                  "These services follow their own privacy policies."),

              _sectionTitle("4. Data Security"),
              _sectionText(
                  "We implement industry-standard security practices such as encrypted communication and controlled access "
                  "permissions to protect your data."),

              _sectionTitle("5. Your Choices"),
              _sectionText(
                  "You may request to delete your account at any time. Deleted accounts permanently remove personal data "
                  "stored in Firebase."),

              _sectionTitle("6. Changes to This Policy"),
              _sectionText(
                  "We may update this Privacy Policy to reflect new features or legal requirements. "
                  "Continued use of the app means acceptance of updates."),

              const SizedBox(height: 24),
              const Text(
                "Last Updated: January 2025",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0, bottom: 6.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _sectionText(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 15, height: 1.4),
    );
  }
}
