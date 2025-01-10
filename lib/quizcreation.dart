import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'results.dart';

class CreateQuizScreen extends StatefulWidget {
  @override
  _CreateQuizScreenState createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  String? _schoolId;
  String? _classId;
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _questions = [];
  final _quizNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _fetchSchoolId();
  }

  Future<void> _fetchSchoolId() async {
    final user = FirebaseAuth.instance.currentUser;
    final teacherDoc = await FirebaseFirestore.instance
        .collection('teachers')
        .doc(user!.uid)
        .get();
    setState(() {
      _schoolId = teacherDoc.data()?['schoolId'];
    });
    _fetchClasses();
  }

  Future<void> _fetchClasses() async {
    try {
      final classesSnapshot = await FirebaseFirestore.instance
          .collection('Classes')
          .where('schoolId', isEqualTo: _schoolId)
          .get();
      setState(() {
        _classes = classesSnapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'name': doc['className'] as String,
          };
        }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching classes: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addQuestion() {
    String questionText = '';
    List<String> options = ['', '', '', ''];
    List<int> correctOptionIndices = [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: Text(
                'Add Question',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo[900],
                ),
              ),
              content: SingleChildScrollView(
                child: Form(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        onChanged: (value) {
                          questionText = value;
                        },
                        decoration: InputDecoration(
                          labelText: 'Question',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        maxLines: 3,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Options:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.indigo[900],
                        ),
                      ),
                      SizedBox(height: 10),
                      ...List.generate(4, (index) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Checkbox(
                                value: correctOptionIndices.contains(index),
                                onChanged: (value) {
                                  setState(() {
                                    if (value ?? false) {
                                      correctOptionIndices.add(index);
                                    } else {
                                      correctOptionIndices.remove(index);
                                    }
                                  });
                                },
                                activeColor: Colors.indigo[700],
                              ),
                              Expanded(
                                child: TextFormField(
                                  onChanged: (value) {
                                    options[index] = value;
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Option ${index + 1}',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (questionText.isNotEmpty &&
                        options.every((option) => option.isNotEmpty) &&
                        correctOptionIndices.isNotEmpty) {
                      setState(() {
                        _questions.add({
                          'question': questionText,
                          'options': options,
                          'correctOptionIndices': correctOptionIndices,
                        });
                      });
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please fill all fields'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('Add Question'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) => setState(() {}));
  }

  Future<void> _createQuizWithName(String quizName) async {
    try {
      final quizRef = await FirebaseFirestore.instance.collection('quizzes').add({
        'schoolId': _schoolId,
        'classId': _classId,
        'quizName': quizName,
        'questions': _questions,
        'createdAt': FieldValue.serverTimestamp(),
        'active': true,
      });

      // Create a separate collection for quiz results
      await FirebaseFirestore.instance.collection('quizResults').doc(quizRef.id).set({
        'submissions': [],
        'averageScore': 0,
        'totalSubmissions': 0,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Quiz created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizResultsScreen(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating quiz: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Create Quiz',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
          ),
        ),
        backgroundColor: Colors.indigo[700],
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuizResultsScreen(),
                  ),
                );
              },
              icon: Icon(Icons.history),
              label: Text('View History'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.indigo[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),





  body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Class',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo[900],
                      ),
                    ),
                    SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _classId,
                      onChanged: (value) {
                        setState(() {
                          _classId = value;
                        });
                      },
                      items: _classes.map((classData) {
                        return DropdownMenuItem<String>(
                          value: classData['id'],
                          child: Text(classData['name']),
                        );
                      }).toList(),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Questions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[900],
              ),
            ),
            SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                final question = _questions[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  margin: EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Question ${index + 1}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo[900],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _questions.removeAt(index);
                                });
                              },
                            ),

                          ],
                        ),
                        SizedBox(height: 8.0),
                        Text(
                          question['question'],
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 16.0),
                        Text(
                          'Options:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo[900],
                          ),
                        ),
                        ...List.generate(
                          question['options'].length,
                              (optionIndex) => Padding(
                            padding: EdgeInsets.only(left: 16.0, top: 8.0),
                            child: Row(
                              children: [
                                Icon(
                                  question['correctOptionIndices']
                                      .contains(optionIndex)
                                      ? Icons.check_circle
                                      : Icons.circle_outlined,
                                  color: question['correctOptionIndices']
                                      .contains(optionIndex)
                                      ? Colors.green
                                      : Colors.grey,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  question['options'][optionIndex],
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _addQuestion,
                    icon: Icon(Icons.add),
                    label: Text('Add Question'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo[700],
                      padding:
                      EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (_classId != null && _questions.isNotEmpty) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Quiz Name'),
                            content: TextField(
                              controller: _quizNameController,
                              decoration: InputDecoration(
                                hintText: 'Enter quiz name',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  if (_quizNameController.text.trim().isNotEmpty) {
                                    _createQuizWithName(
                                        _quizNameController.text.trim());
                                    Navigator.pop(context);
                                  }
                                },
                                child: Text('Create'),
                              ),
                              
                            ],
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Please select a class and add at least one question'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    icon: Icon(Icons.save),
                    label: Text('Create Quiz'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      padding:
                      EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                ],

              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Quiz Results Screen
class QuizResults extends StatelessWidget {
  final String quizId;

  QuizResults({required this.quizId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Quiz Results'),
          backgroundColor: Colors.indigo[700],
        ),
        body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('quizResults')
        .doc(quizId)
        .snapshots(),
    builder: (context, snapshot) {
    if  (!snapshot.hasData) {
      return Center(child: CircularProgressIndicator());
    }

    final data = snapshot.data!.data() as Map<String, dynamic>;
    final submissions = List<Map<String, dynamic>>.from(data['submissions'] ?? []);
    final averageScore = data['averageScore'] ?? 0.0;
    final totalSubmissions = data['totalSubmissions'] ?? 0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsCard(
            context,
            averageScore,
            totalSubmissions,
          ),
          SizedBox(height: 20),
          Text(
            'Recent Submissions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.indigo[900],
            ),
          ),
          SizedBox(height: 10),
          _buildSubmissionsList(submissions),
        ],
      ),
    );
    },
        ),
    );
  }

  Widget _buildStatsCard(BuildContext context, double averageScore, int totalSubmissions) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quiz Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[900],
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Average Score',
                  '${averageScore.toStringAsFixed(1)}%',
                  Icons.analytics,
                  Colors.blue,
                ),
                _buildStatItem(
                  'Total Submissions',
                  totalSubmissions.toString(),
                  Icons.people,
                  Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 40, color: color),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSubmissionsList(List<Map<String, dynamic>> submissions) {
    if (submissions.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.hourglass_empty,
                  size: 48,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 8),
                Text(
                  'No submissions yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: submissions.length,
      itemBuilder: (context, index) {
        final submission = submissions[index];
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          margin: EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.indigo[700],
              child: Text(
                submission['studentName']?[0] ?? '?',
                style: TextStyle(color: Colors.white),
              ),
            ),
            title: Text(submission['studentName'] ?? 'Anonymous'),
            subtitle: Text(
              'Submitted: ${_formatDateTime(submission['submittedAt'])}',
            ),
            trailing: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getScoreColor(submission['score']),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${submission['score'].toStringAsFixed(1)}%',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDateTime(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    final DateTime dateTime = timestamp.toDate();
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Color _getScoreColor(double score) {
    if (score >= 90) return Colors.green[700]!;
    if (score >= 80) return Colors.blue[700]!;
    if (score >= 70) return Colors.orange[700]!;
    return Colors.red[700]!;
  }
}