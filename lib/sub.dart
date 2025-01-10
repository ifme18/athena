import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MpesaService {
  final String consumerKey;
  final String consumerSecret;
  final String passKey;
  final bool isSandbox;

  MpesaService({
    required this.consumerKey,
    required this.consumerSecret,
    required this.passKey,
    this.isSandbox = true,
  });

  String get baseUrl => isSandbox
      ? 'https://sandbox.safaricom.co.ke'
      : 'https://api.safaricom.co.ke';

  Future<String> _getAccessToken() async {
    final credentials = base64Encode(utf8.encode('$consumerKey:$consumerSecret'));

    final response = await http.get(
      Uri.parse('$baseUrl/oauth/v1/generate?grant_type=client_credentials'),
      headers: {
        'Authorization': 'Basic $credentials',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['access_token'];
    }
    throw Exception('Failed to get access token');
  }

  Future<Map<String, dynamic>> initiatePayment({
    required String phoneNumber,
    required double amount,
    required String accountReference,
  }) async {
    final token = await _getAccessToken();
    final timestamp = DateTime.now().toString().replaceAll(RegExp(r'[^0-9]'), '');
    final String businessShortCode = '174379'; // Replace with your shortcode

    final String password = base64Encode(
        utf8.encode('$businessShortCode$passKey$timestamp')
    );

    final response = await http.post(
      Uri.parse('$baseUrl/mpesa/stkpush/v1/processrequest'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'BusinessShortCode': businessShortCode,
        'Password': password,
        'Timestamp': timestamp,
        'TransactionType': 'CustomerPayBillOnline',
        'Amount': amount,
        'PartyA': phoneNumber,
        'PartyB': businessShortCode,
        'PhoneNumber': phoneNumber,
        'CallBackURL': 'https://your-callback-url.com/callback',
        'AccountReference': accountReference,
        'TransactionDesc': 'School Registration Payment',
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to initiate payment');
  }
}

class SchoolRegistrationLogic extends StatelessWidget {
  final mpesa = MpesaService(
    consumerKey: 'your_consumer_key',
    consumerSecret: 'your_consumer_secret',
    passKey: 'your_pass_key',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280.0,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF1A237E),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'School Registration',
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
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF1A237E),
                          const Color(0xFF3949AB),
                          const Color(0xFF3F51B5).withOpacity(0.95),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: -50,
                    top: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 32.0, 24.0, 24.0),
              child: RegistrationForm(mpesa: mpesa),
            ),
          ),
        ],
      ),
    );
  }
}

class RegistrationForm extends StatefulWidget {
  final MpesaService mpesa;

  const RegistrationForm({required this.mpesa});

  @override
  _RegistrationFormState createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final _schoolNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _numberOfStudentsController = TextEditingController();
  final _locationController = TextEditingController();
  bool _isLoading = false;

  Future<void> _processRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final numberOfStudents = int.parse(_numberOfStudentsController.text);
      final amount = numberOfStudents * 60.0; // 60 KES per student

      final result = await widget.mpesa.initiatePayment(
        phoneNumber: _phoneNumberController.text,
        amount: amount,
        accountReference: 'SCH${DateTime.now().millisecondsSinceEpoch}',
      );

      if (result['ResponseCode'] == '0') {
        await _saveSchoolData(amount);
        _showSuccessDialog();
      } else {
        _showErrorDialog('Payment initiation failed. Please try again.');
      }
    } catch (e) {
      _showErrorDialog('An error occurred: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSchoolData(double amount) async {
    await FirebaseFirestore.instance.collection('Schools').add({
      'schoolName': _schoolNameController.text,
      'phoneNumber': _phoneNumberController.text,
      'numberOfStudents': int.parse(_numberOfStudentsController.text),
      'location': _locationController.text,
      'amountPaid': amount,
      'registrationDate': FieldValue.serverTimestamp(),
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: const Text(
          'Payment initiated successfully. Please complete the payment on your phone.',
        ),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
              _clearForm();
            },
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _clearForm() {
    _schoolNameController.clear();
    _phoneNumberController.clear();
    _numberOfStudentsController.clear();
    _locationController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle('School Information'),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _schoolNameController,
            label: 'School Name',
            icon: Icons.school,
            validator: (value) =>
            value?.isEmpty ?? true ? 'Please enter school name' : null,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _locationController,
            label: 'Location',
            icon: Icons.location_on,
            validator: (value) =>
            value?.isEmpty ?? true ? 'Please enter location' : null,
          ),
          const SizedBox(height: 32),
          _buildSectionTitle('Registration Details'),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _phoneNumberController,
            label: 'M-Pesa Phone Number',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Please enter phone number';
              if (!RegExp(r'^254[0-9]{9}$').hasMatch(value!)) {
                return 'Enter valid phone number (254XXXXXXXXX)';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _numberOfStudentsController,
            label: 'Number of Students',
            icon: Icons.people,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Please enter number of students';
              if (int.tryParse(value!) == null)
                return 'Please enter a valid number';
              return null;
            },
          ),
          const SizedBox(height: 32),
          _buildPaymentDetails(),
          const SizedBox(height: 32),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A237E),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF3949AB)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        keyboardType: keyboardType,
        validator: validator,
      ),
    );
  }

  Widget _buildPaymentDetails() {
    final numberOfStudents = int.tryParse(_numberOfStudentsController.text) ?? 0;
    final amount = numberOfStudents * 60;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 16),
          _buildPaymentRow('Cost per student', 'KES 60'),
          const SizedBox(height: 8),
          _buildPaymentRow('Total students', numberOfStudents.toString()),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(),
          ),
          _buildPaymentRow(
            'Total Amount',
            'KES $amount',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            color: isTotal ? const Color(0xFF1A237E) : Colors.black87,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            color: isTotal ? const Color(0xFF1A237E) : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1A237E),
            Color(0xFF3949AB),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _processRegistration,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : const Text(
          'Register and Pay',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  @override
  @override
  void dispose() {
    _schoolNameController.dispose();
    _phoneNumberController.dispose();
    _numberOfStudentsController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}

// Main app entry point
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(SchoolRegistrationApp());
}

class SchoolRegistrationApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'School Registration',
      theme: ThemeData(
        primaryColor: const Color(0xFF1A237E),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFF1A237E),
          secondary: const Color(0xFF3949AB),
        ),
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A237E),
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFF3949AB),
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Colors.red,
              width: 1,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Colors.red,
              width: 2,
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A237E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
      home: SchoolRegistrationLogic(),
    );
  }
}