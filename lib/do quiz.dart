import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AttemptQuizScreen extends StatefulWidget {
  const AttemptQuizScreen({super.key});

  @override
  AttemptQuizScreenState createState() => AttemptQuizScreenState();
}

class AttemptQuizScreenState extends State<AttemptQuizScreen> {
  final List<Map<String, dynamic>> _quizzes = [];
  final List<Map<String, dynamic>> _questions = [];
  late List<int> _selectedAnswers;
  String? _selectedQuizId;
  String? _schoolId;
  String? _classId;
  String? _studentName;
  bool _quizAvailable = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final studentDoc = await FirebaseFirestore.instance
          .collection('students')
          .doc(user.uid)
          .get();

      if (!studentDoc.exists) return;

      setState(() {
        _schoolId = studentDoc.data()?['schoolId'];
        _classId = studentDoc.data()?['classId'];
        _studentName = studentDoc.data()?['name'] ?? 'Anonymous Student';
      });
      await _fetchQuizzes();
    } catch (e) {
      _showError('Error fetching user details: ${e.toString()}');
    }
  }

  Future<void> _fetchQuizzes() async {
    try {
      if (_schoolId == null || _classId == null) return;

      final quizzesSnapshot = await FirebaseFirestore.instance
          .collection('quizzes')
          .where('schoolId', isEqualTo: _schoolId)
          .where('classId', isEqualTo: _classId)
          .get();

      if (quizzesSnapshot.docs.isEmpty) {
        setState(() => _quizAvailable = false);
        return;
      }

      _quizzes.clear();
      _quizzes.addAll(quizzesSnapshot.docs.map((doc) => {
        'id': doc.id,
        'name': doc['quizName'],
        'questions': doc['questions'] ?? [],
      }));

      setState(() {
        _selectedQuizId = _quizzes.isNotEmpty ? _quizzes.first['id'] : null;
      });

      if (_selectedQuizId != null) {
        await _fetchQuizQuestions(_selectedQuizId!);
      }
    } catch (e) {
      _showError('Error fetching quizzes: ${e.toString()}');
      setState(() => _quizAvailable = false);
    }
  }

  Future<void> _fetchQuizQuestions(String quizId) async {
    try {
      final quizDoc = await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(quizId)
          .get();

      if (!quizDoc.exists) {
        setState(() => _quizAvailable = false);
        return;
      }

      final questions = List<Map<String, dynamic>>.from(
          quizDoc.data()?['questions'] ?? []);

      setState(() {
        _questions.clear();
        _questions.addAll(questions);
        _selectedAnswers = List.filled(questions.length, -1);
        _quizAvailable = true;
      });
    } catch (e) {
      _showError('Error fetching quiz questions: ${e.toString()}');
      setState(() => _quizAvailable = false);
    }
  }

  void _selectAnswer(int questionIndex, int optionIndex) {
    setState(() => _selectedAnswers[questionIndex] = optionIndex);
  }

  int _calculateScore() {
    int score = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_selectedAnswers[i] == _questions[i]['correctOptionIndices'][0]) {
        score++;
      }
    }
    return score;
  }

  // Previous imports and class declaration remain the same...

// Update the _submitQuiz method:
  Future<void> _submitQuiz() async {
    if (_selectedAnswers.contains(-1)) {
      _showError('Please answer all questions before submitting');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final score = _calculateScore();
      final percentage = (score / _questions.length) * 100;
      final user = FirebaseAuth.instance.currentUser;

      if (user == null || _selectedQuizId == null) {
        _showError('Authentication error');
        return;
      }

      // Create a new document reference for each submission
      final submissionRef = FirebaseFirestore.instance
          .collection('quizResults')
          .doc(); // Let Firestore auto-generate the ID

      await submissionRef.set({
        'quizId': _selectedQuizId,
        'studentId': user.uid,
        'studentName': _studentName,
        'score': percentage,
        'submittedAt': FieldValue.serverTimestamp(),
        'answers': _selectedAnswers,
      });

      if (!mounted) return;
      _showResults(score);
    } catch (e) {
      _showError('Error submitting quiz: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showResults(int score) {
    final percentage = (score / _questions.length) * 100;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Quiz Results'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              percentage >= 70 ? Icons.check_circle : Icons.info,
              color: percentage >= 70 ? Colors.green : Colors.orange,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'You scored ${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: percentage >= 70 ? Colors.green : Colors.orange,
              ),
            ),
            Text('($score out of ${_questions.length} questions correct)'),
            const SizedBox(height: 16),
            Text(
              percentage >= 70
                  ? 'Great job!'
                  : 'Keep practicing, you can do better!',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedAnswers = List.filled(_questions.length, -1);
              });
            },
            child: const Text('Try Another Quiz'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
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
        title: const Text('Quiz'),
        backgroundColor: Colors.indigo[700],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.indigo[700],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Quiz',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedQuizId,
                      hint: const Text('Select a quiz'),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedQuizId = value);
                          _fetchQuizQuestions(value);
                        }
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
            child: _quizAvailable
                ? SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: List.generate(_questions.length, (index) {
                  final question = _questions[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.indigo[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Question ${index + 1}',
                              style: TextStyle(
                                color: Colors.indigo[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            question['question'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...List.generate(
                            question['options'].length,
                                (optionIndex) => RadioListTile<int>(
                              title: Text(question['options'][optionIndex]),
                              value: optionIndex,
                              groupValue: _selectedAnswers[index],
                              onChanged: (value) =>
                                  _selectAnswer(index, value!),
                              activeColor: Colors.indigo[700],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            )
                : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.quiz,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No quiz available',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _quizAvailable
          ? FloatingActionButton.extended(
        onPressed: _isSubmitting ? null : _submitQuiz,
        icon: _isSubmitting
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(color: Colors.white),
        )
            : const Icon(Icons.check),
        label: Text(_isSubmitting ? 'Submitting...' : 'Submit Quiz'),
        backgroundColor: _isSubmitting ? Colors.grey : Colors.indigo[700],
      )
          : null,
    );
  }
}