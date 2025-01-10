import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_storage.FirebaseStorage _storage =
      firebase_storage.FirebaseStorage.instance;
  final TextEditingController _passwordController = TextEditingController();
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    fetchUserProfileImage();
  }

  Future<void> fetchUserProfileImage() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      final userSnapshot =
      await _firestore.collection('admins').doc(currentUser.uid).get();
      final userData = userSnapshot.data();
      setState(() {
        _profileImageUrl = userData?['profileImageUrl'];
      });
    }
  }

  Future<void> changePassword(String newPassword) async {
    final currentUser = _auth.currentUser;
    try {
      await currentUser?.updatePassword(newPassword);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password updated successfully')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update password: $error')),
      );
    }
  }

  Future<void> uploadProfilePhoto(File imageFile) async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        final reference =
        _storage.ref().child('profile_images/${currentUser.uid}');
        await reference.putFile(imageFile);
        final imageUrl = await reference.getDownloadURL();

        await _firestore.collection('admins').doc(currentUser.uid).update({
          'profileImageUrl': imageUrl,
        });

        setState(() {
          _profileImageUrl = imageUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile photo uploaded successfully')),
        );
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload profile photo: $error')),
        );
      }
    }
  }

  Future<void> pickImageAndUpload() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      final selectedImageFile = File(pickedImage.path);
      uploadProfilePhoto(selectedImageFile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Settings', style: Theme.of(context).textTheme.titleLarge),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_profileImageUrl != null)
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(_profileImageUrl!),
                ),
              ),
            SizedBox(height: 20),
            Text(
              'Change Password',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                if (_passwordController.text.isNotEmpty) {
                  changePassword(_passwordController.text);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a new password')),
                  );
                }
              },
              child: Text('Change Password'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Profile Photo',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: pickImageAndUpload,
              child: Text('Upload Profile Photo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}