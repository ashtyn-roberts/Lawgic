import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lawgic/screens/auth_gate.dart';
import 'package:lawgic/screens/editprofile_screen.dart';
import 'package:lawgic/screens/proposition_detail_screen.dart';
import 'about_tab.dart';

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
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AuthGate()),
            );
          });
          return const Center(child: CircularProgressIndicator());
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;

        return Scaffold(
          backgroundColor: primaryLavender,
          drawer: _buildDrawer(),
          appBar: _buildAppBar(context),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Profile Section (Fixed at top) ---
                Container(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildProfileSection(userData),
                ),
                const SizedBox(height: 16),
                
                // --- Section Header ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildSectionHeader(),
                ),
                const SizedBox(height: 16),
                
                // --- Favorites List (Scrollable only this part) ---
                Expanded(
                  child: _buildFavoritePropositionView(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  Drawer _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: accentPurple.withOpacity(0.15)),
            child: Center(
              child: Text(
                'Menu',
                style: TextStyle(
                  color: textDark,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          _drawerItem(Icons.settings_outlined, 'Settings'),
          _drawerItem(Icons.notifications_outlined, 'Notifications'),
          _drawerItem(Icons.history, 'Recently Viewed'),
          _drawerItem(Icons.info_outline, 'About'),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: primaryLavender,
      elevation: 0,
      centerTitle: true,
      title: Text(
        "Lawgic",
        style: TextStyle(
          color: textDark,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(Icons.menu, color: textDark),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: textDark),
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          itemBuilder: (context) => [
            const PopupMenuItem(
                value: 'Edit Profile', child: Text('Edit Profile')),
            const PopupMenuDivider(),
            const PopupMenuItem(value: 'Sign out', child: Text('Sign out')),
          ],
          onSelected: (value) async {
            if (value == 'Edit Profile') {
              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfile(),
                ),
              );
            } else if (value == 'Sign out') {
              await _signOut();
            }
          },
        )
      ],
    );
  }

  Widget _buildProfileSection(Map<String, dynamic> userData) {
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
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                safeget(userData, 'email', fallback: 'No Email Found'),
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                "${safeget(userData, 'first_name')} ${safeget(userData, 'last_name')}".trim(),
                style: const TextStyle(fontSize: 16, color: Colors.grey),
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
              const Text(
                'Last Registered: Nov 2024',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        Expanded(
          child: Divider(color: Colors.grey, thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            "Favorite Propositions",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: Colors.grey, thickness: 1),
        ),
      ],
    );
  }

  Widget _drawerItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: textDark),
      title: Text(title, style: TextStyle(color: textDark)),
      onTap: () {
        if (title == 'About') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AboutTab()),
          );
        }
      },
    );
  }

  // --------------------------------------------------------
  // FAVORITES VIEW — shows proposition cards vertically
  // --------------------------------------------------------
  Widget _buildFavoritePropositionView() {
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
                  color: Colors.grey,
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
                      color: Colors.grey,
                    ),
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
          color: Colors.white,
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
                color: textDark,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              preview,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14),
                const SizedBox(width: 4),
                Text(
                  electionDate,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}