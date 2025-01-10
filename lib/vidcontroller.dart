import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'lib.dart';
import 'link.dart';
import 'live.dart';
import 'student%20registration.dart';
import 'teacher%20reg.dart';

class AdminDashboard extends StatelessWidget {
  final String adminEmail;
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  AdminDashboard({required this.adminEmail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildCustomAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildAdminTile(
                title: "Teachers",
                iconData: Icons.school,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TeachersRegistrationWidget(),
                    ),
                  );
                },
                gradientColors: [
                  Colors.tealAccent.withOpacity(0.8),
                  Colors.tealAccent.withOpacity(0.6),
                ],
              ),
              const SizedBox(height: 16.0), // Spacing between tiles
              _buildAdminTile(
                title: "Students",
                iconData: Icons.book,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudentRegistrationWidget(),
                    ),
                  );
                },
                gradientColors: [
                  Colors.lightBlueAccent.withOpacity(0.8),
                  Colors.lightBlueAccent.withOpacity(0.6),
                ],
              ),
              const SizedBox(height: 16.0), // Spacing between tiles
              _buildAdminTile(
                title: "Video Call",
                iconData: Icons.video_call,
                onPressed: () {

                },
                gradientColors: [
                  Colors.lightGreenAccent.withOpacity(0.8),
                  Colors.lightGreenAccent.withOpacity(0.6),
                ],
              ),
              const SizedBox(height: 16.0), // Spacing between tiles
              _buildAdminTile(
                title: "Library",
                iconData: Icons.library_books_outlined,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LibraryScreen(),
                    ),
                  );
                },
                gradientColors: [
                  Colors.pinkAccent.withOpacity(0.8),
                  Colors.pinkAccent.withOpacity(0.6),
                ],
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.white, // Set background color of Scaffold to white
    );
  }

  AppBar _buildCustomAppBar() {
    return AppBar(
      title: Text(
        "Admin Dashboard",
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      centerTitle: true,
      backgroundColor: Colors.teal,
      elevation: 8.0, // Increased shadow for more depth
    );
  }

  Widget _buildAdminTile({
    required String title,
    required IconData iconData,
    required VoidCallback onPressed,
    required List<Color> gradientColors,
  }) {
    return Material(
      borderRadius: BorderRadius.circular(16.0),
      elevation: 4.0,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors, // Customized gradient colors
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                ],
              ),
              Icon(
                iconData,
                size: 40.0,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}