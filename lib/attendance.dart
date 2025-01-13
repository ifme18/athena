import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

class AttendanceScreen extends StatefulWidget {
  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late User _user;
  late String _schoolId;
  late List<String> _classIds = [];
  String? _selectedClassId;
  List<DocumentSnapshot> _students = [];
  late List<String> _attendance = [];
  late TextEditingController _commentController;
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();
  final _formKey = GlobalKey<FormState>();

  // New controllers for filtering and searching
  TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _filteredStudents = [];

  @override
  void initState() {
    super.initState();
    _getUserData();
    _commentController = TextEditingController();
    _filteredStudents = _students;
  }

  // Filter students based on search query
  void _filterStudents(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredStudents = _students;
      } else {
        _filteredStudents = _students
            .where((student) =>
            student['name'].toString().toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _getUserData() async {
    _user = FirebaseAuth.instance.currentUser!;
    if (_user != null) {
      final adminData = await FirebaseFirestore.instance
          .collection('admins')
          .doc(_user.uid)
          .get();
      setState(() {
        _schoolId = adminData['schoolId'];
      });

      final classesSnapshot = await FirebaseFirestore.instance
          .collection('Classes')
          .where('schoolId', isEqualTo: _schoolId)
          .get();
      setState(() {
        _classIds = classesSnapshot.docs.map((doc) => doc.id).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.indigo,
        title: Text(
          'Attendance Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              // Show attendance history
              _showAttendanceHistory();
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Top Stats Card
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.indigo,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard(
                        'Total',
                        _students.length.toString(),
                        Icons.people,
                        Colors.blue[100]!,
                      ),
                      _buildStatCard(
                        'Present',
                        _attendance.where((a) => a == 'Present').length.toString(),
                        Icons.check_circle,
                        Colors.green[100]!,
                      ),
                      _buildStatCard(
                        'Absent',
                        _attendance.where((a) => a == 'Absent').length.toString(),
                        Icons.cancel,
                        Colors.red[100]!,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Class Selection and Date Picker
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildClassDropdown(),
                  ),
                  SizedBox(width: 16),
                  IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context),
                  ),
                ],
              ),
            ),

            // Search Bar
            if (_students.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search students...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: _filterStudents,
                ),
              ),

            // Students List
            Expanded(
              child: _filteredStudents.isEmpty
                  ? Center(
                child: Text('No students found'),
              )
                  : ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: _filteredStudents.length,
                itemBuilder: (context, index) {
                  final student = _filteredStudents[index];
                  final originalIndex = _students.indexOf(student);
                  return _buildStudentCard(student, originalIndex);
                },
              ),
            ),

