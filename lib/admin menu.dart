import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'assignmentcreation.dart';
import 'attendance.dart';
import 'class%20creation.dart';
import 'create%20exam.dart';
import 'create%20subject.dart';
import 'event.dart';
import 'examupload.dart';
import 'main.dart';
import 'settings.dart';
import 'Users.dart';
import 'Model/model.dart';

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<AppUser?> get appUserStream =>
      _auth.authStateChanges().map((user) {
        if (user != null) {
          return AppUser(
            uid: user.uid,
            name: user.displayName ?? '',
            email: user.email ?? '',
            className: '',
            schoolName: '',
            schoolId: '',
            role: Role.admin,
          );
        }
        return null;
      });

  ThemeMode _themeMode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My School',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          brightness: Brightness.light,
        ).copyWith(
          secondary: const Color(0xFF42A5F5),
          tertiary: const Color(0xFF64B5F6),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: false,
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF2C3E50),
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          color: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
      ),
      themeMode: _themeMode,
      home: StreamBuilder<AppUser?>(
        stream: appUserStream,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return _buildAuthenticatedUI(snapshot.data!);
          }
          return const MyApp();
        },
      ),
    );
  }

  Widget _buildAuthenticatedUI(AppUser user) {
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('admins').doc(user.uid).get(),
      builder: (context, adminSnapshot) {
        if (adminSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          );
        }
        if (adminSnapshot.hasError || !adminSnapshot.hasData) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error: ${adminSnapshot.error ?? 'User not found'}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          );
        }

        final adminData = adminSnapshot.data!.data() as Map<String, dynamic>;
        final userName = adminData['name'] ?? user.name;
        final schoolId = adminData['schoolId'] ?? '';

        return FutureBuilder<DocumentSnapshot>(
          future: _firestore.collection('Schools').doc(schoolId).get(),
          builder: (context, schoolSnapshot) {
            if (schoolSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(strokeWidth: 2));
            }
            if (schoolSnapshot.hasError || !schoolSnapshot.hasData) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.school_outlined, size: 48, color: Colors.orange[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${schoolSnapshot.error ?? 'School not found'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            final school = School.fromSnapshot(schoolSnapshot.data!);

            return Scaffold(
              appBar: _buildAppBar(userName, school.Schoolname),
              drawer: _buildDrawer(context),
              body: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.blue.shade50,
                          Colors.white,
                        ],
                        stops: const [0.0, 0.3],
                      ),
                    ),
                    child: AdminDashboard(adminEmail: ''),
                  ),
                  Positioned(
                    right: 24,
                    bottom: 24,
                    child: _buildThemeToggle(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(String userName, String schoolName) {
    return AppBar(
      scrolledUnderElevation: 0,
      title: Row(
        children: [
          Container(
            height: 40,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Image.asset(
              "assets/images/Schoolfi.png",
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  schoolName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                Text(
                  'Welcome, $userName',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.red),
            tooltip: 'Logout',
            onPressed: () => _auth.signOut(),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SizedBox(
                    height: 40,
                    child: Image.asset(
                      "assets/images/Schoolfi.png",
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'School Management',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                children: [
                  _buildDrawerItem(
                    icon: Icons.dashboard_rounded,
                    title: 'Dashboard',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AdminDashboard(adminEmail: '')),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDrawerSection('Academics'),
                  _buildDrawerItem(
                    icon: Icons.class_rounded,
                    title: 'Class',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ClassCreation(currentUser: '')),
                    ),
                  ),
                  _buildDrawerItem(
                    icon: Icons.subject_rounded,
                    title: 'Subject',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SubjectCreation()),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDrawerSection('Examinations'),
                  _buildDrawerItem(
                    icon: Icons.assignment_rounded,
                    title: 'Manage Exams',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ExamUpdateScreen()),
                    ),
                  ),
                  _buildDrawerItem(
                    icon: Icons.add_circle_outline_rounded,
                    title: 'Create Exam',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ExamCreation(currentUser: '')),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDrawerSection('Management'),
                  _buildDrawerItem(
                    icon: Icons.event_rounded,
                    title: 'Events',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EventsScreen()),
                    ),
                  ),
                  _buildDrawerItem(
                    icon: Icons.people_rounded,
                    title: 'Attendance',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AttendanceScreen()),
                    ),
                  ),
                  _buildDrawerItem(
                    icon: Icons.settings_rounded,
                    title: 'Settings',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SettingsScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF2C3E50)),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        dense: true,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildThemeToggle() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: _toggleTheme,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          _themeMode == ThemeMode.light
              ? Icons.dark_mode_rounded
              : Icons.light_mode_rounded,
          size: 24,
        ),
      ),
    );
  }

  void _toggleTheme() {
    setState(() {
      _themeMode = (_themeMode == ThemeMode.light)
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }
}


void main() {
  runApp(App());
}