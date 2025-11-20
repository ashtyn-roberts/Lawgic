import 'package:flutter/material.dart';

class NotesPage extends StatelessWidget {
  final String billId;
  const NotesPage({super.key, required this.billId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Your Notes for $billId"),
      ),
      body: const Center(
        child: Text("Notes feature coming soon."),
      ),
    );
  }
}
