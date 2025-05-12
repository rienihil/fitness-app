import 'package:flutter/material.dart';

class WaterTracker extends StatefulWidget {
  @override
  _WaterTrackerState createState() => _WaterTrackerState();
}

class _WaterTrackerState extends State<WaterTracker> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Water Tracker", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: List.generate(8, (index) {
            final filled = index < count;
            return GestureDetector(
              onTap: () {
                setState(() {
                  count = index + 1;
                });
              },
              child: Icon(
                Icons.water_drop,
                color: filled ? Colors.blue : Colors.grey[300],
                size: 32,
              ),
            );
          }),
        ),
      ],
    );
  }
}
