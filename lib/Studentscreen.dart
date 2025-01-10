import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'eventnotify.dar.dart';
import 'event.dart';
import 'assignmentsubmission.dart';
import 'do%20quiz.dart';
import 'exam view.dart';
import 'get material.dart';
import 'joinlive.dart';
import 'main.dart';
import 'studentsettings.dart';
import 'studentvid.dart';

import 'Model/model.dart';
import 'AI.dart';
// ... [previous imports remain the same]

class StudentScreen extends StatefulWidget {
  @override
  _StudentScreenState createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  Future<AppUser?> _fetchCurrentUser() async {
    AppUser? currentUser;

    try {
      final auth.User? user = _auth.currentUser;
      if (user != null) {
        final DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('students')
            .doc(user.uid)
            .get();

        if (userSnapshot.exists) {
          currentUser = AppUser.fromSnapshot(userSnapshot);
        }
      }
    } catch (e) {
      print('Error fetching current user: $e');
    }

    return currentUser;
  }
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _offsetAnimation = Tween<Offset>(
      begin: Offset(0, 0.1),
      end: Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }



  // ... [previous methods remain the same]

  List<Map<String, dynamic>> _getMenuItems() {
    return [
      {
        'title': 'Exams',
        'icon': Icons.school,
        'subtitle': 'View exams',
        'colors': [Colors.blue[400]!, Colors.blue[600]!],
        'route': ResultsScreen()
      },
      {
        'title': 'Schooltube',
        'icon': Icons.play_circle_filled,
        'subtitle': 'Check out latest lessons',
        'colors': [Colors.red[400]!, Colors.red[600]!],
        'route': VideoScreen()
      },
      {
        'title': 'AI Assistant',
        'icon': Icons.psychology,
        'subtitle': 'Chat with Valeen AI',
        'colors': [Colors.purple[400]!, Colors.purple[600]!],
        'route': GenerativeAI()
      },
      {
        'title': 'Study Library',
        'icon': Icons.library_books,
        'subtitle': 'Access study materials',
        'colors': [Colors.green[400]!, Colors.green[600]!],
        'route': MaterialListScreen()
      },
      {
        'title': 'Events',
        'icon': Icons.event_note,
        'subtitle': 'School calendar & events',
        'colors': [Colors.orange[400]!, Colors.orange[600]!],
        'route': EventsShot()
      },
      {
        'title': 'Online Class',
        'icon': Icons.video_camera_front,
        'subtitle': 'Join live classes',
        'colors': [Colors.teal[400]!, Colors.teal[600]!],
        'route': JoinLivestreamScreen()
      },
      {
        'title': 'Online Exams',
        'icon': Icons.quiz,
        'subtitle': 'Take quizzes & tests',
        'colors': [Colors.indigo[400]!, Colors.indigo[600]!],
        'route': AttemptQuizScreen()
      },
      {
        'title': 'Assignments',
        'icon': Icons.assignment,
        'subtitle': 'View & submit work',
        'colors': [Colors.pink[400]!, Colors.pink[600]!],
        'route': AssignmentSubmissionScreen()
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<auth.User?>(
      stream: _auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<AppUser?>(
            future: _fetchCurrentUser(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingState();
              } else if (userSnapshot.hasData) {
                return _buildMainScreen(userSnapshot.data!);
              } else {
                return _buildErrorState();
              }
            },
          );
        } else {
          return _buildLoginRequired();
        }
      },
    );
  }

  Widget _buildMainScreen(AppUser user) {
    final menuItems = _getMenuItems();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          _buildAppBar(user),
          SliverPadding(
            padding: EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                childAspectRatio: 1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final item = menuItems[index];
                  return _buildMenuItem(
                    title: item['title'],
                    icon: item['icon'],
                    subtitle: item['subtitle'],
                    colors: item['colors'],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => item['route']),
                    ),
                  );
                },
                childCount: menuItems.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required String title,
    required IconData icon,
    required String subtitle,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: _offsetAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors[1].withOpacity(0.3),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: onTap,
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          icon,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  SliverAppBar _buildAppBar(AppUser user) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.purple[700]!, Colors.purple[500]!],
            ),
          ),
        ),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome,',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            Text(
              user.name,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
            ),
            child: Icon(Icons.notifications_none, color: Colors.white),
          ),
          onPressed: () {
            // Handle notifications
          },
        ),
        IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
            ),
            child: Icon(Icons.settings_outlined, color: Colors.white),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => StudentSettingsScreen()),
            );
          },
        ),
        SizedBox(width: 8),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SpinKitPulsingGrid(
          color: Colors.purple[600],
          size: 50.0,
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            SizedBox(height: 16),
            Text(
              'Unable to load data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please try again later',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginRequired() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.purple[700]!, Colors.purple[500]!],
          ),
        ),
        child: Center(
          child: Container(
            margin: EdgeInsets.all(32),
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: Colors.purple[400],
                ),
                SizedBox(height: 24),
                Text(
                  'Login Required',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Please sign in to access your student dashboard',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}