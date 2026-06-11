import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../services/firestore_service.dart';

class ManageHabitsScreen extends StatefulWidget {
  const ManageHabitsScreen({super.key});

  @override
  State<ManageHabitsScreen> createState() => _ManageHabitsScreenState();
}

class _ManageHabitsScreenState extends State<ManageHabitsScreen> {
  final FirestoreService firestoreService = FirestoreService();

  final TextEditingController habitController = TextEditingController();
  final TextEditingController targetController = TextEditingController();
  final TextEditingController unitController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  List<Habit> habits = [];

  bool isLoading = true;

  String selectedCategory = 'General';

  final List<String> categories = [
    'General',
    'Health',
    'Fitness',
    'Study',
    'Work',
    'Mental Health',
    'Finance',
    'Spiritual',
  ];

  @override
  void initState() {
    super.initState();
    targetController.text = '1';
    unitController.text = 'time';
    loadHabits();
  }

  Future<void> loadHabits() async {
    List<Habit> savedHabits = await firestoreService.loadHabits();

    setState(() {
      habits = savedHabits;
      isLoading = false;
    });
  }

  Future<void> addHabit() async {
    String habitName = habitController.text.trim();
    String note = noteController.text.trim();
    String unit = unitController.text.trim();
    int targetValue = int.tryParse(targetController.text.trim()) ?? 1;

    if (habitName.isEmpty) {
      showMessage('Please enter habit name');
      return;
    }

    String habitId = DateTime.now().millisecondsSinceEpoch.toString();

    Habit newHabit = Habit(
      id: habitId,
      name: habitName,
      category: selectedCategory,
      targetValue: targetValue,
      unit: unit.isEmpty ? 'time' : unit,
      note: note,
    );

    setState(() {
      habits.add(newHabit);
      habitController.clear();
      targetController.text = '1';
      unitController.text = 'time';
      noteController.clear();
      selectedCategory = 'General';
    });

    await firestoreService.saveHabit(newHabit);

    showMessage('Habit added successfully');
  }

  Future<void> deleteHabit(int index) async {
    String habitId = habits[index].id;

    setState(() {
      habits.removeAt(index);
    });

    await firestoreService.deleteHabit(habitId);

    showMessage('Habit deleted');
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Habits')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create and manage your daily habits',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
            ),

            const SizedBox(height: 18),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: habitController,
                    decoration: const InputDecoration(
                      labelText: 'Habit name',
                      hintText: 'Example: Drink Water',
                    ),
                  ),

                  const SizedBox(height: 14),

                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value ?? 'General';
                      });
                    },
                  ),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: targetController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Target',
                            hintText: 'Example: 8',
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: TextField(
                          controller: unitController,
                          decoration: const InputDecoration(
                            labelText: 'Unit',
                            hintText: 'glasses, pages, km',
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  TextField(
                    controller: noteController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Note',
                      hintText: 'Example: Drink before evening',
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: addHabit,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Habit'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Habits',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${habits.length} habits',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(30),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : habits.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: Text(
                        'No habits created yet.\nAdd your first habit above.',
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
                      Color categoryColor = getCategoryColor(habit.category);

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
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${habit.category} • Target: ${habit.targetValue} ${habit.unit}',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                            onPressed: () {
                              deleteHabit(index);
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
}
