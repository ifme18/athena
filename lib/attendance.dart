import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class AttendanceScreen extends StatefulWidget {
  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class AttendanceData {
  final String attendance;

  AttendanceData(this.attendance);
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

  @override
  void initState() {
    super.initState();
    _getUserData();
    _commentController = TextEditingController();
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

  Future<void> _getStudents() async {
    if (_selectedClassId == null) return;

    final studentsSnapshot = await FirebaseFirestore.instance
        .collection('students')
        .where('classId', isEqualTo: _selectedClassId)
        .get();
    setState(() {
      _students = studentsSnapshot.docs;
      _attendance = List<String>.filled(_students.length, 'Present');
    });
  }

  Future<void> _submitAttendance() async {
    if (_selectedClassId == null || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a class and date first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    print("Submit button pressed");
    setState(() {
      _isLoading = true;
    });
    print("isLoading set to true");

    try {
      print("Attempting to submit to Firestore");
      await FirebaseFirestore.instance
          .collection('attendance')
          .doc(_selectedClassId)
          .collection(_selectedDate.toString())
          .doc()
          .set({
        'userId': _user.uid,
        'attendance': _attendance,
        'comment': _commentController.text,
      });
      print("Firestore submission successful");

      setState(() {
        _selectedClassId = null;
        _students = [];
        _attendance = [];
        _commentController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Attendance submitted successfully'),
        ),
      );
    } catch (e) {
      print('Error submitting attendance: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit attendance. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      print("Setting isLoading to false");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<DocumentSnapshot>> _fetchAttendanceData() async {
    if (_selectedClassId == null) return [];

    try {
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('attendance')
          .doc(_selectedClassId)
          .collection(_selectedDate.toString())
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepOrange,
        title: Text('Fill Attendance'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton(
                onPressed: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2015, 8),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null && picked != _selectedDate) {
                    setState(() {
                      _selectedDate = picked;
                    });
                    _getStudents();
                  }
                },
                child: Text(
                  'Select Date: ${_selectedDate.toString().split(' ')[0]}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String?>(
                value: _selectedClassId,
                hint: Text('Select Class'),
                onChanged: (value) {
                  setState(() {
                    _selectedClassId = value;
                  });
                  if (value != null) {
                    _getStudents();
                  }
                },
                items: _classIds
                    .map((classId) => DropdownMenuItem<String?>(
                  child: FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('Classes')
                        .doc(classId)
                        .get(),
                    builder: (BuildContext context,
                        AsyncSnapshot<DocumentSnapshot> snapshot) {
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }

                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      }

                      return Text(snapshot.data!['className']);
                    },
                  ),
                  value: classId,
                ))
                    .toList(),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                  EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                ),
              ),
              SizedBox(height: 20),
              if (_students.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: _students.length,
                  itemBuilder: (context, index) {
                    final student = _students[index];
                    return Card(
                      child: ListTile(
                        title: Text(student['name']),
                        trailing: DropdownButton<String>(
                          value: _attendance[index],
                          onChanged: (value) {
                            setState(() {
                              _attendance[index] = value!;
                            });
                          },
                          items: ['Absent', 'Present', 'Leave']
                              .map((attendance) => DropdownMenuItem(
                            child: Text(attendance),
                            value: attendance,
                          ))
                              .toList(),
                        ),
                      ),
                    );
                  },
                ),
              SizedBox(height: 20),
              TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  labelText: 'Comments (Optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                  EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitAttendance,
                child: _isLoading
                    ? CircularProgressIndicator(
                  color: Colors.white,
                )
                    : Text('Submit Attendance'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  textStyle: TextStyle(fontSize: 18),
                ),
              ),
              SizedBox(height: 20),
              FutureBuilder(
                future: _fetchAttendanceData(),
                builder: (context,
                    AsyncSnapshot<List<DocumentSnapshot>> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else {
                    if (snapshot.hasError || snapshot.data == null) {
                      return Text('Something went wrong.');
                    } else {
                      final List<DocumentSnapshot> attendanceData =
                      snapshot.data!;
                      if (attendanceData.isEmpty) {
                        return Text(
                            'No attendance records found for the selected date.');
                      }
                      return Column(
                        children: attendanceData.map((doc) {
                          final List<dynamic> attendance = doc['attendance'];
                          final String comment = doc['comment'];
                          return Container(
                            margin: EdgeInsets.symmetric(vertical: 5),
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Date: ${doc.id.split(' ')[0]}'),
                                SizedBox(height: 5),
                                Text('Comment: $comment'),
                                SizedBox(height: 5),
                                Text('Attendance:'),
                                SizedBox(height: 5),
                                ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: attendance.length,
                                  itemBuilder: (context, index) {
                                    return Text(
                                        '- ${_students[index]['name']}: ${attendance[index]}');
                                  },
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    }
                  }
                },
              ),
              SizedBox(height: 20),
              if (_students.isNotEmpty)
                SfCircularChart(
                  series: <CircularSeries>[
                    PieSeries<AttendanceData, String>(
                      dataSource: _attendance
                          .map((attendance) => AttendanceData(attendance))
                          .toList(),
                      xValueMapper: (AttendanceData data, _) => data.attendance,
                      yValueMapper: (AttendanceData data, _) => _attendance
                          .where((att) => att == data.attendance)
                          .length,
                      dataLabelSettings: DataLabelSettings(isVisible: true),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}