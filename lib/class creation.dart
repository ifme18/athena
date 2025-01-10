import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class PieChartData {
  final String className;
  final int count;

  PieChartData(this.className, this.count);
}

class ClassCreation extends StatefulWidget {
  ClassCreation({
    Key? key,
    required this.currentUser,
  }) : super(key: key);

  final String currentUser;

  @override
  _ClassCreationState createState() => _ClassCreationState();
}

class _ClassCreationState extends State<ClassCreation> {
  final TextEditingController _classController = TextEditingController();
  final FirebaseAuth auth = FirebaseAuth.instance;

  bool _isCreatingInProgress = false;
  String? _schoolId;

  @override
  void initState() {
    super.initState();
    _fetchSchoolId();
  }

  Future<void> _fetchSchoolId() async {
    final User? user = auth.currentUser;
    if (user != null) {
      final DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('admins').doc(user.uid).get();
      setState(() {
        _schoolId = userDoc['schoolId'];
      });
    }
  }

  Future<void> _createClass() async {
    setState(() {
      _isCreatingInProgress = true;
    });

    String className = _classController.text;

    await FirebaseFirestore.instance.collection('Classes').add({
      'className': className,
      'schoolId': _schoolId,
    });

    if (mounted) {
      setState(() {
        _isCreatingInProgress = false;
        _classController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Class Creation'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            onPressed: () {}, // Placeholder for future actions
            icon: Icon(Icons.refresh),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Classes')
            .where('schoolId', isEqualTo: _schoolId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          List<String> _classList =
          snapshot.data!.docs.map((doc) => doc['className'].toString()).toList();

          return SingleChildScrollView(
            child: Row(
              children: [
                Expanded(
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
                          'Create Class',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.teal.shade900,
                          ),
                        ),
                        SizedBox(height: 20),
                        TextFormField(
                          controller: _classController,
                          decoration: InputDecoration(
                            labelText: 'Class Name',
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.teal),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _createClass,
                          child: _isCreatingInProgress
                              ? SpinKitCircle(
                            color: Colors.white,
                          )
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
                          'Classes',
                          style: TextStyle(fontSize: 20),
                        ),
                        SizedBox(height: 20),
                        _classList.isEmpty
                            ? Text('No classes available')
                            : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _classList.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => StudentListScreen(
                                      className: _classList[index],
                                      schoolId: _schoolId!,
                                    ),
                                  ),
                                );
                              },
                              child: ListTile(
                                title: Text(_classList[index]),
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
    _classController.dispose();
    super.dispose();
  }
}

class StudentListScreen extends StatefulWidget {
  final String className;
  final String schoolId;

  StudentListScreen({
    required this.className,
    required this.schoolId,
  });

  @override
  _StudentListScreenState createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  List<Map<String, dynamic>> _studentList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('students')
        .where('schoolId', isEqualTo: widget.schoolId)
        .where('className', isEqualTo: widget.className)
        .get();

    List<Map<String, dynamic>> students = [];
    snapshot.docs.forEach((doc) {
      students.add({
        'name': doc['name'] ?? '',
        'regNo': doc['regno'] ?? '',
      });
    });

    setState(() {
      _studentList = students;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Students in ${widget.className}'),
        backgroundColor: Colors.teal,
      ),
      body: Container(
        color: _isLoading ? Colors.teal.shade100 : Colors.white,
        child: _isLoading
            ? Center(
          child: SpinKitCircle(
            color: Colors.teal,
            size: 50.0,
          ),
        )
            : ListView.builder(
          itemCount: _studentList.length,
          itemBuilder: (context, index) {
            final student = _studentList[index];
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.teal,
                  child: Text(
                    student['name'].isNotEmpty ? student['name'][0].toUpperCase() : '',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(student['name']),
                subtitle: Text('Reg No: ${student['regno']}'),
              ),
            );
          },
        ),
      ),
    );
  }
}