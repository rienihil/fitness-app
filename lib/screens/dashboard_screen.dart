import 'package:flutter/material.dart';
import '../widgets/water_tracker.dart';
import '../widgets/step_counter_widget.dart';
import '../widgets/workout_calendar.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  void _handleReload(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Reconnecting.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dashboard"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Reconnect',
            onPressed: () => _handleReload(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Today’s Summary", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: const [
                  StepCounterWidget(),
                ],
              ),
            ),
            SizedBox(height: 24),
            WorkoutCalendar(),
            SizedBox(height: 24),
            WaterTracker(),
          ],
        ),
      ),
    );
  }
}