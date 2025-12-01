import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentsTab extends StatefulWidget {
  final String propositionId;

  const CommentsTab({super.key, required this.propositionId});

  @override
  State<CommentsTab> createState() => _CommentsTabState();
}

class _CommentsTabState extends State<CommentsTab> {
  final TextEditingController _commentController = TextEditingController();

  Color get accentPurple => const Color(0xFFB48CFB);
  Color get textDark => const Color(0xFF3D3A50);

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ballot_propositions')
          .doc(widget.propositionId)
          .collection('comments')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyComments();
        }

        final comments = snapshot.data!.docs;

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final comment = comments[index];
                  return _buildCommentCard(
                    username: comment['username'] ?? 'Anonymous',
                    text: comment['text'] ?? '',
                    timestamp: comment['timestamp'],
                    likes: comment['likes'] ?? 0,
                    dislikes: comment['dislikes'] ?? 0,
                    commentId: comment.id,
                  );
                },
              ),
            ),
            _buildCommentInput(),
          ],
        );
      },
    );
  }

  Widget _buildEmptyComments() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.comment_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No comments yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Be the first to share your thoughts!',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
        _buildCommentInput(),
      ],
    );
  }

  Widget _buildCommentCard({
    required String username,
    required String text,
    required dynamic timestamp,
    required int likes,
    required int dislikes,
    required String commentId,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: accentPurple.withOpacity(0.2),
                child: Text(
                  username[0].toUpperCase(),
                  style: TextStyle(
                    color: accentPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      _formatTimestamp(timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: TextStyle(
              fontSize: 15,
              height: 1.4,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.thumb_up_outlined, size: 20),
                onPressed: () => _handleLike(commentId, true),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
              Text('$likes', style: TextStyle(color: Colors.grey[700])),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.thumb_down_outlined, size: 20),
                onPressed: () => _handleLike(commentId, false),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
              Text('$dislikes', style: TextStyle(color: Colors.grey[700])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Add a comment...',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              maxLines: null,
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            backgroundColor: accentPurple,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: () {
                if (_commentController.text.trim().isNotEmpty) {
                  _postComment(_commentController.text.trim());
                  _commentController.clear();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Just now';
    
    try {
      final DateTime dateTime = (timestamp as Timestamp).toDate();
      final Duration difference = DateTime.now().difference(dateTime);
      
      if (difference.inDays > 365) {
        return '${(difference.inDays / 365).floor()}y ago';
      } else if (difference.inDays > 30) {
        return '${(difference.inDays / 30).floor()}mo ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Just now';
    }
  }

  Future<void> _postComment(String text) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get username from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      final username = userDoc.data()?['username'] ?? 'Anonymous';

      await FirebaseFirestore.instance
          .collection('ballot_propositions')
          .doc(widget.propositionId)
          .collection('comments')
          .add({
        'text': text,
        'username': username,
        'user_id': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': 0,
        'dislikes': 0,
      });
    } catch (e) {
      debugPrint('Error posting comment: $e');
    }
  }

  Future<void> _handleLike(String commentId, bool isLike) async {
    try {
      final commentRef = FirebaseFirestore.instance
          .collection('ballot_propositions')
          .doc(widget.propositionId)
          .collection('comments')
          .doc(commentId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(commentRef);
        if (!snapshot.exists) return;

        final currentLikes = snapshot.data()?['likes'] ?? 0;
        final currentDislikes = snapshot.data()?['dislikes'] ?? 0;

        transaction.update(commentRef, {
          if (isLike) 'likes': currentLikes + 1 else 'dislikes': currentDislikes + 1,
        });
      });
    } catch (e) {
      debugPrint('Error updating like: $e');
    }
  }
}