import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class PdfExamReport {
  static Future<Uint8List> generate({
    required String examName,
    required String schoolName,
    required String className,
    required List<Map<String, dynamic>> students,
    required List<Map<String, dynamic>> subjects,
  }) async {
    final pdf = pw.Document();

    // Sort students by average score (descending)
    students.sort((a, b) {
      double aAvg = calculateAverage(a['scores']);
      double bAvg = calculateAverage(b['scores']);
      return bAvg.compareTo(aAvg);
    });

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader(schoolName, examName, className),
          pw.SizedBox(height: 20),
          _buildSummaryStatistics(students),
          pw.SizedBox(height: 20),
          _buildScoreDistributionTable(students),
          pw.SizedBox(height: 20),
          _buildSubjectAnalysis(students, subjects),
          pw.SizedBox(height: 20),
          _buildDetailedResults(students, subjects),
          pw.SizedBox(height: 20),
          _buildPerformanceAnalysis(students),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(String schoolName, String examName, String className) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          schoolName,
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'EXAMINATION REPORT',
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Class: $className | Exam: $examName',
          style: pw.TextStyle(fontSize: 16),
        ),
        pw.Text(
          'Generated on: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
          style: pw.TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  static pw.Widget _buildSummaryStatistics(List<Map<String, dynamic>> students) {
    double classAverage = students.isEmpty ? 0 :
    students.map((s) => calculateAverage(s['scores'])).reduce((a, b) => a + b) / students.length;

    double highestScore = students.isEmpty ? 0 :
    students.map((s) => calculateAverage(s['scores'])).reduce((a, b) => a > b ? a : b);

    double lowestScore = students.isEmpty ? 0 :
    students.map((s) => calculateAverage(s['scores'])).reduce((a, b) => a < b ? a : b);

    return pw.Container(
      padding: pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'CLASS SUMMARY',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildStatBox('Total Students', '${students.length}'),
              _buildStatBox('Class Average', '${classAverage.toStringAsFixed(2)}%'),
              _buildStatBox('Highest Score', '${highestScore.toStringAsFixed(2)}%'),
              _buildStatBox('Lowest Score', '${lowestScore.toStringAsFixed(2)}%'),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSubjectAnalysis(
      List<Map<String, dynamic>> students,
      List<Map<String, dynamic>> subjects,
      ) {
    Map<String, Map<String, double>> subjectStats = {};

    // Initialize stats for each subject
    for (var subject in subjects) {
      subjectStats[subject['id']] = {
        'total': 0,
        'highest': 0,
        'lowest': 100,
        'count': 0,
      };
    }

    // Calculate statistics for each subject
    for (var student in students) {
      student['scores'].forEach((subjectId, scoreData) {
        double score = (scoreData['score'] ?? 0).toDouble();
        var stats = subjectStats[subjectId]!;
        stats['total'] = stats['total']! + score;
        stats['highest'] = score > stats['highest']! ? score : stats['highest']!;
        stats['lowest'] = score < stats['lowest']! ? score : stats['lowest']!;
        stats['count'] = stats['count']! + 1;
      });
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'SUBJECT ANALYSIS',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                _buildTableCell('Subject', isHeader: true),
                _buildTableCell('Average', isHeader: true),
                _buildTableCell('Highest', isHeader: true),
                _buildTableCell('Lowest', isHeader: true),
              ],
            ),
            ...subjects.map((subject) {
              var stats = subjectStats[subject['id']]!;
              double average = stats['count']! > 0 ? stats['total']! / stats['count']! : 0;
              return pw.TableRow(
                children: [
                  _buildTableCell(subject['name']),
                  _buildTableCell('${average.toStringAsFixed(2)}%'),
                  _buildTableCell('${stats['highest']!.toStringAsFixed(1)}%'),
                  _buildTableCell('${stats['lowest']!.toStringAsFixed(1)}%'),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildDetailedResults(
      List<Map<String, dynamic>> students,
      List<Map<String, dynamic>> subjects,
      ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'DETAILED STUDENT RESULTS',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            // Header row with subject names
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                _buildTableCell('Rank', isHeader: true),
                _buildTableCell('Reg. No.', isHeader: true),
                ...subjects.map((subject) => _buildTableCell(subject['name'], isHeader: true)),
                _buildTableCell('Average', isHeader: true),
                _buildTableCell('Grade', isHeader: true),
              ],
            ),
            // Student rows
            ...students.asMap().entries.map((entry) {
              int rank = entry.key + 1;
              var student = entry.value;
              double avgScore = calculateAverage(student['scores']);

              return pw.TableRow(
                children: [
                  _buildTableCell(rank.toString()),
                  _buildTableCell(student['regno']),
                  ...subjects.map((subject) {
                    var score = student['scores'][subject['id']]?['score'] ?? '-';
                    return _buildTableCell(score.toString());
                  }),
                  _buildTableCell('${avgScore.toStringAsFixed(2)}%'),
                  _buildTableCell(_getGrade(avgScore)),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildScoreDistributionTable(List<Map<String, dynamic>> students) {
    Map<String, int> distribution = {
      '80-100': 0,
      '70-79': 0,
      '50-69': 0,
      '0-49': 0,
    };

    for (var student in students) {
      double avg = calculateAverage(student['scores']);
      if (avg >= 80) distribution['80-100'] = distribution['80-100']! + 1;
      else if (avg >= 70) distribution['70-79'] = distribution['70-79']! + 1;
      else if (avg >= 50) distribution['50-69'] = distribution['50-69']! + 1;
      else distribution['0-49'] = distribution['0-49']! + 1;
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'SCORE DISTRIBUTION',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                _buildTableCell('Score Range', isHeader: true),
                _buildTableCell('Count', isHeader: true),
                _buildTableCell('Grade', isHeader: true),
                _buildTableCell('Remarks', isHeader: true),
              ],
            ),
            ...distribution.entries.map((entry) => pw.TableRow(
              children: [
                _buildTableCell(entry.key),
                _buildTableCell(entry.value.toString()),
                _buildTableCell(_getGrade(double.parse(entry.key.split('-')[0]))),
                _buildTableCell(_getRemarks(entry.key)),
              ],
            )).toList(),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildPerformanceAnalysis(List<Map<String, dynamic>> students) {
    int totalStudents = students.length;
    int excellentCount = students.where((s) => calculateAverage(s['scores']) >= 80).length;
    int goodCount = students.where((s) => calculateAverage(s['scores']) >= 70 && calculateAverage(s['scores']) < 80).length;
    int averageCount = students.where((s) => calculateAverage(s['scores']) >= 50 && calculateAverage(s['scores']) < 70).length;
    int belowAverageCount = students.where((s) => calculateAverage(s['scores']) < 50).length;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'PERFORMANCE ANALYSIS',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Paragraph(
          text: '''
          • Number of students with excellent performance (A, 80-100%): $excellentCount (${(excellentCount/totalStudents * 100).toStringAsFixed(1)}%)
          • Number of students with good performance (B, 70-79%): $goodCount (${(goodCount/totalStudents * 100).toStringAsFixed(1)}%)
          • Number of students with average performance (C, 50-69%): $averageCount (${(averageCount/totalStudents * 100).toStringAsFixed(1)}%)
          • Number of students below average (D, 0-49%): $belowAverageCount (${(belowAverageCount/totalStudents * 100).toStringAsFixed(1)}%)
          ''',
        ),
      ],
    );
  }

  static pw.Widget _buildStatBox(String label, String value) {
    return pw.Container(
      padding: pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
      ),
      child: pw.Column(
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 10)),
          pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: pw.EdgeInsets.all(6),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: isHeader ? pw.FontWeight.bold : null,
        ),
      ),
    );
  }

  static String _getGrade(double score) {
    if (score >= 80) return 'A';
    if (score >= 70) return 'B';
    if (score >= 50) return 'C';
    return 'D';
  }

  static String _getRemarks(String range) {
    switch (range) {
      case '80-100': return 'Excellent';
      case '70-79': return 'Very Good';
      case '50-69': return 'Satisfactory';
      case '0-49': return 'Needs Improvement';
      default: return 'Unknown';
    }
  }

  static double calculateAverage(Map<String, dynamic> scores) {
    if (scores.isEmpty) return 0;
    double total = 0;
    scores.forEach((_, data) {
      total += (data['score'] ?? 0).toDouble();
    });
    return total / scores.length;
  }
}