import 'package:flutter/material.dart';

class AboutTab extends StatelessWidget {
  const AboutTab({super.key});

  Color get primaryLavender => const Color(0xFFF4F0FB);
  Color get textDark => const Color(0xFF3D3A50);
  Color get accentPurple => const Color(0xFFB48CFB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryLavender,
      appBar: AppBar(
        backgroundColor: primaryLavender,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'About Lawgic',
          style: TextStyle(
            color: textDark,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: accentPurple.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.info_outline,
                  size: 60,
                  color: accentPurple,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'About Lawgic',
              style: TextStyle(
                color: textDark,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Lawgic is your comprehensive voting companion, designed to help you stay informed about ballot propositions, candidates, and important election information.'
              'Created by a small group of dedicated students, our mission is to empower voters with the knowledge they need to make informed decisions at the polls.',
              style: TextStyle(
                color: textDark,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Features',
              style: TextStyle(
                color: textDark,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(
              Icons.how_to_vote,
              'Browse Propositions',
              'View and search ballot propositions filtered by your parish and election date',
            ),
            _buildFeatureItem(
              Icons.map_outlined,
              'Find Polling Locations',
              'Locate your nearest voting location on an interactive map',
            ),
            _buildFeatureItem(
              Icons.calendar_today,
              'Election Calendar',
              'Stay up to date with important election dates and deadlines',
            ),
            _buildFeatureItem(
              Icons.person_outline,
              'Personalized Profile',
              'Manage your voter information and preferences',
            ),
            const SizedBox(height: 24),
            Text(
              'Version',
              style: TextStyle(
                color: textDark,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '1.0.0',
              style: TextStyle(
                color: textDark.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Contact',
              style: TextStyle(
                color: textDark,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'For support or feedback, please contact us at support@lawgic.com',
              style: TextStyle(
                color: textDark.withOpacity(0.7),
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentPurple.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accentPurple, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: textDark.withOpacity(0.7),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
