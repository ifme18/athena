import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreatorDashboardScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Creator Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.black87,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<User?>(
          stream: _auth.authStateChanges(),
          builder: (context, authSnapshot) {
            if (authSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!authSnapshot.hasData || authSnapshot.data == null) {
              return Center(
                child: Text(
                  'Please login to view your dashboard.',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }

            String userId = authSnapshot.data!.uid;
            return StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('videos')
                  .where('creator', isEqualTo: userId)
                  .snapshots(),
              builder: (context, videoSnapshot) {
                if (videoSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!videoSnapshot.hasData || videoSnapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No videos found.',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }

                List<DataRow> rows = videoSnapshot.data!.docs.map((doc) {
                  Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                  return DataRow(
                    cells: [
                      DataCell(Text(data['title'] ?? '',
                          style: TextStyle(fontSize: 16))),
                      DataCell(Text(data['video_views']?.toString() ?? '0',
                          style: TextStyle(fontSize: 16))),
                      DataCell(Text(data['likes']?.toString() ?? '0',
                          style: TextStyle(fontSize: 16))),
                      DataCell(Text(data['dislikes']?.toString() ?? '0',
                          style: TextStyle(fontSize: 16))),
                      DataCell(Text(data['monetized'] == true ? 'Yes' : 'No',
                          style: TextStyle(
                              fontSize: 16,
                              color: data['monetized'] == true
                                  ? Colors.green
                                  : Colors.red))),
                    ],
                  );
                }).toList();

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: DataTable(
                        headingRowColor: MaterialStateColor.resolveWith(
                                (states) => Colors.black87),
                        headingTextStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        columns: [
                          DataColumn(label: Text('Title')),
                          DataColumn(label: Text('Views')),
                          DataColumn(label: Text('Likes')),
                          DataColumn(label: Text('Dislikes')),
                          DataColumn(label: Text('Monetized')),
                        ],
                        rows: rows,
                        dataRowHeight: 50,
                        headingRowHeight: 60,
                        columnSpacing: 20,
                        dividerThickness: 1,
                        showBottomBorder: true,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}