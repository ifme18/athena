import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as path;

class TeachersRegistrationWidget extends StatefulWidget {
  @override
  _TeachersRegistrationWidgetState createState() => _TeachersRegistrationWidgetState();
}

class _TeachersRegistrationWidgetState extends State<TeachersRegistrationWidget> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController tscNumberController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  XFile? _imageFile;
  Uint8List? _webImage;
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

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    tscNumberController.dispose();
    phoneController.dispose();
    searchController.dispose();
    super.dispose();
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
        title: const Text('Teachers Registration'),
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () => _showRegistrationDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: const Text('Register Teacher'),
              ),
              const SizedBox(height: 16),
              const Text(
                'List of Teachers:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildTeachersList(),
              const SizedBox(height: 16),
              Text(
                registrationMessage,
                style: TextStyle(color: registrationMessageColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showRegistrationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Teacher Registration'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email (optional)'),
                ),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number (optional)'),
                ),
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
                TextFormField(
                  controller: tscNumberController,
                  decoration: const InputDecoration(labelText: 'TSC Number'),
                ),
                const SizedBox(height: 16),
                _buildProfileImageWidget(),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
            ElevatedButton(
              onPressed: () {
                _registerTeacher();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Register'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTeachersList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search teachers...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25.0),
              ),
              filled: true,
              fillColor: Colors.grey[200],
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('teachers')
                .where('schoolId', isEqualTo: _schoolId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text('No teachers found.');
              }

              List<DataRow> rows = [];
              for (var doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>?;

                if (data != null && _matchesSearchQuery(data)) {
                  rows.add(DataRow(
                    cells: [
                      DataCell(Text(data['name'] ?? '')),
                      DataCell(Text(data['email'] ?? '')),
                      DataCell(Text(data['tscNumber'] ?? '')),
                      DataCell(Text(data['phone'] ?? '')),
                    ],
                  ));
                }
              }

              return DataTable(
                headingRowColor: MaterialStateProperty.all(Colors.indigo),
                dataRowColor: MaterialStateProperty.all(Colors.blue.shade50),
                columns: const [
                  DataColumn(label: Text('Name', style: TextStyle(color: Colors.white))),
                  DataColumn(label: Text('Email', style: TextStyle(color: Colors.white))),
                  DataColumn(label: Text('TSC Number', style: TextStyle(color: Colors.white))),
                  DataColumn(label: Text('Phone', style: TextStyle(color: Colors.white))),
                ],
                rows: rows,
              );
            },
          ),
        ),
      ],
    );
  }

  bool _matchesSearchQuery(Map<String, dynamic> data) {
    if (_searchQuery.isEmpty) return true;

    final String name = (data['name'] ?? '').toLowerCase();
    final String email = (data['email'] ?? '').toLowerCase();
    final String tscNumber = (data['tscNumber'] ?? '').toLowerCase();
    final String phone = (data['phone'] ?? '').toLowerCase();

    return name.contains(_searchQuery) ||
        email.contains(_searchQuery) ||
        tscNumber.contains(_searchQuery) ||
        phone.contains(_searchQuery);
  }

  Widget _buildProfileImageWidget() {
    return Column(
      children: [
        const Text(
          'Profile Picture',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _getImage,
          child: CircleAvatar(
            radius: 50,
            backgroundImage: _getProfileImage(),
            child: _imageFile == null
                ? const Icon(Icons.add_a_photo, size: 50, color: Colors.white)
                : null,
            backgroundColor: Colors.grey[300],
          ),
        ),
      ],
    );
  }

  ImageProvider? _getProfileImage() {
    if (_imageFile == null) return null;
    return _webImage != null ? MemoryImage(_webImage!) : null;
  }

  Future<void> _getImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
        });

        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImage = bytes;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to pick image')),
      );
    }
  }

  Future<void> _registerTeacher() async {
    try {
      if (nameController.text.isEmpty || passwordController.text.isEmpty || tscNumberController.text.isEmpty) {
        throw 'Please fill in all required fields';
      }

      String currentUserUid = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot adminSnapshot = await FirebaseFirestore.instance
          .collection('admins')
          .doc(currentUserUid)
          .get();

      String schoolId = adminSnapshot['schoolId'];

      String? imageUrl;
      if (_imageFile != null && _webImage != null) {
        Reference storageReference = FirebaseStorage.instance
            .ref()
            .child('teacher_profile_images')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

        final uploadTask = storageReference.putData(_webImage!);
        final taskSnapshot = await uploadTask;
        imageUrl = await taskSnapshot.ref.getDownloadURL();
      }

      await _callCloudFunction(imageUrl, schoolId);
    } catch (error) {
      print('Error registering teacher: $error');
      setState(() {
        registrationMessage = error.toString();
        registrationMessageColor = Colors.red;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _callCloudFunction(String? imageUrl, String schoolId) async {
    try {
      HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('registerTeacher');
      final result = await callable.call({
        'name': nameController.text.trim(),
        'email': emailController.text.trim().isNotEmpty ? emailController.text.trim() : null,
        'phoneNumber': phoneController.text.trim().isNotEmpty ? phoneController.text.trim() : null,
        'password': passwordController.text,
        'tscNumber': tscNumberController.text.trim(),
        'schoolId': schoolId,
        'imageUrl': imageUrl,
      });

      // Clear form
      nameController.clear();
      emailController.clear();
      phoneController.clear();
      passwordController.clear();
      tscNumberController.clear();
      setState(() {
        _imageFile = null;
        _webImage = null;
      });

      Map<String, dynamic> data = result.data;
      bool success = data['success'];
      String message = data['message'];

      setState(() {
        registrationMessage = message;
        registrationMessageColor = success ? Colors.green : Colors.red;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

    } catch (e) {
      print('Error calling cloud function: $e');
      setState(() {
        registrationMessage = 'An error occurred while registering the teacher.';
        registrationMessageColor = Colors.red;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to register teacher'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}