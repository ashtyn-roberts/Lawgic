//screens/bill_summarizer.dart
import 'package:flutter/material.dart';
import '../screens/bill_model.dart';
import '../services/gemini.dart'; 
import '../services/firestore.dart'; 

class BillSummarizerScreen extends StatefulWidget {
  final Bill bill;

  const BillSummarizerScreen({super.key, required this.bill});

  @override
  State<BillSummarizerScreen> createState() => _BillSummarizerScreenState();
}

class _BillSummarizerScreenState extends State<BillSummarizerScreen> {
  String? _summaryText;
  bool _isLoading = false;
  
  //service instances
  final GeminiService _geminiService = GeminiService();
  final FirestoreService _firestoreService = FirestoreService();
  
  //init w/ existing summary in bill object
  @override
  void initState() {
    super.initState();
    _summaryText = widget.bill.geminiSummary;
  }

  //call Gemini API + save result
  Future<void> _generateSummary() async {
    if (widget.bill.billText.isEmpty) {
      setState(() {
        _summaryText = "Error: Bill text is empty. Cannot generate summary.";
        _isLoading = false;
      });
      return;
    }
    
    //set loading state + clear existing text
    setState(() {
      _isLoading = true;
      _summaryText = null; 
    });

    try {
      //call gemini service to generate summary
      final generatedSummary = await _geminiService.summarizeBill(widget.bill.billText);
      
      //save new summary back to db
      //check if bill has a docId, else save whole bill + update summary
      if (widget.bill.firestoreDocId == null) {
          await _firestoreService.saveBill(widget.bill); //save bill first
      }
      
      //update summary field on saved doc
      if (widget.bill.firestoreDocId != null) {
        await _firestoreService.updateBillSummary(
          widget.bill.firestoreDocId!, 
          generatedSummary,
        );
      }
      
      //update UI
      setState(() {
        _summaryText = generatedSummary;
      });

    } catch (e) {
      //error message
      setState(() {
        _summaryText = "Failed to generate summary: ${e.toString()}";
      });
    } finally {
      //turn off loading indicator
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color accentPurple = Color(0xFFB48CFB);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.bill.billNumber,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: accentPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //bill title & metadata
            Text(
              widget.bill.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),

            Text(
              'Latest Action: ${widget.bill.latestAction}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            //!!! ---gemini summary---
            const Text(
              'AI Summary (Powered by Gemini)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: accentPurple),
            ),
            const Divider(color: accentPurple, thickness: 1.5),
            const SizedBox(height: 10),

            //loading summary content
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(color: accentPurple),
                ),
              ),
            
            if (!_isLoading && _summaryText != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: accentPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accentPurple.withOpacity(0.3)),
                ),
                child: SelectableText(
                  _summaryText!,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ),

            //button for summarization
            if (!_isLoading && (_summaryText == null || _summaryText!.startsWith('Error:')))
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.flash_on, color: Colors.white),
                  label: Text(_summaryText == null ? 'Generate AI Summary' : 'Retry Summary'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _generateSummary,
                ),
              ),
              
            const SizedBox(height: 30),

            //!!!---full bill text---
            const Text(
              'Full Legislative Text',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const Divider(thickness: 1.0),
            const SizedBox(height: 10),

            //display full text
            SelectableText(
              widget.bill.billText.isNotEmpty 
                  ? widget.bill.billText 
                  : 'Full text could not be loaded from LegiScan.',
              style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}