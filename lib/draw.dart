import 'package:flutter/material.dart';
import 'package:flutter_signature_pad/flutter_signature_pad.dart';


class DrawingScreen extends StatefulWidget {
  @override
  _DrawingScreenState createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  final GlobalKey<SignatureState> _signatureKey = GlobalKey<SignatureState>();
  final TextEditingController _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Drawing Screen'),
        actions: [
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: () {
              _signatureKey.currentState?.clear();
              _textController.clear();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.8, // Set a fixed height for the Signature
              child: Signature(
                key: _signatureKey,
                strokeWidth: 4.0,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: 'Enter text',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _signatureKey.currentState?.clear();
          _textController.clear();
        },
        child: Icon(Icons.clear),
      ),
    );
  }
}