import 'package:flutter/material.dart';

class CalendarHeatmapWidget extends StatelessWidget {
  final DateTime selectedMonth;
  final DateTime selectedDate;
  final int totalHabits;
  final int Function(DateTime date) getCompletedCount;
  final String Function(DateTime date) getDateKey;
  final Function(DateTime date) onDateSelected;

  const CalendarHeatmapWidget({
    super.key,
    required this.selectedMonth,
    required this.selectedDate,
    required this.totalHabits,
    required this.getCompletedCount,
    required this.getDateKey,
    required this.onDateSelected,
  });

  Color getHeatmapColor(int completedCount) {
    if (totalHabits == 0 || completedCount == 0) {
      return const Color(0xFFEDEDED);
    }

    double ratio = completedCount / totalHabits;

    if (ratio < 0.34) {
      return const Color(0xFFC8E6C9);
    } else if (ratio < 0.67) {
      return const Color(0xFF81C784);
    } else {
      return const Color(0xFF2E7D32);
    }
  }

  Color getTextColor(int completedCount) {
    if (totalHabits == 0 || completedCount == 0) {
      return Colors.black87;
    }

    double ratio = completedCount / totalHabits;

    if (ratio >= 0.67) {
      return Colors.white;
    }

    return Colors.black87;
  }

  Widget buildLegendBox(Color color) {
    return Container(
      height: 14,
      width: 14,
      margin: const EdgeInsets.only(right: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
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

    int firstWeekday = DateTime(
      selectedMonth.year,
      selectedMonth.month,
      1,
    ).weekday;

    int emptyCellsBeforeMonth = firstWeekday - 1;

    int totalCells = emptyCellsBeforeMonth + daysInMonth;

    if (totalCells % 7 != 0) {
      totalCells += 7 - (totalCells % 7);
    }

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
              Icon(Icons.calendar_month, color: Color(0xFF2E7D32)),
              SizedBox(width: 8),
              Text(
                'Calendar Heatmap',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            'A monthly view of your habit consistency.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),

          const SizedBox(height: 18),

          Row(
            children: const [
              Expanded(
                child: Center(
                  child: Text(
                    'Mon',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Tue',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Wed',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Thu',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Fri',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Sat',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Sun',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          GridView.builder(
            itemCount: totalCells,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              int dayNumber = index - emptyCellsBeforeMonth + 1;

              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox();
              }

              DateTime date = DateTime(
                selectedMonth.year,
                selectedMonth.month,
                dayNumber,
              );

              int completedCount = getCompletedCount(date);

              bool isSelected = getDateKey(date) == getDateKey(selectedDate);

              return GestureDetector(
                onTap: () {
                  onDateSelected(date);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: getHeatmapColor(completedCount),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? Colors.black87 : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$dayNumber',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: getTextColor(completedCount),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Text(
                'Less',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),

              const SizedBox(width: 8),

              buildLegendBox(const Color(0xFFEDEDED)),
              buildLegendBox(const Color(0xFFC8E6C9)),
              buildLegendBox(const Color(0xFF81C784)),
              buildLegendBox(const Color(0xFF2E7D32)),

              const SizedBox(width: 8),

              Text(
                'More',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
