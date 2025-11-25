//screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:lawgic/services/gemini.dart';

//single message in chat
class ChatMessage {
  final String text;
  final bool isUser; // true for user, false for AI
  
  ChatMessage({required this.text, required this.isUser});
}

//main chat screen widget
class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final GeminiService _geminiService = GeminiService();
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  //sending a message
  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    //add user message to the list
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
      _controller.clear();
    });

    try {
      //call gemini
      final responseText = await _geminiService.generateText(text);

      //add AI response to list
      setState(() {
        _messages.add(ChatMessage(text: responseText, isUser: false));
      });

    } catch (e) {
      //handle potential errors during API call
      setState(() {
        _messages.add(ChatMessage(text: "Error: Failed to connect to AI. $e", isUser: false));
      });
    } finally {
      //update loading state
      setState(() {
        _isLoading = false;
      });
    }
  }

  //build a message bubble
  Widget _buildMessage(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: <Widget>[
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: message.isUser ? Colors.blue.shade600 : Colors.grey.shade800,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16.0),
                  topRight: const Radius.circular(16.0),
                  bottomLeft: message.isUser ? const Radius.circular(16.0) : const Radius.circular(4.0),
                  bottomRight: message.isUser ? const Radius.circular(4.0) : const Radius.circular(16.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : Colors.white70,
                  fontSize: 15.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI Assistant',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        color: Colors.black, //background for chat
        child: Column(
          children: <Widget>[
            //chat message list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                reverse: true, //show latest messages at bottom
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  //display messages from end of the list (most recent)
                  return _buildMessage(_messages[_messages.length - 1 - index]);
                },
              ),
            ),
            
            //loading indicator
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(width: 8),
                    SizedBox(
                      width: 20, 
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'AI is typing...', 
                      style: TextStyle(color: Colors.white54, fontSize: 14)
                    ),
                  ],
                ),
              ),

            //input composer
            _buildTextComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextComposer() {
    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(30.0),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: <Widget>[
          //text input field
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: (_) => _sendMessage(),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration.collapsed(
                hintText: 'Ask your legal question...',
                hintStyle: TextStyle(color: Colors.white54),
              ),
            ),
          ),
          
          //send button
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.blueAccent),
              onPressed: _isLoading ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}