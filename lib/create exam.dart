import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';

class ExamCreation extends StatefulWidget {
  final String currentUser;

  ExamCreation({Key? key, required this.currentUser}) : super(key: key);

  @override
  _ExamCreationState createState() => _ExamCreationState();
}

class _ExamCreationState extends State<ExamCreation> {
  final TextEditingController _examController = TextEditingController();
  final FirebaseAuth auth = FirebaseAuth.instance;

  bool _isCreatingInProgress = false;
  String? _schoolId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSchoolId();
  }

  Future<void> _fetchSchoolId() async {
    try {
      final User? user = auth.currentUser;
      if (user != null) {
        final DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('admins')
            .doc(user.uid)
            .get();
        setState(() {
          _schoolId = userDoc['schoolId'];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to fetch school ID: $e';
      });
    }
  }

  Future<void> _createClass() async {
    if (_examController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Exam name cannot be empty';
      });
      return;
    }

    setState(() {
      _isCreatingInProgress = true;
      _errorMessage = null;
    });

    try {
      String examName = _examController.text.trim();
      Timestamp createdDate = Timestamp.now();

      await FirebaseFirestore.instance.collection('exams').add({
        'examName': examName,
        'schoolId': _schoolId,
        'createdDate': createdDate,
      });

      if (mounted) {
        setState(() {
          _isCreatingInProgress = false;
          _examController.clear();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to create exam: $e';
        _isCreatingInProgress = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Exam Creation'),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _schoolId != null
            ? FirebaseFirestore.instance
            .collection('exams')
            .where('schoolId', isEqualTo: _schoolId)
            .snapshots()
            : null,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (_errorMessage != null) {
            return Center(
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          List<DocumentSnapshot> examDocs = snapshot.data?.docs ?? [];

          return SingleChildScrollView(
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade100,
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(color: Colors.teal.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create Exam',
                          style: TextStyle(
                              fontSize: 20, color: Colors.teal.shade900),
                        ),
                        SizedBox(height: 20),
                        TextFormField(
                          controller: _examController,
                          decoration: InputDecoration(
                            labelText: 'Exam Name',
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.teal),
                            ),
                            errorText: _errorMessage,
                          ),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _isCreatingInProgress
                              ? null
                              : _createClass,
                          child: _isCreatingInProgress
                              ? SpinKitCircle(color: Colors.white)
                              : Text('Create'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Exams',
                          style: TextStyle(fontSize: 20),
                        ),
                        SizedBox(height: 20),
                        examDocs.isEmpty
                            ? Text('No exams available')
                            : ListView.builder(
                          shrinkWrap: true,
                          itemCount: examDocs.length,
                          itemBuilder: (context, index) {
                            Timestamp createdDate =
                            examDocs[index]['createdDate'];
                            String formattedDate = DateFormat.yMd()
                                .add_Hms()
                                .format(createdDate.toDate());
                            return ListTile(
                              title: Text(
                                '${examDocs[index]['examName']} - $formattedDate',
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _examController.dispose();
    super.dispose();
  }
}