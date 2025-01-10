
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'statistics.dart';
import 'videouploadscreen.dart';

class Video {
  final String id;
  final String title;
  final String description;
  final String videoUrl;
  final bool monetized;

  Video({
    required this.id,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.monetized,
  });
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  List<Video> _filteredVideos = []; // For storing search results
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _fetchAllVideos();
  }

  void _fetchAllVideos() async {
    QuerySnapshot querySnapshot = await _firestore.collection('videos').get();
    setState(() {
      _filteredVideos = querySnapshot.docs.map((doc) {
        return Video(
          id: doc.id,
          title: doc['title'],
          description: doc['description'],
          videoUrl: doc['video_url'],
          monetized: doc['monetized'],
        );
      }).toList();
    });
  }

  void _searchVideos(String query) async {
    if (query.isEmpty) {
      _fetchAllVideos();
      return;
    }

    setState(() {
      _isSearching = true;
    });

    QuerySnapshot querySnapshot = await _firestore
        .collection('videos')
        .where('title', isGreaterThanOrEqualTo: query)
        .where('title', isLessThanOrEqualTo: query + '\uf8ff')
        .get();

    setState(() {
      _filteredVideos = querySnapshot.docs.map((doc) {
        return Video(
          id: doc.id,
          title: doc['title'],
          description: doc['description'],
          videoUrl: doc['video_url'],
          monetized: doc['monetized'],
        );
      }).toList();
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Video Library',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black87,
        elevation: 0,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              await _auth.signOut();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search Videos',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _searchVideos, // Real-time search
            ),
          ),
          Expanded(
            child: _isSearching
                ? Center(child: CircularProgressIndicator())
                : _filteredVideos.isEmpty
                ? Center(child: Text('No videos found'))
                : GridView.builder(
              padding: const EdgeInsets.all(10.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 1,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _filteredVideos.length,
              itemBuilder: (context, index) {
                return VideoTile(video: _filteredVideos[index]);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => UploadVideoScreen()),
          );
        },
        child: const Icon(Icons.video_camera_back), // Studio icon
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            SizedBox(width: 16), // Add some space between icons if needed
            FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreatorDashboardScreen()),
                );
              },
              child: const Icon(Icons.stacked_bar_chart), // Studio icon
            ),
          ],
        ),
      ),
    );
  }
}

class VideoTile extends StatefulWidget {
  final Video video;

  const VideoTile({required this.video});

  @override
  _VideoTileState createState() => _VideoTileState();
}

class _VideoTileState extends State<VideoTile> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.network(widget.video.videoUrl);
    _initializeVideoPlayerFuture = _controller.initialize().then((_) {
      setState(() {});
    }).catchError((error) {
      print('Error initializing video player: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: FutureBuilder(
              future: _initializeVideoPlayerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error loading video'));
                  }
                  return Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      VideoPlayer(_controller),
                      VideoProgressIndicator(
                        _controller,
                        allowScrubbing: true,
                        padding: const EdgeInsets.all(8.0),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(_controller.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow),
                            onPressed: () {
                              setState(() {
                                _controller.value.isPlaying
                                    ? _controller.pause()
                                    : _controller.play();
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.replay_10),
                            onPressed: () {
                              _controller.seekTo(
                                Duration(seconds: _controller.value.position.inSeconds - 10),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.forward_10),
                            onPressed: () {
                              _controller.seekTo(
                                Duration(seconds: _controller.value.position.inSeconds + 10),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  );
                } else if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else {
                  return Center(child: Text('Error loading video'));
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              widget.video.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(widget.video.description),
          ),
          if (widget.video.monetized)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: const Text(
                'Monetized',
                style: TextStyle(color: Colors.green),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}






