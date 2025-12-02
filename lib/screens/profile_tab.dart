import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lawgic/screens/auth_gate.dart';
import 'package:lawgic/screens/editprofile_screen.dart';
import 'about_tab.dart';

// Profile Tab Screen
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTab();
}

class _ProfileTab extends State<ProfileTab> {
  final List<Map<String, dynamic>> bills = [
    {
      'id': '192.123',
      'summary': '1 sentence summary here',
      'color': const Color(0xFFB48CFB),
      'type': 'Healthcare',
    },
    {
      'id': '1930.423',
      'summary': '1 sentence summary here',
      'color': const Color(0xFFF28B82),
      'type': 'Taxes',
    },
    {
      'id': '138.45',
      'summary': '1 sentence summary here',
      'color': const Color(0xFF81C995),
      'type': 'Education',
    },
    {
      'id': '56.786',
      'summary': '1 sentence summary here',
      'color': const Color(0xFFFB9DA7),
      'type': 'Taxes',
    },
    {
      'id': '4857.345',
      'summary': '1 sentence summary here',
      'color': const Color(0xFFFFC47D),
      'type': 'Energy',
    },
    {
      'id': '7876.5',
      'summary': '1 sentence summary here',
      'color': const Color(0xFF9AC8EB),
      'type': 'Crime',
    },
  ];

  final List<Map<String, dynamic>> categories = [
    {'label': 'All', 'color': Colors.grey},
    {'label': 'Healthcare', 'color': Color(0xFFB48CFB)},
    {'label': 'Education', 'color': Color(0xFF81C995)},
    {'label': 'Energy', 'color': Color(0xFFFFC47D)},
    {'label': 'Taxes', 'color': Color(0xFFF28B82)},
    {'label': 'Crime', 'color': Color(0xFF9AC8EB)},
  ];

  String selectedCategory = 'All';

  Color get primaryLavender => const Color(0xFFF4F0FB);
  Color get accentPurple => const Color(0xFFB48CFB);
  Color get textDark => const Color(0xFF3D3A50);

@override
Widget build(BuildContext context) {
  // Use StreamBuilder to listen in real-time to the current user's Firestore document
  final user = FirebaseAuth.instance.currentUser;

  // if no user is signed in, redirect to AuthGate
  if (user == null){
    return const AuthGate();
  }
  return StreamBuilder<DocumentSnapshot>(
    stream: FirebaseFirestore.instance
        .collection('users')         // Access the 'users' collection in Firestore
        .doc(user.uid)       // Target the document of the currently signed-in user
        .snapshots(),                // Listen for real-time updates to this document
    builder: (context, snapshot) {
      // Show a loading spinner while Firestore data is loading

      if(snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (!snapshot.hasData || !snapshot.data!.exists) {

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AuthGate(),));
        });
        return const Center(child: CircularProgressIndicator());
      }

      // Once Firestore returns data, extract it into a usable variable
      final userData = snapshot.data!.data() as Map<String, dynamic>;

      final profilePic = safeget(userData, 'ProfilePicUrl', fallback: '');
      // Filter bills based on the selected category
      // If 'All' is selected, show all bills; otherwise filter by the selected type
      final filteredBills = selectedCategory == 'All'
          ? bills
          : bills.where((b) => b['type'] == selectedCategory).toList();

      // Now return the main scaffold that represents the profile page
      return Scaffold(
        backgroundColor: primaryLavender,

        // ---------- App Bar ----------
        appBar: AppBar(
          backgroundColor: primaryLavender,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'Lawgic',
            style: TextStyle(
              color: textDark,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),

          // Left menu icon
          leading: Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu, color: textDark),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),

          // Popup menu for extra actions (Edit Profile / Sign Out)
          actions: [
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: textDark),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), ),
              itemBuilder: (context) => [
                
                const PopupMenuItem(value: 'Edit Profile', child: Text('Edit Profile')),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'Sign out', child: Text('Sign out')),
      
              ],
              onSelected: (value)  async{
              if (value == 'Edit Profile') {


                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfile(),
                    ),
                  );
                });
              } 
              else if (value == 'Sign out') {
                await _signOut();
              }
  },
            )
          
          ]
        ),

        // ---------- Drawer (Side Menu) ----------
        drawer: Drawer(
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
        ),


        // ---------- Profile Body ----------
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Profile Section ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile Image
                  CircleAvatar(
                    radius: 50,
                    backgroundImage:(userData['ProfilePicUrl'] != null &&
                                     userData['ProfilePicUrl'].toString().isNotEmpty)
                        ? NetworkImage("${userData['ProfilePicUrl']}?v=${DateTime.now().millisecondsSinceEpoch}")
                        : const AssetImage('images/sleepyjoe.jpg') as ImageProvider,
                  ),
                  const SizedBox(width: 20),

                  // User Information (pulled from Firestore)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Display user's Firestore name
                        Text(

                          safeget(userData, 'username', fallback: 'User'),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Display user's email
                        Text(
                          safeget(userData, 'email', fallback: 'No Email Found'),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Display user's full name
                        Text(
                              "${safeget(userData, 'first_name')} ${safeget(userData, 'last_name')}".trim(),
                                style: const TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                        const SizedBox(height: 8),

                        // Registration status (optional)
                        const Text(
                          'Registration: Active',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Example: Last Registered
                        const Text(
                          'Last Registered: Nov 2024',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // --- "My Bills" Section Divider ---
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  children: const [
                    Expanded(
                      child: Divider(
                        thickness: 1,
                        color: Colors.grey,
                        endIndent: 10,
                      ),
                    ),
                    Text(
                      "My Bills",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        thickness: 1,
                        color: Colors.grey,
                        indent: 10,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // --- Bills List ---
              Expanded(
                child: ListView.builder(
                  itemCount: filteredBills.length,
                  itemBuilder: (context, index) {
                    final bill = filteredBills[index];
                    return GestureDetector(
                      // Navigate to BillDetailPage when user taps a bill
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                BillDetailPage(billId: bill['id']),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Colored side bar based on bill type
                            Container(
                              width: 6,
                              height: 70,
                              decoration: BoxDecoration(
                                color: bill['color'],
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  bottomLeft: Radius.circular(16),
                                ),
                              ),
                            ),
                            Expanded(
                              child: ListTile(
                                title: Text(
                                  'Bill ${bill['id']}',
                                  style: TextStyle(
                                    color: textDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  bill['summary'],
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.chat_bubble_outline,
                                    color: Colors.black54,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CommentsPage(billId: bill['id']),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
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
}

// --- Blank Bill Detail Page ---
class BillDetailPage extends StatelessWidget {
  final String billId;
  const BillDetailPage({super.key, required this.billId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bill $billId')),
      body: const Center(
        child: Text('This will be the main Bill Detail Page.'),
      ),
    );
  }
}

// --- Blank Comments Page ---
class CommentsPage extends StatelessWidget {
  final String billId;
  const CommentsPage({super.key, required this.billId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Comments for Bill $billId')),
      body: const Center(child: Text('Comments section will go here.')),
    );
  }
}

String safeget(Map<String, dynamic> data, String key, {String fallback = ''})
{
  if (data.containsKey(key) && data[key] != null){
    return data[key].toString();
  }
  return fallback;
}