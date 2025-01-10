import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/Premium Vector _ Geometric hi-tech background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SizedBox(
            width: 400,
            child: Card(
              elevation: 8, // Add a subtle shadow
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15), // Rounded corners
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SignInForm(),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacementNamed('/register');
                      },
                      child: const Text(
                        'Create an admin account',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
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
  String _selectedRole = 'admin';

  @override
  void initState() {
    super.initState();
    _auth = FirebaseAuth.instance;
  }

  Future<void> _login() async {
    try {
      final email = _emailController.text;
      final password = _passwordController.text;

      switch (_selectedRole) {
        case 'admin':
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
          break;
        case 'student':
        // Similar logic for student login
          break;
        case 'teacher':
        // Similar logic for teacher login
          break;
      }
    } catch (e) {
      // Show error message to the user
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text(e.toString()),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Login',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 20),
        DropdownButton<String>(
          value: _selectedRole,
          onChanged: (newValue) {
            setState(() {
              _selectedRole = newValue!;
            });
          },
          items: <String>['admin', 'student', 'teacher']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Form(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    hintText: 'Email',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: Icon(Icons.email), // Email icon
                  ),
                  style: const TextStyle(color: Colors.black),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    hintText: 'Password',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: Icon(Icons.lock), // Lock icon
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