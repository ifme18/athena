import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class SchoolRegistrationScreen extends StatefulWidget {
  @override
  _SchoolRegistrationScreenState createState() => _SchoolRegistrationScreenState();
}

class _SchoolRegistrationScreenState extends State<SchoolRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _schoolName;
  late String _location;
  late int _numberOfStudents;

  void _registerSchool() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        await FirebaseFirestore.instance.collection('Schools').add({
          'schoolName': _schoolName,
          'location': _location,
          'numberOfStudents': _numberOfStudents,
        });

        // Clear the form after successful registration
        _formKey.currentState!.reset();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('School registered successfully')),
        );
      } catch (error) {
        print('Failed to register school: $error');
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to register school: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primaryColor: Colors.purple,
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.purple,
          title: Text('School Registration'),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TextFormField(
                    decoration: InputDecoration(labelText: 'School Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter school name';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _schoolName = value!;
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Location'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter location';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _location = value!;
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Number of Students'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter number of students';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _numberOfStudents = int.parse(value!);
                    },
                  ),
                  SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: _registerSchool,
                    child: Text('Register School'),
                  ),
                  SizedBox(height: 32.0),
                  Text(
                    'Registered Schools',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  StreamBuilder(
                    stream: FirebaseFirestore.instance.collection('Schools').snapshots(),
                    builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      final schools = snapshot.data!.docs;

                      return DataTable(
                        columns: [
                          DataColumn(label: Text('School Name')),
                          DataColumn(label: Text('Location')),
                          DataColumn(label: Text('Number of Students')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: schools.map((school) {
                          final schoolData = school.data() as Map<String, dynamic>;

                          // Ensure fields are not null
                          final schoolName = schoolData['schoolName'] ?? '';
                          final location = schoolData['location'] ?? '';
                          final numberOfStudents = schoolData['numberOfStudents'] ?? '';

                          return DataRow(
                            cells: [
                              DataCell(Text(schoolName)),
                              DataCell(Text(location)),
                              DataCell(Text(numberOfStudents.toString())),
                              DataCell(Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit),
                                    onPressed: () {
                                      // Implement edit functionality
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete),
                                    onPressed: () {
                                      // Implement delete functionality
                                      school.reference.delete();
                                    },
                                  ),
                                ],
                              )),
                            ],
                          );
                        }).toList(),
                      );
                    },
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