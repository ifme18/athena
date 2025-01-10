import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart';

class Video {
  final String title;
  final String description;
  final bool monetized;
  List<String> tags;
  String category;
  Uint8List? thumbnail;

  Video({
    required this.title,
    required this.description,
    required this.monetized,
    required this.tags,
    required this.category,
    this.thumbnail,
  });
}

class UploadVideoScreen extends StatefulWidget {
  @override
  _UploadVideoScreenState createState() => _UploadVideoScreenState();
}

class _UploadVideoScreenState extends State<UploadVideoScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _monetized = false;
  XFile? _videoFile;
  Uint8List? _thumbnail;
  List<String> _tags = [];
  String _category = '';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  late VideoPlayerController _videoPlayerController;
  late String _downloadUrl = '';

  @override
  void initState() {
    super.initState();
    _videoPlayerController = VideoPlayerController.network(_downloadUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Video'),
        backgroundColor: Colors.deepOrangeAccent,
      ),
      body: Row(
        children: [
          // Left sidebar - Control Panel
          Expanded(
            child: Container(
              color: Colors.grey[200],
              child: ListView(
                children: [
                  YourBodyWidget(
                    videoFile: _videoFile,
                    videoPlayerController: _videoPlayerController,
                  ),
                  _buildControlPanelButton(
                    icon: Icons.content_cut,
                    text: 'Trim Video',
                    onPressed: _videoFile != null ? trimVideo : null,
                  ),
                  _buildControlPanelButton(
                    icon: Icons.image,
                    text: 'Add Thumbnail',
                    onPressed: _videoFile != null ? pickThumbnail : null,
                  ),
                  ElevatedButton(
                    onPressed: pickVideo,
                    child: Text('Pick Video'),
                  ),
                ],
              ),
            ),
          ),
          // Center area - Staging Area (video preview)
          Expanded(
            flex: 2,
            child: _videoFile != null
                ? AspectRatio(
              aspectRatio: _videoPlayerController.value.aspectRatio,
              child: VideoPlayer(_videoPlayerController),
            )
                : Center(child: Text('No video selected')),
          ),
          // Right sidebar - Metadata Area
          Expanded(
            child: Container(
              color: Colors.grey[200],
              padding: EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(labelText: 'Title'),
                  ),
                  SizedBox(height: 10.0),
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(labelText: 'Description'),
                    maxLines: 4,
                  ),
                  SizedBox(height: 10.0),
                  CheckboxListTile(
                    title: Text('Monetize Video'),
                    value: _monetized,
                    onChanged: (newValue) {
                      setState(() {
                        _monetized = newValue!;
                      });
                    },
                  ),
                  SizedBox(height: 10.0),
                  Text('Tags: ${_tags.join(', ')}'),
                  Text('Category: $_category'),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ElevatedButton(
              onPressed: _videoFile != null ? uploadVideo : null,
              child: Text('Submit'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanelButton({
    required IconData icon,
    required String text,
    required VoidCallback? onPressed,
  }) {
    return Padding(
      padding: EdgeInsets.all(15.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(
            onPressed != null ? Colors.deepOrangeAccent : Colors.grey,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40.0),
            SizedBox(height: 10.0),
            Text(
              text,
              style: TextStyle(fontSize: 16.0),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 30),
      );

      if (video != null) {
        setState(() {
          _videoFile = video;
        });
        _initializeVideoPlayer();
      }
    } catch (e) {
      print('Error picking video: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking video: $e')),
      );
    }
  }

  void _initializeVideoPlayer() {
    setState(() {
      _videoPlayerController = kIsWeb
          ? VideoPlayerController.networkUrl(Uri.parse(_videoFile!.path))
          : VideoPlayerController.file(File(_videoFile!.path));
      _videoPlayerController.initialize().then((_) {
        setState(() {});
        _videoPlayerController.play();
      }).catchError((error) {
        print('Error initializing video player: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing video: $error')),
        );
      });
    });
  }

  Future<void> pickThumbnail() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _thumbnail = bytes;
        });
      }
    } catch (e) {
      print('Error picking thumbnail: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking thumbnail: $e')),
      );
    }
  }

  // Placeholder method for trimming video that doesn't actually trim
  Future<void> trimVideo() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Video trimming functionality not available')),
    );
  }

  Future<void> uploadVideo() async {
    if (_videoFile != null) {
      String filename = DateTime.now().millisecondsSinceEpoch.toString() + '.mp4';
      User? user = _auth.currentUser;
      if (user != null) {
        TaskSnapshot snapshot;
        try {
          if (kIsWeb) {
            snapshot = await _storage
                .ref('videos/${user.uid}/$filename')
                .putData(await _videoFile!.readAsBytes());
          } else {
            snapshot = await _storage
                .ref('videos/${user.uid}/$filename')
                .putFile(File(_videoFile!.path));
          }
          _downloadUrl = await snapshot.ref.getDownloadURL();

          // Creating video object with metadata
          Video video = Video(
            title: _titleController.text,
            description: _descriptionController.text,
            monetized: _monetized,
            tags: _tags,
            category: _category,
            thumbnail: _thumbnail,
          );

          // Uploading video metadata to Firestore
          await _firestore.collection('videos').add({
            'title': video.title,
            'description': video.description,
            'monetized': video.monetized,
            'creator': user.uid,
            'video_url': _downloadUrl,
            'tags': video.tags,
            'category': video.category,
            'thumbnail': video.thumbnail,
            'uploadedAt': FieldValue.serverTimestamp(),
          });

          // Clear form after successful upload
          _titleController.clear();
          _descriptionController.clear();
          setState(() {
            _monetized = false;
            _videoFile = null;
            _videoPlayerController.dispose();
            _videoPlayerController = VideoPlayerController.network('');
            _tags = [];
            _category = '';
            _thumbnail = null;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Video uploaded successfully!')),
          );
        } catch (e) {
          print('Error uploading video: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading video: $e')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

class YourBodyWidget extends StatefulWidget {
  final XFile? videoFile;
  final VideoPlayerController? videoPlayerController;

  YourBodyWidget({
    Key? key,
    required this.videoFile,
    required this.videoPlayerController,
  }) : super(key: key);

  @override
  _YourBodyWidgetState createState() => _YourBodyWidgetState();
}

class _YourBodyWidgetState extends State<YourBodyWidget> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    if (widget.videoPlayerController != null) {
      _controller = widget.videoPlayerController!;
      _controller.addListener(() {
        if (_controller.value.isPlaying != _isPlaying) {
          setState(() {
            _isPlaying = _controller.value.isPlaying;
          });
        }
      });
    }
  }

  void _togglePlayPause() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
  }

  @override
  void dispose() {
    if (widget.videoPlayerController != null) {
      widget.videoPlayerController!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.videoFile != null && widget.videoPlayerController != null
        ? Container(
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: widget.videoPlayerController!.value.aspectRatio,
            child: VideoPlayer(widget.videoPlayerController!),
          ),
          if (!_isPlaying)
            IconButton(
              icon: Icon(Icons.play_arrow, color: Colors.white, size: 50.0),
              onPressed: _togglePlayPause,
            ),
          if (_isPlaying)
            IconButton(
              icon: Icon(Icons.pause, color: Colors.white, size: 50.0),
              onPressed: _togglePlayPause,
            ),
        ],
      ),
    )
        : Center(child: Text('No video selected'));
  }
}