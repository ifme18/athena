import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'books.dart';

class CollectionsScreen extends StatefulWidget {
  @override
  _CollectionsScreenState createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  late String _currentSchoolId = '';
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _getCurrentSchoolId();
  }

  Future<void> _getCurrentSchoolId() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('admins').doc(user.uid).get();
        Map<String, dynamic> adminData = snapshot.data() as Map<String, dynamic>;
        setState(() {
          _currentSchoolId = adminData['schoolId'];
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  Future<int> _getBookCount(String collectionId) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('materials')
        .where('collectionId', isEqualTo: collectionId)
        .get();
    return snapshot.docs.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Collections'),
        backgroundColor: Colors.teal,
      ),
      body: _hasError
          ? Center(child: Text('Error: $_errorMessage'))
          : _currentSchoolId.isEmpty
          ? Center(child: CircularProgressIndicator())
          : StreamBuilder(
        stream: FirebaseFirestore.instance.collection('collections')
            .where('schoolId', isEqualTo: _currentSchoolId)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (BuildContext context, int index) {
              QueryDocumentSnapshot document = snapshot.data!.docs[index];
              Map<String, dynamic> data = document.data() as Map<String, dynamic>;

              return FutureBuilder<int>(
                future: _getBookCount(document.id),
                builder: (BuildContext context, AsyncSnapshot<int> countSnapshot) {
                  if (!countSnapshot.hasData) {
                    return Container(
                      margin: EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.accents[index % Colors.accents.length],
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
                        title: Text(data['collectionName']),
                        subtitle: Text('Loading...'),
                        onTap: () {},
                      ),
                    );
                  }

                  return Container(
                    margin: EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.accents[index % Colors.accents.length],
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
                      title: Text('${data['collectionName']}'),
                      subtitle: Text('Books: ${countSnapshot.data}'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BooksScreen(collectionId: document.id, schoolId: _currentSchoolId),
                          ),
                        );
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
          _showAddCollectionDialog(context);
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.teal,
      ),
    );
  }

  void _showAddCollectionDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String _collectionName = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Collection'),
          content: Form(
            key: _formKey,
            child: TextFormField(
              decoration: InputDecoration(hintText: "Enter collection name"),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a collection name';
                }
                return null;
              },
              onSaved: (value) {
                _collectionName = value!;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Submit'),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  FirebaseFirestore.instance.collection('collections').add({
                    'collectionName': _collectionName,
                    'schoolId': _currentSchoolId,
                  }).then((_) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Collection added successfully')));
                  }).catchError((error) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add collection: $error')));
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
