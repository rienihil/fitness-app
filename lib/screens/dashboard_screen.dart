import 'package:flutter/material.dart';
import '../widgets/water_tracker.dart';
import '../widgets/progress_section.dart';
import '../widgets/step_counter_widget.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Dashboard")),
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
            ProgressSection(),
            SizedBox(height: 24),
            WaterTracker(),
          ],
        ),
      ),
    );
  }
}
