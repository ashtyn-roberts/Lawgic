import 'package:flutter/material.dart';
import 'package:lawgic/services/favorites_service.dart';
import 'comments_tab.dart';
import 'notes_tab.dart';


class PropositionDetailScreen extends StatefulWidget {
  final String propositionId;
  final String title;
  final String fullText;
  final String electionDate;
  final String parish;


  const PropositionDetailScreen({
    super.key,
    required this.propositionId,
    required this.title,
    required this.fullText,
    required this.electionDate,
    required this.parish,

  });

  @override
  State<PropositionDetailScreen> createState() => _PropositionDetailScreenState();
}

class _PropositionDetailScreenState extends State<PropositionDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Color get primaryLavender => const Color(0xFFF4F0FB);
  Color get accentPurple => const Color(0xFFB48CFB);
  Color get textDark => const Color(0xFF3D3A50);

  final FavoritesService _favoritesService = FavoritesService();
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    final fav = await _favoritesService.isFavorite(widget.propositionId);
    if (mounted) {
      setState(() {
        _isFavorite = fav;
      });
    }
  }

  void _toggleFavorite() async {
    final billData = {
    'title': widget.title,
    'full_text': widget.fullText,
    'election_date': widget.electionDate,
    'parish': widget.parish,
    };

    if(_isFavorite) {
      await _favoritesService.removeFavorite(widget.propositionId);
    } else {
      await _favoritesService.addFavorite(widget.propositionId, billData);
  
    }

    if (mounted)
    {
      setState(() {
        _isFavorite = !_isFavorite;
      });
    }
  }


  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryLavender,
      appBar: AppBar(
        backgroundColor: primaryLavender,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Proposition Details',
          style: TextStyle(
            color: textDark,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: accentPurple,
          unselectedLabelColor: Colors.grey,
          indicatorColor: accentPurple,
          tabs: const [
            Tab(text: 'Details'),
            Tab(text: 'Comments'),
            Tab(text: 'Notes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Details Tab
          _buildDetailsTab(),
          
          // Comments Tab (separate file)
          CommentsTab(propositionId: widget.propositionId),
          
          // Notes Tab (separate file)
          NotesTab(propositionId: widget.propositionId),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Election: ${widget.electionDate}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.parish,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          
          const SizedBox(height: 12),

          Center(
  child: ElevatedButton.icon(
    onPressed: _toggleFavorite,
    icon: Icon(
      _isFavorite ? Icons.favorite : Icons.favorite_border,
      color: Colors.white,
    ),
    label: Text(_isFavorite ? 'Remove from Favorites' : 'Add to Favorites'),
    style: ElevatedButton.styleFrom(
      backgroundColor: accentPurple,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
),

          // Full Text Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.description, color: accentPurple, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Full Text',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  widget.fullText,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Community Sentiment Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.poll, color: accentPurple, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Community Sentiment',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _sentimentIndicator('For', 65, Colors.green),
                    _sentimentIndicator('Against', 35, Colors.red),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'Based on community comments',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sentimentIndicator(String label, int percentage, Color color) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                value: percentage / 100,
                strokeWidth: 8,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}