import 'package:flutter/material.dart';

class CommentsPage extends StatelessWidget {
  final String billId;
  const CommentsPage({super.key, required this.billId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Comments for $billId"),
      ),
      body: const Center(
        child: Text("Comments section coming soon."),
      ),
    );
  }
}
