import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class QuizResultsScreen extends StatefulWidget {
  @override
  _QuizResultsScreenState createState() => _QuizResultsScreenState();
}

class _QuizResultsScreenState extends State<QuizResultsScreen> {
  List<Map<String, dynamic>> _quizzes = [];
  String? _selectedQuizId;
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = true;
  String? _studentId;
  String? _schoolId;
  String? _classId;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final studentDoc = await FirebaseFirestore.instance
            .collection('students')
            .doc(user.uid)
            .get();

        if (studentDoc.exists) {
          setState(() {
            _studentId = user.uid;
            _schoolId = studentDoc.data()?['schoolId'];
            _classId = studentDoc.data()?['classId'];
          });
          await _fetchQuizzes();
        }
      } catch (e) {
        _showError('Error fetching user details');
      }
    }
  }

  Future<void> _fetchQuizzes() async {
    try {
      final quizzesSnapshot = await FirebaseFirestore.instance
          .collection('quizzes')
          .where('schoolId', isEqualTo: _schoolId)
          .where('classId', isEqualTo: _classId)
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _quizzes = quizzesSnapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'name': doc['quizName'],
          };
        }).toList();

        _selectedQuizId = _quizzes.isNotEmpty ? _quizzes.first['id'] : null;
        if (_selectedQuizId != null) {
          _fetchQuizResults(_selectedQuizId!);
        } else {
          _isLoading = false;
        }
      });
    } catch (e) {
      _showError('Error fetching quizzes');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchQuizResults(String quizId) async {
    setState(() {
      _isLoading = true;
      _results = [];
    });

    try {
      final resultDoc = await FirebaseFirestore.instance
          .collection('quizResults')
          .doc(quizId)
          .get();

      if (resultDoc.exists) {
        final submissions = List<Map<String, dynamic>>.from(
            resultDoc.data()?['submissions'] ?? []);

        // Filter submissions for the current student
        final studentSubmissions = submissions.where((submission) =>
        submission['studentId'] == _studentId).toList();

        setState(() {
          _results = studentSubmissions.map((submission) {
            final timestamp = submission['submittedAt'] as Timestamp;
            return {
              'score': submission['score'],
              'submittedAt': timestamp,
              'answers': submission['answers'],
            };
          }).toList();

          // Sort results by submission date, newest first
          _results.sort((a, b) => b['submittedAt'].compareTo(a['submittedAt']));
        });
      }
    } catch (e) {
      _showError('Error fetching quiz results');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
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
        elevation: 0,
        title: Text('Quiz Results'),
        backgroundColor: Colors.indigo[700],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.indigo[700],
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Quiz',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedQuizId,
                      hint: Text('Select a quiz'),
                      onChanged: (value) {
                        setState(() {
                          _selectedQuizId = value;
                          if (value != null) {
                            _fetchQuizResults(value);
                          }
                        });
                      },
                      items: _quizzes.map((quiz) {
                        return DropdownMenuItem<String>(
                          value: quiz['id'],
                          child: Text(quiz['name']),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _results.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assessment_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No results available',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final result = _results[index];
                final score = result['score'] as num;
                final submittedAt = result['submittedAt'] as Timestamp;
                final dateString = DateFormat('MMM dd, yyyy - hh:mm a')
                    .format(submittedAt.toDate());

                return Card(
                  margin: EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Attempt ${_results.length - index}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo[700],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: score >= 70
                                    ? Colors.green[100]
                                    : Colors.orange[100],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${score.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: score >= 70
                                      ? Colors.green[700]
                                      : Colors.orange[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Submitted on: $dateString',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          score >= 70
                              ? 'Passed'
                              : 'Needs Improvement',
                          style: TextStyle(
                            color: score >= 70
                                ? Colors.green[700]
                                : Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}