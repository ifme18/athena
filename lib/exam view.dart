import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ResultsScreen extends StatefulWidget {
  @override
  _ResultsScreenState createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  String? studentId;
  String? schoolId;
  String? selectedExamId;
  List<String> examNames = [];
  Map<String, String> examIdMap = {};
  List<Map<String, dynamic>> results = [];
  bool isLoading = true;
  bool showChart = false;
  double averageScore = 0.0;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      studentId = user.uid;

      DocumentSnapshot studentDoc = await FirebaseFirestore.instance
          .collection('students')
          .doc(studentId)
          .get();

      if (studentDoc.exists) {
        schoolId = studentDoc['schoolId'];
        await fetchExams();
      } else {
        setState(() {
          isLoading = false;
        });
        return;
      }
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchExams() async {
    try {
      QuerySnapshot examsSnapshot = await FirebaseFirestore.instance
          .collection('exams')
          .where('schoolId', isEqualTo: schoolId)
          .get();

      List<String> fetchedExamNames = [];
      Map<String, String> fetchedExamIdMap = {};

      for (var doc in examsSnapshot.docs) {
        String examId = doc.id;
        String examName = doc['examName'] ?? 'Unknown Exam';
        fetchedExamNames.add(examName);
        fetchedExamIdMap[examName] = examId;
      }

      setState(() {
        examNames = fetchedExamNames;
        examIdMap = fetchedExamIdMap;
        if (examNames.isNotEmpty) {
          selectedExamId = examIdMap[examNames.first];
          fetchResults(selectedExamId!);
        }
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching exams: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchResults(String examId) async {
    try {
      QuerySnapshot resultsSnapshot = await FirebaseFirestore.instance
          .collection('exams')
          .doc(examId)
          .collection('results')
          .where('registrationNumber', isEqualTo: studentId)
          .get();

      List<Map<String, dynamic>> fetchedResults = [];
      double totalScore = 0;

      for (var doc in resultsSnapshot.docs) {
        Map<String, dynamic> resultData = doc.data() as Map<String, dynamic>;
        fetchedResults.add(resultData);
        totalScore += resultData['score'] ?? 0;
      }

      setState(() {
        results = fetchedResults;
        averageScore = results.isNotEmpty ? totalScore / results.length : 0.0;
      });
    } catch (e) {
      print('Error fetching results: $e');
    }
  }

  void onVisualizePressed() {
    setState(() {
      showChart = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'Academic Performance',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.teal.shade700,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.teal.shade700,
        elevation: 0,
        centerTitle: true,
      ),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.teal.shade700),
          strokeWidth: 3,
        ),
      )
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (examNames.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: examNames.firstWhere(
                            (examName) => examIdMap[examName] == selectedExamId,
                        orElse: () => examNames.first,
                      ),
                      items: examNames.map((examName) {
                        return DropdownMenuItem<String>(
                          value: examName,
                          child: Text(
                            examName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.teal.shade700,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (newExamName) {
                        setState(() {
                          selectedExamId = examIdMap[newExamName!];
                          fetchResults(selectedExamId!);
                          showChart = false;
                        });
                      },
                      isExpanded: true,
                      icon: Icon(Icons.keyboard_arrow_down, color: Colors.teal.shade700),
                    ),
                  ),
                ),
              SizedBox(height: 24),
              if (results.isEmpty)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assessment_outlined, size: 64, color: Colors.teal.shade200),
                      SizedBox(height: 16),
                      Text(
                        'No results available',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                examNames.firstWhere(
                                      (examName) => examIdMap[examName] == selectedExamId,
                                  orElse: () => 'No Exam Selected',
                                ),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.teal.shade700,
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade700,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Avg: ${averageScore.toStringAsFixed(1)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final result = results[index];
                          return Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey.shade100,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    result['subjectName'] ?? 'No Subject',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getScoreColor(result['score']),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${result['score']}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    result['rating'] ?? 'N/A',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildActionButton(
                              icon: Icons.bar_chart,
                              label: 'Visualize',
                              onPressed: onVisualizePressed,
                            ),
                            _buildActionButton(
                              icon: Icons.print,
                              label: 'Print',
                              onPressed: () {/* Print functionality */},
                            ),
                            _buildActionButton(
                              icon: Icons.share,
                              label: 'Share',
                              onPressed: () {/* Share functionality */},
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              if (showChart)
                Container(
                  margin: EdgeInsets.only(top: 24),
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: SfCartesianChart(
                    primaryXAxis: CategoryAxis(
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    primaryYAxis: NumericAxis(
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    title: ChartTitle(
                      text: 'Performance Analysis',
                      textStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.teal.shade700,
                      ),
                    ),
                    tooltipBehavior: TooltipBehavior(enable: true),
                    series: <ChartSeries>[
                      ColumnSeries<Map<String, dynamic>, String>(
                        dataSource: results,
                        xValueMapper: (Map<String, dynamic> data, _) =>
                        data['subjectName'] ?? 'Unknown',
                        yValueMapper: (Map<String, dynamic> data, _) =>
                        data['score'] ?? 0,
                        name: 'Score',
                        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                        gradient: LinearGradient(
                          colors: [Colors.teal.shade300, Colors.teal.shade700],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        dataLabelSettings: DataLabelSettings(
                          isVisible: true,
                          labelAlignment: ChartDataLabelAlignment.top,
                          textStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white, backgroundColor: Colors.teal.shade700,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 0,
      ),
    );
  }

  Color _getScoreColor(dynamic score) {
    if (score == null) return Colors.grey;
    if (score >= 80) return Colors.green.shade600;
    if (score >= 60) return Colors.orange.shade600;
    return Colors.red.shade600;
  }
}
