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

  String _formatDate(DateTime date) => date.toIso8601String().substring(0, 10);

  Color _getDayColor(DateTime day) {
    final key = _formatDate(day);
    final data = _dailyLogs[key];
    if (data == null) return Colors.grey.shade200;

    final hasWorkouts = (data['workouts'] as List?)?.isNotEmpty ?? false;
    final steps = data['steps'] ?? 0;
    final water = data['waterMl'] ?? 0;

    if (hasWorkouts && steps > 3000 && water > 1000) {
      return Colors.green;
    } else if (hasWorkouts) {
      return Colors.orange;
    } else if (steps > 0 || water > 0) {
      return Colors.blueGrey;
    }
    return Colors.grey.shade200;
  }

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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: Colors.white,
        title: Text(
          "Данные за $key",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        content: data == null
            ? const Text("Нет данных.")
            : Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStat("🚶 Шаги", "${data['steps'] ?? 0}"),
            _buildStat("💧 Вода", "${data['waterMl'] ?? 0} мл"),
            _buildStat("🔥 Калории", "${data['calories'] ?? 0}"),
            _buildStat("🥚 Белки", "${data['protein'] ?? 0} г"),
            _buildStat("🍞 Углеводы", "${data['carbs'] ?? 0} г"),
            _buildStat("🥑 Жиры", "${data['fat'] ?? 0} г"),
            const SizedBox(height: 12),
            const Text("🏋️ Тренировки:",
                style: TextStyle(fontWeight: FontWeight.w600)),
            if ((data['workouts'] as List).isEmpty)
              const Text("– нет"),
            ...List<String>.from(data['workouts'] ?? [])
                .map((w) => Text("– $w")),
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

  Widget _buildStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
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
                ),
              ],
            ),
            if (_selectedDay != null) ...[
              const SizedBox(height: 8),
              Text(
                "Выбранная дата: ${_formatDate(_selectedDay!)}",
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
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
