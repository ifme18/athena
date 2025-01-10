import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum Role {
  admin,
  teacher,
  student,
}

extension RoleExtension on Role {
  String get value => describeEnum(this);
}

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String className;
  final String schoolName;
  final String schoolId;
  final Role role;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.className,
    required this.schoolName,
    required this.schoolId,
    required this.role,
  });
  factory AppUser.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>?;

    return AppUser(
      uid: snapshot.id,
      schoolId: snapshot.id as String? ?? '',
      name: data?['name'] as String? ?? '',
      email: data?['email'] as String? ?? '',
      className: data?['className'] as String? ?? '',
      schoolName: data?['schoolName'] as String? ?? '',
      role: Role.values.firstWhere(
            (role) => describeEnum(role) == (data?['role'] as String? ?? ''),
        orElse: () => Role.student,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'schoolId':schoolId,
      'name': name,
      'email': email,
      'className': className,
      'schoolName': schoolName,
      'role': describeEnum(role),
    };
  }
}
class Payment {
  final String paymentId;
  final String userId;
  final double amount;
  final String description;
  final DateTime timestamp;

  Payment({
    required this.paymentId,
    required this.userId,
    required this.amount,
    required this.description,
    required this.timestamp,
  });

  factory Payment.fromSnapshot(DocumentSnapshot snapshot) {
    var data = snapshot.data() as Map<String, dynamic>?; // Cast data to Map<String, dynamic>
    return Payment(
      paymentId: snapshot.id,
      userId: data?['userId'] as String? ?? '',
      amount: (data?['amount'] as num?)?.toDouble() ?? 0.0, // Cast 'amount' to num?
      description: data?['description'] as String? ?? '',
      timestamp: (data?['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Payment copyWith({
    String? paymentId,
    String? userId,
    double? amount,
    String? description,
    DateTime? timestamp,
  }) {
    return Payment(
      paymentId: paymentId ?? this.paymentId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paymentId': paymentId,
      'userId': userId,
      'amount': amount,
      'description': description,
      'timestamp': timestamp,
    };
  }
}

class Exam {
  final String examId;
  final String userId;
  final String className;
  final String examName;
  final String subject;
  final Map<String, double> marks;
  final DateTime timestamp;

  Exam({
    required this.examId,
    required this.userId,
    required this.className,
    required this.examName,
    required this.subject,
    required this.marks,
    required this.timestamp,
  });

  double get averageMarks {
    if (marks.isEmpty) {
      return 0.0;
    } else {
      double sum = marks.values.reduce((a, b) => a + b);
      double count = marks.length.toDouble();
      return sum / count;
    }
  }

  factory Exam.fromSnapshot(DocumentSnapshot snapshot) {
    var data = snapshot.data() as Map<String, dynamic>?; // Cast data to Map<String, dynamic>
    return Exam(
      examId: snapshot.id,
      userId: data?['userId'] as String? ?? '',
      className: data?['className'] as String? ?? '',
      examName: data?['examName'] as String? ?? '',
      subject: data?['subject'] as String? ?? '',
      marks: Map<String, double>.from(data?['marks'] as Map<String, dynamic>? ?? {}),
      timestamp: (data?['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'examId': examId,
      'userId': userId,
      'className': className,
      'examName': examName,
      'subject': subject,
      'marks': marks,
      'timestamp': timestamp,
    };
  }
}

class School {
  final String schoolId;
  final String Schoolname;
  final String address;
  final String city;

  School({
    required this.schoolId,
    required this.Schoolname,
    required this.address,
    required this.city,
  });

  factory School.fromSnapshot(DocumentSnapshot snapshot) {
    var data = snapshot.data() as Map<String, dynamic>?; // Cast data to Map<String, dynamic>
    return School(
      schoolId: snapshot.id,
      Schoolname: data?['Schoolname'] as String? ?? '',
      address: data?['address'] as String? ?? '',
      city: data?['city'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schoolId': schoolId,
      'Schoolname': Schoolname,
      'address': address,
      'city': city,
    };
  }
}