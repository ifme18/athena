import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'pdfexamreport.dart';
import 'package:pdf/widgets.dart' as pw;
import 'pdfviewerscreen.dart';
import 'dart:async';

class ExamUpdateScreen extends StatefulWidget {
  @override
  _ExamUpdateScreenState createState() => _ExamUpdateScreenState();
}

class _ExamUpdateScreenState extends State<ExamUpdateScreen> {
  String selectedClass = "";
  String selectedExam = "";
  late Future<List<Map<String, dynamic>>> _studentsFuture;
  String schoolId = "";
  List<Map<String, dynamic>> classes = [];
  List<Map<String, dynamic>> exams = [];
  List<Map<String, dynamic>> subjects = [];
  List<String> selectedSubjects = [];
  bool _isUpdating = false;

  Map<String, Map<String, TextEditingController>> scoreControllers = {};
  Map<String, Map<String, dynamic>> studentScores = {};

  @override
  void initState() {
    super.initState();
    _studentsFuture = Future.value([]);
    _initialize();
  }

  Future<void> _initialize() async {
    await fetchSchoolId();
    await Future.wait([
      fetchClasses(),
      fetchExams(),
      fetchSubjects(),
    ]);
    _studentsFuture = fetchStudentsWithScores(selectedClass);
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
    studentScores.clear();

    for (var doc in snapshot.docs) {
      var data = doc.data();
      Map<String, dynamic> scores = {};

      // Fetch existing scores for each subject
      for (String subjectId in selectedSubjects) {
        final results = await fetchPreviousResults(doc.id, subjectId);
        if (results.docs.isNotEmpty) {
          var lastResult = results.docs.first.data();
          scores[subjectId] = {
            'score': lastResult['score'],
            'rating': lastResult['rating'],
            'resultId': results.docs.first.id,
          };
        }
      }

      studentsList.add({
        'id': doc.id,
        'regno': data['regno'] ?? 'N/A',
        'name': data['firstName'] ?? 'Unknown',
      });

      studentScores[doc.id] = scores;
    }

    initializeControllers(studentsList);
    return studentsList;
  }

  void initializeControllers(List<Map<String, dynamic>> students) {
    scoreControllers.clear();

    for (var student in students) {
      scoreControllers[student['id']] = {};
      for (var subjectId in selectedSubjects) {
        var score = studentScores[student['id']]?[subjectId]?['score']?.toString() ?? '';
        scoreControllers[student['id']]![subjectId] = TextEditingController(text: score);
      }
    }
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
            onPressed: () => _initialize(),
          ),
          if (_isUpdating)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: Padding(
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
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _studentsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error loading students: ${snapshot.error}'));
                  }

