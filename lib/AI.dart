import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';

void main() {
  runApp(const GenerativeAI());
}

class GenerativeAI extends StatefulWidget {
  const GenerativeAI({Key? key}) : super(key: key);

  @override
  State<GenerativeAI> createState() => _GenerativeAIState();
}

class _GenerativeAIState extends State<GenerativeAI> {
  bool _isDarkMode = true;

  void _toggleDarkMode() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter + OpenAI',
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: ChatScreen(
        title: 'Claudiea',
        toggleDarkMode: _toggleDarkMode,
      ),
    );
  }
}

class ChatScreen extends StatelessWidget {
  final String title;
  final VoidCallback toggleDarkMode;

  const ChatScreen({
    Key? key,
    required this.title,
    required this.toggleDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.deepOrange,
        actions: [
          IconButton(
            icon: const Icon(Icons.light_mode),
            onPressed: toggleDarkMode,
          ),
        ],
      ),
      body: const ChatWidget(),
    );
  }
}

class ChatWidget extends StatefulWidget {
  const ChatWidget({Key? key}) : super(key: key);

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFieldFocus = FocusNode(debugLabel: 'TextField');
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemBuilder: (context, idx) {
                var message = _messages[idx];
                return MessageWidget(
                  text: message.text,
                  isFromUser: message.role == 'user',
                );
              },
              itemCount: _messages.length,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 25,
              horizontal: 15,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    autofocus: true,
                    focusNode: _textFieldFocus,
                    decoration: textFieldDecoration(context, 'Enter a prompt...'),
                    controller: _textController,
                    onSubmitted: (String value) {
                      _sendChatMessage(value);
                    },
                  ),
                ),
                const SizedBox.square(
                  dimension: 15,
                ),
                if (!_loading)
                  IconButton(
                    onPressed: () async {
                      _sendChatMessage(_textController.text);
                    },
                    icon: const Icon(
                      Icons.send,
                    ),
                  )
                else
                  const CircularProgressIndicator(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendChatMessage(String message) async {
    setState(() {
      _loading = true;
      _messages.add(ChatMessage(text: message, role: 'user'));
    });

    try {
      final response = await sendChatMessage(message);
      setState(() {
        _loading = false;
        _messages.add(ChatMessage(text: response!, role: 'assistant'));
        _scrollDown();
      });
    } catch (e) {
      _showError(e.toString());
      setState(() {
        _loading = false;
      });
    } finally {
      _textController.clear();
      _textFieldFocus.requestFocus();
    }
  }

  Future<String?> sendChatMessage(String message) async {
    const String apiKey = 'sk-proj-Csrntnf6fuNEGfjQRNWyT3BlbkFJqPmAw3a5znKeuxnDpVjO';
    final Uri uri = Uri.parse('https://api.openai.com/v1/engines/davinci-codex/completions');
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };
    final Map<String, dynamic> body = {
      'prompt': message,
      'temperature': 0.5,
      'max_tokens': 100,
      'top_p': 1,
      'frequency_penalty': 0,
      'presence_penalty': 0,
    };

    final http.Response response = await http.post(uri, headers: headers, body: json.encode(body));

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final aiResponse = jsonResponse['choices'][0]['text'];
      return aiResponse;
    } else {
      print('Request failed with status: ${response.statusCode}.');
      return null;
    }
  }

  void _scrollDown() {
    WidgetsBinding.instance!.addPostFrameCallback(
          (_) => _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(
          milliseconds: 750,
        ),
        curve: Curves.easeOutCirc,
      ),
    );
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Something went wrong'),
          content: SingleChildScrollView(
            child: Text(message),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            )
          ],
        );
      },
    );
  }
}

class MessageWidget extends StatelessWidget {
  final String text;
  final bool isFromUser;

  const MessageWidget({
    Key? key,
    required this.text,
    required this.isFromUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: isFromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Flexible(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            decoration: BoxDecoration(
              color: isFromUser ? Theme.of(context).primaryColor : Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.symmetric(
              vertical: 15,
              horizontal: 20,
            ),
            margin: const EdgeInsets.only(bottom: 8),
            child: MarkdownBody(data: text),
          ),
        ),
      ],
    );
  }
}

InputDecoration textFieldDecoration(BuildContext context, String hintText) =>
    InputDecoration(
      contentPadding: const EdgeInsets.all(15),
      hintText: hintText,
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(
          Radius.circular(14),
        ),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(
          Radius.circular(14),
        ),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );

class ChatMessage {
  final String text;
  final String role;

  ChatMessage({required this.text, required this.role});
}