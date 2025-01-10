
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'pdf%20viewer.dart';


class AssignmentScreen extends StatefulWidget {
  @override
  _TeacherAssignmentScreenState createState() => _TeacherAssignmentScreenState();
}

class _TeacherAssignmentScreenState extends State<AssignmentScreen> {
  late User _currentUser;
  String _schoolId = '';
  String _selectedClassId = '';
  late TextEditingController _assignmentController;
  late DateTime _deadline;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _assignmentController = TextEditingController();
    _deadline = DateTime.now();
    _getCurrentUser(); // Call the method here to initialize user data
  }

  Future<void> _getCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentUser = user;
      });
      await _getUserSchoolId(user.uid);
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getUserSchoolId(String userId) async {
    try {
      final userData = await FirebaseFirestore.instance.collection('teachers').doc(userId).get();
      if (userData.exists) {
        setState(() {
          _schoolId = userData['schoolId'] ?? '';
          _isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User data not found. Please contact admin.')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (error) {
      print('Error fetching user data: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching user data: $error')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showCreateAssignmentDialog() async {
    String _assignmentDescription = '';

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create New Assignment'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Class:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5.0),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('Classes')
                      .where('schoolId', isEqualTo: _schoolId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      print('Stream error: ${snapshot.error}');
                      return Text('Error fetching classes: ${snapshot.error}');
                    }

                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    var classDocs = snapshot.data!.docs;
                    return DropdownButtonFormField<String>(
                      value: _selectedClassId.isNotEmpty ? _selectedClassId : null,
                      onChanged: (value) {
                        setState(() {
                          _selectedClassId = value ?? '';
                        });
                      },
                      items: classDocs.map((doc) {
                        return DropdownMenuItem<String>(
                          value: doc.id,
                          child: Text(doc['className'] ?? 'No name available'),
                        );
                      }).toList(),
                      decoration: const InputDecoration(
                        labelText: 'Select Class',
                        border: OutlineInputBorder(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20.0),
                const Text(
                  'Assignment Description:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5.0),
                TextFormField(
                  controller: _assignmentController,
                  maxLines: null,
                  decoration: const InputDecoration(
                    labelText: 'Assignment Description',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    _assignmentDescription = value;
                  },
                ),
                const SizedBox(height: 20.0),
                const Text(
                  'Set Submission Deadline:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5.0),
                ElevatedButton(
                  onPressed: () {
                    showDatePicker(
                      context: context,
                      initialDate: _deadline,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    ).then((value) {
                      if (value != null) {
                        setState(() {
                          _deadline = value;
                        });
                      }
                    });
                  },
                  child: const Text('Select Deadline'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _submitAssignment(_assignmentDescription);
                Navigator.of(context).pop();
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitAssignment(String assignmentDescription) async {
    final timeStamp = DateTime.now();
    try {
      DocumentReference docRef = await FirebaseFirestore.instance.collection('assignments').add({
        'classId': _selectedClassId,
        'userId': _currentUser.uid,
        'assignmentDescription': assignmentDescription,
        'deadline': _deadline,
        'timestamp': timeStamp,
      });

      // Update the document with its own ID
      await docRef.update({'assignmentId': docRef.id});

      setState(() {
        _selectedClassId = '';
        _assignmentController.clear();
        _deadline = DateTime.now();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assignment submitted successfully'),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting assignment: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Assignments',
          style: TextStyle(color: Colors.deepOrangeAccent[800], fontSize: 20.0),
        ),
        backgroundColor: Colors.deepOrangeAccent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('assignments')
            .where('userId', isEqualTo: _currentUser.uid)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No assignments yet.'));
          }
          return ListView(
            children: snapshot.data!.docs.map((doc) {
              final assignment = doc.data() as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 3), // changes position of shadow
                      ),
                    ],
                  ),
                  child: ListTile(
                    title: Text(assignment['assignmentDescription'] ?? 'No description available'),
                    subtitle: Text('Deadline: ${DateFormat.yMMMMd().format((assignment['deadline'] as Timestamp?)?.toDate() ?? DateTime.now())}'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AssignmentSubmissionScreen(assignment: assignment),
                        ),
                      );
                    },
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateAssignmentDialog,
        tooltip: 'New Assignment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AssignmentSubmissionScreen extends StatelessWidget {
  final Map<String, dynamic> assignment;

  AssignmentSubmissionScreen({required this.assignment});

  Future<Map<String, String>> _getStudentInfo(String userId) async {
    try {
      DocumentSnapshot studentDoc = await FirebaseFirestore.instance.collection('students').doc(userId).get();
      if (studentDoc.exists) {
        String regNo = studentDoc['regNo'] ?? 'No registration number available';
        String name = studentDoc['name'] ?? 'No name available';
        return {'regNo': regNo, 'name': name};
      } else {
        return {'regNo': 'Student not found', 'name': 'Student not found'};
      }
    } catch (e) {
      print('Error fetching student data: $e');
      return {'regNo': 'Error fetching data', 'name': 'Error fetching data'};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignment Submissions'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Assignment Description:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5.0),
                  Text(assignment['assignmentDescription'] ?? 'No description available'),
                  const SizedBox(height: 20.0),
                  const Text(
                    'Deadline:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5.0),
                  Text(DateFormat.yMMMMd().format((assignment['deadline'] as Timestamp?)?.toDate() ?? DateTime.now())),
                ],
              ),
            ),
            const SizedBox(height: 20.0),
            const Text(
              'Submissions:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10.0),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('assignments')
                  .doc(assignment['assignmentId'])
                  .collection('submissions')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No submissions yet.'));
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var submission = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    return FutureBuilder<Map<String, String>>(
                      future: _getStudentInfo(submission['userId']),
                      builder: (context, studentInfoSnapshot) {
                        String regNo = studentInfoSnapshot.data?['regNo'] ?? 'Fetching registration number...';
                        String name = studentInfoSnapshot.data?['name'] ?? 'Fetching name...';
                        return Card(
                          child: ListTile(
                            title: Text('Student Name: $name'),
                            subtitle: Text('Registration No: $regNo\nSubmitted at: ${DateFormat.yMMMd().add_jm().format((submission['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now())}'),
                            trailing: IconButton(
                              icon: Icon(Icons.visibility),
                              onPressed: () {
                                if (submission['downloadUrl'] != null && submission['downloadUrl'].isNotEmpty) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FileViewerScreen(
                                        fileUrl: submission['downloadUrl'],
                                      ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('No file URL provided')),
                                  );
                                }
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}