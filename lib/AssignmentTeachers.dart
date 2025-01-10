import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherAssignmentScreen extends StatefulWidget {
  @override
  _TeacherAssignmentScreenState createState() => _TeacherAssignmentScreenState();
}

class _TeacherAssignmentScreenState extends State<TeacherAssignmentScreen> {
  late User _user;
  String _schoolId = '';
  String _selectedClassId = '';
  late TextEditingController _assignmentController;
  late DateTime _deadline;

  @override
  void initState() {
    super.initState();
    _assignmentController = TextEditingController();
    _deadline = DateTime.now();
    _getUserData(); // Call the method here to initialize user data
  }

  Future<void> _getUserData() async {
    _user = FirebaseAuth.instance.currentUser!;
    if (_user != null) {
      try {
        final adminDoc = await FirebaseFirestore.instance
            .collection('teachers')
            .doc(_user.uid)
            .get();

        if (adminDoc.exists) {
          setState(() {
            _schoolId = adminDoc['schoolId'];
            print('School ID: $_schoolId'); // Debug print
          });
        } else {
          print('Document does not exist for user UID: ${_user.uid}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User data not found. Please contact admin.')),
          );
        }
      } catch (error) {
        print('Error fetching user data: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching user data: $error')),
        );
      }
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
                          _selectedClassId = value!;
                        });
                      },
                      items: classDocs.map((doc) {
                        return DropdownMenuItem<String>(
                          value: doc.id,
                          child: Text(doc['className']),
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
      await FirebaseFirestore.instance.collection('assignments').add({
        'classId': _selectedClassId,
        'userId': _user.uid,
        'schoolId': _schoolId, // Include schoolId in the assignment data
        'assignmentDescription': assignmentDescription,
        'deadline': _deadline,
        'timestamp': timeStamp,
      });
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
    } on FirebaseException catch (e) {
      print('Error submitting assignment: ${e.message}');
      _showErrorSnackBar('Error submitting assignment: ${e.message}');
    } catch (error) {
      print('Unexpected error: $error');
      _showErrorSnackBar('Unexpected error: $error');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
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
      body: FutureBuilder<void>(
        future: _getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('assignments')
                  .where('userId', isEqualTo: _user.uid)
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
                    return ListTile(
                      title: Text(assignment['assignmentDescription']),
                      subtitle: Text('Deadline: ${assignment['deadline'].toString()}'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AssignmentSubmissionScreen(assignment: assignment),
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            );
          }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignment Submission'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Assignment Description:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5.0),
            Text(assignment['assignmentDescription']),
            const SizedBox(height: 20.0),
            const Text(
              'Deadline:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5.0),
            Text(assignment['deadline'].toString()),
          ],
        ),
      ),
    );
  }
}