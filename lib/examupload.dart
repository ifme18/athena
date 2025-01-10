import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'pdfexamreport.dart';
import 'package:pdf/widgets.dart' as pw;
import 'pdfviewerscreen.dart';

class ExamUpdateScreen extends StatefulWidget {
  @override
  _ExamUpdateScreenState createState() => _ExamUpdateScreenState();
}

class _ExamUpdateScreenState extends State<ExamUpdateScreen> {
  String selectedClass = "";
  String selectedExam = "";
  List<Map<String, dynamic>> students = [];
  String schoolId = "";
  List<Map<String, dynamic>> classes = [];
  List<Map<String, dynamic>> exams = [];
  List<Map<String, dynamic>> subjects = [];
  List<String> selectedSubjects = [];

  late Future<void> _initializationFuture;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initialize();
  }

  Future<void> _initialize() async {
    await fetchSchoolId();
    await Future.wait([
      fetchClasses(),
      fetchExams(),
      fetchSubjects(),
    ]);
  }

  Future<void> fetchSchoolId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final userData = await FirebaseFirestore.instance
        .collection('admins')
        .doc(user.uid)
        .get();

    if (!userData.exists) throw Exception('User data not found');

    setState(() {
      schoolId = userData['schoolId'];
    });
  }

  Future<QuerySnapshot<Map<String, dynamic>>> fetchPreviousResults(String studentId, String subjectId) async {
    return FirebaseFirestore.instance
        .collection('exams')
        .doc(selectedExam)
        .collection('results')
        .where('registrationNumber', isEqualTo: studentId)
        .where('subjectId', isEqualTo: subjectId)
        .get();
  }

  Future<void> fetchClasses() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Classes')
        .where('schoolId', isEqualTo: schoolId)
        .get();

    setState(() {
      classes = snapshot.docs
          .map((doc) => {'id': doc.id, 'name': doc['className']})
          .toList();
    });
  }

  Future<void> fetchExams() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('exams')
        .where('schoolId', isEqualTo: schoolId)
        .get();

    setState(() {
      exams = snapshot.docs
          .map((doc) => {'id': doc.id, 'name': doc['examName']})
          .toList();
    });
  }

  Future<void> fetchSubjects() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Subjects')
        .where('schoolId', isEqualTo: schoolId)
        .get();

    setState(() {
      subjects = snapshot.docs
          .map((doc) => {'id': doc.id, 'name': doc['subjectName']})
          .toList();
    });
  }

  Future<List<Map<String, dynamic>>> fetchStudentsWithScores(String classId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('students')
        .where('classId', isEqualTo: classId)
        .get();

    List<Map<String, dynamic>> studentsList = [];

    for (var doc in snapshot.docs) {
      var data = doc.data();
      Map<String, dynamic> scores = {};

      // Fetch previous scores for each subject
      for (String subjectId in selectedSubjects) {
        final previousResults = await fetchPreviousResults(doc.id, subjectId);
        if (previousResults.docs.isNotEmpty) {
          var lastResult = previousResults.docs.first.data();
          scores[subjectId] = {
            'score': lastResult['score'],
            'rating': lastResult['rating'],
            'averageScore': lastResult['averageScore'],
          };
        }
      }

      studentsList.add({
        'id': doc.id,
        'regno': data['regno'] ?? 'N/A',
        'scores': scores,
      });
    }

    return studentsList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurpleAccent,
        title: Text('Examinations View'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _initializationFuture = _initialize();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _initializationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                buildClassDropdown(),
                SizedBox(height: 16.0),
                buildExamDropdown(),
                SizedBox(height: 16.0),
                buildSubjectsSelection(),
                SizedBox(height: 16.0),
                if (selectedClass.isNotEmpty)
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: fetchStudentsWithScores(selectedClass),
                      builder: (context, studentsSnapshot) {
                        if (studentsSnapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (studentsSnapshot.hasError) {
                          return Center(child: Text('Error loading students: ${studentsSnapshot.error}'));
                        }

                        students = studentsSnapshot.data ?? [];
                        return buildStudentsTable();
                      },
                    ),
                  ),
                SizedBox(height: 16.0),
                buildActionButtons(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildClassDropdown() {
    return DropdownButton<String>(
      value: selectedClass.isNotEmpty ? selectedClass : null,
      hint: Text('Choose Class'),
      items: classes.map((classItem) {
        return DropdownMenuItem<String>(
          value: classItem['id'],
          child: Text(classItem['name']),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          selectedClass = value!;
        });
      },
    );
  }

  Widget buildExamDropdown() {
    return DropdownButton<String>(
      value: selectedExam.isNotEmpty ? selectedExam : null,
      hint: Text('Choose Exam'),
      items: exams.map((examItem) {
        return DropdownMenuItem<String>(
          value: examItem['id'],
          child: Text(examItem['name']),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          selectedExam = value!;
        });
      },
    );
  }

  Widget buildSubjectsSelection() {
    return MultiSelectChip(
      subjects: subjects,
      onSelectionChanged: (selectedList) {
        setState(() {
          selectedSubjects = selectedList;
        });
      },
    );
  }

  Widget buildStudentsTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text('Reg. No.')),
          ...selectedSubjects.map((subjectId) {
            return DataColumn(
              label: SizedBox(
                width: 150,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(getSubjectName(subjectId)),
                    SizedBox(height: 8),
                    Text('Score'),
                  ],
                ),
              ),
            );
          }).toList(),
          DataColumn(label: Text('Average Score')),
        ],
        rows: students.map((student) {
          return buildStudentRow(student);
        }).toList(),
      ),
    );
  }

  DataRow buildStudentRow(Map<String, dynamic> student) {
    double totalScore = 0;
    int subjectCount = 0;

    student['scores'].forEach((subjectId, data) {
      totalScore += data['score'] ?? 0;
      subjectCount++;
    });

    double averageScore = subjectCount == 0 ? 0 : totalScore / subjectCount;

    return DataRow(
      cells: [
        DataCell(Text(student['regno'])),
        ...selectedSubjects.map((subjectId) {
          return DataCell(
            Container(
              width: 150,
              child: TextFormField(
                initialValue: student['scores'][subjectId]?['score']?.toString() ?? '',
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    student['scores'][subjectId] = {
                      'score': int.tryParse(value) ?? 0,
                    };
                  });
                },
              ),
            ),
          );
        }).toList(),
        DataCell(Text(averageScore.toStringAsFixed(2))),
      ],
    );
  }

  Widget buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: submitScores,
          child: Text('Submit'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
          ),
        ),
        ElevatedButton(
          onPressed: generateInvoice,
          child: Text('Generate Report'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
        ),
        ElevatedButton(
          onPressed: visualizeData,
          child: Text('Visualize'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
          ),
        ),
      ],
    );
  }
