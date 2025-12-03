import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'auth_gate.dart';
import 'editprofile_screen.dart';
import 'proposition_detail_screen.dart';
import 'about_tab.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
// --------------------------------------------------------
// SAFE GETTER — prevents null crashes from Firestore maps
// --------------------------------------------------------
dynamic safeget(Map<String, dynamic> map, String key,
    {dynamic fallback = ''}) {
  try {
    return map.containsKey(key) ? map[key] : fallback;
  } catch (_) {
    return fallback;
  }
}

// --------------------------------------------------------
// PROFILE TAB
// --------------------------------------------------------
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  Color get primaryLavender => const Color(0xFFF4F0FB);
  Color get accentPurple => const Color(0xFFB48CFB);
  Color get textDark => const Color(0xFF3D3A50);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    //final drawerColor = Theme.of(context).drawerTheme.backgroundColor ?? (isDark ? const Color(0xFF121212) : Colors.white);
    //final drawerHeaderColor = Theme.of(context).colorScheme.surfaceVariant ?? (isDark ? Colors.deepPurple.withOpacity(0.25) : accentPurple.withOpacity(0.15));
    final textColor = isDark ? Colors.white : textDark;
    final subtitleColor = isDark ? Colors.white70 : Colors.black87;
    final cardColor = isDark ? const Color(0xFF1B1B1B) : Colors.white;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const AuthGate();
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text("Profile not found"));
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;

  return Container(
          color: bgColor,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Profile",
                        style: TextStyle(
                          fontSize: 26,
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: textColor),
                        color: isDark ? const Color(0xFF222222) : Colors.white,
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'Edit',
                            child: Text("Edit Profile", style: TextStyle(color: textColor)),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'Sign out',
                            child: Text("Sign Out", style: TextStyle(color: textColor)),
                          ),
                        ],
                        onSelected: (value) async {
                          if (value == 'Edit') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const EditProfile()),
                            );
                          } else if (value == 'Sign out') {
                            await FirebaseAuth.instance.signOut();
                          }
                        },
                      )
                    ],
                  ),

                  const SizedBox(height: 24),

                  // --------------------------------------------------------
                  // PROFILE HEADER
                  // --------------------------------------------------------
                  _buildProfileSection(userData, textColor, subtitleColor),

                  const SizedBox(height: 30),

                  // SECTION HEADER
                  _buildSectionHeader(textColor),

                  const SizedBox(height: 20),

                  // FAVORITE PROPOSITIONS LIST
                  _buildFavoritePropositionView(
                    textColor,
                    subtitleColor,
                    cardColor,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileSection(
    Map<String, dynamic> userData,
    Color textColor,
    Color subtitleColor,
  ) {
      return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Profile Image
        CircleAvatar(
          radius: 50,
          backgroundImage: (userData['ProfilePicUrl'] != null &&
                  userData['ProfilePicUrl'].toString().isNotEmpty)
              ? NetworkImage(
                  "${userData['ProfilePicUrl']}?v=${DateTime.now().millisecondsSinceEpoch}")
              : const AssetImage('images/sleepyjoe.jpg') as ImageProvider,
        ),
        const SizedBox(width: 20),
        // User Information
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                safeget(userData, 'username', fallback: 'User'),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                safeget(userData, 'email', fallback: 'No Email Found'),
                style: TextStyle(fontSize: 16, color: subtitleColor),
              ),
              const SizedBox(height: 8),
              Text(
                "${safeget(userData, 'first_name')} ${safeget(userData, 'last_name')}".trim(),
                style: TextStyle(fontSize: 16, color: subtitleColor),
              ),
              const SizedBox(height: 8),
              const Text(
                'Registration: Active',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
                Text(
                'Last Registered: Nov 2024',
                style: TextStyle(fontSize: 14, color: subtitleColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(Color textColor) {
    return Row(
      children: [
        Expanded(
          child: Divider(color: textColor.withOpacity(0.4), thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            "Favorite Propositions",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: textColor.withOpacity(0.4), thickness: 1),
        ),
      ],
    );
  }

  // --------------------------------------------------------
  // FAVORITES VIEW — shows proposition cards vertically
  // --------------------------------------------------------
  Widget _buildFavoritePropositionView(Color textColor, Color subtitleColor, Color cardColor,) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    final favStream = FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("favorites")
        .snapshots();

    final propStream = FirebaseFirestore.instance
        .collection("ballot_propositions")
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: favStream,
      builder: (context, favSnap) {
        if (favSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!favSnap.hasData || favSnap.data!.docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                "No favorite propositions yet.",
                style: TextStyle(
                  fontSize: 16,
                  color: subtitleColor,
                ),
              ),
            ),
          );
        }

        final favoriteIds = favSnap.data!.docs.map((d) => d.id).toSet();

        return StreamBuilder<QuerySnapshot>(
          stream: propStream,
          builder: (context, propSnap) {
            if (propSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!propSnap.hasData) {
              return const Center(
                child: Text("Error loading propositions"),
              );
            }

            final props = propSnap.data!.docs
                .where((d) => favoriteIds.contains(d.id))
                .toList();

            if (props.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    "No favorite propositions yet.",
                    style: TextStyle(
                      fontSize: 16,
                      color: subtitleColor,
                    ),
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: props.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final doc = props[i];

                final title = doc["title"] ?? "Untitled";
                final fullText = doc["full_text"] ?? "";
                final electionDate = doc["election_date"] ?? "";

                final preview = fullText.length > 150
                    ? "${fullText.substring(0, 150)}..."
                    : fullText;

                return _propositionCard(
                  title: title,
                  preview: preview,
                  fullText: fullText,
                  electionDate: electionDate,
                  propositionId: doc.id,
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  cardColor: cardColor
                );
              },
            );
          },
        );
      },
    );
  }

  // --------------------------------------------------------
  // PROPOSITION CARD
  // --------------------------------------------------------
  Widget _propositionCard({
    required String title,
    required String preview,
    required String fullText,
    required String electionDate,
    required String propositionId,
    required Color textColor,
    required Color subtitleColor,
    required Color cardColor,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PropositionDetailScreen(
              propositionId: propositionId,
              title: title,
              fullText: fullText,
              electionDate: electionDate,
              parish: "Unknown",
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              preview,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, color: subtitleColor)
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: subtitleColor),
                const SizedBox(width: 4),
                Text(
                  electionDate,
                  style: TextStyle(fontSize: 14, color: subtitleColor)
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}