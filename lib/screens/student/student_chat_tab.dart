import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/ai_service.dart';
import 'dart:developer';

class StudentChatTab extends StatefulWidget {
  @override
  _StudentChatTabState createState() => _StudentChatTabState();
}

class _StudentChatTabState extends State<StudentChatTab> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  final List<String> _suggestedPrompts = [
    "What documents do I need to submit?",
    "How do I check my document status?",
    "Why was my document rejected?",
    "What are the submission deadlines?",
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _processMessage(String message) async {
    if (message.isEmpty) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': message});
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final aiService = Provider.of<AIService>(context, listen: false);
      if (aiService.apiKey == 'API_KEY_NOT_FOUND') {
        setState(() {
          _messages.add({
            'sender': 'ai',
            'text':
            'It looks like the API key is missing. Please add your Gemini API key to the .env file at the root of the project and restart the app.'
          });
        });
        return;
      }

      final response = await aiService.generateChatResponse(message);

      log('AI Response: $response');

      setState(() {
        _messages.add({'sender': 'ai', 'text': response});
      });
    } catch (e) {
      log('Error processing message: $e');
      setState(() {
        _messages.add({
          'sender': 'ai',
          'text': 'Sorry, an unexpected error occurred. Please try again.'
        });
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    _messageController.clear();
    _processMessage(message);
  }

  void _sendSuggestedPrompt(String prompt) {
    _processMessage(prompt);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildSuggestions() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 4.0,
        alignment: WrapAlignment.center,
        children: _suggestedPrompts.map((prompt) {
          return ActionChip(
            label: Text(prompt, style: const TextStyle(color: Colors.black87)),
            onPressed: () => _sendSuggestedPrompt(prompt),
            backgroundColor: Colors.white,
            shape: StadiumBorder(side: BorderSide(color: Colors.grey.shade300)),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('University Assistant'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.support_agent, size: 80, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'Ask me anything!',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Or tap a suggestion below to get started.',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    _buildSuggestions(),
                  ],
                ),
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUserMessage = message['sender'] == 'user';
                return Align(
                  alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: isUserMessage
                          ? Theme.of(context).primaryColorLight
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(message['text']!),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: LinearProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                    ),
                    onSubmitted: (value) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
