import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExamUpdateScreen extends StatefulWidget {
  @override
  _ExamUpdateScreenState createState() => _ExamUpdateScreenState();
}

class _ExamUpdateScreenState extends State<ExamUpdateScreen> {
  String selectedClass = "";
  String selectedExam = "";
  String selectedSubject = "";
  List<Map<String, dynamic>> students = [];
  String schoolId = "";

  @override
  void initState() {
    super.initState();
    fetchSchoolId();
  }

  Future<void> fetchSchoolId() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        final userData = await FirebaseFirestore.instance
            .collection('teachers')
            .doc(user.uid)
            .get();

        if (userData.exists) {
          setState(() {
            schoolId = userData['schoolId'];
          });
        } else {
          print('User data not found');
        }
      } catch (e) {
        print('Error fetching user data: $e');
      }
    } else {
      print('User not authenticated');
    }
  }

  Future<List<String>> getClasses(String schoolId) async {
    try {
      final classData = await FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('classes')
          .get();

      return classData.docs
          .map<String>((doc) => doc['className'] as String)
          .toList();
    } catch (e) {
      print('Error fetching classes: $e');
      return [];
    }
  }

  Future<List<String>> getExams(String schoolId) async {
    try {
      final examData = await FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('exams')
          .get();

      return examData.docs
          .map<String>((doc) => doc['examName'] as String)
          .toList();
    } catch (e) {
      print('Error fetching exams: $e');
      return [];
    }
  }

  Future<List<String>> getSubjects(String schoolId) async {
    try {
      final subjectData = await FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('subjects')
          .get();

      return subjectData.docs
          .map<String>((doc) => doc['subjectName'] as String)
          .toList();
    } catch (e) {
      print('Error fetching subjects: $e');
      return [];
    }
  }

  Future<void> getStudents(String schoolId, String classId) async {
    try {
      final studentData = await FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('classes')
          .doc(classId)
          .collection('students')
          .get();

      setState(() {
        students = studentData.docs
            .map((doc) => {
          'id': doc.id,
          'name': doc['name'],
          'subjectScores': {}, // Initialize empty subject scores map
        })
            .toList();
      });
    } catch (e) {
      print('Error fetching students: $e');
    }
  }

  Future<void> queryExamResults(
      String schoolId, String classId, String examId, String subject) async {
    try {
      final examResultsData = await FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('exams')
          .doc(examId)
          .collection('results')
          .where('classId', isEqualTo: classId)
          .where('subject', isEqualTo: subject)
          .get();

      examResultsData.docs.forEach((doc) {
        // Update student's subject score
        final studentIndex =
        students.indexWhere((student) => student['id'] == doc['studentId']);
        if (studentIndex != -1) {
          setState(() {
            students[studentIndex]['subjectScores'][subject] = doc['score'];
          });
        }
      });
    } catch (e) {
      print('Error querying exam results: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple,
        title: Text('Examinations View'),
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: Icon(
            Icons.arrow_back,
            size: 30.0,
          ),
        ),
        actions: [],
        toolbarHeight: 80.0,
        titleSpacing: 20.0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<List<String>>(
              future: getClasses(schoolId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                final classes = snapshot.data ?? [];
                return DropdownButtonFormField<String>(
                  value: selectedClass,
                  hint: Text('Select Class'),
                  items: classes.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedClass = value ?? "";
                      getStudents(schoolId, '');
                    });
                  },
                );
              },
            ),
            SizedBox(height: 16.0),
            FutureBuilder<List<String>>(
              future: getExams(schoolId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                final exams = snapshot.data ?? [];
                return DropdownButtonFormField<String>(
                  value: selectedExam,
                  hint: Text('Select Exam'),
                  items: exams.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedExam = value ?? "";
                    });
                  },
                );
              },
            ),
            SizedBox(height: 16.0),
            FutureBuilder<List<String>>(
              future: getSubjects(schoolId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                final subjects = snapshot.data ?? [];
                return DropdownButtonFormField<String>(
                  value: selectedSubject,
                  hint: Text('Choose Subject to grade'),
                  items: subjects.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedSubject = value ?? "";
                      queryExamResults(
                          schoolId, selectedClass, selectedExam, selectedSubject);
                    });
                  },
                );
              },
            ),
            SizedBox(height: 16.0),
            DataTable(
              columns: [
                DataColumn(label: Text('Student')),
                ...students.isNotEmpty
                    ? (selectedSubject.isNotEmpty
                    ? [DataColumn(label: Text(selectedSubject))] // Display subject column if subject selected
                    : students.first['subjectScores'].keys.map((subject) {
                  return DataColumn(label: Text(subject));
                }).toList())
                    : [], // Display subject columns if subject-wise scores available
              ],
              rows: students.map((student) {
                return DataRow(
                  cells: [
                    DataCell(Text(student['name'])),
                    ...student['subjectScores'].entries.map((entry) {
                      return DataCell(
                        Text(entry.value.toString()),
                      );
                    }).toList(),
                  ],
                );
              }).toList(),
            ),
            SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Implement logic to save scores to Firestore
                  },
                  child: Text('Save'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Implement logic to submit scores to Firestore
                  },
                  child: Text('Submit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}