import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'collectin.dart';

class LibraryScreen extends StatefulWidget {
  @override
  _LibraryScreenState createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late String _currentUserId = '';
  bool _isCheckingStudents = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _getCurrentUserId();
  }

  Future<void> _getCurrentUserId() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('admins').doc(user.uid).get();
        Map<String, dynamic> adminData = snapshot.data() as Map<String, dynamic>;
        setState(() {
          _currentUserId = adminData['schoolId'];
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Library',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.teal,
        elevation: 0,
        centerTitle: true,
      ),
      body: _hasError
          ? Center(child: Text('Error: $_errorMessage', style: TextStyle(color: Colors.red)))
          : _currentUserId.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildToggleButtons(),
          Expanded(
            child: _isCheckingStudents
                ? StudentList(currentUserId: _currentUserId)
                : TeacherList(currentUserId: _currentUserId),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButtons() {
    return Container(
      margin: EdgeInsets.all(16.0),
      padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildToggleButton('Students', _isCheckingStudents),
          _buildToggleButton('Teachers', !_isCheckingStudents),
          _buildBookButton(),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isActive) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _isCheckingStudents = label == 'Students';
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? Colors.teal : Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.teal,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBookButton() {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CollectionsScreen()),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        child: Text(
          'Books',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class StudentList extends StatefulWidget {
  final String currentUserId;

  StudentList({required this.currentUserId});

  @override
  _StudentListState createState() => _StudentListState();
}

class _StudentListState extends State<StudentList> {
  final TextEditingController _searchController = TextEditingController();
  List<QueryDocumentSnapshot> _filteredStudents = [];
  List<QueryDocumentSnapshot> _allStudents = [];

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    QuerySnapshot snapshot =
    await FirebaseFirestore.instance.collection('students').where('schoolId', isEqualTo: widget.currentUserId).get();
    setState(() {
      _allStudents = snapshot.docs;
      _filteredStudents = snapshot.docs;
    });
  }

  void _filterStudents(String searchText) {
    setState(() {
      _filteredStudents = _allStudents.where((document) {
        String studentName = (document.data() as Map<String, dynamic>)['name'].toString().toLowerCase();
        return studentName.contains(searchText.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            onChanged: _filterStudents,
            decoration: InputDecoration(
              hintText: 'Search for a student...',
              prefixIcon: Icon(Icons.search, color: Colors.teal),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
                borderSide: BorderSide(color: Colors.teal),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
                borderSide: BorderSide(color: Colors.teal),
              ),
            ),
          ),
        ),
        Expanded(
          child: _filteredStudents.isEmpty
              ? Center(child: Text('No students found.', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
            itemCount: _filteredStudents.length,
            itemBuilder: (BuildContext context, int index) {
              DocumentSnapshot document = _filteredStudents[index];
              Map<String, dynamic> data = document.data() as Map<String, dynamic>;
              return Card(
                margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(data['name'], style: TextStyle(fontSize: 16)),
                  subtitle: Text(data['regno'], style: TextStyle(color: Colors.grey)),
                  trailing: Icon(Icons.chevron_right, color: Colors.teal),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => BookDetails(studentId: document.id)),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class TeacherList extends StatefulWidget {
  final String currentUserId;

  TeacherList({required this.currentUserId});

  @override
  _TeacherListState createState() => _TeacherListState();
}

class _TeacherListState extends State<TeacherList> {
  late String _searchText = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            onChanged: (value) {
              setState(() {
                _searchText = value.toLowerCase();
              });
            },
            decoration: InputDecoration(
              hintText: 'Search for a teacher...',
              prefixIcon: Icon(Icons.search, color: Colors.teal),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
                borderSide: BorderSide(color: Colors.teal),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
                borderSide: BorderSide(color: Colors.teal),
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder(
            stream: FirebaseFirestore.instance.collection('teachers').where('schoolId', isEqualTo: widget.currentUserId).snapshots(),
            builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.red)));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              var filteredTeachers = snapshot.data!.docs.where((document) {
                String teacherName = (document.data() as Map<String, dynamic>)['name'].toString().toLowerCase();
                return teacherName.contains(_searchText);
              }).toList();

              return ListView.builder(
                itemCount: filteredTeachers.length,
                itemBuilder: (BuildContext context, int index) {
                  DocumentSnapshot document = filteredTeachers[index];
                  Map<String, dynamic> data = document.data() as Map<String, dynamic>;
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: Text(data['name'], style: TextStyle(fontSize: 16)),
                      trailing: Icon(Icons.chevron_right, color: Colors.teal),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => BookDetails(teacherId: document.id)),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class BookDetails extends StatefulWidget {
  final String studentId;
  final String teacherId;

  BookDetails({this.studentId = '', this.teacherId = ''});

  @override
  _BookDetailsState createState() => _BookDetailsState();
}

class _BookDetailsState extends State<BookDetails> {
  final _formKey = GlobalKey<FormState>();
  String _bookName = '';
  String _bookNumber = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: StreamBuilder(
        stream: widget.studentId.isNotEmpty
            ? FirebaseFirestore.instance.collection('books').where('studentId', isEqualTo: widget.studentId).snapshots()
            : FirebaseFirestore.instance.collection('books').where('teacherId', isEqualTo: widget.teacherId).snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error fetching books: ${snapshot.error}\n'
                    'Please check your internet connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                widget.studentId.isNotEmpty
                    ? 'No books found for this student.\n'
                    'Student ID: ${widget.studentId}'
                    : 'No books found for this teacher.\n'
                    'Teacher ID: ${widget.teacherId}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data = document.data() as Map<String, dynamic>;
              return Card(
                margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(data['bookName'] ?? 'Unnamed Book', style: TextStyle(fontSize: 18)),
                  subtitle: Text('Book Number: ${data['bookNumber'] ?? 'N/A'}', style: TextStyle(color: Colors.grey)),
                  trailing: Text('Status: ${data['status'] ?? 'Unknown'}', style: TextStyle(color: Colors.teal)),
                  onTap: () {
                    _showReturnDialog(context, document);
                  },
                ),
              );
            }).toList(),
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
    );
  }

  void _showReturnDialog(BuildContext context, DocumentSnapshot document) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Mark as Returned', style: TextStyle(color: Colors.teal)),
          content: Text('Do you want to mark this book as returned?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Mark as Returned', style: TextStyle(color: Colors.teal)),
              onPressed: () {
                _markBookAsReturned(context, document);
              },
            ),
          ],
        );
      },
    );
  }

  void _markBookAsReturned(BuildContext context, DocumentSnapshot document) {
    FirebaseFirestore.instance.collection('books').doc(document.id).update({'status': 'Returned'}).then((_) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Book marked as returned'), backgroundColor: Colors.teal));
      setState(() {});
    }).catchError((error) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update book status: $error'), backgroundColor: Colors.red));
    });
  }

  void _showAddBookDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Book', style: TextStyle(color: Colors.teal)),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  decoration: InputDecoration(hintText: "Enter book name"),
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
                  decoration: InputDecoration(hintText: "Enter book number"),
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
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Submit', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              onPressed: () {
                _submitNewBook(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _submitNewBook(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      FirebaseFirestore.instance.collection('books').add({
        'bookName': _bookName,
        'bookNumber': _bookNumber,
        'status': 'Issued',
        'studentId': widget.studentId,
        'teacherId': widget.teacherId,
      }).then((_) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Book added successfully'), backgroundColor: Colors.teal));
        setState(() {});
      }).catchError((error) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add book: $error'), backgroundColor: Colors.red));
      });
    }
  }
}