import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_filereader/flutter_filereader.dart';

import 'package:flutter/foundation.dart' show kIsWeb; // Import kIsWeb
import 'dart:io';
import 'dart:typed_data'; // Import Uint8List for file downloading on web
import 'dart:html' as html; // Import html for web file downloading

class MaterialListScreen extends StatefulWidget {
  @override
  _MaterialListScreenState createState() => _MaterialListScreenState();
}

class _MaterialListScreenState extends State<MaterialListScreen> {
  Future<void> _downloadFile(String? url, String fileName) async {
    if (url == null) return; // Ensure url is not null

    if (kIsWeb) {
      final Uint8List? data = await FirebaseStorage.instance.refFromURL(url).getData();
      if (data == null) return; // Handle if data is null
      final blob = html.Blob([data]);
      final downloadUrl = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement anchorElement = html.AnchorElement(href: downloadUrl);
      anchorElement.download = fileName;
      anchorElement.click();
      html.Url.revokeObjectUrl(downloadUrl);
    } else {
      final ref = FirebaseStorage.instance.refFromURL(url);
      final Directory systemTempDir = Directory.systemTemp;
      final File tempFile = File('${systemTempDir.path}/$fileName');

      if (!await tempFile.exists()) {
        await ref.writeToFile(tempFile);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File downloaded successfully'),
          ),
        );
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfViewerScreen(filePath: tempFile.path),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Material List'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                    return Text('No study materials available.');
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final url = doc['url'] as String?; // Cast to String?
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: GestureDetector(
                          onTap: () {
                            _downloadFile(url, '${doc['title']}.pdf');
                          },
                          child: Card(
                            elevation: 2,
                            child: ListTile(
                              leading: Icon(Icons.description, color: Colors.yellow),
                              title: Text(doc['title']),
                              subtitle: Text(doc['description']),
                              trailing: IconButton(
                                icon: Icon(Icons.file_download),
                                onPressed: () {
                                  _downloadFile(url, '${doc['title']}.pdf');
                                },
                              ),
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
      ),
    );
  }
}

class PdfViewerScreen extends StatelessWidget {
  final String filePath;

  const PdfViewerScreen({required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF Viewer'),
      ),
      body: kIsWeb ? _buildWebPdfViewer() : FileReaderView(filePath: filePath),
    );
  }

  Widget _buildWebPdfViewer() {
    return Center(
      child: Text(
        'PDF Viewer is not supported on web. Please download the file to view.',
        textAlign: TextAlign.center,
      ),
    );
  }
}