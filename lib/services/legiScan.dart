//services/legiScan.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/bill_model.dart';

//!!! - replace placeholder with actual LegiScan API key.
const String _legiScanApiKey = '7d803ad4b409194319d1315b3447199d'; // <-LEGISCAN KEY
const String _baseUrl = 'https://api.legiscan.com/';

class LegiScanService {
  final http.Client _client = http.Client();
  
  //call LegiScan API with standard key/format
  Future<Map<String, dynamic>> _fetchData(String op, {String? param}) async {
    final query = StringBuffer()
      ..write('$_baseUrl?key=$_legiScanApiKey&op=$op');

    if (param != null && param.isNotEmpty) {
      query.write('&id=$param');
    }

    final url = Uri.parse(query.toString());
    final response = await _client.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      //LegiScan wraps response data inside 'status' object
      if (data['status'] == 'OK') {
        return data.cast<String, dynamic>();
      } else {
        throw Exception('LegiScan API Error: ${data['status']} - ${data['message']}');
      }
    } else {
      throw Exception('Failed to connect to LegiScan API. Status code: ${response.statusCode}');
    }
  }

  //get latest list of bills for LA
  Future<List<Map<String, dynamic>>> _getRecentBillsList() async {
    //'getmasterlist' for state ID 14 (LA)
    final response = await _fetchData('getmasterlist', param: '14');
    
    final Map<String, dynamic> masterList = response['masterlist'].cast<String, dynamic>();
    
    //map of bills (keys = IDs) into list of bill objects
    final List<Map<String, dynamic>> bills = masterList.values
        .where((value) => value is Map && value.containsKey('bill_id'))
        .take(5) //limit to 5 for testing
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();
        
    return bills;
  }

  //get full text for specific bill
  Future<String> _getBillText(String billId) async {
    //'getbill' requires bill ID
    final response = await _fetchData('getbill', param: billId);
    final bill = response['bill'] as Map<String, dynamic>?;

    if (bill == null) {
      return 'Full text not available or could not be retrieved.';
    }
    
    //find latest official version of bill text
    final texts = (bill['texts'] as List<dynamic>?) ?? [];

      if (texts.isEmpty) {
        return 'Full text not available or could not be retrieved.';
      }

      final latestTextInfo = texts.lastWhere(
        (t) => t['state_link'] != null,
        orElse: () => texts.last,
      ) as Map<String, dynamic>;

      final docId = latestTextInfo['doc_id'];
      if (docId == null) {
        return 'Full text not available or could not be retrieved.';
      }

      // Use gettext with doc_id to retrieve content
      final textResponse =
          await _fetchData('gettext', param: docId.toString());

      final encodedText = textResponse['text']?['doc'] as String?;
      if (encodedText == null) {
        return 'Full text not available or could not be retrieved.';
      }

      try {
        return utf8.decode(base64.decode(encodedText));
      } catch (_) {
        return 'Full text not available or could not be retrieved.';
      }
    }

  //combine list + text fetching
  Future<List<Bill>> fetchLouisianaBills() async {
    final billList = await _getRecentBillsList();
    final List<Bill> newBills = [];

    //process each bill in order for full text
    for (final billData in billList) {
      final billId = billData['bill_id'].toString();
      final billText = await _getBillText(billId);

      final bill = Bill(
        billId: billId,
        billNumber: billData['bill_number'] ?? 'N/A',
        title: billData['title'] ?? 'No Title Available',
        latestAction: billData['change_hash'] ?? 'N/A', //change_hash = latest action summary
        billUrl: billData['state_link'] ?? 'N/A',
        billText: billText,
      );
      newBills.add(bill);
    }
    return newBills;
  }
}