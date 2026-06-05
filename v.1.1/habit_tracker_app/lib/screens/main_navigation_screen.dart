import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'manage_habits_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int currentIndex = 0;

  int dashboardRefreshKey = 0;
  int manageRefreshKey = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      DashboardScreen(key: ValueKey(dashboardRefreshKey)),
      ManageHabitsScreen(key: ValueKey(manageRefreshKey)),
    ];

    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            currentIndex = index;

            if (index == 0) {
              dashboardRefreshKey++;
            }

            if (index == 1) {
              manageRefreshKey++;
            }
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.add_task), label: 'Manage'),
        ],
      ),
    );
  }
}
