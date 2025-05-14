import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../data/yoga_data.dart';

class YogaDetailScreen extends StatefulWidget {
  final YogaPose pose;
  final int initialDurationInSeconds = 30;

  const YogaDetailScreen({required this.pose});

  @override
  _YogaDetailScreenState createState() => _YogaDetailScreenState();
}

class _YogaDetailScreenState extends State<YogaDetailScreen> {
  late VideoPlayerController _videoController;
  Timer? _timer;
  int _remainingTime = 0;
  bool _isRunning = false;
  final TextEditingController _durationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _remainingTime = widget.initialDurationInSeconds;
    _durationController.text = _remainingTime.toString();

    _videoController = VideoPlayerController.asset(widget.pose.videoAsset)
      ..initialize().then((_) {
        _videoController.setVolume(0);
        _videoController.setLooping(true);
        _videoController.play();
        setState(() {});
      });
  }

  void startTimer() {
    final inputSeconds = int.tryParse(_durationController.text) ?? widget.initialDurationInSeconds;
    setState(() {
      _remainingTime = inputSeconds;
      _isRunning = true;
    });

    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        timer.cancel();
        setState(() {
          _isRunning = false;
        });
      }
    });
  }

  void stopTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _videoController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.pose.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Video preview
            _videoController.value.isInitialized
                ? AspectRatio(
              aspectRatio: _videoController.value.aspectRatio,
              child: VideoPlayer(_videoController),
            )
                : CircularProgressIndicator(),

            SizedBox(height: 20),
            Text(widget.pose.description, style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),

            // Duration Input
            TextField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Duration (seconds)',
                border: OutlineInputBorder(),
              ),
              enabled: !_isRunning,
            ),
            SizedBox(height: 20),

            Text('$_remainingTime s',
                style: TextStyle(fontSize: 40, color: Colors.deepPurple, fontWeight: FontWeight.bold)),

            SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _isRunning ? null : startTimer,
                  icon: Icon(Icons.play_arrow),
                  label: Text('Start'),
                ),
                SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _isRunning ? stopTimer : null,
                  icon: Icon(Icons.stop),
                  label: Text('Stop'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}