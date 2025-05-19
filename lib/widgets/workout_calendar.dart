import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:convert';

class WorkoutCalendar extends StatefulWidget {
  const WorkoutCalendar({super.key});

  @override
  State<WorkoutCalendar> createState() => _WorkoutCalendarState();

  /// Добавляет выполненную тренировку в список тренировок текущего дня
  static Future<void> markTodayWorkoutDone(String workoutName) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);

    final jsonString = prefs.getString('dailyLogs') ?? '{}';
    final Map<String, dynamic> logs = json.decode(jsonString);

    final dayData = logs[today] ?? {
      "steps": 0,
      "waterMl": 0,
      "workouts": [],
      "calories": 0,
      "protein": 0,
      "carbs": 0,
      "fat": 0,
      "synced": false,
    };

    final workouts = List<String>.from(dayData["workouts"] ?? []);
    if (!workouts.contains(workoutName)) {
      workouts.add(workoutName);
      dayData["workouts"] = workouts;
    }

    logs[today] = dayData;
    await prefs.setString('dailyLogs', json.encode(logs));
  }
}

class _WorkoutCalendarState extends State<WorkoutCalendar> {
  Map<String, dynamic> _dailyLogs = {};
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _loadWorkoutData();
  }

  Future<void> _loadWorkoutData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('dailyLogs') ?? '{}';
    final Map<String, dynamic> logs = json.decode(jsonString);
    setState(() {
      _dailyLogs = logs;
    });
  }

  Color _getDayColor(DateTime day) {
    final key = _formatDate(day);
    final workouts = _dailyLogs[key]?['workouts'];
    final hasWorkouts = (workouts != null && workouts is List && workouts.isNotEmpty);
    return hasWorkouts ? Colors.green : Colors.grey.shade300;
  }

  String _formatDate(DateTime date) => date.toIso8601String().substring(0, 10);

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
    });
    _showDayDetails(selectedDay);
  }

  void _showDayDetails(DateTime day) {
    final key = _formatDate(day);
    final data = _dailyLogs[key];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Данные за $key"),
        content: data == null
            ? const Text("Нет данных.")
            : Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Шаги: ${data['steps'] ?? 0}"),
            Text("Вода: ${data['waterMl'] ?? 0} мл"),
            Text("Калории: ${data['calories'] ?? 0}"),
            Text("Белки: ${data['protein'] ?? 0} г"),
            Text("Углеводы: ${data['carbs'] ?? 0} г"),
            Text("Жиры: ${data['fat'] ?? 0} г"),
            const SizedBox(height: 8),
            Text("Тренировки:"),
            if ((data['workouts'] as List).isEmpty)
              const Text(" - нет"),
            ...List<String>.from(data['workouts'] ?? []).map((w) => Text(" - $w")),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("ОК"),
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
                const Text(
                  "Training Calendar",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: "Обновить",
                  onPressed: _loadWorkoutData,
                )
              ],
            ),
            const SizedBox(height: 12),
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
                      style: const TextStyle(color: Colors.white),
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
