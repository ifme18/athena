import 'package:athena_analytic/Super%20Admin.dart';
import 'package:athena_analytic/sub.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';



class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen();

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'schoolregistration@example.com',
      queryParameters: {
        'subject': 'Request for School Registration',
        'body': 'Dear School Administration,\n\nI would like to request registration for our school.\n\nThank you,'
      },
    );

    try {
      await launch(emailLaunchUri.toString());
    } catch (e) {
      print('Could not launch email: $e');
    }
  }
  void _navigateToSchoolReg(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SchoolRegistrationLogic()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF2D3250),
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
              ),
              onPressed: () => _navigateToSchoolReg(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: const ShimmeringText(
                'Join Our Community',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          const Color(0xFF2D3250),
                          const Color(0xFF424769),
                          const Color(0xFF424769).withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                  CustomPaint(
                    painter: BubblePainter(),
                  ),
                  Image.asset(
                    'assets/images/Schoolfi.png',
                    fit: BoxFit.cover,
                    color: Colors.black.withOpacity(0.3),
                    colorBlendMode: BlendMode.darken,
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline),
                onPressed: _launchEmail,
              ),


            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Hero(
                tag: 'registration_card',
                child: Card(
                  elevation: 8,
                  shadowColor: const Color(0xFF2D3250).withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const _ModernRegistrationForm(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ShimmeringText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  const ShimmeringText(this.text, {this.style});

  @override
  _ShimmeringTextState createState() => _ShimmeringTextState();
}

class _ShimmeringTextState extends State<ShimmeringText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                Colors.white,
                Colors.white.withOpacity(0.5),
                Colors.white,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ],
              tileMode: TileMode.clamp,
            ).createShader(bounds);
          },
          child: Text(
            widget.text,
            style: widget.style,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class BubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final random = DateTime.now().millisecondsSinceEpoch;
    for (var i = 0; i < 20; i++) {
      final x = (random + i * 100) % size.width;
      final y = (random + i * 200) % size.height;
      final radius = (random + i) % 20 + 5.0;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _ModernRegistrationForm extends StatefulWidget {
  const _ModernRegistrationForm();

  @override
  _ModernRegistrationFormState createState() => _ModernRegistrationFormState();
}

class _ModernRegistrationFormState extends State<_ModernRegistrationForm>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  String? _selectedSchoolId;
  List<Map<String, dynamic>> _schools = [];
  late AnimationController _formAnimationController;
  late Animation<double> _formAnimation;

  @override
  void initState() {
    super.initState();
    _getSchools();
    _formAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _formAnimation = CurvedAnimation(
      parent: _formAnimationController,
      curve: Curves.easeInOut,
    );
    _formAnimationController.forward();
  }

  @override
  void dispose() {
    _formAnimationController.dispose();
    super.dispose();
  }
  Future<void> _getSchools() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('Schools').get();
      setState(() {
        _schools = snapshot.docs.map<Map<String, dynamic>>((doc) => {
          'id': doc.id,
          'name': doc['schoolName'] as String,
        }).toList();
      });
    } catch (e) {
      print('Error fetching schools: $e');
    }
  }

  Future<void> _registerAdmin() async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('registerAdmin');
      final result = await callable.call({
        'email': _emailController.text,
        'name': _nameController.text,
        'schoolId': _selectedSchoolId,
        'password': _passwordController.text,
      });

      if (result.data['status'] == 'success') {
        _showSuccessDialog();
      } else {
        _showErrorDialog('Registration failed. Please try again.');
      }
    } catch (e) {
      _showErrorDialog('An error occurred. Please try again later.');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Success'),
        content: const Text('Registration completed successfully!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  // ... (keep existing methods like _getSchools, _registerAdmin, etc.)

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _formAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(_formAnimation),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const ShimmeringText(
                'Create Account',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3250),
                ),
              ),
              const SizedBox(height: 32),
              _buildAnimatedTextField(
                controller: _emailController,
                label: 'Email Address',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                delay: 0,
              ),
              const SizedBox(height: 16),
              _buildAnimatedTextField(
                controller: _nameController,
                label: 'Full Name',
                prefixIcon: Icons.person_outline,
                delay: 1,
              ),
              const SizedBox(height: 16),
              _buildAnimatedTextField(
                controller: _passwordController,
                label: 'Password',
                prefixIcon: Icons.lock_outline,
                obscureText: !_isPasswordVisible,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFF2D3250),
                  ),
                  onPressed: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
                delay: 2,
              ),
              const SizedBox(height: 16),
              _buildAnimatedSchoolDropdown(delay: 3),
              const SizedBox(height: 32),
              _buildAnimatedButton(delay: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    Widget? suffixIcon,
    bool obscureText = false,
    TextInputType? keyboardType,
    required int delay,
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.5, 0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _formAnimationController,
          curve: Interval(
            delay * 0.2,
            (delay * 0.2) + 0.2,
            curve: Curves.easeOut,
          ),
        ),
      ),
      child: _ModernTextField(
        controller: controller,
        label: label,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        obscureText: obscureText,
        keyboardType: keyboardType,
      ),
    );
  }

  Widget _buildAnimatedSchoolDropdown({required int delay}) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.5, 0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _formAnimationController,
          curve: Interval(
            delay * 0.2,
            (delay * 0.2) + 0.2,
            curve: Curves.easeOut,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[100],
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2D3250).withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedSchoolId,
            hint: const Text('Select School'),
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF2D3250)),
            items: _schools.map((school) {
              return DropdownMenuItem<String>(
                value: school['id'],
                child: Text(school['name']),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedSchoolId = value),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedButton({required int delay}) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.5, 0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _formAnimationController,
          curve: Interval(
            delay * 0.2,
            (delay * 0.2) + 0.2,
            curve: Curves.easeOut,
          ),
        ),
      ),
      child: ElevatedButton(
        onPressed: _registerAdmin,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2D3250),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          shadowColor: const Color(0xFF2D3250).withOpacity(0.3),
        ),
        child: const Text(
          'Register',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
class _ModernTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;

  const _ModernTextField({
    required this.controller,
    required this.label,
    required this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(prefixIcon, color: const Color(0xFF2D3250)),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
      ),
    );
  }
}

// Keep the existing _ModernTextField class