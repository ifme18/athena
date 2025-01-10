import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubjectCreation extends StatefulWidget {
  SubjectCreation({Key? key}) : super(key: key);

  @override
  _SubjectCreationState createState() => _SubjectCreationState();
}

class _SubjectCreationState extends State<SubjectCreation> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  String? _selectedAdministrator;
  bool _isCreatingInProgress = false;
  bool _isLoadingInProgress = false;
  List<String> _subjectList = [];
  String? _schoolId;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserSchoolId();
  }

  Future<void> _fetchCurrentUserSchoolId() async {
    User? user = _auth.currentUser;
    if (user != null) {
      String userId = user.uid;
      final snapshot = await FirebaseFirestore.instance.collection('admins').doc(userId).get();

      if (snapshot.exists) {
        setState(() {
          _schoolId = snapshot.get('schoolId');
        });
        _fetchSubjects(); // Fetch subjects once schoolId is retrieved
      }
    }
  }

  Stream<List<String>> _fetchSubjectsStream() {
    return FirebaseFirestore.instance
        .collection('Subjects')
        .where('schoolId', isEqualTo: _schoolId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.get('subjectName') as String).toList());
  }

  void _fetchSubjects() {
    setState(() {
      _isLoadingInProgress = true;
    });

    FirebaseFirestore.instance
        .collection('Subjects')
        .where('schoolId', isEqualTo: _schoolId)
        .get()
        .then((snapshot) {
      List<String> subjects = [];
      snapshot.docs.forEach((doc) {
        subjects.add(doc.get('subjectName') as String);
      });

      setState(() {
        _subjectList = subjects;
        _isLoadingInProgress = false;
      });
    }).catchError((error) {
      print('Error fetching subjects: $error');
      setState(() {
        _isLoadingInProgress = false;
      });
    });
  }

  Future<void> _createSubject() async {
    setState(() {
      _isCreatingInProgress = true;
    });

    String subjectName = _nameController.text;
    String subjectCode = _subjectController.text;

    await FirebaseFirestore.instance.collection('Subjects').add({
      'subjectName': subjectName,
      'subjectCode': subjectCode,
      'schoolId': _schoolId,
      'administrator': _selectedAdministrator,
    });

    setState(() {
      _isCreatingInProgress = false;
      _nameController.clear();
      _subjectController.clear();
      _selectedAdministrator = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Subject Creation'),
        backgroundColor: Colors.deepPurpleAccent,
        elevation: 10.0,
      ),
      body: StreamBuilder<List<String>>(
        stream: _fetchSubjectsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          List<String> subjects = snapshot.data ?? [];

          return SingleChildScrollView(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey[50],
                      border: Border.all(color: Colors.blueGrey[200]!, width: 1.0),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Register Subject',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent),
                        ),
                        SizedBox(height: 20),
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Subject Name',
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.purpleAccent),
                            ),
                            prefixIcon: Icon(Icons.subject),
                          ),
                        ),
                        SizedBox(height: 10),
                        TextFormField(
                          controller: _subjectController,
                          decoration: InputDecoration(
                            labelText: 'Subject Code',
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black87),
                            ),
                            prefixIcon: Icon(Icons.code),
                          ),
                        ),
                        SizedBox(height: 20),
                        Center(
                          child: ElevatedButton(
                            onPressed: _createSubject,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurpleAccent,
                              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                              textStyle: TextStyle(fontSize: 18),
                            ),
                            child: _isCreatingInProgress ? CircularProgressIndicator(color: Colors.white) : Text('Create'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: Colors.lightGreen[100],
                      border: Border.all(color: Colors.lightGreen[200]!, width: 1.0),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Subjects',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green[800]),
                        ),
                        SizedBox(height: 20),
                        _isLoadingInProgress
                            ? Center(child: CircularProgressIndicator())
                            : subjects.isEmpty
                            ? Center(child: Text('No subjects found'))
                            : Container(
                          height: 300,
                          child: ListView.builder(
                            itemCount: subjects.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Text(
                                  subjects[index],
                                  style: TextStyle(fontSize: 18, color: Colors.black87),
                                ),
                                leading: Icon(Icons.book, color: Colors.green[800]),
                              );
                            },
                          ),
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
    _nameController.dispose();
    _subjectController.dispose();
    super.dispose();
  }
}