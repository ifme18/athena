import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookDetails extends StatefulWidget {
  final String id;
  final String name;
  final bool isStudent;

  BookDetails({required this.id, required this.name, required this.isStudent});

  @override
  _BookDetailsState createState() => _BookDetailsState();
}

class _BookDetailsState extends State<BookDetails> {
  Future<void> _markAsReturned(String bookId) async {
    try {
      await FirebaseFirestore.instance.collection('books').doc(bookId).update({
        'status': 'returned',
      });
    } catch (e) {
      // Handle the error
      print('Failed to mark book as returned: $e');
    }
  }

  Future<void> _issueBookDialog() async {
    final _formKey = GlobalKey<FormState>();
    String _bookNumber = '';
    String _bookTitle = '';
    DateTime _issueDate = DateTime.now();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Issue Book to ${widget.name}'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: InputDecoration(labelText: 'Book Number'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the book number';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _bookNumber = value!;
                  },
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Book Title'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the book title';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _bookTitle = value!;
                  },
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();

                      // Perform issue book logic here
                      try {
                        await FirebaseFirestore.instance.collection('books').add({
                          'bookNumber': _bookNumber,
                          'bookTitle': _bookTitle,
                          'issueDate': _issueDate,
                          'status': 'issued',
                          'studentId': widget.isStudent ? widget.id : null,
                          'teacherId': !widget.isStudent ? widget.id : null,
                        });

                        Navigator.pop(context); // Close the dialog
                      } catch (e) {
                        print('Failed to issue book: $e');
                        // Handle error
                      }
                    }
                  },
                  child: Text('Issue Book'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book Details'),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder(
        stream: widget.isStudent
            ? FirebaseFirestore.instance.collection('books').where('studentId', isEqualTo: widget.id).snapshots()
            : FirebaseFirestore.instance.collection('books').where('teacherId', isEqualTo: widget.id).snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data = document.data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['bookTitle'] ?? 'No Title'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Book Number: ${data['bookNumber'] ?? 'N/A'}'),
                    Text('Issue Date: ${data['issueDate'] != null ? (data['issueDate'] as Timestamp).toDate().toString() : 'N/A'}'),
                    Text('Status: ${data['status'] ?? 'Unknown'}'),
                  ],
                ),
                onTap: () {
                  // Handle tap event (e.g., mark book as returned)
                  if (data['status'] == 'issued') {
                    _markAsReturned(document.id);
                  }
                },
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _issueBookDialog();
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.teal,
      ),
    );
  }
}