// Add these methods to the _ExamUpdateScreenState class

  Future<void> submitScores() async {
    if (selectedClass.isEmpty || selectedExam.isEmpty || students.isEmpty || selectedSubjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select all required fields')),
      );
      return;
    }

    try {
      for (var student in students) {
        String studentId = student['id'];
        var scores = student['scores'];

        for (var subjectId in selectedSubjects) {
          var scoreData = scores[subjectId];
          if (scoreData != null) {
            String rating;
            int score = scoreData['score'];

            if (score >= 0 && score <= 49) {
              rating = 'Below Expectation';
            } else if (score >= 50 && score <= 69) {
              rating = 'Approaching Expectation';
            } else if (score >= 70 && score <= 79) {
              rating = 'Meeting Expectation';
            } else if (score >= 80 && score <= 100) {
              rating = 'Exceeding Expectation';
            } else {
              rating = 'Unknown';
            }

            String subjectName = getSubjectName(subjectId);

            // First check if a record already exists
            var existingResults = await FirebaseFirestore.instance
                .collection('exams')
                .doc(selectedExam)
                .collection('results')
                .where('registrationNumber', isEqualTo: studentId)
                .where('subjectId', isEqualTo: subjectId)
                .get();

            if (existingResults.docs.isNotEmpty) {
              // Update existing record
              await existingResults.docs.first.reference.update({
                'score': score,
                'rating': rating,
                'lastUpdated': DateTime.now(),
              });
            } else {
              // Create new record
              await FirebaseFirestore.instance
                  .collection('exams')
                  .doc(selectedExam)
                  .collection('results')
                  .add({
                'registrationNumber': studentId,
                'subjectName': subjectName,
                'score': score,
                'rating': rating,
                'classId': selectedClass,
                'examId': selectedExam,
                'subjectId': subjectId,
                'createdAt': DateTime.now(),
                'lastUpdated': DateTime.now(),
              });
            }
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scores submitted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting scores: $e')),
      );
    }
  }

  // Update the generateInvoice method in _ExamUpdateScreenState
  Future<void> generateInvoice() async {
    if (selectedClass.isEmpty || selectedExam.isEmpty || students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select all required fields')),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );

      final pdfData = await PdfExamReport.generate(
        examName: getExamName(selectedExam),
        schoolName: await getSchoolName(),
        className: getClassName(selectedClass),
        students: students,
        subjects: subjects,
      );

      // Remove loading dialog
      Navigator.pop(context);

      // Navigate to PDF viewer
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WebPdfViewer(pdfData: pdfData),
        ),
      );
    } catch (e) {
      // Remove loading dialog if still showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating report: $e')),
      );
    }
  }

  Future<String> getSchoolName() async {
    try {
      final schoolDoc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .get();

      return schoolDoc.data()?['schoolName'] ?? 'School Name Not Found';
    } catch (e) {
      return 'School Name Not Found';
    }
  }

  List<Map<String, dynamic>> calculateScoreDistribution() {
    Map<String, int> distribution = {
      '0-20': 0,
      '21-40': 0,
      '41-60': 0,
      '61-80': 0,
      '81-100': 0,
    };

    students.forEach((student) {
      student['scores'].forEach((subject, data) {
        int score = data['score'] ?? 0;
        if (score <= 20)
          distribution['0-20'] = (distribution['0-20'] ?? 0) + 1;
        else if (score <= 40)
          distribution['21-40'] = (distribution['21-40'] ?? 0) + 1;
        else if (score <= 60)
          distribution['41-60'] = (distribution['41-60'] ?? 0) + 1;
        else if (score <= 80)
          distribution['61-80'] = (distribution['61-80'] ?? 0) + 1;
        else
          distribution['81-100'] = (distribution['81-100'] ?? 0) + 1;
      });
    });

    return distribution.entries
        .map((e) => {'range': e.key, 'count': e.value})
        .toList();
  }

  void visualizeData() {
    if (students.isEmpty || selectedSubjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No data available to visualize')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.8,
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text('Score Distribution', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 20),
                Expanded(
                  child: SfCartesianChart(
                    primaryXAxis: CategoryAxis(),
                    series: <ChartSeries>[
                      ColumnSeries<Map<String, dynamic>, String>(
                        dataSource: calculateScoreDistribution(),
                        xValueMapper: (Map<String, dynamic> data, _) => data['range'],
                        yValueMapper: (Map<String, dynamic> data, _) => data['count'],
                        dataLabelSettings: DataLabelSettings(isVisible: true),
                      )
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String getClassName(String classId) {
    return classes.firstWhere(
          (element) => element['id'] == classId,
      orElse: () => {'name': 'Unknown Class'},
    )['name'];
  }

  String getExamName(String examId) {
    return exams.firstWhere(
          (element) => element['id'] == examId,
      orElse: () => {'name': 'Unknown Exam'},
    )['name'];
  }

  String getSubjectName(String subjectId) {
    return subjects.firstWhere(
          (element) => element['id'] == subjectId,
      orElse: () => {'name': 'Unknown Subject'},
    )['name'];
  }
}

class MultiSelectChip extends StatefulWidget {
  final List<Map<String, dynamic>> subjects;
  final Function(List<String>) onSelectionChanged;

  MultiSelectChip({
    required this.subjects,
    required this.onSelectionChanged,
  });

  @override
  _MultiSelectChipState createState() => _MultiSelectChipState();
}

class _MultiSelectChipState extends State<MultiSelectChip> {
  List<String> selectedSubjects = [];

  Widget _buildChoiceList() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: widget.subjects.map((item) {
        return ChoiceChip(
          label: Text(item['name']),
          selected: selectedSubjects.contains(item['id']),
          onSelected: (selected) {
            setState(() {
              if (selected) {
                selectedSubjects.add(item['id']);
              } else {
                selectedSubjects.remove(item['id']);
              }
              widget.onSelectionChanged(selectedSubjects);
            });
          },
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: _buildChoiceList(),
    );
  }
}