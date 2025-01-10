import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'Studentscreen.dart';
import 'Super Admin.dart';
import 'Teachers Screen.dart';
import 'admin%20menu.dart';
import 'admin%20menu.dart';
import 'reg.dart';
import 'resetpassword.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDYX-NLjHblN6vtSwJqYuDpJS6AYQy8pbA",
      authDomain: "mytest-ae5c5.firebaseapp.com",
      databaseURL: "https://mytest-ae5c5-default-rtdb.firebaseio.com",
      projectId: "mytest-ae5c5",
      storageBucket: "mytest-ae5c5.appspot.com",
      messagingSenderId: "1077512582594",
      appId: "1:1077512582594:web:0fb7a4357fa3fcaf4d925b",
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/': (context) => const SplashScreen(),
        '/welcome': (context) => App(),
        '/student': (context) =>  StudentScreen() ,
        '/teacher': (context) =>  TeachersScreen(),
        '/signin': (context) => const SignInScreen(),
        '/register': (context) => const RegistrationScreen(),
        '/schoolRegistration': (context)=>  SchoolRegistrationScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen();

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward().then((_) {
      Future.delayed(const Duration(seconds: 3), () {
        _checkSession();
      });
    });
  }

  void _checkSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? lastSignInTime = prefs.getString('lastSignInTime');
    if (lastSignInTime != null) {
      final DateTime lastSignIn = DateTime.parse(lastSignInTime);
      final DateTime now = DateTime.now();
      final difference = now.difference(lastSignIn).inDays;
      if (difference <= 14) {
        // Session is still valid, navigate to appropriate screen
        String? userType = prefs.getString('userType');
        switch (userType) {
          case 'admin':
            Navigator.of(context).pushReplacementNamed('/welcome');
            break;
          case 'student':
            Navigator.of(context).pushReplacementNamed('/student');
            break;
          case 'teacher':
            Navigator.of(context).pushReplacementNamed('/teacher');
            break;
          case 'superAdmin':
            Navigator.of(context).pushReplacementNamed('/schoolRegistration');
            break;
          default:
            Navigator.of(context).pushReplacementNamed('/signin');
            break;
        }
      } else {
        // Session expired, clear stored session data
        prefs.remove('lastSignInTime');
        prefs.remove('userType');
        Navigator.of(context).pushReplacementNamed('/signin');
      }
    } else {
      // No stored session data, navigate to sign-in screen
      Navigator.of(context).pushReplacementNamed('/signin');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primaryColor: Colors.deepOrangeAccent,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: Colors.tealAccent,
        ),
      ),
      child: Scaffold(
        body: Center(
          child: FadeTransition(
            opacity: _scaleAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.deepOrangeAccent, Colors.tealAccent],
                      ),
                    ),
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          "assets/images/Schoolfi.png",
                          height: 120,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Shule Bora',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            foreground: Paint()
                              ..shader = const LinearGradient(
                                colors: <Color>[
                                  Colors.deepOrangeAccent,
                                  Colors.tealAccent,
                                ],
                              ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
                            fontFamily: 'Ubuntu',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
class SignInScreen extends StatelessWidget {
  const SignInScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.deepOrangeAccent, Colors.tealAccent],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/background.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: SizedBox(
              width: 400,
              child: Card(
                elevation: 5.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Image.asset(
                            'assets/images/Schoolfi.png',
                            height: 60.0,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20.0),
                      _SignInForm(), // The centered form
                      const SizedBox(height: 20.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacementNamed('/register');
                            },
                            child: const Text('Create an Admin Account'),
                            backgroundColor: Colors.tealAccent,
                          ),
                          const SizedBox(width: 10.0),
                          CustomButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ForgotPasswordScreen(),
                                ),
                              );
                            },
                            child: const Text('reset password!'),
                            backgroundColor: Colors.deepOrange,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10.0),


                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class _SignInForm extends StatefulWidget {
  @override
  __SignInFormState createState() => __SignInFormState();
}

class __SignInFormState extends State<_SignInForm> {
  late FirebaseAuth _auth;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _selectedRole = 'admin';
  bool _loading = false; // Flag to show loading indicator


  @override
  void initState() {
    super.initState();
    _auth = FirebaseAuth.instance;
  }
  Future<void> _login() async {
    setState(() {
      _loading = true; // Set loading state to true
    });
    try {
      final email = _emailController.text;
      final phone = _phoneController.text;
      final password = _passwordController.text;

      switch (_selectedRole) {
        case 'admin':
          await _loginAdmin(email, password);
          break;
        case 'student':
          await _loginStudent(email, phone, password);
          break;
        case 'teacher':
          await _loginTeacher(email, phone, password);
          break;
        case 'superAdmin':
          await _loginSuperAdmin(email, password); // Use user-provided credentials
          break;
      }
    } catch (e) {
      _showErrorSnackBar('Error logging in: $e');
    } finally {
      setState(() {
        _loading = false; // Set loading state to false after operation completes
      });
    }
  }



