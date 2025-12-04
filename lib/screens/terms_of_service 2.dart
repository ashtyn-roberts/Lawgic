import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Terms of Service"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Terms of Service",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              _sectionTitle("1. Acceptance of Terms"),
              _sectionText(
                  "By accessing or using the Lawgic app, you agree to be bound by these Terms of Service. "
                  "If you do not agree, you may not use the app."),

              _sectionTitle("2. Use of the App"),
              _sectionText(
                  "You agree to use Lawgic only for lawful purposes. Any attempt to tamper with, reverse engineer, "
                  "or misuse data sources is strictly prohibited."),

              _sectionTitle("3. User Accounts"),
              _sectionText(
                  "You are responsible for maintaining the confidentiality of your login credentials. Any activity under "
                  "your account is your responsibility."),

              _sectionTitle("4. Data Accuracy"),
              _sectionText(
                  "While Lawgic strives to provide accurate legislative information, we make no guarantee about the completeness "
                  "or accuracy of external data sources such as LegiScan or state APIs."),

              _sectionTitle("5. Limitation of Liability"),
              _sectionText(
                  "Lawgic is provided on an \"as-is\" basis. We are not liable for decisions made based on summaries, bill text, "
                  "or voter data included in the app."),

              _sectionTitle("6. Changes to Terms"),
              _sectionText(
                  "We may update these Terms at any time. Continued use of Lawgic means you accept the updated Terms."),

              const SizedBox(height: 24),
              const Text(
                "Last Updated: December 2025",
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
