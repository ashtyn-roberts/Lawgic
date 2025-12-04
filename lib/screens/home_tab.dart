//screens/home_tab.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lawgic/screens/editprofile_screen.dart';
import '../screens/profile_tab.dart';
import 'proposition_detail_screen.dart';
import 'about_tab.dart';
import '../screens/settings_screen.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String searchQuery = '';
  String? userParish;
  String? userParishCode;
  bool _isLoadingUser = true;
  bool isDarkMode = false;

  Color get primaryLavender => const Color(0xFFF4F0FB);
  Color get accentPurple => const Color(0xFFB48CFB);
  Color get textDark => const Color(0xFF3D3A50);

  @override
  void initState() {
    super.initState();
    _loadUserParish();
  }

  /// Load user's parish from Firestore
  Future<void> _loadUserParish() async {
    if (!mounted) return;
    setState(() => _isLoadingUser = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() => _isLoadingUser = false);
        return;
      }

      final userDoc = 
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        setState(() {
          userParish = data['voter_parish'];
          // Convert to format with code (e.g., "EAST BATON ROUGE - 17")
          userParishCode = _getParishWithCode(userParish);
          _isLoadingUser = false;
        });
      } else {
        setState(() => _isLoadingUser = false);
      }
    } catch (e) {
      debugPrint("Error loading user parish: $e");
      if (!mounted) return;
      setState(() => _isLoadingUser = false);
    }
  }

  /// Convert parish name to format with code
  String? _getParishWithCode(String? parish) {
    if (parish == null) return null;
    
    final parishCodes = {
      'ACADIA': '01', 'ALLEN': '02', 'ASCENSION': '03', 'ASSUMPTION': '04',
      'AVOYELLES': '05', 'BEAUREGARD': '06', 'BIENVILLE': '07', 'BOSSIER': '08',
      'CADDO': '09', 'CALCASIEU': '10', 'CALDWELL': '11', 'CAMERON': '12',
      'CATAHOULA': '13', 'CLAIBORNE': '14', 'CONCORDIA': '15', 'DE SOTO': '16',
      'EAST BATON ROUGE': '17', 'EAST CARROLL': '18', 'EAST FELICIANA': '19',
      'EVANGELINE': '20', 'FRANKLIN': '21', 'GRANT': '22', 'IBERIA': '23',
      'IBERVILLE': '24', 'JACKSON': '25', 'JEFFERSON': '26', 'JEFFERSON DAVIS': '27',
      'LAFAYETTE': '28', 'LAFOURCHE': '29', 'LA SALLE': '30', 'LINCOLN': '31',
      'LIVINGSTON': '32', 'MADISON': '33', 'MOREHOUSE': '34', 'NATCHITOCHES': '35',
      'ORLEANS': '36', 'OUACHITA': '37', 'PLAQUEMINES': '38', 'POINTE COUPEE': '39',
      'RAPIDES': '40', 'RED RIVER': '41', 'RICHLAND': '42', 'SABINE': '43',
      'ST. BERNARD': '44', 'ST. CHARLES': '45', 'ST. HELENA': '46', 'ST. JAMES': '47',
      'ST. JOHN THE BAPTIST': '48', 'ST. LANDRY': '49', 'ST. MARTIN': '50',
      'ST. MARY': '51', 'ST. TAMMANY': '52', 'TANGIPAHOA': '53', 'TENSAS': '54',
      'TERREBONNE': '55', 'UNION': '56', 'VERMILION': '57', 'VERNON': '58',
      'WASHINGTON': '59', 'WEBSTER': '60', 'WEST BATON ROUGE': '61',
      'WEST CARROLL': '62', 'WEST FELICIANA': '63', 'WINN': '64',
    };

    final parishUpper = parish.toUpperCase();
    final code = parishCodes[parishUpper];
    
    return code != null ? '$parishUpper - $code' : parish;
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    // ------------------ THEME DETECTION ------------------
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final bgColor = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF4F0FB);
    final cardColor = isDark ? const Color(0xFF1B1B1B) : Colors.white;
    final drawerColor = isDark ? const Color(0xFF121212) : Colors.white;
    final drawerDivider = isDark ? Colors.white24 : Colors.grey.withOpacity(0.3);

    final drawerHeaderColor =
        isDark ? Colors.deepPurple.withOpacity(0.25) : accentPurple.withOpacity(0.15);

    final textColor = isDark ? Colors.white : textDark;
    final subtitleColor = isDark ? Colors.white70 : Colors.grey[700];

    return Scaffold(
      backgroundColor: bgColor,

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
            icon: Icon(Icons.menu, color: textColor),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      // ------------------ DRAWER --------------------
      drawer: Drawer(
        backgroundColor: drawerColor,
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
              decoration: BoxDecoration(color: drawerHeaderColor),
              child: Center(
                child: Text(
                  'Menu',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            _drawerItem(Icons.settings_outlined, 'Settings', textColor),
            _drawerItem(Icons.info_outline, 'About', textColor),

            Divider(color: drawerDivider),

            // Dark Mode Toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: ListTile(
                leading: Icon(Icons.dark_mode, color: textColor),
                title: Text('Dark Mode', style: TextStyle(color: textColor)),
                trailing: Switch(
                  value: isDark,
                  activeColor: accentPurple,
                  onChanged: (value) {
                  Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
                  },
                ),
              ),
            ),

            Divider(color: drawerDivider),
          ],
        ),
      ),

      // ------------------ BODY ---------------------
      body: _isLoadingUser
          ? const Center(child: CircularProgressIndicator())
          : userParishCode == null
              ? _buildNoParishView(textColor, subtitleColor)
              : _buildPropositionsView(textColor, subtitleColor, cardColor),
    );
  }

  /// Show message when user doesn't have parish info
  Widget _buildNoParishView(Color textColor, Color? subtitleColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.how_to_vote, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Voter Registration Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please complete your voter registration to view ballot propositions.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: subtitleColor,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EditProfile()),
                );
              },
              child: const Text('Update Registration Info'),
            ),
          ],
        ),
      ),
    );
  }

  /// Main view showing ballot propositions
  Widget _buildPropositionsView(Color textColor, Color? subtitleColor, Color cardColor) {
    // Debug: Print what we're querying for
    debugPrint("Querying ballot_propositions for parish: $userParishCode");
    
    // Stream of ballot propositions for user's parish
    final stream = FirebaseFirestore.instance
        .collection('ballot_propositions')
        .where('parish', isEqualTo: userParishCode)
        .snapshots();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Parish info banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accentPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accentPurple.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on, color: accentPurple),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Parish',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        userParish ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 16,
                          color: textDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadUserParish,
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Search bar
          TextField(
            onChanged: (value) {
              setState(() => searchQuery = value.toLowerCase());
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1B1B1B) : Colors.white,
              hintText: 'Search propositions...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              hintStyle: TextStyle(color: Colors.grey[600]),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Section title
          Text(
            'Ballot Propositions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),

          const SizedBox(height: 12),

          // ------------------ PROPOSITIONS LIST ------------------
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  debugPrint("Error in StreamBuilder: ${snapshot.error}");
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                          const SizedBox(height: 16),
                          Text(
                            'Error Loading Propositions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            snapshot.error.toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadUserParish,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.ballot_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No Propositions Found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No ballot propositions available for your parish yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                // Filter by search query
                final filtered = docs.where((doc) {
                  if (searchQuery.isEmpty) return true;
                  
                  final title = (doc['title'] ?? '').toString().toLowerCase();
                  final fullText = (doc['full_text'] ?? '').toString().toLowerCase();
                  
                  return title.contains(searchQuery) || fullText.contains(searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No propositions match your search'),
                  );
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final title = doc['title'] ?? 'Untitled Proposition';
                    final fullText = doc['full_text'] ?? '';
                    final electionDate = doc['election_date'] ?? '';
                    
                    // Get preview (first 150 characters)
                    String preview = fullText.length > 150
                        ? '${fullText.substring(0, 150)}...'
                        : fullText;

                    return _propositionCard(
                      propositionId: doc.id,
                      title: title,
                      preview: preview,
                      fullText: fullText,
                      electionDate: electionDate,
                      aiSummary: doc['ai_summary'],
                      keyPoints: doc['ai_key_points'],
                      aiYesVote: doc['ai_yes_vote'],
                      aiNoVote: doc['ai_no_vote'],
                      cardColor: cardColor,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Proposition card widget
  Widget _propositionCard({
    required String title,
    required String preview,
    required String fullText,
    required String electionDate,
    required String propositionId,
    String? aiSummary,
    String? keyPoints,
    String? aiYesVote,
    String? aiNoVote,
    Color? cardColor,
    Color? textColor,
    Color? subtitleColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap ?? () {
        // Navigate to detail screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PropositionDetailScreen(
              propositionId: propositionId,
              title: title,
              fullText: fullText,
              electionDate: electionDate,
              parish: userParish ?? 'Unknown',
              aiSummary: aiSummary,
              keyPoints: keyPoints,
              aiYesVote: aiYesVote,
              aiNoVote: aiNoVote,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cardColor ?? Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Color accent bar
            Container(
              width: 6,
              height: 100,
              decoration: BoxDecoration(
                color: accentPurple,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor ?? Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      preview,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: subtitleColor ?? Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                    if (electionDate.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: subtitleColor ?? Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            electionDate,
                            style: TextStyle(
                              fontSize: 12,
                              color: subtitleColor ?? Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Arrow icon
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: subtitleColor ?? Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, Color textColor) {
    return ListTile(
      leading: Icon(icon, color: textColor),
      title: Text(title, style: TextStyle(color: textColor)),
      onTap: () {
        Navigator.pop(context); // close drawer first

      if (title == 'Settings') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        );
      }
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