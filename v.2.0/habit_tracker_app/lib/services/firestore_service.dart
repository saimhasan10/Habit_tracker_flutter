import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/habit.dart';

class FirestoreService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  String get userId {
    return firebaseAuth.currentUser!.uid;
  }

  CollectionReference get habitsCollection {
    return firestore.collection('users').doc(userId).collection('habits');
  }

  DocumentReference get completedHabitsDocument {
    return firestore
        .collection('users')
        .doc(userId)
        .collection('tracking')
        .doc('completedHabits');
  }

  Future<void> saveHabit(Habit habit) async {
    await habitsCollection.doc(habit.id).set(habit.toJson());
  }

  Future<List<Habit>> loadHabits() async {
    QuerySnapshot snapshot = await habitsCollection.get();

    return snapshot.docs.map((doc) {
      return Habit.fromJson(doc.data() as Map<String, dynamic>);
    }).toList();
  }

  Future<void> deleteHabit(String habitId) async {
    await habitsCollection.doc(habitId).delete();
  }

  Future<void> saveCompletedHabits(
    Map<String, List<String>> completedHabits,
  ) async {
    Map<String, dynamic> data = completedHabits.map((date, habitIds) {
      return MapEntry(date, habitIds);
    });

    await completedHabitsDocument.set({'data': data});
  }

  Future<Map<String, List<String>>> loadCompletedHabits() async {
    DocumentSnapshot snapshot = await completedHabitsDocument.get();

    if (!snapshot.exists) {
      return {};
    }

    Map<String, dynamic> documentData = snapshot.data() as Map<String, dynamic>;

    Map<String, dynamic> completedData = Map<String, dynamic>.from(
      documentData['data'] ?? {},
    );

    return completedData.map((date, habitIds) {
      return MapEntry(date, List<String>.from(habitIds));
    });
  }
}
