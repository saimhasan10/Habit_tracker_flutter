import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/habit.dart';
import '../services/firestore_service.dart';
import '../widgets/calendar_heatmap_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirestoreService firestoreService = FirestoreService();

  List<Habit> habits = [];
  Map<String, List<String>> completedHabits = {};

  bool isLoading = true;

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

  List<String> getCurrentHabitIds() {
    return habits.map((habit) => habit.id).toList();
  }

  Future<void> loadData() async {
    List<Habit> savedHabits = await firestoreService.loadHabits();

    Map<String, List<String>> savedCompleted = await firestoreService
        .loadCompletedHabits();

    setState(() {
      habits = savedHabits;
      completedHabits = savedCompleted;
      isLoading = false;
    });
  }

  Future<void> saveCompletedData() async {
    await firestoreService.saveCompletedHabits(completedHabits);
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

  int getValidCompletedCountForDate(DateTime date) {
    String dateKey = getDateKey(date);
    List<String> currentHabitIds = getCurrentHabitIds();

    return completedHabits[dateKey]
            ?.where((habitId) => currentHabitIds.contains(habitId))
            .length ??
        0;
  }

  DateTime getStartOfWeek() {
    return selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
  }

  int getWeeklyCompletedCount() {
    DateTime startOfWeek = getStartOfWeek();

    int completed = 0;

    for (int i = 0; i < 7; i++) {
      DateTime date = startOfWeek.add(Duration(days: i));
      completed += getValidCompletedCountForDate(date);
    }

    return completed;
  }

  List<int> getWeeklyCompletionData() {
    DateTime startOfWeek = getStartOfWeek();

    List<int> weekData = [];

    for (int i = 0; i < 7; i++) {
      DateTime date = startOfWeek.add(Duration(days: i));
      int completedCount = getValidCompletedCountForDate(date);
      weekData.add(completedCount);
    }

    return weekData;
  }

  bool hasWeeklyChartData(List<int> weeklyData) {
    return weeklyData.any((value) => value > 0);
  }

  int getCurrentStreak(String habitId) {
    int streak = 0;
    DateTime checkingDate = selectedDate;

    while (true) {
      String dateKey = getDateKey(checkingDate);

      bool completed = completedHabits[dateKey]?.contains(habitId) ?? false;

      if (completed) {
        streak++;
        checkingDate = checkingDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
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

  Color getCategoryColor(String category) {
    switch (category) {
      case 'Health':
        return Colors.green;
      case 'Fitness':
        return Colors.orange;
      case 'Study':
        return Colors.blue;
      case 'Work':
        return Colors.purple;
      case 'Mental Health':
        return Colors.teal;
      case 'Finance':
        return Colors.indigo;
      case 'Spiritual':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  IconData getCategoryIcon(String category) {
    switch (category) {
      case 'Health':
        return Icons.favorite;
      case 'Fitness':
        return Icons.fitness_center;
      case 'Study':
        return Icons.menu_book;
      case 'Work':
        return Icons.work;
      case 'Mental Health':
        return Icons.self_improvement;
      case 'Finance':
        return Icons.account_balance_wallet;
      case 'Spiritual':
        return Icons.auto_awesome;
      default:
        return Icons.check_circle;
    }
  }

  Widget buildWeeklyAnalyticsChart(List<int> weeklyData) {
    int highestValue = 1;

    for (int value in weeklyData) {
      if (value > highestValue) {
        highestValue = value;
      }
    }

    double maxY = highestValue + 1;
    int weeklyCompletedCount = getWeeklyCompletedCount();
    int weeklyTotalCount = habits.length * 7;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart, color: Color(0xFF2E7D32)),
              SizedBox(width: 8),
              Text(
                'Weekly Analytics',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            '$weeklyCompletedCount of $weeklyTotalCount habits completed this week',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),

          const SizedBox(height: 18),

          if (!hasWeeklyChartData(weeklyData))
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'No completed habit data found for this selected week yet. Tick some habits on different days to see bars clearly.',
                style: TextStyle(
                  color: Color(0xFF8A6D00),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),

          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                minY: 0,
                maxY: maxY,
                alignment: BarChartAlignment.spaceAround,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
                  },
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value < 0) {
                          return const SizedBox();
                        }

                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      getTitlesWidget: (value, meta) {
                        const List<String> days = [
                          'Mon',
                          'Tue',
                          'Wed',
                          'Thu',
                          'Fri',
                          'Sat',
                          'Sun',
                        ];

                        int index = value.toInt();

                        if (index < 0 || index > 6) {
                          return const SizedBox();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            days[index],
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(7, (index) {
                  double value = weeklyData[index].toDouble();

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: value,
                        width: 20,
                        color: const Color(0xFF2E7D32),
                        borderRadius: BorderRadius.circular(8),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY,
                          color: const Color(0xFFE8F5E9),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int daysInMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
      0,
    ).day;

    int completedCount = getValidCompletedCountForDate(selectedDate);
    int totalHabits = habits.length;

    double dailyProgress = totalHabits == 0 ? 0 : completedCount / totalHabits;

    int dailyProgressPercent = (dailyProgress * 100).round();

    List<int> weeklyData = getWeeklyCompletionData();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Daily Habits',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            color: Color(0xFF1B1B1B),
          ),
        ),
        centerTitle: false,
        titleSpacing: 16,
        toolbarHeight: 72,
        backgroundColor: const Color(0xFFF6F8F5),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
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

                  const SizedBox(height: 16),

                  buildWeeklyAnalyticsChart(weeklyData),

                  const SizedBox(height: 16),

                  CalendarHeatmapWidget(
                    selectedMonth: selectedMonth,
                    selectedDate: selectedDate,
                    totalHabits: totalHabits,
                    getCompletedCount: getValidCompletedCountForDate,
                    getDateKey: getDateKey,
                    onDateSelected: (date) {
                      setState(() {
                        selectedDate = date;
                        selectedMonth = DateTime(date.year, date.month);
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Today’s Habits',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  habits.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 30),
                            child: Text(
                              'No habits added yet.\nGo to Manage page to add habits.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: habits.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            Habit habit = habits[index];

                            bool completed = isHabitCompleted(habit.id);

                            Color categoryColor = getCategoryColor(
                              habit.category,
                            );

                            int streak = getCurrentStreak(habit.id);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: categoryColor.withAlpha(35),
                                  child: Icon(
                                    getCategoryIcon(habit.category),
                                    color: categoryColor,
                                  ),
                                ),
                                title: Text(
                                  habit.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    decoration: completed
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                    color: completed
                                        ? Colors.grey
                                        : Colors.black,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 5),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${habit.category} • Target: ${habit.targetValue} ${habit.unit}',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      if (habit.note.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 3,
                                          ),
                                          child: Text(
                                            habit.note,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 5),
                                        child: Text(
                                          streak > 0
                                              ? '🔥 $streak day streak'
                                              : 'No streak yet',
                                          style: TextStyle(
                                            color: streak > 0
                                                ? Colors.deepOrange
                                                : Colors.grey.shade500,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: Checkbox(
                                  value: completed,
                                  activeColor: const Color(0xFF2E7D32),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  onChanged: (value) {
                                    toggleHabit(habit.id, value);
                                  },
                                ),
                              ),
                            );
                          },
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
