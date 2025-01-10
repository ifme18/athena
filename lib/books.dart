import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

class BooksProvider with ChangeNotifier {
  List<QueryDocumentSnapshot> _books = [];

  List<QueryDocumentSnapshot> get books => _books;

  void setBooks(List<QueryDocumentSnapshot> newBooks) {
    _books = newBooks;
    notifyListeners();
  }

  void addBook(QueryDocumentSnapshot book) {
    _books.add(book);
    notifyListeners();
  }
}

class BooksScreen extends StatelessWidget {
  final String collectionId;
  final String schoolId;

  BooksScreen({required this.collectionId, required this.schoolId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BooksProvider(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Books'),
          backgroundColor: Colors.teal,
        ),
        body: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('materials')
              .where('collectionId', isEqualTo: collectionId)
              .where('schoolId', isEqualTo: schoolId)
              .snapshots(),
          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            context.read<BooksProvider>().setBooks(snapshot.data!.docs);

            return Consumer<BooksProvider>(
              builder: (context, booksProvider, child) {
                return ListView.builder(
                  itemCount: booksProvider.books.length,
                  itemBuilder: (BuildContext context, int index) {
                    QueryDocumentSnapshot document = booksProvider.books[index];
                    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
                    return Container(
                      margin: EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ListTile(
                        title: Text(data['bookName']),
                        subtitle: Text('Book Number: ${data['bookNumber']}'),
                        trailing: Text('Status: ${data['status']}'),
                        onTap: () {
                          _showBookDetailsDialog(context, data);
                        },
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _showAddBookDialog(context);
          },
          child: Icon(Icons.add),
          backgroundColor: Colors.teal,
        ),
      ),
    );
  }

  void _showBookDetailsDialog(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.teal.shade50,
          title: Text('Book Details', style: TextStyle(color: Colors.teal)),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Book Name: ${data['bookName']}', style: TextStyle(color: Colors.teal)),
              SizedBox(height: 8),
              Text('Book Number: ${data['bookNumber']}', style: TextStyle(color: Colors.teal)),
              SizedBox(height: 8),
              Text('Book Subject: ${data['bookSubject']}', style: TextStyle(color: Colors.teal)),
              SizedBox(height: 8),
              Text('Pages: ${data['pages']}', style: TextStyle(color: Colors.teal)),
              SizedBox(height: 8),
              Text('Acquiring Date: ${data['acquiringDate'].toDate().toString()}', style: TextStyle(color: Colors.teal)),
              SizedBox(height: 8),
              Text('Status: ${data['status']}', style: TextStyle(color: Colors.teal)),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Close', style: TextStyle(color: Colors.teal)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showAddBookDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String _bookName = '';
    String _bookNumber = '';
    String _bookSubject = '';
    int _pages = 0;
    DateTime _acquiringDate = DateTime.now();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.teal.shade50,
          title: Text('Add New Book', style: TextStyle(color: Colors.teal)),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    hintText: "Enter book name",
                    hintStyle: TextStyle(color: Colors.teal),
                    labelText: "Book Name",
                    labelStyle: TextStyle(color: Colors.teal),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a book name';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _bookName = value!;
                  },
                ),
                TextFormField(
                  decoration: InputDecoration(
                    hintText: "Enter book number",
                    hintStyle: TextStyle(color: Colors.teal),
                    labelText: "Book Number",
                    labelStyle: TextStyle(color: Colors.teal),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a book number';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _bookNumber = value!;
                  },
                ),
                TextFormField(
                  decoration: InputDecoration(
                    hintText: "Enter book subject",
                    hintStyle: TextStyle(color: Colors.teal),
                    labelText: "Book Subject",
                    labelStyle: TextStyle(color: Colors.teal),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a book subject';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _bookSubject = value!;
                  },
                ),
                TextFormField(
                  decoration: InputDecoration(
                    hintText: "Enter number of pages (e.g., 200)",
                    hintStyle: TextStyle(color: Colors.teal),
                    labelText: "Pages",
                    labelStyle: TextStyle(color: Colors.teal),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the number of pages';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _pages = int.parse(value!);
                  },
                ),
                TextFormField(
                  decoration: InputDecoration(
                    hintText: "Enter acquiring date (yyyy-mm-dd)",
                    hintStyle: TextStyle(color: Colors.teal),
                    labelText: "Acquiring Date",
                    labelStyle: TextStyle(color: Colors.teal),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the acquiring date';
                    }
                    try {
                      DateTime.parse(value);
                    } catch (e) {
                      return 'Invalid date format';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _acquiringDate = DateTime.parse(value!);
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.teal)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Submit'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.teal,
              ),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  FirebaseFirestore.instance.collection('materials').add({
                    'collectionId': collectionId,
                    'schoolId': schoolId,
                    'bookName': _bookName,
                    'bookNumber': _bookNumber,
                    'bookSubject': _bookSubject,
                    'pages': _pages,
                    'acquiringDate': _acquiringDate,
                    'status': 'available',
                  }).then((doc) {
                    Provider.of<BooksProvider>(context, listen: false).addBook(doc as QueryDocumentSnapshot<Object?>);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Book added successfully')));
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }
}
