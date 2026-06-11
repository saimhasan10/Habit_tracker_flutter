import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService authService = AuthService();
  final FirestoreService firestoreService = FirestoreService();
  final NotificationService notificationService = NotificationService();

  List<Habit> habits = [];
  Map<String, List<String>> completedHabits = {};

  bool isLoading = true;
  bool reminderEnabled = false;
  bool reminderActionLoading = false;

  TimeOfDay reminderTime = const TimeOfDay(hour: 20, minute: 0);

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    List<Habit> savedHabits = await firestoreService.loadHabits();

    Map<String, List<String>> savedCompleted = await firestoreService
        .loadCompletedHabits();

    SharedPreferences prefs = await SharedPreferences.getInstance();

    int savedHour = prefs.getInt('reminderHour') ?? 20;
    int savedMinute = prefs.getInt('reminderMinute') ?? 0;
    bool savedReminderEnabled = prefs.getBool('reminderEnabled') ?? false;

    if (!mounted) {
      return;
    }

    setState(() {
      habits = savedHabits;
      completedHabits = savedCompleted;
      reminderTime = TimeOfDay(hour: savedHour, minute: savedMinute);
      reminderEnabled = savedReminderEnabled;
      isLoading = false;
    });
  }

  Future<void> saveReminderSettings({
    required bool enabled,
    required TimeOfDay time,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setBool('reminderEnabled', enabled);
    await prefs.setInt('reminderHour', time.hour);
    await prefs.setInt('reminderMinute', time.minute);
  }

  Future<void> pickReminderTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: reminderTime,
    );

    if (pickedTime == null) {
      return;
    }

    setState(() {
      reminderTime = pickedTime;
    });

    await saveReminderSettings(enabled: reminderEnabled, time: pickedTime);

    if (reminderEnabled) {
      bool success = await notificationService.scheduleDailyReminder(
        pickedTime,
      );

      if (success) {
        showMessage('Reminder time updated');
      } else {
        showMessage('Notification permission was not granted');
      }
    }
  }

  Future<void> enableDailyReminder() async {
    setState(() {
      reminderActionLoading = true;
    });

    bool success = await notificationService.scheduleDailyReminder(
      reminderTime,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      setState(() {
        reminderEnabled = true;
      });

      await saveReminderSettings(enabled: true, time: reminderTime);

      showMessage('Daily reminder enabled');
    } else {
      showMessage('Notification permission was not granted');
    }

    if (mounted) {
      setState(() {
        reminderActionLoading = false;
      });
    }
  }

  Future<void> cancelDailyReminder() async {
    setState(() {
      reminderActionLoading = true;
    });

    await notificationService.cancelDailyReminder();

    if (!mounted) {
      return;
    }

    setState(() {
      reminderEnabled = false;
    });

    await saveReminderSettings(enabled: false, time: reminderTime);

    showMessage('Daily reminder cancelled');

    if (mounted) {
      setState(() {
        reminderActionLoading = false;
      });
    }
  }

  Future<void> testNotification() async {
    setState(() {
      reminderActionLoading = true;
    });

    bool success = await notificationService.showTestNotification();

    if (!mounted) {
      return;
    }

    if (success) {
      showMessage('Test notification sent');
    } else {
      showMessage('Notification permission was not granted');
    }

    setState(() {
      reminderActionLoading = false;
    });
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String getDateKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  List<String> getCurrentHabitIds() {
    return habits.map((habit) => habit.id).toList();
  }

  String getUserName(User? user) {
    String name = user?.displayName?.trim() ?? '';

    if (name.isNotEmpty) {
      return name;
    }

    return 'Set your name';
  }

  int getTotalCompletedHabits() {
    List<String> currentHabitIds = getCurrentHabitIds();

    int total = 0;

    completedHabits.forEach((date, habitIds) {
      total += habitIds
          .where((habitId) => currentHabitIds.contains(habitId))
          .length;
    });

    return total;
  }

  int getCurrentStreakForHabit(String habitId) {
    int streak = 0;
    DateTime checkingDate = DateTime.now();

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

  int getHighestCurrentStreak() {
    int highestStreak = 0;

    for (Habit habit in habits) {
      int streak = getCurrentStreakForHabit(habit.id);

      if (streak > highestStreak) {
        highestStreak = streak;
      }
    }

    return highestStreak;
  }

  List<Achievement> getAchievements() {
    int totalCompleted = getTotalCompletedHabits();
    int highestStreak = getHighestCurrentStreak();

    return [
      Achievement(
        title: 'First Step',
        description: 'Complete your first habit.',
        icon: Icons.flag,
        isUnlocked: totalCompleted >= 1,
      ),
      Achievement(
        title: 'Habit Collector',
        description: 'Create at least 3 habits.',
        icon: Icons.playlist_add_check_circle,
        isUnlocked: habits.length >= 3,
      ),
      Achievement(
        title: 'Streak Starter',
        description: 'Reach a 3 day current streak.',
        icon: Icons.local_fire_department,
        isUnlocked: highestStreak >= 3,
      ),
      Achievement(
        title: 'Consistency Builder',
        description: 'Complete 10 total habits.',
        icon: Icons.trending_up,
        isUnlocked: totalCompleted >= 10,
      ),
      Achievement(
        title: 'Habit Champion',
        description: 'Complete 50 total habits.',
        icon: Icons.workspace_premium,
        isUnlocked: totalCompleted >= 50,
      ),
      Achievement(
        title: 'Master Performer',
        description: 'Complete 100 total habits.',
        icon: Icons.military_tech,
        isUnlocked: totalCompleted >= 100,
      ),
    ];
  }

  int getUnlockedAchievementCount() {
    return getAchievements()
        .where((achievement) => achievement.isUnlocked)
        .length;
  }

  Future<void> showEditNameDialog() async {
    User? user = FirebaseAuth.instance.currentUser;

    TextEditingController nameController = TextEditingController(
      text: user?.displayName ?? '',
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Name'),
          content: TextField(
            controller: nameController,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                String name = nameController.text.trim();

                if (name.isEmpty) {
                  showMessage('Name cannot be empty');
                  return;
                }

                await authService.updateUserName(name);

                if (mounted) {
                  setState(() {});
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    int totalCompleted = getTotalCompletedHabits();
    int highestStreak = getHighestCurrentStreak();
    int unlockedAchievements = getUnlockedAchievementCount();
    List<Achievement> achievements = getAchievements();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
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
        backgroundColor: Color(0xFFF6F8F5),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Column(
                children: [
                  buildProfileHeader(user),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: buildStatCard(
                          title: 'Total Habits',
                          value: '${habits.length}',
                          icon: Icons.check_circle,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: buildStatCard(
                          title: 'Completed',
                          value: '$totalCompleted',
                          icon: Icons.done_all,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: buildStatCard(
                          title: 'Best Streak',
                          value: '$highestStreak days',
                          icon: Icons.timeline,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: buildStatCard(
                          title: 'Badges',
                          value: '$unlockedAchievements/${achievements.length}',
                          icon: Icons.workspace_premium,
                          color: Colors.indigo,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  buildAchievementsSection(achievements),
                  const SizedBox(height: 24),
                  buildReminderSection(),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: () async {
                        await authService.logout();
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget buildProfileHeader(User? user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 42,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 50, color: Color(0xFF2E7D32)),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  getUserName(user),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: showEditNameDialog,
                child: const Icon(Icons.edit, color: Colors.white, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            user?.email ?? 'No Email',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withAlpha(220), fontSize: 14),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(35),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              user?.emailVerified == true
                  ? 'Verified Account'
                  : 'Email Account',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildReminderSection() {
    String reminderStatus = reminderEnabled ? 'Enabled' : 'Disabled';

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
              Icon(Icons.notifications_active, color: Color(0xFF2E7D32)),
              SizedBox(width: 8),
              Text(
                'Daily Reminder',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Reminder is $reminderStatus at ${reminderTime.format(context)}.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F8F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFF2E7D32).withAlpha(35),
                  child: const Icon(Icons.schedule, color: Color(0xFF2E7D32)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reminder Time',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reminderTime.format(context),
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: reminderEnabled
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    reminderStatus,
                    style: TextStyle(
                      color: reminderEnabled
                          ? const Color(0xFF2E7D32)
                          : Colors.orange.shade800,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: reminderActionLoading ? null : pickReminderTime,
              icon: const Icon(Icons.access_time),
              label: const Text('Change Time'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2E7D32),
                padding: const EdgeInsets.symmetric(vertical: 13),
                side: const BorderSide(color: Color(0xFF2E7D32)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: reminderActionLoading
                      ? null
                      : reminderEnabled
                      ? null
                      : enableDailyReminder,
                  icon: const Icon(Icons.notifications),
                  label: const Text('Enable'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: reminderActionLoading || !reminderEnabled
                      ? null
                      : cancelDailyReminder,
                  icon: const Icon(Icons.notifications_off),
                  label: const Text('Cancel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: reminderActionLoading ? null : testNotification,
              icon: const Icon(Icons.send),
              label: const Text('Send Test Notification'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2E7D32),
              ),
            ),
          ),
          if (reminderActionLoading)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Center(
                child: SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildAchievementsSection(List<Achievement> achievements) {
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
              Icon(Icons.verified, color: Color(0xFF2E7D32)),
              SizedBox(width: 8),
              Text(
                'Achievements',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Unlocked badges are based on your habit activity.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 18),
          ListView.builder(
            itemCount: achievements.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              Achievement achievement = achievements[index];

              return buildAchievementCard(achievement);
            },
          ),
        ],
      ),
    );
  }

  Widget buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withAlpha(35),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAchievementCard(Achievement achievement) {
    Color activeColor = const Color(0xFF2E7D32);
    Color lockedColor = Colors.grey;

    bool unlocked = achievement.isUnlocked;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: unlocked ? const Color(0xFFF1F8E9) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: unlocked ? const Color(0xFFC8E6C9) : const Color(0xFFE0E0E0),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: unlocked
                ? activeColor.withAlpha(35)
                : lockedColor.withAlpha(25),
            child: Icon(
              achievement.icon,
              color: unlocked ? activeColor : lockedColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: unlocked ? Colors.black : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.description,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            unlocked ? Icons.lock_open : Icons.lock,
            color: unlocked ? activeColor : lockedColor,
            size: 22,
          ),
        ],
      ),
    );
  }
}

class Achievement {
  final String title;
  final String description;
  final IconData icon;
  final bool isUnlocked;

  Achievement({
    required this.title,
    required this.description,
    required this.icon,
    required this.isUnlocked,
  });
}