            // Bottom Action Bar
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Add comment...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  ElevatedButton.icon(
                    icon: _isLoading
                        ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : Icon(Icons.save),
                    label: Text('Submit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: _isLoading ? null : _submitAttendance,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitAttendance() async {
    if (_selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a class first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No students to mark attendance for.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);

      // Create attendance record
      Map<String, dynamic> attendanceData = {
        'userId': _user.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'attendance': _attendance,
        'comment': _commentController.text.trim(),
        'studentIds': _students.map((doc) => doc.id).toList(),
      };

      // Add attendance stats
      attendanceData['stats'] = {
        'present': _attendance.where((status) => status == 'Present').length,
        'absent': _attendance.where((status) => status == 'Absent').length,
        'leave': _attendance.where((status) => status == 'Leave').length,
        'total': _students.length,
      };

      // Submit to Firestore
      await FirebaseFirestore.instance
          .collection('attendance')
          .doc(_selectedClassId)
          .collection(dateString)
          .add(attendanceData);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Attendance submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear form
      setState(() {
        _commentController.clear();
      });

    } catch (e) {
      print('Error submitting attendance: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit attendance. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
// [Previous imports and class definitions remain the same until _AttendanceScreenState]

  // Add these methods after the existing state variables and before build method
  // [Previous code remains the same until _getStudents method]

  Future<void> _getStudents() async {
    if (_selectedClassId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Simplified query: only filter by classId without ordering
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('classId', isEqualTo: _selectedClassId)
          .get();

      // Sort the results in memory instead
      final sortedDocs = studentsSnapshot.docs.toList()
        ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

      setState(() {
        _students = sortedDocs;
        _filteredStudents = _students;
        _attendance = List<String>.filled(_students.length, 'Present');
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching students: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to fetch students. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

// [Rest of the code remains the same]
  Future<List<DocumentSnapshot>> _fetchAttendanceData() async {
    if (_selectedClassId == null) return [];

    try {
      final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('attendance')
          .doc(_selectedClassId)
          .collection(dateString)
          .get();

      return querySnapshot.docs;
    } catch (e) {
      print('Error fetching attendance data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to fetch attendance data. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return [];
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    // Format for display (e.g., "15 Jan 2025")
    String formattedDisplayDate = DateFormat('dd MMM yyyy').format(_selectedDate);

    // Format for storage (e.g., "20250115")
    String formattedStorageDate = DateFormat('yyyyMMdd').format(_selectedDate);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        // Remove time component and store only the date
        _selectedDate = DateTime(picked.year, picked.month, picked.day);

        // Update the formatted dates
        formattedDisplayDate = DateFormat('dd MMM yyyy').format(_selectedDate);
        formattedStorageDate = DateFormat('yyyyMMdd').format(_selectedDate);
      });

      print('Display Date: $formattedDisplayDate'); // For UI display
      print('Storage Date: $formattedStorageDate'); // For Firestore storage

      await _getStudents();
    }
  }

// [Rest of the existing code remains the same]
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(title),
        ],
      ),
    );
  }

  Widget _buildClassDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedClassId,
      decoration: InputDecoration(
        labelText: 'Select Class',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
      ),
      items: _classIds.map((classId) {
        return DropdownMenuItem(
          value: classId,
          child: FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('Classes')
                .doc(classId)
                .get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return CircularProgressIndicator();
              return Text(snapshot.data!['className']);
            },
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedClassId = value;
          _getStudents();
        });
      },
    );
  }

  Widget _buildStudentCard(DocumentSnapshot student, int index) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(student['name'][0]),
          backgroundColor: Colors.indigo[100],
        ),
        title: Text(
          student['name'],
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(student['regno'] ?? ''),
        trailing: DropdownButton<String>(
          value: _attendance[index],
          items: ['Present', 'Absent', 'Leave'].map((status) {
            return DropdownMenuItem(
              value: status,
              child: Text(
                status,
                style: TextStyle(
                  color: status == 'Present'
                      ? Colors.green
                      : status == 'Absent'
                      ? Colors.red
                      : Colors.orange,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _attendance[index] = value!;
            });
          },
        ),
      ),
    );
  }



  void _showAttendanceHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Attendance History',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: FutureBuilder(
                  future: _fetchAttendanceData(),
                  builder: (context, AsyncSnapshot<List<DocumentSnapshot>> snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final record = snapshot.data![index];
                        return _buildHistoryCard(record);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryCard(DocumentSnapshot record) {
    // Parse the date string with the correct format (assuming yyyyMMdd format)
    DateTime date;
    try {
      // Assuming record.id is in format 'yyyyMMdd'
      String dateStr = record.id;
      date = DateTime(
          int.parse(dateStr.substring(0, 4)),  // year
          int.parse(dateStr.substring(4, 6)),  // month
          int.parse(dateStr.substring(6, 8))   // day
      );
    } catch (e) {
      // Fallback in case of parsing error
      date = DateTime.now();
      print('Error parsing date: ${record.id}');
    }

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('MMMM d, yyyy').format(date),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text('Comment: ${record['comment']}'),
            SizedBox(height: 8),
            Text(
              'Attendance Summary:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAttendanceCount('Present', Colors.green, record),
                _buildAttendanceCount('Absent', Colors.red, record),
                _buildAttendanceCount('Leave', Colors.orange, record),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceCount(String status, Color color, DocumentSnapshot record) {
    final count = (record['attendance'] as List)
        .where((a) => a == status)
        .length;
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(status),
      ],
    );
  }
}