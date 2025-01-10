import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentRegistrationWidget extends StatefulWidget {
  @override
  _StudentRegistrationWidgetState createState() => _StudentRegistrationWidgetState();
}

class _StudentRegistrationWidgetState extends State<StudentRegistrationWidget> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController regNoController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  String selectedClassId = '';
  String selectedClassName = '';
  String registrationMessage = '';
  Color registrationMessageColor = Colors.green;
  String _schoolId = '';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _getSchoolId();
    searchController.addListener(() {
      setState(() {
        _searchQuery = searchController.text.toLowerCase();
      });
    });
  }

  Future<void> _getSchoolId() async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('admins').doc(userId).get();
      setState(() {
        _schoolId = snapshot['schoolId'] ?? '';
      });
    } catch (e) {
      print('Error fetching school ID: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Registration'),
        backgroundColor: Colors.indigo,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo.shade50, Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () => _showRegistrationDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Register New Student',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search students...',
                      prefixIcon: Icon(Icons.search, color: Colors.indigo),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.indigo.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.indigo.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.indigo, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: _buildModernStudentList(),
                  ),
                ),
              ),
              if (registrationMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Card(
                    color: registrationMessageColor.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        registrationMessage,
                        style: TextStyle(
                          color: registrationMessageColor,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showRegistrationDialog(BuildContext context) async {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.school, color: Colors.indigo),
              SizedBox(width: 10),
              Text('Student Registration'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(
                  controller: nameController,
                  label: 'Name',
                  icon: Icons.person,
                ),
                SizedBox(height: 16),
                _buildTextField(
                  controller: emailController,
                  label: 'Email (optional)',
                  icon: Icons.email,
                ),
                SizedBox(height: 16),
                _buildTextField(
                  controller: phoneController,
                  label: 'Phone Number (optional)',
                  icon: Icons.phone,
                ),
                SizedBox(height: 16),
                _buildTextField(
                  controller: regNoController,
                  label: 'Registration Number',
                  icon: Icons.badge,
                ),
                SizedBox(height: 16),
                _buildTextField(
                  controller: passwordController,
                  label: 'Password',
                  icon: Icons.lock,
                  isPassword: true,
                ),
                SizedBox(height: 16),
                _buildClassDropdown(),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                _registerStudent(context);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Register'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.indigo),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.indigo.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.indigo.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.indigo, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildClassDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('Classes').where('schoolId', isEqualTo: _schoolId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        List<Map<String, dynamic>> classes = [];
        snapshot.data!.docs.forEach((doc) {
          classes.add({
            'classId': doc.id,
            'className': doc['className'],
          });
        });

        if (_schoolId.isEmpty) {
          return const SizedBox();
        }

        if (selectedClassId.isEmpty || !classes.any((element) => element['classId'] == selectedClassId)) {
          selectedClassId = classes.isNotEmpty ? classes.first['classId'] : '';
          selectedClassName = classes.isNotEmpty ? classes.first['className'] : '';
        }

        return DropdownButtonFormField<String>(
          value: selectedClassId,
          decoration: InputDecoration(
            labelText: 'Select Class',
            prefixIcon: Icon(Icons.class_, color: Colors.indigo),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.indigo.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.indigo.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.indigo, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          onChanged: (value) {
            setState(() {
              selectedClassId = value!;
              selectedClassName = classes.firstWhere((element) => element['classId'] == value)['className'];
            });
          },
          items: classes.map((classInfo) {
            return DropdownMenuItem<String>(
              value: classInfo['classId'],
              child: Text(classInfo['className']),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildModernStudentList() {
    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
        .collection('students')
        .where('schoolId', isEqualTo: _schoolId)
        .snapshots(),
    builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
    return Center(
    child: CircularProgressIndicator(
    valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
    ),
    );
    }

    if (snapshot.hasError) {
    return Center(
    child: Text(
    'Error: ${snapshot.error}',
    style: TextStyle(color: Colors.red),
    ),
    );
    }

    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
    return Center(
    child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
    Icon(Icons.school_outlined, size: 64, color: Colors.grey),
    SizedBox(height: 16),
    Text(
    'No students found',
    style: TextStyle(
    fontSize: 18,
    color: Colors.grey,
    fontWeight: FontWeight.bold,
    ),
    ),
    ],
    ),
    );
    }

    List<Widget> studentCards = [];
    snapshot.data!.docs.forEach((doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data != null && _matchesSearchQuery(data)) {
    studentCards.add(
    Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: () {
    // Handle student card tap
    },
    child: Padding(
    padding: const EdgeInsets.all(16),
    child: Row(
    children: [
    CircleAvatar(
    backgroundColor: Colors.indigo.shade100,
    radius: 25,
    child: Text(
    data['name']?.substring(0, 1).toUpperCase() ?? '?',
    style: TextStyle(
    color: Colors.indigo,
    fontWeight: FontWeight.bold,
    fontSize: 20,
    ),
    ),
    ),
    SizedBox(width: 16),
    Expanded(
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text(
    data['name'] ?? '',
    style: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
    ),
    ),
    SizedBox(height: 4),
    Text(
    data['email'] ?? 'No email provided',
    style: TextStyle(
    color: Colors.grey[600],
    fontSize: 14,
    ),
    ),
    ],
    ),
    ),
    Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
    Container(
    padding: EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 6,
    ),
    decoration: BoxDecoration(
    color: Colors.indigo.shade50,
    borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
    data['className'] ?? '',
    style: TextStyle(
    color: Colors.indigo,
    fontWeight: FontWeight.bold,
    ),
    ),
    ),
    SizedBox(height: 4),
    Text(
    'Reg: ${data['regno'] ?? ''}',
    style: TextStyle(
    color: Colors.grey[600],
    fontSize: 12,
    ),
    ),
    ],
    ),
    ],
    ),
    ),
    ),
    ),
    ),
    );
    }
    });

    return ListView(
    padding: EdgeInsets.symmetric(vertical: 8),
    children: studentCards,
    );
    },
    );
  }

  void _registerStudent(BuildContext context) async {
    String message = '';
    bool success = false;

    try {
      if (nameController.text.isEmpty || regNoController.text.isEmpty || passwordController.text.isEmpty) {
        setState(() {
          registrationMessage = 'Please fill in all required fields';
          registrationMessageColor = Colors.red;
        });
        return;
      }

      HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('registerStudent');
      final result = await callable.call({
        'name': nameController.text.trim(),
        'email': emailController.text.trim().isNotEmpty ? emailController.text.trim() : null,
        'phoneNumber': phoneController.text.trim().isNotEmpty ? phoneController.text.trim() : null,
        'regno': regNoController.text.trim(),
        'password': passwordController.text,
        'classId': selectedClassId,
        'className': selectedClassName,
        'schoolId': _schoolId,
      });

      // Clear form fields after successful registration
      nameController.clear();
      emailController.clear();
      phoneController.clear();
      regNoController.clear();
      passwordController.clear();
      selectedClassId = '';
      selectedClassName = '';

      Map<String, dynamic> data = result.data;
      success = data['success'];
      message = data['message'];

      if (success) {
        print('Student registered successfully: $message');
      } else {
        print('Error registering student: $message');
      }
    } catch (error) {
      print('Error registering student: $error');
      message = 'An error occurred during registration.';
      success = false;
    }

    setState(() {
      registrationMessage = message.isNotEmpty ? message : 'Registration successful';
      registrationMessageColor = success ? Colors.green : Colors.red;
    });
  }

  bool _matchesSearchQuery(Map<String, dynamic> data) {
    if (_searchQuery.isEmpty) return true;

    final String name = data['name']?.toLowerCase() ?? '';
    final String email = data['email']?.toLowerCase() ?? '';
    final String regno = data['regno']?.toLowerCase() ?? '';
    final String className = data['className']?.toLowerCase() ?? '';

    return name.contains(_searchQuery) ||
        email.contains(_searchQuery) ||
        regno.contains(_searchQuery) ||
        className.contains(_searchQuery);
  }

  @override
  void dispose() {
    nameController.dispose();
    regNoController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    searchController.dispose();
    super.dispose();
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
    theme: ThemeData(
      primarySwatch: Colors.indigo,
      scaffoldBackgroundColor: Colors.white,
      fontFamily: 'Roboto',
      cardTheme: CardTheme(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    ),
    home: StudentRegistrationWidget(),
  ));
}