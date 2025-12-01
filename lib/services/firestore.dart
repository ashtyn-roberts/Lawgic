//services/firestore.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bill_model.dart'; 

class FirestoreService {
  //collection reference for 'bills' collection
  //all user-saved bills + summaries
  final CollectionReference _billCollection = 
      FirebaseFirestore.instance.collection('bills');

  //save or update bill
  Future<void> saveBill(Bill bill) async {
    final Map<String, dynamic> data = bill.toFirestore();
    
    try {
      if (bill.firestoreDocId != null) {
        //if doc ID exists, update the existing document
        await _billCollection.doc(bill.firestoreDocId).update(data);
      } else {
        //if no ID, create new document
        final docRef = await _billCollection.add(data);
        //update bill object in memory with newly generated firestore ID
        bill.firestoreDocId = docRef.id; 
      }
    } on FirebaseException catch (e) {
      print("Firestore Error saving/updating bill: ${e.message}");
      rethrow;
    }
  }

  //fetch bill by firestore doc ID
  //used by bill_summarizer to retrieve a fully saved bill object
  Future<Bill?> getBillByDocId(String docId) async {
    try {
      final doc = await _billCollection.doc(docId).get();
      if (doc.exists) {
        //factory constructor to create bill object from firestore data
        return Bill.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } on FirebaseException catch (e) {
      print("Firestore Error fetching bill (Doc ID: $docId): ${e.message}");
      return null;
    }
  }
  
  //update summary field specifically
  //used by gemini.dart and bill_summarizer.dart after summary successfully generated
  Future<void> updateBillSummary(String docId, String summary) async {
    try {
      await _billCollection.doc(docId).update({
        'geminiSummary': summary,
        //update timestamp to track last modification time
        'timestamp': DateTime.now().toUtc().toIso8601String(), 
      });
    } on FirebaseException catch (e) {
      print("Firestore Error updating summary (Doc ID: $docId): ${e.message}");
      rethrow;
    }
  }
  
  //fetch all saved bills
  //populate home_tab list view with the user's saved items.
  Future<List<Bill>> getAllSavedBills() async {
    try {
      final querySnapshot = await _billCollection
          .orderBy('timestamp', descending: true) 
          .get();

      return querySnapshot.docs.map((doc) {
        return Bill.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } on FirebaseException catch (e) {
      print("Firestore Error fetching saved bills list: ${e.message}");
      return [];
    }
  }
}
