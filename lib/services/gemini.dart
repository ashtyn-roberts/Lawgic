//services/gemini.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async'; // For stream operations
import '../config/api_keys.dart';

//!!! - gemini API key goes here
final String _geminiKey = ApiKeys.geminiKey;
const String _apiUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent";

class GeminiService {
  final http.Client _client = http.Client();

  //making API call w/ exponential backoff
  Future<Map<String, dynamic>> _makeApiCall(Map<String, dynamic> payload) async {
    for (int i = 0; i < 3; i++) { //max 3 retries
      try {
        final response = await _client.post(
          Uri.parse('$_apiUrl?key=$_geminiKey'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(payload),
        ).timeout(const Duration(seconds: 15)); //timeout

        if (response.statusCode == 200) {
          return json.decode(response.body);
        } else if (response.statusCode == 429 && i < 2) { //429: Too Many Requests
          //exponential backoff
          final delay = Duration(seconds: 1 << i);
          await Future.delayed(delay);
          continue; //retry request
        } else {
          throw Exception('API call failed with status ${response.statusCode}: ${response.body}');
        }
      } on TimeoutException {
        if (i < 2) {
          final delay = Duration(seconds: 1 << i);
          await Future.delayed(delay);
          continue;
        } else {
          throw Exception('API call timed out after multiple retries.');
        }
      } catch (e) {
        //non-HTTP error like socket error or network issue
        rethrow;
      }
    }
    throw Exception('Failed to get response from Gemini API after multiple attempts.');
  }

  //chat method used by chat_screen
  Future<String> generateText(String prompt) async {
    final payload = {
      "contents": [{"parts": [{"text": prompt}]}],
    };

    final result = await _makeApiCall(payload);
    
    //extract generated text
    final text = result['candidates']?[0]?['content']?['parts']?[0]?['text'];

    if (text == null || text.isEmpty) {
      throw Exception("Gemini returned an empty or invalid response.");
    }
    return text;
  }
  
  //for summarizing bill text by bill_summarizer_screen
  Future<String> summarizeBill(String fullBillText) async {
    //instruction for the AI model to output format
    const String systemPrompt = """
      You are an objective, expert legislative analyst. 
      Your task is to review the provided full legislative text and create a concise, 
      neutral summary that is no more than 150 words long. 
      Focus only on the key provisions, purpose, and major changes proposed by the bill. 
      Do not use flowery language, quotes, or opinions. State the facts clearly.
      The summary must be 150 words or less.
    """;

    //user query w/ text to be summarized
    final String userQuery = "Please summarize the following legislative text: $fullBillText";

    final payload = {
      "contents": [{"parts": [{"text": userQuery}]}],
      "systemInstruction": {"parts": [{"text": systemPrompt}]},
    };

    final result = await _makeApiCall(payload);

    //extract generated text
    final text = result['candidates']?[0]?['content']?['parts']?[0]?['text'];

    if (text == null || text.isEmpty) {
      throw Exception("Gemini returned an empty or invalid summary response.");
    }
    return text.trim();
  }
}
