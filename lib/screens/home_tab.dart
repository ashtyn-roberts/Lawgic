import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeTab extends StatefulWidget {
  final String currentParish;
  final String currentElectionDate;
  const HomeTab({super.key, required this.currentParish, required this.currentElectionDate});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String selectedCategory = 'All';
  String searchQuery = '';

  // --- Category definitions ---
  final List<Map<String, dynamic>> categories = [
    {'label': 'All', 'color': Colors.grey},
    {'label': 'Healthcare', 'color': Color(0xFFB48CFB)},
    {'label': 'Education', 'color': Color(0xFF81C995)},
    {'label': 'Energy', 'color': Color(0xFFFFC47D)},
    {'label': 'Taxes', 'color': Color(0xFFF28B82)},
    {'label': 'Crime', 'color': Color(0xFF9AC8EB)},
  ];

  // --- Color fallback map if Firestore doesn't contain color ---
  final Map<String, Color> categoryColors = {
    'Healthcare': Color(0xFFB48CFB),
    'Education': Color(0xFF81C995),
    'Energy': Color(0xFFFFC47D),
    'Taxes': Color(0xFFF28B82),
    'Crime': Color(0xFF9AC8EB),
  };

  Color get primaryLavender => const Color(0xFFF4F0FB);
  Color get textDark => const Color(0xFF3D3A50);

  // The widget tree is now built from the single `build` below.

  //user sign out
  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }
  @override
  Widget build(BuildContext context) {
    // Compose a single Firestore stream filtered by parish and election date
    final stream = FirebaseFirestore.instance
        .collection('ballot_propositions')
        .where('parish', isEqualTo: widget.currentParish)
        .where('election_date', isEqualTo: widget.currentElectionDate)
        .orderBy('title')
        .snapshots();

    return Scaffold(
      backgroundColor: primaryLavender,

      // ------------------ APP BAR ------------------ 
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
              }
            },
          ),
        ],
      ),

      // ------------------ DRAWER --------------------
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
                color: categoryColors['Healthcare']!.withOpacity(0.15),
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

      // ------------------ BODY ---------------------
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search bar
            TextField(
              onChanged: (value) {
                setState(() => searchQuery = value.toLowerCase());
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Search bills...',
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

            // Category chips
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
                    onSelected: (_) =>
                        setState(() => selectedCategory = cat['label']),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // ------------------ FIRESTORE STREAM ------------------
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: stream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  // --- Filtering ---
                  final filtered = docs.where((doc) {
                    final title = (doc['title'] ?? '').toString().toLowerCase();
                    final category = doc['category'] ?? 'Uncategorized';

                    final matchesCategory = selectedCategory == 'All'
                        ? true
                        : category == selectedCategory;

                    final matchesSearch = title.contains(searchQuery);

                    return matchesCategory && matchesSearch;
                  }).toList();

                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final doc = filtered[index];
                      final title = doc['title'];
                      final summary = doc['summary']?['overview'] ??
                          "No summary available";
                      final category = doc['category'] ?? 'Uncategorized';

                      // Choose color
                      final color = categoryColors[category] ?? Colors.grey;

                      return _billCard(
                        id: doc.id,
                        title: title,
                        summary: summary,
                        color: color,
                        category: category,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------ BILL CARD ------------------
  Widget _billCard({
    required String id,
    required String title,
    required String summary,
    required Color color,
    required String category,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BillDetailPage(billId: id),
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
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: ListTile(
                title: Text(
                  title,
                  style: TextStyle(
                    color: textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[700]),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, color: Colors.black54),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CommentsPage(billId: id),
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
  }

  Widget _drawerItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: textDark),
      title: Text(title, style: TextStyle(color: textDark)),
      onTap: () {},
    );
  }
}

// ---------- Dummy Detail & Comments Pages ----------

class BillDetailPage extends StatelessWidget {
  final String billId;
  const BillDetailPage({super.key, required this.billId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bill $billId')),
      body: const Center(child: Text('Bill Details Placeholder')),
    );
  }
}

class CommentsPage extends StatelessWidget {
  final String billId;
  const CommentsPage({super.key, required this.billId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Comments for Bill $billId')),
      body: const Center(child: Text('Comments Placeholder')),
    );
  }
}
