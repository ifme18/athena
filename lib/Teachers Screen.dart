import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'Assignmentteachers.dart';
import 'teacherexamfill.dart';
import 'Teachersattendance.dart';
import 'assignmentcreation.dart';
import 'attendance.dart';
import 'examupload.dart';
import 'joinlive.dart';
import 'link.dart';
import 'quizcreation.dart';
import 'studymaterials.dart';
import 'teacherconten.dart';
import 'teachersetting.dart';

import 'Model/model.dart';
import 'AI.dart';

class TeachersScreen extends StatefulWidget {
  @override
  _TeachersScreenState createState() => _TeachersScreenState();
}

class _TeachersScreenState extends State<TeachersScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  Future<AppUser?> _fetchCurrentUser() async {
    AppUser? currentUser;

    try {
      final auth.User? user = _auth.currentUser;
      if (user != null) {
        final DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('teachers')
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
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.8),
      end: const Offset(0.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<auth.User?>(
      stream: _auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          // User is authenticated
          auth.User? currentUser = snapshot.data;
          if (currentUser != null) {
            return FutureBuilder<AppUser?>(
              future: _fetchCurrentUser(),
              builder: (BuildContext context,
                  AsyncSnapshot<AppUser?> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // Display loading indicator while data is being fetched
                  return Center(
                    child: SpinKitCircle(
                      color: Colors.greenAccent, // Use a vibrant green
                      size: 50.0,
                    ),
                  );
                } else if (snapshot.hasData) {
                  return Scaffold(
                    appBar: AppBar(
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const Text(
                            'Jambo', // Swahili greeting
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          Text(
                            snapshot.data!.name,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          const Icon(
                            Icons.emoji_people,
                            color: Colors.yellow,
                          ),
                          const Spacer(),
                          PopupMenuButton<String>(
                            onSelected: (String value) {
                              switch (value) {
                                case 'Settings':
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TeachersSettingsScreen(),
                                    ),
                                  );
                                  break;
                                case 'Logout':
                                // Perform logout operation
                                  break;
                                case 'Exams':
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TeachersExamUpdateScreen(),
                                    ),
                                  );
                                  break;
                                case 'Assignment':
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TeacherAssignmentScreen(),
                                    ),
                                  );
                                  break;
                                case 'Videos':
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => HomeScreen(),
                                    ),
                                  );
                                  break;
                                case 'AI':
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => GenerativeAI(),
                                    ),
                                  );
                                  break;

                              }
                            },
                            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                              PopupMenuItem<String>(
                                value: 'Settings',
                                child: Row(
                                  children: <Widget>[
                                    Icon(Icons.settings),
                                    SizedBox(width: 8.0),
                                    Text('Settings'),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'Logout',
                                child: Row(
                                  children: <Widget>[
                                    Icon(Icons.logout),
                                    SizedBox(width: 8.0),
                                    Text('Logout'),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'Exams',
                                child: Row(
                                  children: <Widget>[
                                    Icon(Icons.grading_outlined),
                                    SizedBox(width: 8.0),
                                    Text('Exams'),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'Videos',
                                child: Row(
                                  children: <Widget>[
                                    Icon(Icons.video_camera_front),
                                    SizedBox(width: 8.0),
                                    Text('Video Studio'),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'AI',
                                child: Row(
                                  children: <Widget>[
                                    Icon(Icons.chat),
                                    SizedBox(width: 8.0),
                                    Text('Ask Valeen'),
                                  ],
                                ),
                              ),

                            ],
                          ),
                        ],
                      ),
                      backgroundColor: Colors
                          .deepOrangeAccent, // Use a warm orange
                    ),
                    body: LayoutBuilder(
                      builder: (context, constraints) {
                        return GridView.count(
                          crossAxisCount: constraints.maxWidth < 600 ? 2 : 4,
                          crossAxisSpacing: 20.0,
                          mainAxisSpacing: 20.0,
                          padding: EdgeInsets.all(20.0),
                          children: [
                            _buildGridItem(
                              icon: Icons.school,
                              title: 'Exams',
                              subtitle: 'Grade your students',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TeachersExamUpdateScreen(),
                                  ),
                                );
                              },
                              color1: Colors.deepPurpleAccent,
                              color2: Colors.deepOrangeAccent,
                              fontSize: constraints.maxWidth < 600 ? 12.0 : 24.0,
                              iconSize: constraints.maxWidth < 600 ? 30.0 : 60.0,
                            ),
                            _buildGridItem(
                              icon: Icons.event,
                              title: 'Assignments',
                              subtitle: 'Upload and View Assignments',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AssignmentScreen(),
                                  ),
                                );
                              },
                              color1: Colors.greenAccent,
                              color2: Colors.lightGreenAccent,
                              fontSize: constraints.maxWidth < 600 ? 12.0 : 24.0,
                              iconSize: constraints.maxWidth < 600 ? 30.0 : 60.0,
                            ),
                            _buildGridItem(
                              icon: Icons.video_camera_front,
                              title: 'Upload lessons',
                              subtitle: 'Upload your lessons',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HomeScreen(),
                                  ),
                                );
                              },
                              color1: Colors.greenAccent,
                              color2: Colors.lightGreenAccent,
                              fontSize: constraints.maxWidth < 600 ? 12.0 : 24.0,
                              iconSize: constraints.maxWidth < 600 ? 30.0 : 60.0,
                            ),
                            _buildGridItem(
                              icon: Icons.question_mark,
                              title: 'Online Quizes',
                              subtitle: 'Upload your lessons',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CreateQuizScreen(),
                                  ),
                                );
                              },
                              color1: Colors.greenAccent,
                              color2: Colors.lightGreenAccent,
                              fontSize: constraints.maxWidth < 600 ? 12.0 : 24.0,
                              iconSize: constraints.maxWidth < 600 ? 30.0 : 60.0,
                            ),
                            _buildGridItem(
                              icon: Icons.question_answer_rounded,
                              title: 'AI',
                              subtitle: 'View and interact with AI Valeen Chatbot Teacher',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => GenerativeAI(),
                                  ),
                                );
                              },
                              color1: Colors.deepPurple,
                              color2: Colors.pink,
                              fontSize: constraints.maxWidth < 600 ? 12.0 : 24.0,
                              iconSize: constraints.maxWidth < 600 ? 30.0 : 60.0,
                            ),
                            _buildGridItem(
                              icon: Icons.book_online,
                              title: 'Online Materials',
                              subtitle: 'Uploaad and View Materials',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => StudyMaterialScreen(),
                                  ),
                                );
                              },
                              color1: Colors.deepPurple,
                              color2: Colors.pink,
                              fontSize: constraints.maxWidth < 600 ? 12.0 : 24.0,
                              iconSize: constraints.maxWidth < 600 ? 30.0 : 60.0,
                            ),
                            _buildGridItem(
                              icon: Icons.mark_chat_read,
                              title: 'Attendance',
                              subtitle: 'check student attendance',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TeacherAttendanceScreen(),
                                  ),
                                );
                              },
                              color1: Colors.deepPurple,
                              color2: Colors.pink,
                              fontSize: constraints.maxWidth < 600 ? 12.0 : 24.0,
                              iconSize: constraints.maxWidth < 600 ? 30.0 : 60.0,
                            ),
                            _buildGridItem(
                              icon: Icons.book_online,
                              title: 'Video Confrencing',
                              subtitle: 'join meeting and administer online classes',
                              onTap: () {
                                //
                              },
                              color1: Colors.deepPurple,
                              color2: Colors.pink,
                              fontSize: constraints.maxWidth < 600 ? 12.0 : 24.0,
                              iconSize: constraints.maxWidth < 600 ? 30.0 : 60.0,
                            ),
                          ],
                        );
                      },
                    ),
                  );
                } else {
                  // Handle errors if data fetching fails
                  return const Text('Failed to fetch data');
                }
              },
            );
          } else {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Login Required'),
              ),
              body: const Center(
                child: Text('Please log in to access this screen.'),
              ),
            );
          }
        } else {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Login Required'),
            ),
            body: const Center(
              child: Text('Please log in to access this screen.'),
            ),
          );
        }
      },
    );
  }

  Widget _buildGridItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required void Function() onTap,
    required Color color1,
    required Color color2,
    required double fontSize,
    required double iconSize,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color1, color2],
          ),
        ),
        padding: EdgeInsets.all(16.0), // Add padding to the container
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: Colors.white,
            ),
            SizedBox(height: 16.0),
            Text(
              title,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.0),
            Expanded(
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: fontSize * 0.6,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}