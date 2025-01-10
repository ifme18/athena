import 'package:cloud_firestore/cloud_firestore.dart';
import 'model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  static const String _usersCollection = 'students';
  static const String _paymentsCollection = 'payments';
  static const String _examsCollection = 'exams';
  static const String _schoolsCollection = 'schools';

  // User Data
  Future<void> saveUser(AppUser user) async {
    await _firestore
        .collection(_usersCollection)
        .doc(user.uid)
        .set(user.toJson());
  }

  Future<AppUser?> getUserById(String id) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
    await _firestore.collection(_usersCollection).doc(id).get();
    if (!snapshot.exists) return null;
    final data = snapshot.data()!;
    return AppUser(
      uid: snapshot.id,
      name: data['name'],
      email: data['email'],
      className: data['className'],
      schoolName: data['schoolName'],
      schoolId: data[''],
      role:
      Role.values.firstWhere((role) => role.value == data['role']),
    );
  }

  Future<List<AppUser>> getUsersByuid(String schoolName) async {
    final QuerySnapshot<Map<String, dynamic>> querySnapshot =
    await _firestore
        .collection(_usersCollection)
        .where('schoolName', isEqualTo: schoolName)
        .get();
    return querySnapshot.docs
        .map((doc) => AppUser(
      uid: doc.id,
      name: doc['name'],
      email: doc['email'],
      className: doc['className'],
      schoolName: doc['schoolName'],
      schoolId: doc[''],
      role: Role.values.firstWhere(
              (role) => role.value == doc['role']),
    ))
        .toList();
  }

  Future<void> updateUser(String id,
      {String? name, String? email}) async {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (email != null) data['email'] = email;
    await _firestore.collection(_usersCollection).doc(id).update(data);
  }

  Future<void> deleteUser(String id) async {
    await _firestore.collection(_usersCollection).doc(id).delete();
  }

  // Payment Data
  Future<void> savePayment(Payment payment) async {
    await _firestore
        .collection(_paymentsCollection)
        .doc(payment.paymentId)
        .set(payment.toJson());
  }

  Future<List<Payment>> getPaymentsByUserId(String userId) async {
    final QuerySnapshot<Map<String, dynamic>> querySnapshot =
    await _firestore
        .collection(_paymentsCollection)
        .where('userId', isEqualTo: userId)
        .get();
    return querySnapshot.docs
        .map((doc) => Payment(
      paymentId: doc.id,
      userId: doc['userId'],
      amount: doc['amount'],
      description: doc['description'],
      timestamp: doc['timestamp'],
    ))
        .toList();
  }

  Future<void> updatePayment(
      String paymentId, double newAmount, String newDescription) async {
    await _firestore
        .collection(_paymentsCollection)
        .doc(paymentId)
        .update({'amount': newAmount, 'description': newDescription});
  }

  Future<void> deletePayment(String paymentId) async {
    await _firestore
        .collection(_paymentsCollection)
        .doc(paymentId)
        .delete();
  }

  // Exam Data
  Future<void> saveExam(Exam exam) async {
    await _firestore
        .collection(_examsCollection)
        .doc(exam.examId)
        .set(exam.toJson());
  }

  Future<List<Exam>> getExamsByUserId(String userId) async {
    final QuerySnapshot<Map<String, dynamic>> querySnapshot =
    await _firestore
        .collection(_examsCollection)
        .where('userId', isEqualTo: userId)
        .get();
    return querySnapshot.docs
        .map((doc) => Exam(
      examId: doc.id,
      userId: doc['userId'],
      className: doc['className'],
      examName: doc['examName'],
      subject: doc['subject'],
      marks:
      Map<String, double>.from(doc['marks'] ?? {}),
      timestamp: doc['timestamp'],
    ))
        .toList();
  }
  Future<void> updateExam(
      String examId,
      Map<String, double> newMarks,
      String newSubject) async {
    await _firestore
        .collection(_examsCollection)
        .doc(examId)
        .update({'marks': newMarks, 'subject': newSubject});
  }


  Future<void> deleteExam(String examId) async {
    await _firestore.collection(_examsCollection).doc(examId).delete();
  }

  // School Data
  Future<void> saveSchool(School school) async {
    await _firestore
        .collection(_schoolsCollection)
        .doc(school.schoolId)
        .set(school.toJson());
  }

  Future<List<School>> getAllSchools() async {
    final QuerySnapshot<Map<String, dynamic>> querySnapshot =
    await _firestore.collection(_schoolsCollection).get();
    return querySnapshot.docs
        .map((doc) => School(
      schoolId: doc.id,
      Schoolname: doc['Schoolname'],
      address: doc['address'],
      city: doc['city'],
    ))
        .toList();
  }

  Future<void> updateSchool(String schoolId, String newName,
      String newAddress, String newCity) async {
    await _firestore.collection(_schoolsCollection).doc(schoolId).update({
      'name': newName,
      'address': newAddress,
      'city': newCity,
    });
  }

  Future<void> deleteSchool(String schoolId) async {
    await _firestore.collection(_schoolsCollection).doc(schoolId).delete();
  }

  // New method - fetch all users with the given role
  Future<List<AppUser>> fetchAllUsers({required String role}) async {
    final QuerySnapshot<Map<String, dynamic>> querySnapshot =
    await _firestore
        .collection(_usersCollection)
        .where('role', isEqualTo: role)
        .get();
    return querySnapshot.docs
        .map((doc) => AppUser(
      uid: doc.id,
      name: doc['name'],
      email: doc['email'],
      className: doc['className'],
      schoolName: doc['schoolName'],
      schoolId: doc[''],
      role: Role.values.firstWhere(
              (role) => role.value == doc['role']),
    ))
        .toList();
  }
}