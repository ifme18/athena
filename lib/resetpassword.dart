import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _verificationId = '';

  @override
  void dispose() {
    _inputController.dispose( );
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Forgot Password',
          style: TextStyle(color: Colors.purple[800]),
        ),
        backgroundColor: Colors.deepOrangeAccent,
      ),
      body: Center(
        child: Container(
          padding: EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.0),
            color: Colors.purple[100]?.withOpacity(0.8),
          ),
          child: Form(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _inputController,
                  decoration: InputDecoration(
                    labelText: 'Email or Phone Number',
                    labelStyle: TextStyle(color: Colors.orange[800]),
                  ),
                  style: TextStyle(color: Colors.black),
                ),
                if (_verificationId.isNotEmpty)
                  TextFormField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      labelText: 'Verification Code',
                      labelStyle: TextStyle(color: Colors.orange[800]),
                    ),
                    style: TextStyle(color: Colors.black),
                  ),
                SizedBox(height: 20.0),
                ElevatedButton(
                  onPressed: () async {
                    if (_verificationId.isEmpty) {
                      await _resetPassword(context);
                    } else {
                      await _verifyCodeAndReset(context);
                    }
                  },
                  child: Text(_verificationId.isEmpty ? 'Reset Password' : 'Verify Code'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.orange[400],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _resetPassword(BuildContext context) async {
    final input = _inputController.text.trim();

    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter your email or phone number.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Determine if input is email or phone number
      if (input.contains('@')) {
        // If input is an email
        final isEmailRegistered = await _isEmailRegistered(input);
        if (!isEmailRegistered) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No corresponding email found. Please check your input.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        await _auth.sendPasswordResetEmail(email: input);
      } else {
        // If input is a phone number
        await _auth.verifyPhoneNumber(
          phoneNumber: input,
          verificationCompleted: (PhoneAuthCredential credential) async {
            await _auth.signInWithCredential(credential);
          },
          verificationFailed: (FirebaseAuthException e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Verification failed: ${e.message}'),
                backgroundColor: Colors.red,
              ),
            );
          },
          codeSent: (String verificationId, int? resendToken) {
            setState(() {
              _verificationId = verificationId;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Verification code sent to $input'),
                backgroundColor: Colors.green,
              ),
            );
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Code auto-retrieval timed out. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          },
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset instructions sent.'),
          backgroundColor: Colors.green,
        ),
      );
      if (_verificationId.isNotEmpty) {
        _codeController.clear();
      }
      Navigator.of(context).pop(); // Close the password reset screen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending password reset instructions: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _verifyCodeAndReset(BuildContext context) async {
    try {
      final AuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _codeController.text.trim(),
      );
      final authResult = await _auth.signInWithCredential(credential);
      if (authResult.user != null) {
        await authResult.user!.updatePassword('NEW_PASSWORD_HERE');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset successfully.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); // Close the password reset screen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error resetting password. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error verifying code: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool> _isEmailRegistered(String email) async {
    final methods = await _auth.fetchSignInMethodsForEmail(email);
    return methods.isNotEmpty;
  }
}