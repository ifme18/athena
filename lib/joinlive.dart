import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class JoinLivestreamScreen extends StatefulWidget {
  @override
  _JoinLivestreamScreenState createState() => _JoinLivestreamScreenState();
}

class _JoinLivestreamScreenState extends State<JoinLivestreamScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _linkController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _pasteFromClipboard();

    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    _animation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      setState(() {
        _linkController.text = data.text!;
      });
    }
  }

  Future<void> _joinLivestream() async {
    final link = _linkController.text;

    if (link.isNotEmpty) {
      try {
        final snapshot = await _firestore.collection('livestream_links').doc(link).get();
        if (snapshot.exists) {
          print('Navigating to video conferencing screen with link: $link');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Livestream link not found. Please enter a valid link.')),
          );
        }
      } catch (error) {
        print('Error joining livestream: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred. Please try again later.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a livestream link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Join Livestream'),
        backgroundColor: Colors.deepOrange,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _linkController,
              decoration: InputDecoration(
                labelText: 'Livestream Link',
              ),
            ),
            SizedBox(height: 16.0),
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return ElevatedButton(
                  onPressed: _joinLivestream,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color.lerp(Colors.blue, Colors.purple, _animation.value)!,
                          Color.lerp(Colors.purple, Colors.red, _animation.value)!,
                          Color.lerp(Colors.red, Colors.orange, _animation.value)!,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Container(
                      constraints: BoxConstraints(minWidth: 88.0, minHeight: 36.0),
                      alignment: Alignment.center,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        child: Text(
                          'Join',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}