import 'package:flutter/material.dart';

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
    // Filter bills based on selected category
    final filteredBills = selectedCategory == 'All'
        ? bills
        : bills.where((b) => b['type'] == selectedCategory).toList();

    return Scaffold(
      backgroundColor: primaryLavender,
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
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: textDark),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.add, color: textDark),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'Edit Profile',
                child: Text('Edit Profile'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'Sign Out', child: Text('Sign Out')),
            ],
          ),
        ],
      ),

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

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //  Profile section
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 50, // slightly bigger for visual balance
                  backgroundImage: AssetImage('images/sleepyjoe.jpg'),
                ),

                const SizedBox(width: 20), // space between avatar and info
                //  Expanded user information section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Joe Biden',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '@sleepyjoe',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      //  New line for registration status
                      Text(
                        'Registration: Active',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      //  Optional: add more info below
                      Text(
                        'Last Registered : Nov 2024',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Section divider labeled "My Bills"
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

            // Bills list
            Expanded(
              child: ListView.builder(
                itemCount: filteredBills.length,
                itemBuilder: (context, index) {
                  final bill = filteredBills[index];
                  return GestureDetector(
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
  }

  Widget _drawerItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: textDark),
      title: Text(title, style: TextStyle(color: textDark)),
      onTap: () {},
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

// --- Blank Bill Detail Page ---
class EditProfile extends StatelessWidget {
  final String billId;
  const EditProfile({super.key, required this.billId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bill $billId')),
      body: const Center(child: Text('This will be the Edit Profile Page.')),
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

