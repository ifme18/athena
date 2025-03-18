import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class PieChartData {
  final String className;
  final int count;

  PieChartData(this.className, this.count);
}

class ClassCreation extends StatefulWidget {
  ClassCreation({
    Key? key,
    required this.currentUser,
  }) : super(key: key);

  final String currentUser;

  @override
  _ClassCreationState createState() => _ClassCreationState();
}

class _ClassCreationState extends State<ClassCreation> with SingleTickerProviderStateMixin {
  final TextEditingController _classController = TextEditingController();
  final FirebaseAuth auth = FirebaseAuth.instance;

  bool _isCreatingInProgress = false;
  String? _schoolId;
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchSchoolId();
  }

  Future<void> _fetchSchoolId() async {
    final User? user = auth.currentUser;
    if (user != null) {
      final DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('admins').doc(user.uid).get();
      setState(() {
        _schoolId = userDoc['schoolId'];
      });
    }
  }

  Future<void> _createClass() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isCreatingInProgress = true;
      });

      String className = _classController.text;

      try {
        await FirebaseFirestore.instance.collection('Classes').add({
          'className': className,
          'schoolId': _schoolId,
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Class created successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: EdgeInsets.all(10),
          ),
        );

        if (mounted) {
          setState(() {
            _isCreatingInProgress = false;
            _classController.clear();
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create class: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: EdgeInsets.all(10),
          ),
        );

        setState(() {
          _isCreatingInProgress = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Class Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            onPressed: _fetchSchoolId,
            icon: Icon(Icons.refresh),
            tooltip: 'Refresh data',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'ALL CLASSES', icon: Icon(Icons.list_alt)),
            Tab(text: 'CREATE CLASS', icon: Icon(Icons.add_circle_outline)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildClassListTab(),
          _buildCreateClassTab(),
        ],
      ),
    );
  }

  Widget _buildCreateClassTab() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create New Class',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade800,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Add a new class for your school',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 24),
                    TextFormField(
                      controller: _classController,
                      decoration: InputDecoration(
                        labelText: 'Class Name',
                        hintText: 'e.g. Grade 10-A, Biology 101',
                        prefixIcon: Icon(Icons.school, color: Colors.teal),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.teal, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a class name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isCreatingInProgress ? null : _createClass,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: _isCreatingInProgress
                            ? SpinKitThreeBounce(
                          color: Colors.white,
                          size: 24,
                        )
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add),
                            SizedBox(width: 8),
                            Text(
                              'Create Class',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassListTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Classes')
          .where('schoolId', isEqualTo: _schoolId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: SpinKitPulse(
              color: Colors.teal,
              size: 50.0,
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                SizedBox(height: 16),
                Text(
                  'Error loading classes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(snapshot.error.toString()),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _fetchSchoolId,
                  icon: Icon(Icons.refresh),
                  label: Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                  ),
                ),
              ],
            ),
          );
        }

        List<DocumentSnapshot> classDocs = snapshot.data!.docs;

        if (classDocs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.school_outlined, size: 80, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  'No Classes Available',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Create your first class using the Create tab',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    _tabController.animateTo(1);
                  },
                  icon: Icon(Icons.add),
                  label: Text('Create Class'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.all(16),
          child: ListView.builder(
            itemCount: classDocs.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> data = classDocs[index].data() as Map<String, dynamic>;
              String className = data['className'] ?? 'Unnamed Class';

              return Card(
                elevation: 2,
                margin: EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StudentListScreen(
                          className: className,
                          schoolId: _schoolId!,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.teal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.school,
                              color: Colors.teal,
                              size: 30,
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                className,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              FutureBuilder<int>(
                                future: _getStudentCount(className),
                                builder: (context, snapshot) {
                                  return Text(
                                    snapshot.hasData
                                        ? '${snapshot.data} students'
                                        : 'Loading student count...',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<int> _getStudentCount(String className) async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('students')
        .where('schoolId', isEqualTo: _schoolId)
        .where('className', isEqualTo: className)
        .get();

    return snapshot.docs.length;
  }

  @override
  void dispose() {
    _classController.dispose();
    _tabController.dispose();
    super.dispose();
  }
}

class StudentListScreen extends StatefulWidget {
  final String className;
  final String schoolId;

  StudentListScreen({
    required this.className,
    required this.schoolId,
  });

  @override
  _StudentListScreenState createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  List<Map<String, dynamic>> _studentList = [];
  bool _isLoading = true;
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredStudentList = [];

  @override
  void initState() {
    super.initState();
    _fetchStudents();

    _searchController.addListener(() {
      _filterStudents();
    });
  }

  void _filterStudents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredStudentList = List.from(_studentList);
      } else {
        _filteredStudentList = _studentList.where((student) {
          final nameMatch = student['name'].toLowerCase().contains(query);
          final regNoMatch = student['regNo'].toLowerCase().contains(query);
          return nameMatch || regNoMatch;
        }).toList();
      }
    });
  }

  Future<void> _fetchStudents() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('schoolId', isEqualTo: widget.schoolId)
          .where('className', isEqualTo: widget.className)
          .get();

      List<Map<String, dynamic>> students = [];
      snapshot.docs.forEach((doc) {
        students.add({
          'id': doc.id,
          'name': doc['name'] ?? '',
          'regNo': doc['regno'] ?? '',
        });
      });

      setState(() {
        _studentList = students;
        _filteredStudentList = students;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching students: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        title: Text(
          widget.className,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _fetchStudents();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Student List',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_studentList.length} students',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name or registration number',
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1),
          Expanded(
            child: _isLoading
                ? Center(
              child: SpinKitPulse(
                color: Colors.teal,
                size: 50.0,
              ),
            )
                : _filteredStudentList.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_search,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    _searchController.text.isEmpty
                        ? 'No students in this class'
                        : 'No students match your search',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
                : ListView.separated(
              padding: EdgeInsets.all(16),
              itemCount: _filteredStudentList.length,
              separatorBuilder: (context, index) => SizedBox(height: 8),
              itemBuilder: (context, index) {
                final student = _filteredStudentList[index];
                final firstLetter = student['name'].isNotEmpty
                    ? student['name'][0].toUpperCase()
                    : '?';

                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal,
                      radius: 24,
                      child: Text(
                        firstLetter,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    title: Text(
                      student['name'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'Reg No: ${student['regNo']}',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.more_vert),
                      onPressed: () {
                        // Add student options menu here
                        _showStudentOptions(student);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Add functionality to add students
          _showAddStudentDialog();
        },
        icon: Icon(Icons.person_add),
        label: Text('Add Student'),
        backgroundColor: Colors.teal,
      ),
    );
  }

  void _showStudentOptions(Map<String, dynamic> student) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.teal,
                  child: Text(
                    student['name'].isNotEmpty ? student['name'][0].toUpperCase() : '?',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(student['name']),
                subtitle: Text('Reg No: ${student['regNo']}'),
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.edit, color: Colors.blue),
                title: Text('Edit Student'),
                onTap: () {
                  Navigator.pop(context);
                  // Add edit functionality
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Remove Student'),
                onTap: () {
                  Navigator.pop(context);
                  // Add delete functionality
                },
              ),
              ListTile(
                leading: Icon(Icons.book, color: Colors.amber),
                title: Text('View Performance'),
                onTap: () {
                  Navigator.pop(context);
                  // Add performance view functionality
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddStudentDialog() {
    // Implementation for adding a student
    // This would be implemented similar to the class creation dialog
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}