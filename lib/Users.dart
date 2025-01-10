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
      appBar: _buildAppBar(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8F9FA),
              Color(0xFFE9ECEF),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              children: [
                _buildHeader(),
                SizedBox(height: 32),
                _buildGridView(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      title: Text(
        "Dashboard",
        style: TextStyle(
          color: Color(0xFF2D3436),
          fontWeight: FontWeight.w700,
          fontSize: 24,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.notifications_outlined, color: Color(0xFF2D3436)),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(Icons.settings_outlined, color: Color(0xFF2D3436)),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Welcome back,",
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF636E72),
            ),
          ),
          SizedBox(height: 8),
          Text(
            adminEmail,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 20,
      crossAxisSpacing: 20,
      childAspectRatio: 1.25,
      children: [
        _buildCard(
          context: context,
          title: "Teachers",
          icon: Icons.school_outlined,
          color: Color(0xFF00B894),
          route: TeachersRegistrationWidget(),
        ),
        _buildCard(
          context: context,
          title: "Students",
          icon: Icons.people_outline,
          color: Color(0xFF0984E3),
          route: StudentRegistrationWidget(),
        ),
        _buildCard(
          context: context,
          title: "Video Call",
          icon: Icons.video_call_outlined,
          color: Color(0xFF6C5CE7),
          route: LibraryScreen(),
        ),
        _buildCard(
          context: context,
          title: "Library",
          icon: Icons.library_books_outlined,
          color: Color(0xFFE17055),
          route: LibraryScreen(),
        ),
      ],
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required Widget route,
  }) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => route),
      ),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 32,
                color: color,
              ),
            ),
            SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3436),
              ),
            ),
          ],
        ),
      ),
    );
  }
}