                  var students = snapshot.data ?? [];
                  return buildStudentsTable(students);
                },
              ),
            ),
            SizedBox(height: 16.0),
            buildActionButtons(),
          ],
        ),
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
          _studentsFuture = fetchStudentsWithScores(selectedClass);
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
          _studentsFuture = fetchStudentsWithScores(selectedClass);
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
          _studentsFuture = fetchStudentsWithScores(selectedClass);
        });
      },
    );
  }

  Widget buildStudentsTable(List<Map<String, dynamic>> students) {
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
    var scores = studentScores[student['id']] ?? {};

    scores.forEach((subjectId, data) {
      if (data['score'] != null) {
        totalScore += data['score'] as num;
        subjectCount++;
      }
    });

    double averageScore = subjectCount == 0 ? 0 : totalScore / subjectCount;

    return DataRow(
      cells: [
        DataCell(Text(student['regno'])),
        ...selectedSubjects.map((subjectId) {
          var controller = scoreControllers[student['id']]![subjectId]!;

          return DataCell(
            Container(
              width: 150,
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        errorText: _validateScore(controller.text),
                      ),
                      onChanged: (value) {
                        setState(() {
                          scores[subjectId] = {
                            'score': int.tryParse(value) ?? 0,
                            'resultId': scores[subjectId]?['resultId'],
                          };
                        });
                      },
                    ),
                  ),
                  if (scores[subjectId]?['resultId'] != null)
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteScore(student['id'], subjectId),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
        DataCell(Text(averageScore.toStringAsFixed(2))),
      ],
    );
  }

  String? _validateScore(String value) {
    if (value.isEmpty) return null;
    final score = int.tryParse(value);
    if (score == null) return 'Invalid number';
    if (score < 0 || score > 100) return 'Score must be 0-100';
    return null;
  }

  Future<void> _deleteScore(String studentId, String subjectId) async {
    var scoreData = studentScores[studentId]?[subjectId];
    if (scoreData == null || scoreData['resultId'] == null) return;

    try {
      setState(() => _isUpdating = true);

      await FirebaseFirestore.instance
          .collection('exams')
          .doc(selectedExam)
          .collection('results')
          .doc(scoreData['resultId'])
          .delete();

      setState(() {
        studentScores[studentId]?.remove(subjectId);
        scoreControllers[studentId]![subjectId]!.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Score deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting score: $e')),
      );
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Widget buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: _isUpdating ? null : submitScores,
          child: Text(_isUpdating ? 'Updating...' : 'Submit'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
          ),
        ),
        ElevatedButton(
          onPressed: _isUpdating ? null : generateInvoice,
          child: Text('Generate Report'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
        ),
        ElevatedButton(
          onPressed: _isUpdating ? null : visualizeData,
          child: Text('Visualize'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
          ),
        ),
      ],
    );
  }

  Future<void> submitScores() async {
    if (selectedClass.isEmpty || selectedExam.isEmpty || selectedSubjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select all required fields')),
      );
      return;
    }

    setState(() => _isUpdating = true);

    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (var student in studentScores.entries) {
        for (var subjectId in selectedSubjects) {
          var scoreData = student.value[subjectId];
          if (scoreData != null) {
            var controller = scoreControllers[student.key]![subjectId]!;
            int? newScore = int.tryParse(controller.text);

            if (newScore != null && _validateScore(controller.text) == null) {
              String rating = determineRating(newScore);
              String subjectName = getSubjectName(subjectId);

              if (scoreData['resultId'] != null) {
                // Update existing score
                var docRef = FirebaseFirestore.instance
                    .collection('exams')
                    .doc(selectedExam)
                    .collection('results')
                    .doc(scoreData['resultId']);

                batch.update(docRef, {
                  'score': newScore,
                  'rating': rating,
                  'lastUpdated': FieldValue.serverTimestamp(),
                });
              } else {
                // Create new score
                var newDocRef = FirebaseFirestore.instance
                    .collection('exams')
                    .doc(selectedExam)
                    .collection('results')
                    .doc();

                batch.set(newDocRef, {
                  'registrationNumber': student.key,
                  'subjectName': subjectName,
                  'score': newScore,
                  'rating': rating,
                  'classId': selectedClass,
                  'examId': selectedExam,
                  'subjectId': subjectId,
                  'createdAt': FieldValue.serverTimestamp(),
                  'lastUpdated': FieldValue.serverTimestamp(),
                });
              }

              student.value[subjectId]['score'] = newScore; // Update local copy
            }
          }
        }
      }

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scores updated successfully')),
      );

      setState(() {
        _studentsFuture = fetchStudentsWithScores(selectedClass);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating scores: $e')),
      );
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  String determineRating(int score) {
    if (score >= 0 && score <= 49) {
      return 'Below Expectation';
    } else if (score >= 50 && score <= 69) {
      return 'Approaching Expectation';
    } else if (score >= 70 && score <= 79) {
      return 'Meeting Expectation';
    } else if (score >= 80 && score <= 100) {
      return 'Exceeding Expectation';
    } else {
      return 'Unknown';
    }
  }

  Future<void> generateInvoice() async {
    if (selectedClass.isEmpty || selectedExam.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select all required fields')),
      );
      return;
    }

    try {


      final pdfData = await PdfExamReport.generate(
        examName: getExamName(selectedExam),
        schoolName: await getSchoolName(),
        className: getClassName(selectedClass),
        students: studentScores.keys.map((id) => {
          'id': id,
          'regno': 'N/A', // You'd need to fetch this from your students list
          'scores': studentScores[id],
        }).toList(),
        subjects: subjects,
      );

      Navigator.pop(context);

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WebPdfViewer(pdfData: pdfData),
        ),
      );
    } catch (e) {
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

    studentScores.forEach    ((_, scores) {
      scores.forEach((_, data) {
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
    if (studentScores.isEmpty || selectedSubjects.isEmpty) {
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
