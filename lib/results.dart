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
  String? _schoolId;

  @override
  void initState() {
    super.initState();
    _fetchTeacherDetails();
  }

  Future<void> _fetchTeacherDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Assume teachers have a separate collection for their profiles
        final teacherDoc = await FirebaseFirestore.instance
            .collection('teachers')
            .doc(user.uid)
            .get();

        if (teacherDoc.exists) {
          setState(() {
            _schoolId = teacherDoc.data()?['schoolId'];
          });
          await _fetchQuizzes();
        } else {
          print('Teacher document does not exist for user: ${user.uid}');
          _showError('Teacher data not found');
        }
      } catch (e) {
        print('Error fetching teacher details: $e');
        _showError('Error fetching teacher details: ${e.toString()}');
      }
    } else {
      print('No authenticated user');
      _showError('Please log in to view quiz results');
    }
  }

  Future<void> _fetchQuizzes() async {
    if (_schoolId == null) return;
    try {
      // Fetch quizzes for the school
      final quizzesSnapshot = await FirebaseFirestore.instance
          .collection('quizzes')
          .where('schoolId', isEqualTo: _schoolId)
          .get();

      setState(() {
        _quizzes = quizzesSnapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'name': doc['quizName'],
          };
        }).toList();
        print('Fetched quizzes: $_quizzes');

        _selectedQuizId = _quizzes.isNotEmpty ? _quizzes.first['id'] : null;
        if (_selectedQuizId != null) {
          _fetchQuizResults(_selectedQuizId!);
        } else {
          _isLoading = false;
        }
      });
    } catch (e) {
      print('Error fetching quizzes: $e');
      _showError('Error fetching quizzes: ${e.toString()}');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchQuizResults(String quizId) async {
    print('Fetching results for quizId: $quizId');
    setState(() {
      _isLoading = true;
      _results = [];
    });

    try {
      // Fetch results for the selected quiz
      final resultsSnapshot = await FirebaseFirestore.instance
          .collection('quizResults')
          .where('quizId', isEqualTo: quizId)
          .get();

      // Filter results by schoolId in Dart after fetching
      List<Map<String, dynamic>> filteredResults = resultsSnapshot.docs
          .where((doc) => doc.data()['schoolId'] == _schoolId)
          .map((doc) {
        final data = doc.data();
        final timestamp = data['submittedAt'] as Timestamp;
        return {
          'studentName': data['studentName'],
          'score': data['score'] as num,
          'submittedAt': timestamp,
        };
      }).toList();

      // Sort results by submission time, most recent first
      filteredResults.sort((a, b) => b['submittedAt'].compareTo(a['submittedAt']));

      setState(() {
        _results = filteredResults;
        print('Filtered and Sorted Results: $_results');
      });
    } catch (e) {
      print('Error in _fetchQuizResults: $e');
      _showError('Error fetching quiz results: ${e.toString()}');
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
                          print('Selected quiz ID: $_selectedQuizId');
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${result['studentName']}',
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