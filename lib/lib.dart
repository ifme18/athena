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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Library',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.teal[600],
        elevation: 0,
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: _hasError
          ? Center(
        child: ErrorDisplay(message: _errorMessage),
      )
          : _currentUserId.isEmpty
          ? Center(
        child: CircularProgressIndicator(
          color: Colors.teal,
        ),
      )
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildToggleButton('Students', _isCheckingStudents),
            SizedBox(width: 8),
            _buildToggleButton('Teachers', !_isCheckingStudents),
            SizedBox(width: 8),
            _buildBookButton(),
          ],
        ),
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
          backgroundColor: isActive ? Colors.teal[600] : Colors.grey[100],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.symmetric(vertical: 12),
          elevation: isActive ? 4 : 0,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.teal[600],
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBookButton() {
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CollectionsScreen()),
          );
        },
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 4,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[600]!, Colors.purple[600]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Books',
              textAlign: TextAlign.center,
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
  }
}

class ErrorDisplay extends StatelessWidget {
  final String message;

  const ErrorDisplay({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red[300]!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 48),
          SizedBox(height: 16),
          Text(
            'Error Occurred',
            style: TextStyle(
              color: Colors.red[800],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: Colors.red[800]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final String message;

  const EmptyStateWidget({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('schoolId', isEqualTo: widget.currentUserId)
          .get();

      setState(() {
        _allStudents = snapshot.docs;
        _filteredStudents = snapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: TextField(
            controller: _searchController,
            onChanged: _filterStudents,
            decoration: InputDecoration(
              hintText: 'Search for a student...',
              prefixIcon: Icon(Icons.search, color: Colors.teal[600]),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: Icon(Icons.clear, color: Colors.grey),
                onPressed: () {
                  _searchController.clear();
                  _filterStudents('');
                },
              )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
                borderSide: BorderSide(color: Colors.teal[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
                borderSide: BorderSide(color: Colors.teal[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
                borderSide: BorderSide(color: Colors.teal[600]!, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: Colors.teal))
              : _filteredStudents.isEmpty
              ? EmptyStateWidget(message: 'No students found')
              : ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filteredStudents.length,
            itemBuilder: (BuildContext context, int index) {
              DocumentSnapshot document = _filteredStudents[index];
              Map<String, dynamic> data = document.data() as Map<String, dynamic>;
              return StudentCard(
                name: data['name'],
                regNo: data['regno'],
                documentId: document.id,
              );
            },
          ),
        ),
      ],
    );
  }
}

class StudentCard extends StatelessWidget {
  final String name;
  final String regNo;
  final String documentId;

  const StudentCard({
    Key? key,
    required this.name,
    required this.regNo,
    required this.documentId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => BookDetails(studentId: documentId)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.teal[100],
                radius: 24,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : "?",
                  style: TextStyle(
                    color: Colors.teal[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Reg No: $regNo',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.teal[600],
                size: 16,
              ),
            ],
          ),
        ),
      ),
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
  final TextEditingController _searchController = TextEditingController();
  late String _searchText = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchText = value.toLowerCase();
              });
            },
            decoration: InputDecoration(
              hintText: 'Search for a teacher...',
              prefixIcon: Icon(Icons.search, color: Colors.teal[600]),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: Icon(Icons.clear, color: Colors.grey),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchText = '';
                  });
                },
              )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
                borderSide: BorderSide(color: Colors.teal[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
                borderSide: BorderSide(color: Colors.teal[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
                borderSide: BorderSide(color: Colors.teal[600]!, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('teachers')
                .where('schoolId', isEqualTo: widget.currentUserId)
                .snapshots(),
            builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: ErrorDisplay(message: snapshot.error.toString()),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: Colors.teal));
              }

              var filteredTeachers = snapshot.data!.docs.where((document) {
                String teacherName = (document.data() as Map<String, dynamic>)['name'].toString().toLowerCase();
                return teacherName.contains(_searchText);
              }).toList();

              if (filteredTeachers.isEmpty) {
                return EmptyStateWidget(message: 'No teachers found');
              }

              return ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredTeachers.length,
                itemBuilder: (BuildContext context, int index) {
                  DocumentSnapshot document = filteredTeachers[index];
                  Map<String, dynamic> data = document.data() as Map<String, dynamic>;
                  return TeacherCard(
                    name: data['name'],
                    documentId: document.id,
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

class TeacherCard extends StatelessWidget {
  final String name;
  final String documentId;

  const TeacherCard({
    Key? key,
    required this.name,
    required this.documentId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => BookDetails(teacherId: documentId)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue[100],
                radius: 24,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : "?",
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.blue[600],
                size: 16,
              ),
            ],
          ),
        ),
      ),
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
    final String personType = widget.studentId.isNotEmpty ? 'Student' : 'Teacher';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Book Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.teal[600],
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: StreamBuilder(
        stream: widget.studentId.isNotEmpty
            ? FirebaseFirestore.instance.collection('books').where('studentId', isEqualTo: widget.studentId).snapshots()
            : FirebaseFirestore.instance.collection('books').where('teacherId', isEqualTo: widget.teacherId).snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Colors.teal));
          }

          if (snapshot.hasError) {
            return Center(
              child: ErrorDisplay(message: 'Error fetching books: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.menu_book,
                    size: 72,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No books found for this $personType',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    personType == 'Student'
                        ? 'Student ID: ${widget.studentId}'
                        : 'Teacher ID: ${widget.teacherId}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Issued Books',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[700],
                  ),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (BuildContext context, int index) {
                      DocumentSnapshot document = snapshot.data!.docs[index];
                      Map<String, dynamic> data = document.data() as Map<String, dynamic>;

                      final bool isReturned = (data['status'] ?? '') == 'Returned';

                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: isReturned ? Colors.green[100] : Colors.orange[100],
                            child: Icon(
                              isReturned ? Icons.check : Icons.book,
                              color: isReturned ? Colors.green[700] : Colors.orange[700],
                            ),
                          ),
                          title: Text(
                            data['bookName'] ?? 'Unnamed Book',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4),
                              Text(
                                'Book Number: ${data['bookNumber'] ?? 'N/A'}',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              SizedBox(height: 8),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isReturned ? Colors.green[50] : Colors.orange[50],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isReturned ? Colors.green[300]! : Colors.orange[300]!,
                                  ),
                                ),
                                child: Text(
                                  'Status: ${data['status'] ?? 'Unknown'}',
                                  style: TextStyle(
                                    color: isReturned ? Colors.green[700] : Colors.orange[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: !isReturned
                              ? IconButton(
                            icon: Icon(Icons.assignment_return, color: Colors.teal[600]),
                            onPressed: () {
                              _showReturnDialog(context, document);
                            },
                          )
                              : null,
                          onTap: () {
                            if (!isReturned) {
                              _showReturnDialog(context, document);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddBookDialog(context);
        },
        label: Text('Add Book'),
        icon: Icon(Icons.add),
        backgroundColor: Colors.teal[600],
      ),
    );
  }

  void _showReturnDialog(BuildContext context, DocumentSnapshot document) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Mark as Returned', style: TextStyle(color: Colors.teal[700])),
          content: Text('Do you want to mark this book as returned?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[600],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text('Mark as Returned', style: TextStyle(color: Colors.white)),
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
    FirebaseFirestore.instance.collection('books').doc(document.id).update({
      'status': 'Returned',
      'returnDate': DateTime.now(),
    }).then((_) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Book marked as returned'),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(10),
      ));
    }).catchError((error) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to update book status: $error'),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(10),
      ));
    });
  }

  void _showAddBookDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.add_circle, color: Colors.teal[600]),
              SizedBox(width: 8),
              Text('Add New Book', style: TextStyle(color: Colors.teal[700])),
            ],
          ),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  decoration: InputDecoration(
                    labelText: "Book Name",
                    labelStyle: TextStyle(color: Colors.teal[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.teal[600]!, width: 2),
                    ),
                    prefixIcon: Icon(Icons.book, color: Colors.teal[600]),
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
                SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: "Book Number",
                    labelStyle: TextStyle(color: Colors.teal[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.teal[600]!, width: 2),
                    ),
                    prefixIcon: Icon(Icons.numbers, color: Colors.teal[600]),
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
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[600],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text('Add Book', style: TextStyle(color: Colors.white)),
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
        'issueDate': DateTime.now(),
        'studentId': widget.studentId,
        'teacherId': widget.teacherId,
      }).then((_)  {
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