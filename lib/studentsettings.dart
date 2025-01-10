import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Settings',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: StudentSettingsScreen(),
    );
  }
}

class StudentSettingsScreen extends StatefulWidget {
  @override
  _StudentSettingsScreenState createState() => _StudentSettingsScreenState();
}

class _StudentSettingsScreenState extends State<StudentSettingsScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _classTeacherController = TextEditingController();
  final TextEditingController _hobbiesController = TextEditingController();
  final TextEditingController _clubsController = TextEditingController();
  final TextEditingController _talentsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  File? _image;
  bool _uploadingImage = false;
  String? _profilePictureUrl;
  late Stream<DocumentSnapshot> _userDataStream;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    _userDataStream = FirebaseFirestore.instance
        .collection('personal_information')
        .doc(uid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Student Settings'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _savePersonalInformation,
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _userDataStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            _updateControllers(data);
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPasswordSection(),
                  SizedBox(height: 16),
                  _buildProfilePictureSection(),
                  SizedBox(height: 16),
                  _buildPersonalInformationSection(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPasswordSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Change Password',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'New Password',
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _changePasswordDialog(context),
              child: Text('Reset Password'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePictureSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile Picture',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            ListTile(
              leading: _buildProfilePicture(),
              trailing: IconButton(
                icon: Icon(Icons.upload),
                onPressed: _uploadProfilePicture,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInformationSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: _dobController,
              decoration: InputDecoration(
                labelText: 'Date of Birth',
                prefixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: () => _selectDate(context),
            ),
            TextFormField(
              controller: _classTeacherController,
              decoration: InputDecoration(
                labelText: 'Class Teacher',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            TextFormField(
              controller: _hobbiesController,
              decoration: InputDecoration(
                labelText: 'Hobbies',
                prefixIcon: Icon(Icons.sports_basketball),
              ),
            ),
            TextFormField(
              controller: _clubsController,
              decoration: InputDecoration(
                labelText: 'Clubs Involved',
                prefixIcon: Icon(Icons.group),
              ),
            ),
            TextFormField(
              controller: _talentsController,
              decoration: InputDecoration(
                labelText: 'Talents',
                prefixIcon: Icon(Icons.stars),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePicture() {
    if (_uploadingImage) {
      return CircularProgressIndicator();
    } else if (_profilePictureUrl != null) {
      return CircleAvatar(
        backgroundImage: NetworkImage(_profilePictureUrl!),
        radius: 30,
      );
    } else {
      return Icon(Icons.account_circle, size: 60);
    }
  }

  void _updateControllers(Map<String, dynamic> data) {
    _dobController.text = data['dateOfBirth'] ?? '';
    _classTeacherController.text = data['classTeacher'] ?? '';
    _hobbiesController.text = data['hobbies'] ?? '';
    _clubsController.text = data['clubsInvolved'] ?? '';
    _talentsController.text = data['talents'] ?? '';
    _profilePictureUrl = data['profilePictureUrl'];
  }

  Future<void> _changePasswordDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Change Password'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to reset your password?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Reset'),
              onPressed: () async {
                await _changePassword(context);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        _dobController.text = pickedDate.toIso8601String().split('T')[0];
      });
    }
  }

  Future<void> _savePersonalInformation() async {
    if (_formKey.currentState!.validate()) {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance.collection('personal_information').doc(uid).set({
        'dateOfBirth': _dobController.text,
        'classTeacher': _classTeacherController.text,
        'hobbies': _hobbiesController.text,
        'clubsInvolved': _clubsController.text,
        'talents': _talentsController.text,
        'profilePictureUrl': _profilePictureUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Personal information saved successfully.')),
      );
    }
  }

  Future<void> _uploadProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _uploadingImage = true;
      });

      final uid = FirebaseAuth.instance.currentUser!.uid;
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('$uid.jpg');

      await ref.putFile(_image!);

      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('personal_information').doc(uid).update({
        'profilePictureUrl': url,
      });

      setState(() {
        _profilePictureUrl = url;
        _uploadingImage = false;
      });
    }
  }

  Future<void> _changePassword(BuildContext context) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: FirebaseAuth.instance.currentUser!.email!,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset email sent. Please check your email.')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send password reset email.')),
      );
    }
  }
}