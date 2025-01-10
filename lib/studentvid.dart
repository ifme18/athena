import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:video_player/video_player.dart';
import 'package:shimmer/shimmer.dart';

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

class VideoScreen extends StatelessWidget {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Video Library',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              // Profile action
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search Videos',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.5)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  onSubmitted: (value) async {
                    if (value.isNotEmpty) {
                      await _storeSearchQuery(value);
                    }
                  },
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FutureBuilder<bool>(
              future: _checkSubscription(),
              builder: (context, subscriptionSnapshot) {
                if (subscriptionSnapshot.connectionState == ConnectionState.waiting) {
                  return _buildShimmerLoading();
                }
                final bool subscribed = subscriptionSnapshot.data ?? false;

                return StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('videos').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return _buildShimmerLoading();
                    }
                    List<Video> videos = [];
                    snapshot.data!.docs.forEach((doc) {
                      videos.add(Video(
                        id: doc.id,
                        title: doc['title'],
                        description: doc['description'],
                        videoUrl: doc['video_url'],
                        monetized: doc['monetized'],
                      ));
                    });

                    if (!subscribed) {
                      videos = videos.where((video) => !video.monetized).toList();
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          int crossAxisCount = constraints.maxWidth > 600 ? 2 : 1;
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.8,
                            ),
                            itemCount: videos.length,
                            itemBuilder: (context, index) {
                              return ModernVideoTile(video: videos[index]);
                            },
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (!_checkSubscription().toString().contains('true'))
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () => _subscribeToPremium(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C4DFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Upgrade to Premium',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF2A2A2A),
      highlightColor: const Color(0xFF3A3A3A),
      child: Column(
        children: List.generate(
          3,
              (index) => Container(
            margin: const EdgeInsets.all(16),
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
      ),
    );
  }

  // All the existing methods remain the same
  Future<bool> _checkSubscription() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous) {
      final snapshot = await _firestore.collection('users').doc(user.uid).get();
      if (snapshot.exists) {
        final Timestamp? expirationTimestamp = snapshot['subscriptionExpiration'];
        if (expirationTimestamp != null) {
          final DateTime expirationDate = expirationTimestamp.toDate();
          return expirationDate.isAfter(DateTime.now());
        }
      }
    }
    return false;
  }

  Future<void> _storeSearchQuery(String query) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous) {
      await _firestore.collection('search_history').doc(user.uid).collection('queries').add({
        'query': query,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  void _subscribeToPremium(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous) {
      bool paymentSuccessful = await _initiateDarajaSubscription();

      if (paymentSuccessful) {
        final DateTime expirationDate = DateTime.now().add(const Duration(days: 30));
        await _firestore.collection('users').doc(user.uid).set({
          'subscribed': true,
          'subscriptionExpiration': expirationDate,
        }, SetOptions(merge: true));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Welcome to Premium!',
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: const Color(0xFF7C4DFF),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Subscription failed. Please try again.',
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<bool> _initiateDarajaSubscription() async {
    try {
      final response = await http.post(
        Uri.parse('YOUR_DARAJA_SUBSCRIPTION_ENDPOINT'),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(<String, dynamic>{}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error subscribing to premium: $e');
      return false;
    }
  }
}

class ModernVideoTile extends StatefulWidget {
  final Video video;

  const ModernVideoTile({required this.video});

  @override
  _ModernVideoTileState createState() => _ModernVideoTileState();
}

class _ModernVideoTileState extends State<ModernVideoTile> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.video.videoUrl);
    _initializeVideoPlayerFuture = _controller.initialize().then((_) {
      setState(() {});
      _logVideoView(widget.video.id);
    }).catchError((error) {
      print('Error initializing video player: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()
          ..scale(_isHovered ? 1.02 : 1.0),
        child: Card(
          elevation: _isHovered ? 8 : 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          color: const Color(0xFF2A2A2A),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _buildVideoPlayer(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.video.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.video.description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    _buildControls(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return FutureBuilder(
      future: _initializeVideoPlayerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Error loading video',
                style: TextStyle(color: Colors.white),
              ),
            );
          }
          return Stack(
            alignment: Alignment.bottomCenter,
            children: [
              VideoPlayer(_controller),
              VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
                padding: const EdgeInsets.all(8.0),
                colors: VideoProgressColors(
                  playedColor: const Color(0xFF7C4DFF),
                  bufferedColor: Colors.white.withOpacity(0.3),
                  backgroundColor: Colors.white.withOpacity(0.1),
                ),
              ),
            ],
          );
        } else {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C4DFF)),
            ),
          );
        }
      },
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildControlButton(
          icon: _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
          onPressed: () {
            setState(() {
              if (_controller.value.isPlaying) {
                _controller.pause();
                _logPauseEvent(widget.video.id);
              } else {
                _controller.play();
                _logPlayEvent(widget.video.id);
              }
            });
          },
        ),
        _buildControlButton(
          icon: Icons.replay_10,
          onPressed: () {
            _controller.seekTo(
              Duration(seconds: _controller.value.position.inSeconds - 10),
            );
          },
        ),
        _buildControlButton(
          icon: Icons.forward_10,
          onPressed: () {
            _controller.seekTo(
              Duration(seconds: _controller.value.position.inSeconds + 10),
            );
          },
        ),
        _buildControlButton(
          icon: Icons.thumb_up_outlined,
          onPressed: () => _handleLike(widget.video.id),
        ),
        _buildControlButton(
          icon: Icons.thumb_down_outlined,
          onPressed: () => _handleDislike(widget.video.id),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF3A3A3A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
        splashColor: const Color(0xFF7C4DFF).withOpacity(0.3),
        highlightColor: const Color(0xFF7C4DFF).withOpacity(0.2),
      ),
    );
  }
  Future<void> _logVideoView(String videoId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous) {
      final viewsCollection = FirebaseFirestore.instance
          .collection('videos')
          .doc(videoId)
          .collection('views');
      final viewDoc = viewsCollection.doc(user.uid);

      final viewSnapshot = await viewDoc.get();
      if (!viewSnapshot.exists) {
        await viewDoc.set({
          'user_id': user.uid,
          'timestamp': FieldValue.serverTimestamp(),
        });

        await FirebaseFirestore.instance.collection('videos').doc(videoId).update({
          'view_count': FieldValue.increment(1),
        });
      }
    }
  }

  Future<void> _logPlayEvent(String videoId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous) {
      await FirebaseFirestore.instance
          .collection('videos')
          .doc(videoId)
          .collection('events')
          .add({
        'user_id': user.uid,
        'event': 'play',
        'timestamp': FieldValue.serverTimestamp(),
        'playback_position': _controller.value.position.inSeconds,
      });
    }
  }

  Future<void> _logPauseEvent(String videoId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous) {
      await FirebaseFirestore.instance
          .collection('videos')
          .doc(videoId)
          .collection('events')
          .add({
        'user_id': user.uid,
        'event': 'pause',
        'timestamp': FieldValue.serverTimestamp(),
        'playback_position': _controller.value.position.inSeconds,
      });
    }
  }

  Future<void> _handleLike(String videoId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous) {
      setState(() {
        // Add loading state if needed
      });

      try {
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final videoRef = FirebaseFirestore.instance.collection('videos').doc(videoId);
          final videoDoc = await transaction.get(videoRef);

          if (videoDoc.exists) {
            final currentLikes = videoDoc.data()?['likes'] ?? 0;
            transaction.update(videoRef, {'likes': currentLikes + 1});
          }
        });

        await FirebaseFirestore.instance
            .collection('videos')
            .doc(videoId)
            .collection('events')
            .add({
          'user_id': user.uid,
          'event': 'like',
          'timestamp': FieldValue.serverTimestamp(),
        });

        setState(() {
          // Handle success state
        });
      } catch (e) {
        print('Error handling like: $e');
        // Handle error state
      }
    }
  }

  Future<void> _handleDislike(String videoId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous) {
      setState(() {
        // Add loading state if needed
      });

      try {
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final videoRef = FirebaseFirestore.instance.collection('videos').doc(videoId);
          final videoDoc = await transaction.get(videoRef);

          if (videoDoc.exists) {
            final currentDislikes = videoDoc.data()?['dislikes'] ?? 0;
            transaction.update(videoRef, {'dislikes': currentDislikes + 1});
          }
        });

        await FirebaseFirestore.instance
            .collection('videos')
            .doc(videoId)
            .collection('events')
            .add({
          'user_id': user.uid,
          'event': 'dislike',
          'timestamp': FieldValue.serverTimestamp(),
        });

        setState(() {
          // Handle success state
        });
      } catch (e) {
        print('Error handling dislike: $e');
        // Handle error state
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// Add this extension for additional UI helpers
extension ColorExtension on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  Color lighten([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return hslLight.toColor();
  }
}

// Event logging methods remain the same


