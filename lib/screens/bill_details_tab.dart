import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'comments_tab.dart';
import 'notes_tab.dart';

class BillDetailsPage extends StatelessWidget {
  final String billId;
  const BillDetailsPage({super.key, required this.billId});

  Color get textDark => const Color(0xFF3D3A50);
  Color get accentPurple => const Color(0xFFB48CFB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F0FB),
      appBar: AppBar(
        title: const Text("Lawgic"),
        backgroundColor: Colors.transparent,
        foregroundColor: textDark,
        elevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection("ballot_propositions")
            .doc(billId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final title = data["title"] ?? "Bill";
          final fullText = data["full_text"] ?? "No bill text available.";
          final summary = data["summary"]?["overview"] ?? "No summary available.";
          final category = data["category"] ?? "Uncategorized";

          final politicalLean = data["political_lean"] ?? {};
          final explanation = politicalLean["explanation"] ?? "No analysis available.";

          final supporting = List<String>.from(politicalLean["supporting_groups"] ?? []);
          final opposing = List<String>.from(politicalLean["opposing_groups"] ?? []);

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ------------------ TITLE ------------------
                  Text(
                    title,
                    style: TextStyle(
                      color: textDark,
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ------------------ BILL VIEW WINDOW ------------------
                  Container(
                    height: 260,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: SingleChildScrollView(
                        child: Text(
                          fullText,
                          style: TextStyle(
                            color: textDark,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ------------------ SUMMARY ------------------
                  Text(
                    "Summary",
                    style: TextStyle(
                      color: textDark,
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    summary,
                    style: TextStyle(
                      color: Colors.grey[800],
                      height: 1.35,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ------------------ CATEGORY & POLITICAL GAUGE ------------------
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: accentPurple.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: accentPurple,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),

                      // Political lean placeholder gauge (you can later replace with a gauge widget)
                      Column(
                        children: [
                          const Icon(Icons.circle, color: Colors.blue, size: 16),
                          Text(
                            "Lean",
                            style: TextStyle(color: textDark, fontSize: 11),
                          )
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // ------------------ SUPPORT / OPPOSE ------------------
                  Text(
                    "Political Tendencies",
                    style: TextStyle(
                      color: textDark,
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Text(
                    explanation,
                    style: TextStyle(color: Colors.grey[800], height: 1.4),
                  ),

                  const SizedBox(height: 16),

                  if (supporting.isNotEmpty)
                    _leanList("Groups Typically Supporting:", supporting, Colors.green),

                  if (opposing.isNotEmpty)
                    _leanList("Groups Typically Opposing:", opposing, Colors.red),

                  const SizedBox(height: 30),

                  // ------------------ COMMENTS BUTTON ------------------
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentPurple,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 26,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CommentsPage(billId: billId),
                          ),
                        );
                      },
                      child: const Text(
                        "Join the Discussion",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ------------------ NOTES BUTTON ------------------
                  Center(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 26,
                          vertical: 12,
                        ),
                        side: BorderSide(color: accentPurple, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NotesPage(billId: billId),
                          ),
                        );
                      },
                      child: Text(
                        "Your Notes",
                        style: TextStyle(color: accentPurple),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ------------------ SUPPORT/OPPOSE LIST UI ------------------
  Widget _leanList(String label, List<String> items, Color dotColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style:
                TextStyle(color: textDark, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(Icons.circle, color: dotColor, size: 10),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(color: Colors.grey[800], fontSize: 14),
                    ),
                  )
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
