import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';

class StorageService {
  static const String habitsKey = 'habits';
  static const String completedKey = 'completed_habits';

  Future<void> saveHabits(List<Habit> habits) async {
    final prefs = await SharedPreferences.getInstance();

    List<String> habitList = habits
        .map((habit) => jsonEncode(habit.toJson()))
        .toList();

    await prefs.setStringList(habitsKey, habitList);
  }

  Future<List<Habit>> loadHabits() async {
    final prefs = await SharedPreferences.getInstance();

    List<String>? habitList = prefs.getStringList(habitsKey);

    if (habitList == null) {
      return [];
    }

    return habitList
        .map((habitString) => Habit.fromJson(jsonDecode(habitString)))
        .toList();
  }

  Future<void> saveCompletedHabits(
    Map<String, List<String>> completedHabits,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    String encodedData = jsonEncode(completedHabits);

    await prefs.setString(completedKey, encodedData);
  }

  Future<Map<String, List<String>>> loadCompletedHabits() async {
    final prefs = await SharedPreferences.getInstance();

    String? encodedData = prefs.getString(completedKey);

    if (encodedData == null) {
      return {};
    }

    Map<String, dynamic> decodedData = jsonDecode(encodedData);

    return decodedData.map((date, habitIds) {
      return MapEntry(date, List<String>.from(habitIds));
    });
  }
}
