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
      title: 'Teacher Settings',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TeachersSettingsScreen(),
    );
  }
}

class TeachersSettingsScreen extends StatefulWidget {
  @override
  _TeachersSettingsScreenState createState() => _TeachersSettingsScreenState();
}

class _TeachersSettingsScreenState extends State<TeachersSettingsScreen> {
  final TextEditingController _passwordController = TextEditingController();
  File? _image;
  bool _uploadingImage = false;
  String? _profilePictureUrl;
  TextEditingController _classAssignedController = TextEditingController();
  TextEditingController _homeLocationController = TextEditingController();
  bool _isGovernmentTeacher = false;
  DateTime? _reportDay;
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _savePersonalInformation,
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('personalProfiles')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var teacherData = snapshot.data!;
          if (teacherData.exists) {
            _classAssignedController.text = teacherData['classAssigned'] ?? '';
            _homeLocationController.text = teacherData['homeLocation'] ?? '';
            _isGovernmentTeacher = teacherData['isGovernmentTeacher'] ?? false;
            _reportDay = (teacherData['reportDay'] != null)
                ? (teacherData['reportDay'] as Timestamp).toDate()
                : null;
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Change Password',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
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
                  ),
                  SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Profile Picture',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
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
                  ),
                  SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Personal Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _classAssignedController,
                            decoration: InputDecoration(
                              labelText: 'Class Assigned',
                              prefixIcon: Icon(Icons.group),
                            ),
                          ),
                          TextFormField(
                            controller: _homeLocationController,
                            decoration: InputDecoration(
                              labelText: 'Home Location',
                              prefixIcon: Icon(Icons.home),
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Text('Is Government Teacher: '),
                              Checkbox(
                                value: _isGovernmentTeacher,
                                onChanged: (value) {
                                  setState(() {
                                    _isGovernmentTeacher = value!;
                                  });
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Text('Report Day: '),
                              TextButton(
                                onPressed: () => _selectReportDay(context),
                                child: Text(
                                  _reportDay != null
                                      ? _reportDay!.toString().split(' ')[0]
                                      : 'Select Date',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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

  Future<void> _selectReportDay(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
    );

    if (pickedDate != null) {
      setState(() {
        _reportDay = pickedDate;
      });
    }
  }

  Future<void> _savePersonalInformation() async {
    if (_formKey.currentState!.validate()) {
      final classAssigned = _classAssignedController.text;
      final homeLocation = _homeLocationController.text;

      await _savePersonalInfo(
          classAssigned, homeLocation, _isGovernmentTeacher, _reportDay);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Personal information saved successfully.'),
        ),
      );
    }
  }

  Future<void> _uploadProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _uploadingImage = true;
      });

      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('${FirebaseAuth.instance.currentUser!.uid}.jpg');

      await ref.putFile(_image!);

      final url = await ref.getDownloadURL();

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
        SnackBar(
          content: Text('Password reset email sent. Please check your email.'),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send password reset email.'),
        ),
      );
    }
  }

  Future<void> _savePersonalInfo(
      String classAssigned,
      String homeLocation,
      bool isGovernmentTeacher,
      DateTime? reportDay,
      ) async {
    try {
      await FirebaseFirestore.instance
          .collection('personalProfiles')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .set({
        'classAssigned': classAssigned,
        'homeLocation': homeLocation,
        'isGovernmentTeacher': isGovernmentTeacher,
        'reportDay': reportDay,
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving personal information: $error'),
          backgroundColor: Colors.lightGreenAccent,
        ),
      );
    }
  }
}