  Future<void> _loginAdmin(String email, String password) async {
    // Authenticate the user and sign in
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Get the user's ID token
    final User? user = _auth.currentUser;
    if (user != null) {
      final idTokenResult = await user.getIdTokenResult();

      // Check if the user has a custom claim for admin role
      final Map<String, dynamic>? customClaims = idTokenResult.claims;
      if (customClaims != null &&
          customClaims.containsKey('role') &&
          customClaims['role'] == 'admin') {
        Navigator.of(context).pushReplacementNamed('/welcome');
      } else {
        // Show error message to the user
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: const Text('Invalid admin credentials.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  Future<void> _loginStudent(String email, String phone,
      String password) async {
    try {
      if (email.isNotEmpty) {
        // Authenticate with email and password
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else if (phone.isNotEmpty) {
        // Authenticate with phone number and password
        await _auth.signInWithCredential(
          PhoneAuthProvider.credential(
            verificationId: '', // You'll need to implement phone verification
            smsCode: password,
          ),
        );
      } else {
        // Show error if neither email nor phone number is provided
        _showErrorSnackBar('Please enter either an email or a phone number');
        return;
      }

      // Get the user's ID token
      final User? user = _auth.currentUser;
      if (user != null) {
        final idTokenResult = await user.getIdTokenResult();

        // Check if the user has a custom claim for student role
        final Map<String, dynamic>? customClaims = idTokenResult.claims;
        if (customClaims != null &&
            customClaims.containsKey('role') &&
            customClaims['role'] == 'student') {
          // Create an instance of the StudentScreen widget and pass the user object to it
          Navigator.of(context).pushReplacementNamed(
              '/student', arguments: user);
        } else {
          // Show error message to the user
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Error'),
                content: const Text('Invalid student credentials.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error logging in: $e');
    }
  }
  void _showErrorSnackBar(String errorMessage) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _loginSuperAdmin(String email, String password) async {
    // Hardcoded email and password for SuperAdmin
    const superAdminEmail = 'schoolifi@student.com';
    const superAdminPassword = 'schoolifi2024';

    // Check if the provided email and password match the SuperAdmin credentials
    if (email == superAdminEmail && password == superAdminPassword) {
      // Navigate to SuperAdmin's screen
      Navigator.of(context).pushReplacementNamed('/schoolRegistration');
    } else {
      // Show error message if credentials do not match
      _showErrorSnackBar('Invalid super admin credentials.');
    }
  }



  Future<void> _loginTeacher(String email, String phone,
      String password) async {
    try {
      if (email.isNotEmpty) {
        // Authenticate with email and password
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else if (phone.isNotEmpty) {
        // Authenticate with phone number and password
        await _auth.signInWithCredential(
          PhoneAuthProvider.credential(
            verificationId: '', // You'll need to implement phone verification
            smsCode: password,
          ),
        );
      } else {
        // Show error if neither email nor phone number is provided
        _showErrorSnackBar('Please enter either an email or a phone number');
        return;
      }

      // Get the user's ID token
      final User? user = _auth.currentUser;
      if (user != null) {
        final idTokenResult = await user.getIdTokenResult();

        // Check if the user has a custom claim for teacher role
        final Map<String, dynamic>? customClaims = idTokenResult.claims;
        if (customClaims != null &&
            customClaims.containsKey('role') &&
            customClaims['role'] == 'teacher') {
          Navigator.of(context).pushReplacementNamed('/teacher');
        } else {
          // Show error message to the user
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Error'),
                content: const Text('Invalid teacher credentials.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error logging in: $e');
    }
  }

  Future<void> _storeSessionData(String userType) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('userType', userType);
    prefs.setString('lastSignInTime', DateTime.now().toString());
  }

  Future<void> _clearSessionData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('userType');
    prefs.remove('lastSignInTime');
  }

  // Other login methods for student, teacher, and superAdmin...

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Login',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 10),
        DropdownButton<String>(
          value: _selectedRole,
          onChanged: (newValue) {
            setState(() {
              _selectedRole = newValue!;
            });
          },
          items: <String>['admin', 'student', 'teacher', 'superAdmin']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        Form(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.deepOrange,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    hintText: 'Email (optional)',
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(color: Colors.black),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.lightBlueAccent,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    hintText: 'Phone Number (optional)',
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(color: Colors.black),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.lightGreenAccent,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    hintText: 'Password',
                    border: InputBorder.none,
                  ),
                  obscureText: true,
                  style: const TextStyle(color: Colors.black),
                ),
              ),

              ElevatedButton(
                onPressed: _login,
                child: Text('Login as $_selectedRole'),
              ),
            ],
          ),
        ),
      ],
    );
  }

}
class CustomButton extends StatelessWidget {
  final Function onPressed;
  final Widget child;
  final Color backgroundColor;

  const CustomButton({
    required this.onPressed,
    required this.child,
    this.backgroundColor = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => onPressed(),
      child: child,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      ),
    );
  }
}
