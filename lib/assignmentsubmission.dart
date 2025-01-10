import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_selector/file_selector.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AssignmentSubmissionScreen extends StatefulWidget {
  @override
  _AssignmentSubmissionScreenState createState() =>
      _AssignmentSubmissionScreenState();
}

class _AssignmentSubmissionScreenState extends State<AssignmentSubmissionScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  String? _classId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getClassId();
  }

  Future<void> _getClassId() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final DocumentSnapshot studentDoc =
        await _firestore.collection('students').doc(user.uid).get();
        if (studentDoc.exists) {
          setState(() {
            _classId = studentDoc.get('classId');
            _isLoading = false;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Student data not found. Please contact admin.')),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (error) {
      print('Error fetching class ID: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching class ID: $error')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadAssignment(String assignmentId, DateTime deadline) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      if (DateTime.now().isAfter(deadline)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deadline has passed. Cannot submit.')),
        );
        return;
      }

      // Configure allowed file types (optional)
      final typeGroup = XTypeGroup(
        label: 'Documents',
        extensions: ['pdf', 'doc', 'docx'],
      );

      XFile? file;
      if (kIsWeb) {
        // For web platform
        file = await openFile(
          acceptedTypeGroups: [typeGroup],
        );
      } else {
        // For mobile platforms
        file = await openFile(
          acceptedTypeGroups: [typeGroup],
        );
      }

      if (file == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No file selected')),
        );
        return;
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      Reference storageRef;
      UploadTask uploadTask;
      String fileName = file.name;

      if (kIsWeb) {
        Uint8List fileBytes = await file.readAsBytes();
        storageRef = _storage
            .ref()
            .child('assignments/$assignmentId/${user.uid}/$fileName');
        uploadTask = storageRef.putData(fileBytes);
      } else {
        storageRef = _storage
            .ref()
            .child('assignments/$assignmentId/${user.uid}/$fileName');
        uploadTask = storageRef.putFile(File(file.path));
      }

      // Listen to upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
      });

      await uploadTask.whenComplete(() => print('Upload completed'));
      String downloadUrl = await storageRef.getDownloadURL();

      await _firestore
          .collection('assignments')
          .doc(assignmentId)
          .collection('submissions')
          .doc(user.uid)
          .set({
        'userId': user.uid,
        'submittedAt': FieldValue.serverTimestamp(),
        'downloadUrl': downloadUrl,
        'fileName': fileName,
      });

      // Hide loading indicator
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Assignment uploaded successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      // Hide loading indicator if there's an error
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      print('Error uploading assignment: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading assignment: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Assignment Submission'),
        backgroundColor: Colors.teal[700],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _classId == null
          ? Center(child: Text('No class ID found'))
          : SingleChildScrollView(
        child: Column(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('assignments')
                  .where('classId', isEqualTo: _classId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                      child: Text('No assignments available.'));
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot assignment =
                    snapshot.data!.docs[index];
                    Map<String, dynamic>? data =
                    assignment.data() as Map<String, dynamic>?;
                    DateTime deadline =
                    (data?['deadline'] as Timestamp).toDate();
                    return Card(
                      margin: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16),
                        title: Text(
                          data?['assignmentDescription'] ??
                              'No description',
                          style:
                          TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 8),
                            Text(
                              'Deadline: ${DateFormat.yMMMd().add_jm().format(deadline)}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            SizedBox(height: 8),
                            FutureBuilder<DocumentSnapshot>(
                              future: _firestore
                                  .collection('assignments')
                                  .doc(assignment.id)
                                  .collection('submissions')
                                  .doc(FirebaseAuth
                                  .instance.currentUser?.uid)
                                  .get(),
                              builder: (context, submissionSnapshot) {
                                if (submissionSnapshot
                                    .connectionState ==
                                    ConnectionState.waiting) {
                                  return Text(
                                      'Checking submission status...');
                                }
                                if (submissionSnapshot.hasData &&
                                    submissionSnapshot.data!.exists) {
                                  final submissionData =
                                  submissionSnapshot.data!
                                      .data() as Map<String,
                                      dynamic>?;
                                  final downloadUrl =
                                  submissionData?['downloadUrl']
                                  as String?;
                                  final fileName =
                                      submissionData?['fileName'] ??
                                          'Submitted file';
                                  return Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.check_circle,
                                              color: Colors.green,
                                              size: 16),
                                          SizedBox(width: 4),
                                          Text('Submitted',
                                              style: TextStyle(
                                                  color:
                                                  Colors.green)),
                                        ],
                                      ),
                                      if (downloadUrl != null)
                                        TextButton.icon(
                                          onPressed: () =>
                                              _launchURL(downloadUrl),
                                          icon: Icon(
                                              Icons.remove_red_eye),
                                          label: Text(fileName),
                                          style:
                                          TextButton.styleFrom(
                                            foregroundColor: Colors.teal,
                                          ),
                                        ),
                                    ],
                                  );
                                }
                                return Row(
                                  children: [
                                    Icon(Icons.warning,
                                        color: Colors.red,
                                        size: 16),
                                    SizedBox(width: 4),
                                    Text('Not submitted',
                                        style: TextStyle(
                                            color: Colors.red)),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                        trailing: ElevatedButton.icon(
                          icon: Icon(Icons.upload_file),
                          label: Text('Upload'),
                          onPressed: DateTime.now().isBefore(deadline)
                              ? () => _uploadAssignment(
                              assignment.id, deadline)
                              : null,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white, backgroundColor: Colors.teal[700],
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    try {
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open the file.')),
      );
    }
  }
}