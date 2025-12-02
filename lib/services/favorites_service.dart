import '../models/bill_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FavoritesService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _favoritesCollection{
    final uid = _auth.currentUser?.uid;
    if(uid == null){
      throw Exception("User not logged in");
    }
    return _db.collection('users').doc(uid).collection('favorites');
  }

  Future<void> addFavorite(String billId, Map<String, dynamic> billData) async {
    await _favoritesCollection.doc(billId).set({
      'id' :billId,
      ...billData,
      "timestamp": FieldValue.serverTimestamp(), 
  });
  }
  
  Future<void> removeFavorite(String billId) async {
    await _favoritesCollection.doc(billId).delete();
  }

  Future<bool> isFavorite(String billId) async {
    final doc = await _favoritesCollection.doc(billId).get();
    return doc.exists;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getFavorites()  {
    return  _favoritesCollection.orderBy('timestamp', descending: true).snapshots();;
  }
}