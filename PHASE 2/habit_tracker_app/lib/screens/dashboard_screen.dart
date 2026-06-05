import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../services/storage_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final StorageService storageService = StorageService();

  List<Habit> habits = [];
  Map<String, List<String>> completedHabits = {};

  DateTime selectedDate = DateTime.now();

  DateTime selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    loadData();
  }

  String getDateKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  Future<void> loadData() async {
    List<Habit> savedHabits = await storageService.loadHabits();

    Map<String, List<String>> savedCompleted = await storageService
        .loadCompletedHabits();

    setState(() {
      habits = savedHabits;
      completedHabits = savedCompleted;
    });
  }

  Future<void> saveCompletedData() async {
    await storageService.saveCompletedHabits(completedHabits);
  }

  void toggleHabit(String habitId, bool? value) {
    String dateKey = getDateKey(selectedDate);

    completedHabits[dateKey] ??= [];

    setState(() {
      if (value == true) {
        if (!completedHabits[dateKey]!.contains(habitId)) {
          completedHabits[dateKey]!.add(habitId);
        }
      } else {
        completedHabits[dateKey]!.remove(habitId);
      }
    });

    saveCompletedData();
  }

  bool isHabitCompleted(String habitId) {
    String dateKey = getDateKey(selectedDate);

    return completedHabits[dateKey]?.contains(habitId) ?? false;
  }

  String getReadableDate(DateTime date) {
    return '${date.day} ${getMonthName(date.month)}, ${date.year}';
  }

  void goToPreviousMonth() {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);

      selectedDate = DateTime(selectedMonth.year, selectedMonth.month, 1);
    });
  }

  void goToNextMonth() {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);

      selectedDate = DateTime(selectedMonth.year, selectedMonth.month, 1);
    });
  }

  int getWeeklyCompletedCount() {
    DateTime startOfWeek = selectedDate.subtract(
      Duration(days: selectedDate.weekday - 1),
    );

    int completed = 0;

    for (int i = 0; i < 7; i++) {
      DateTime date = startOfWeek.add(Duration(days: i));

      String dateKey = getDateKey(date);

      completed += completedHabits[dateKey]?.length ?? 0;
    }

    return completed;
  }

  @override
  Widget build(BuildContext context) {
    int daysInMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
      0,
    ).day;

    String dateKey = getDateKey(selectedDate);

    int completedCount = completedHabits[dateKey]?.length ?? 0;

    int totalHabits = habits.length;

    double dailyProgress = totalHabits == 0 ? 0 : completedCount / totalHabits;

    int dailyProgressPercent = (dailyProgress * 100).round();

    int weeklyCompletedCount = getWeeklyCompletedCount();

    int weeklyTotalCount = totalHabits * 7;

    double weeklyProgress = weeklyTotalCount == 0
        ? 0
        : weeklyCompletedCount / weeklyTotalCount;

    int weeklyProgressPercent = (weeklyProgress * 100).round();

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Habits')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              getReadableDate(selectedDate),
              style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
            ),

            const SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: goToPreviousMonth,
                  icon: const Icon(Icons.arrow_back_ios),
                ),

                Text(
                  '${getMonthName(selectedMonth.month)} ${selectedMonth.year}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                IconButton(
                  onPressed: goToNextMonth,
                  icon: const Icon(Icons.arrow_forward_ios),
                ),
              ],
            ),

            const SizedBox(height: 16),

            SizedBox(
              height: 82,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: daysInMonth,
                itemBuilder: (context, index) {
                  DateTime date = DateTime(
                    selectedMonth.year,
                    selectedMonth.month,
                    index + 1,
                  );

                  bool isSelected =
                      getDateKey(date) == getDateKey(selectedDate);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedDate = date;
                      });
                    },
                    child: Container(
                      width: 62,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF2E7D32)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(10),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            getWeekDay(date.weekday),
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade600,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Row(
                children: [
                  SizedBox(
                    height: 78,
                    width: 78,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: weeklyProgress,
                          strokeWidth: 9,
                          backgroundColor: const Color(0xFFE8F5E9),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF2E7D32),
                          ),
                        ),

                        Center(
                          child: Text(
                            '$weeklyProgressPercent%',
                            style: const TextStyle(
                              color: Color(0xFF2E7D32),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 20),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Weekly Progress',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          '$weeklyCompletedCount of $weeklyTotalCount habits completed this week',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Row(
                children: [
                  SizedBox(
                    height: 82,
                    width: 82,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: dailyProgress,
                          strokeWidth: 9,
                          backgroundColor: Colors.white.withAlpha(55),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),

                        Center(
                          child: Text(
                            '$dailyProgressPercent%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 20),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Daily Progress',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          '$completedCount of $totalHabits habits completed today',
                          style: TextStyle(
                            color: Colors.white.withAlpha(220),
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Today’s Habits',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: habits.isEmpty
                  ? const Center(
                      child: Text(
                        'No habits added yet.\nGo to Manage page to add habits.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: habits.length,
                      itemBuilder: (context, index) {
                        Habit habit = habits[index];

                        bool completed = isHabitCompleted(habit.id);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),

                            leading: Checkbox(
                              value: completed,
                              activeColor: const Color(0xFF2E7D32),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              onChanged: (value) {
                                toggleHabit(habit.id, value);
                              },
                            ),

                            title: Text(
                              habit.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                decoration: completed
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                color: completed ? Colors.grey : Colors.black,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String getWeekDay(int weekDay) {
    switch (weekDay) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }

  String getMonthName(int month) {
    switch (month) {
      case 1:
        return 'January';
      case 2:
        return 'February';
      case 3:
        return 'March';
      case 4:
        return 'April';
      case 5:
        return 'May';
      case 6:
        return 'June';
      case 7:
        return 'July';
      case 8:
        return 'August';
      case 9:
        return 'September';
      case 10:
        return 'October';
      case 11:
        return 'November';
      case 12:
        return 'December';
      default:
        return '';
    }
  }
}
