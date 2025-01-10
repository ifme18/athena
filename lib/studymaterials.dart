import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class StudyMaterialScreen extends StatefulWidget {
  @override
  _StudyMaterialScreenState createState() => _StudyMaterialScreenState();
}

class _StudyMaterialScreenState extends State<StudyMaterialScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  XFile? _file;
  bool _uploadingFile = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _uploadFile() async {
    setState(() {
      _uploadingFile = true;
    });

    print('Starting file upload process...');

    try {
      // Configure file type filter for PDFs
      final typeGroup = XTypeGroup(
        label: 'PDFs',
        extensions: ['pdf'],
      );

      // Pick file using file_selector
      final XFile? result = await openFile(
        acceptedTypeGroups: [typeGroup],
      );

      if (result != null) {
        final fileName = result.name;
        print('File selected: $fileName');

        // Read file bytes
        final fileBytes = await result.readAsBytes();
        final fileSize = (fileBytes.length / (1024 * 1024)).toStringAsFixed(2); // Size in MB

        // Upload to Firebase Storage
        final ref = FirebaseStorage.instance.ref('uploads/$fileName');
        print('Uploading file to Firebase Storage...');

        if (kIsWeb) {
          await ref.putData(fileBytes);
        } else {
          await ref.putFile(File(result.path));
        }

        final url = await ref.getDownloadURL();
        print('File uploaded successfully: $url');

        // Save metadata to Firestore
        await FirebaseFirestore.instance.collection('study_materials').add({
          'title': _titleController.text,
          'description': _descriptionController.text,
          'url': url,
          'timestamp': Timestamp.now(),
          'fileSize': fileSize,
          'fileType': 'pdf',
          'fileName': fileName,
        });

        print('File information added to Firestore');

        // Reset form
        setState(() {
          _uploadingFile = false;
          _titleController.clear();
          _descriptionController.clear();
          _file = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );

        print('Upload process completed successfully');
      } else {
        setState(() {
          _uploadingFile = false;
        });
      }
    } catch (e) {
      print('Error uploading file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading file: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _uploadingFile = false;
      });
    }
  }

  Future<void> _downloadFile(String url, String fileName) async {
    try {
      if (kIsWeb) {
        // For web, we'll use a different approach since we can't access file system directly
        // You might want to implement browser download here
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloads not supported on web. Please use the URL directly.'),
          ),
        );
        return;
      }

      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String filePath = '${appDocDir.path}/$fileName';
      final File file = File(filePath);

      final ref = FirebaseStorage.instance.refFromURL(url);
      await ref.writeToFile(file);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File downloaded successfully to: $filePath'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error downloading file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepOrange,
        title: Text('Study Materials'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Colors.deepOrange,
                ),
                onPressed: _uploadingFile ? null : _uploadFile,
                child: _uploadingFile
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    SizedBox(width: 8.0),
                    Text('Uploading...'),
                  ],
                )
                    : Text(_file != null ? 'Change File' : 'Select PDF File'),
              ),
              SizedBox(height: 40.0),
              Text(
                'Available Study Materials',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20.0),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('study_materials')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        children: [
                          Icon(Icons.no_sim, size: 50, color: Colors.grey),
                          Text('No study materials available.',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    );
                  }

                  return ListView(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    children: snapshot.data!.docs.map((doc) {
                      return Card(
                        elevation: 3,
                        margin: EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Icon(Icons.picture_as_pdf, color: Colors.deepOrange),
                          title: Text(
                            doc['title'],
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(doc['description']),
                              Text(
                                'Size: ${doc['fileSize']} MB',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.download, color: Colors.deepOrange),
                            onPressed: () {
                              _downloadFile(doc['url'], '${doc['fileName']}');
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      primarySwatch: Colors.deepOrange,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    ),
    home: StudyMaterialScreen(),
  ));
}