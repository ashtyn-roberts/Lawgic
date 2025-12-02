import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RateAppScreen extends StatefulWidget {
  const RateAppScreen({super.key});

  @override
  State<RateAppScreen> createState() => _RateAppScreenState();
}

class _RateAppScreenState extends State<RateAppScreen> {
  int _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _submitRating() async {
    if (_rating == 0) {
      setState(() => _errorMessage = "Please select a star rating.");
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance.collection("app_ratings").add({
        "uid": user?.uid,
        "email": user?.email ?? "",
        "rating": _rating,
        "feedback": _feedbackController.text.trim(),
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Thank you for your feedback!")),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "Error submitting rating: $e";
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildStar(int index) {
    return IconButton(
      onPressed: () {
        setState(() => _rating = index);
      },
      icon: Icon(
        index <= _rating ? Icons.star : Icons.star_border,
        size: 40,
        color: Colors.amber,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Rate The App"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "How would you rate your experience?",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) => _buildStar(i + 1)),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _feedbackController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: "Additional feedback (optional)",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),

            const SizedBox(height: 10),

            _isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitRating,
                      child: const Text("Submit Rating"),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}





