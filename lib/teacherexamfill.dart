import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'pdfexamreport.dart';
import 'package:pdf/widgets.dart' as pw;
import 'pdfviewerscreen.dart';



class TeachersExamUpdateScreen extends StatefulWidget {
  @override
  _ExamUpdateScreenState createState() => _ExamUpdateScreenState();
}

class _ExamUpdateScreenState extends State<TeachersExamUpdateScreen> {
  String selectedClass = "";
  String selectedExam = "";
  List<Map<String, dynamic>> students = [];
  String schoolId = "";
  List<Map<String, dynamic>> classes = [];
  List<Map<String, dynamic>> exams = [];
  List<Map<String, dynamic>> subjects = [];
  List<String> selectedSubjects = [];

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
          print('User data: ${userData.data()}');

          // Call fetch functions here
          await fetchClasses();
          await fetchExams();
          await fetchSubjects();
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

  Future<void> fetchClasses() async {
    print('Attempting to fetch classes for school ID: $schoolId');
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Classes')
          .where('schoolId', isEqualTo: schoolId)
          .get();

      print('Fetch classes query completed. Documents retrieved: ${snapshot.docs.length}');

      setState(() {
        classes = snapshot.docs
            .map((doc) => {'id': doc.id, 'name': doc['className']})
            .toList();
        selectedClass = "";
        students.clear();
      });

      print('Classes fetched and processed: ${classes.length}');
    } catch (e) {
      print('Error fetching classes: $e');
    }
  }

  Future<void> fetchExams() async {
    print('Attempting to fetch exams for school ID: $schoolId');
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('exams')
          .where('schoolId', isEqualTo: schoolId)
          .get();

      print('Fetch exams query completed. Documents retrieved: ${snapshot.docs.length}');

      setState(() {
        exams = snapshot.docs
            .map((doc) => {'id': doc.id, 'name': doc['examName']})
            .toList();
        selectedExam = "";
      });

      print('Exams fetched and processed: ${exams.length}');
    } catch (e) {
      print('Error fetching exams: $e');
    }
  }

  Future<void> fetchSubjects() async {
    print('Attempting to fetch subjects for school ID: $schoolId');
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Subjects')
          .where('schoolId', isEqualTo: schoolId)
          .get();

      print('Fetch subjects query completed. Documents retrieved: ${snapshot.docs.length}');

      setState(() {
        subjects = snapshot.docs
            .map((doc) => {'id': doc.id, 'name': doc['subjectName']})
            .toList();
      });

      print('Subjects fetched and processed: ${subjects.length}');
    } catch (e) {
      print('Error fetching subjects: $e');
    }
  }

  Future<void> fetchStudents(String classId) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('classId', isEqualTo: classId)
          .get();

      if (snapshot.docs.isEmpty) {
        print('No students found for class: $classId');
      } else {
        setState(() {
          students = snapshot.docs.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              'regno': data['regno'] ?? 'N/A',
              'scores': {},
            };
          }).toList();
        });
        for (var student in students) {
          print('Student: ${student['regno']}');
        }
      }
    } catch (e) {
      print('Error fetching students: $e');
    }
  }

  void queryExamResults(String classId, String examId) async {
    print('Querying exam results for class: $classId, exam: $examId');
    if (classId.isEmpty || examId.isEmpty || selectedSubjects.isEmpty) {
      print('One or more parameters are empty');
      return;
    }

    try {
      for (String subjectId in selectedSubjects) {
        final examResultsData = await FirebaseFirestore.instance
            .collection('exams')
            .doc(examId)
            .collection('results')
            .where('classId', isEqualTo: classId)
            .where('subject', isEqualTo: subjectId)
            .get();

        examResultsData.docs.forEach((doc) {
          final studentIndex =
          students.indexWhere((student) => student['id'] == doc['studentId']);
          if (studentIndex != -1) {
            setState(() {
              students[studentIndex]['scores'][subjectId] = {
                'score': doc['score'],
                'rating': doc['rating'] ?? 'Meeting Expectation',
              };
            });
          }
        });
      }

      print('Exam results updated for ${students.length} students');
    } catch (e) {
      print('Error querying exam results: $e');
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
        int score = data['score'];
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

  List<Map<String, dynamic>> calculateSubjectComparison() {
    Map<String, List<int>> subjectScores = {};

    students.forEach((student) {
      student['scores'].forEach((subject, data) {
        if (!subjectScores.containsKey(subject)) {
          subjectScores[subject] = [];
        }
        subjectScores[subject]!.add(data['score']);
      });
    });

    return subjectScores.entries.map((e) {
      double average = e.value.reduce((a, b) => a + b) / e.value.length;
      return {'subject': e.key, 'averageScore': average};
    }).toList();
  }
  void generateInvoice() async {
    if (selectedClass.isEmpty || selectedExam.isEmpty || students.isEmpty) {
      print('Incomplete data for generating invoice');
      return;
    }

    try {
      final pdf = pw.Document();

      final schoolSnapshot = await FirebaseFirestore.instance
          .collection('Schools')
          .doc(schoolId)
          .get();
      final schoolName = schoolSnapshot['schoolName'];

      // Generate PDF report
      final pdfData = await PdfExamReport.generate(
        examName: getExamName(selectedExam),
        schoolName: schoolName,
        className: getClassName(selectedClass),
        students: students, subjects: [],
      );

      // Display the PDF using a PDF viewer
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WebPdfViewer(pdfData: pdfData),
        ),
      );
    } catch (e) {
      print('Error generating invoice: $e');
    }
  }


  void visualizeData() {
    List<Map<String, dynamic>> scoreDistribution = calculateScoreDistribution();
    List<Map<String, dynamic>> subjectComparison = calculateSubjectComparison();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Distribution of Scores'),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: SfCartesianChart(
              series: <ChartSeries>[
                ColumnSeries<Map<String, dynamic>, String>(
                  dataSource: scoreDistribution,
                  xValueMapper: (Map<String, dynamic> data, _) => data['range'],
                  yValueMapper: (Map<String, dynamic> data, _) => data['count'],
                  dataLabelSettings: DataLabelSettings(isVisible: true),
                )
              ],
              primaryXAxis: CategoryAxis(),
            ),
          ),
        );
      },
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Comparison Between Subjects'),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: SfCartesianChart(
              series: <ChartSeries>[
                ColumnSeries<Map<String, dynamic>, String>(
                  dataSource: subjectComparison,
                  xValueMapper: (Map<String, dynamic> data, _) => data['subject'],
                  yValueMapper: (Map<String, dynamic> data, _) => data['averageScore'],
                  dataLabelSettings: DataLabelSettings(isVisible: true),
                )
              ],
              primaryXAxis: CategoryAxis(),
              primaryYAxis: NumericAxis(),
            ),
          ),
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurpleAccent,
        title: Text(
          selectedClass.isEmpty || selectedExam.isEmpty
              ? 'Examinations View'
              : 'Update Scores - ${getClassName(selectedClass)}, ${getExamName(selectedExam)}',
        ),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(
            Icons.arrow_back,
            size: 30.0,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              fetchClasses();
              fetchExams();
              fetchSubjects();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButton<String>(
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
                  fetchStudents(selectedClass);
                });
              },
            ),
            SizedBox(height: 16.0),
            DropdownButton<String>(
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
                  if (selectedClass.isNotEmpty && selectedSubjects.isNotEmpty) {
                    queryExamResults(selectedClass, selectedExam);
                  }
                });
              },
            ),
            SizedBox(height: 16.0),
            MultiSelectChip(
              subjects: subjects,
              onSelectionChanged: (selectedList) {
                setState(() {
                  selectedSubjects = selectedList;
                  if (selectedClass.isNotEmpty && selectedExam.isNotEmpty) {
                    queryExamResults(selectedClass, selectedExam);
                  }
                });
              },
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: SingleChildScrollView(
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
                    double totalScore = 0;
                    int subjectCount = 0;
                    student['scores'].forEach((subjectId, data) {
                      totalScore += data['score'];
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
                  }).toList(),
                ),
              ),
            ),
            SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Implement logic to save scores to Firestore
                    print('Saving scores...');
                  },
                  child: Text('Save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Implement logic to submit scores to Firestore
                    print('Submitting scores...');
                  },
                  child: Text('Submit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),

                ElevatedButton(
                  onPressed: () {
                    // Implement logic to submit scores to Firestore
                    print('Submitting scores...');
                  },
                  child: Text('Submit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
                ElevatedButton(
                  onPressed: generateInvoice,
                  child: Text('Generate Invoice'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
                ElevatedButton(
                  onPressed: visualizeData,
                  child: Text('Visualize Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }




  String getClassName(String classId) {
    return classes.firstWhere((element) => element['id'] == classId)['name'];
  }

  String getExamName(String examId) {
    return exams.firstWhere((element) => element['id'] == examId)['name'];
  }

  String getSubjectName(String subjectId) {
    return subjects.firstWhere((element) => element['id'] == subjectId)['name'];
  }
}

class MultiSelectChip extends StatefulWidget {
  final List<Map<String, dynamic>> subjects;
  final Function(List<String>) onSelectionChanged;

  MultiSelectChip({required this.subjects, required this.onSelectionChanged});

  @override
  _MultiSelectChipState createState() => _MultiSelectChipState();
}

class _MultiSelectChipState extends State<MultiSelectChip> {
  List<String> selectedSubjects = [];

  _buildChoiceList() {
    List<Widget> choices = [];
    widget.subjects.forEach((item) {
      choices.add(Container(
        padding: const EdgeInsets.all(2.0),
        child: ChoiceChip(
          label: Text(item['name']),
          selected: selectedSubjects.contains(item['id']),
          onSelected: (selected) {
            setState(() {
              selectedSubjects.contains(item['id'])
                  ? selectedSubjects.remove(item['id'])
                  : selectedSubjects.add(item['id']);
              widget.onSelectionChanged(selectedSubjects);
            });
          },
        ),
      ));
    });
    return choices;
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: _buildChoiceList(),
    );
  }
}