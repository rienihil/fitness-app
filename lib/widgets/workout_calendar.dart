import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:convert';

class WorkoutCalendar extends StatefulWidget {
  const WorkoutCalendar({super.key});

  @override
  State<WorkoutCalendar> createState() => _WorkoutCalendarState();

  static Future<void> markTodayWorkoutDone(String workoutName) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);

    final jsonString = prefs.getString('workoutDays') ?? '{}';
    final Map<String, dynamic> rawMap = json.decode(jsonString);
    final Map<String, List<String>> days = rawMap.map(
          (key, value) => MapEntry(key, List<String>.from(value)),
    );

    final todayList = days[today] ?? [];
    if (!todayList.contains(workoutName)) {
      todayList.add(workoutName);
      days[today] = todayList;
    }

    await prefs.setString('workoutDays', json.encode(days));
  }
}


class _WorkoutCalendarState extends State<WorkoutCalendar> {
  Map<String, List<String>> _completedWorkouts = {};
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _loadWorkoutData();
  }

  Future<void> _loadWorkoutData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('workoutDays') ?? '{}';
    final Map<String, dynamic> rawMap = json.decode(jsonString);
    setState(() {
      _completedWorkouts = rawMap.map(
            (key, value) => MapEntry(key, List<String>.from(value)),
      );
    });
  }

  Color _getDayColor(DateTime day) {
    final key = _formatDate(day);
    final hasWorkouts = (_completedWorkouts[key]?.isNotEmpty ?? false);
    return hasWorkouts ? Colors.green : Colors.grey.shade300;
  }

  String _formatDate(DateTime date) => date.toIso8601String().substring(0, 10);

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
    });
    _showWorkoutDetails(selectedDay);
  }

  void _showWorkoutDetails(DateTime day) {
    final key = _formatDate(day);
    final workouts = _completedWorkouts[key] ?? [];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Тренировки $key"),
        content: workouts.isEmpty
            ? Text("Нет выполненных тренировок.")
            : Column(
          mainAxisSize: MainAxisSize.min,
          children: workouts.map((w) => Text("- $w")).toList(),
        ),
        actions: [
          TextButton(
            child: Text("ОК"),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  "Training calendar",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.refresh),
                  tooltip: "Refresh",
                  onPressed: _loadWorkoutData,
                )
              ],
            ),
            SizedBox(height: 12),
            TableCalendar(
              firstDay: DateTime.utc(2025, 1, 1),
              lastDay: DateTime.utc(2025, 12, 31),
              focusedDay: DateTime.now(),
              selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
              onDaySelected: _onDaySelected,
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  return Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getDayColor(day),
                    ),
                    child: Text(
                      '${day.day}',
                      style: TextStyle(color: Colors.white),
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
}