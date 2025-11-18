import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../screens/profile_tab.dart';
import '../screens/bill_model.dart';
import '../services/legiScan.dart';
import '../services/firestore.dart';
import '../screens/bill_summarizer.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final LegiScanService _legiScanService = LegiScanService();
  final FirestoreService _firestoreService = FirestoreService();
  
  List<Bill> _allBills = [];
  bool _isLoading = true;

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
  void initState() {
    super.initState();
    _loadBills();
  }

  Future<void> _loadBills() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch bills from LegiScan
      final newBills = await _legiScanService.fetchLouisianaBills();

      // Optionally fetch saved bills from Firestore (not yet merged here)
      final savedBills = await _firestoreService.getAllSavedBills();
      // TODO: merge newBills + savedBills if you want “saved” indicators, etc.

      setState(() {
        _allBills = newBills;
      });
    } catch (e) {
      // You might later show a SnackBar or dialog instead of just printing
      debugPrint("Error loading bills: $e");
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  //user sign out
  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    // Filter bills based on selected category
    final List<Bill> filteredBills =
        selectedCategory == 'All' ? _allBills : _allBills; // TODO: filter by type when added

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
            icon: Icon(Icons.person_outline, color: textDark),
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Account', child: Text('Account')),
              const PopupMenuItem(value: 'Registration Status', child: Text('Registration Status')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'Sign Out', child: Text('Sign Out')),
            ],
            onSelected: (value) {
              if (value == 'Sign Out') {
                _signOut();
              } else if (value == 'Account') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileTab(),
                  ),
                );
              } else if (value == 'Registration Status') {
                // TODO: implement registration status page/dialog
              }
              //navigation/logic for other menu items here
            },
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
              decoration: BoxDecoration(
                color: accentPurple.withOpacity(0.15),
              ),
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
          children: [
            // Search bar
            TextField(
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Hinted search text',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                hintStyle: TextStyle(color: Colors.grey[600]),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Category chips (with filter functionality)
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final bool isSelected = selectedCategory == cat['label'];
                  return ChoiceChip(
                    label: Text(
                      cat['label'],
                      style: TextStyle(
                        color: isSelected ? Colors.white : cat['color'].withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: cat['color'].withOpacity(0.9),
                    backgroundColor: cat['color'].withOpacity(0.15),
                    onSelected: (_) {
                      setState(() {
                        selectedCategory = cat['label'];
                      });
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // Bills list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredBills.isEmpty
                      ? Center(
                          child: Text(
                            'No bills found.',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredBills.length,
                          itemBuilder: (context, index) {
                            final bill = filteredBills[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        BillSummarizerScreen(
                                      bill: bill,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12
                                          .withOpacity(0.05),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // Colored stripe – using accentPurple for now
                                    Container(
                                      width: 6,
                                      height: 70,
                                      decoration: BoxDecoration(
                                        color: accentPurple,
                                        borderRadius:
                                            const BorderRadius.only(
                                          topLeft: Radius.circular(16),
                                          bottomLeft:
                                              Radius.circular(16),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: ListTile(
                                        title: Text(
                                          bill.billNumber,
                                          style: TextStyle(
                                            color: textDark,
                                            fontWeight:
                                                FontWeight.w600,
                                          ),
                                        ),
                                        subtitle: Text(
                                          bill.geminiSummary ??
                                              bill.latestAction,
                                          maxLines: 2,
                                          overflow:
                                              TextOverflow.ellipsis,
                                          style: TextStyle(
                                              color:
                                                  Colors.grey[700]),
                                        ),
                                        trailing: IconButton(
                                          icon: const Icon(
                                            Icons
                                                .chat_bubble_outline,
                                            color: Colors.black54,
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    CommentsPage(
                                                  billId: bill.billId,
                                                ),
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

// --- Blank Comments Page ---
class CommentsPage extends StatelessWidget {
  final String billId;
  const CommentsPage({super.key, required this.billId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Comments for Bill $billId')),
      body: const Center(
        child: Text('Comments section will go here.'),
      ),
    );
  }
}
