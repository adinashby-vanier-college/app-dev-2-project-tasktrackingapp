import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'routine.dart';
import 'settings.dart';
import 'reminders.dart';
import '../main.dart'; 

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  int hours = 0;    
  int minutes = 0;  
  int seconds = 0;  
  Duration? _duration;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    hours = 0;
    minutes = 0;
    seconds = 0;
    _duration = null; 
  }

  @override
  void dispose() {
    _isRunning = false;
    super.dispose();
  }

  void _setQuickTime(int h, int m, int s) {
    setState(() {
      hours = h;
      minutes = m;
      seconds = s;
    });
  }

  void _startTimer() async {
    if (_isRunning) return;
    setState(() {
      _isRunning = true;
      _duration = Duration(hours: hours, minutes: minutes, seconds: seconds);
    });

    while (_duration!.inSeconds > 0 && _isRunning) {
      await Future.delayed(const Duration(seconds: 1));
      if (!_isRunning) break;
      setState(() {
        _duration = _duration! - const Duration(seconds: 1);
      });
    }

    if (_duration!.inSeconds == 0 && _isRunning) {
      _showTimerNotification();
      setState(() {
        _isRunning = false;
      });
    }
  }

  void _stopTimer() {
    setState(() {
      _isRunning = false;
    });
  }

  Future<void> _showTimerNotification() async {
    await flutterLocalNotificationsPlugin.show(
      0,
      'Timer Finished',
      'Your timer has ended!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel',
          'Reminders',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayTime = _duration != null
        ? "${_duration!.inHours.toString().padLeft(2, '0')}:${(_duration!.inMinutes % 60).toString().padLeft(2, '0')}:${(_duration!.inSeconds % 60).toString().padLeft(2, '0')}"
        : "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        ),
        title: const Text(
          "Timer",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            displayTime,
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPicker("Hours", 100, (val) => setState(() => hours = val)),
              _buildPicker("Minutes", 60, (val) => setState(() => minutes = val)),
              _buildPicker("Seconds", 60, (val) => setState(() => seconds = val)),
            ],
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _quickButton("00:10:00", 0, 10, 0),
              _quickButton("00:15:00", 0, 15, 0),
              _quickButton("00:30:00", 0, 30, 0),
            ],
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: 200,
            height: 50,
            child: ElevatedButton(
              onPressed: _isRunning ? _stopTimer : _startTimer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                _isRunning ? "Stop" : "Start",
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 1,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.star_border),
            label: "Routine",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: "Timer",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.alarm),
            label: "Reminders",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TasksPage()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RemindersPage()),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          }
        },
      ),
    );
  }

  Widget _buildPicker(String label, int max, Function(int) onSelected) {
    final List<int> values = List.generate(max, (i) => i);
    final List<int> extendedValues = List.generate(300, (i) => values[i % max]);

    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          SizedBox(
            height: 150,
            child: CupertinoPicker(
              itemExtent: 40,
              scrollController: FixedExtentScrollController(initialItem: 150),
              onSelectedItemChanged: (index) {
                onSelected(extendedValues[index]);
              },
              children: extendedValues.map((val) {
                return Center(
                  child: Text(
                    val.toString().padLeft(2, '0'),
                    style: const TextStyle(fontSize: 22),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickButton(String text, int h, int m, int s) {
    return ElevatedButton(
      onPressed: () => _setQuickTime(h, m, s),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[300],
        foregroundColor: Colors.black,
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(30),
      ),
      child: Text(text),
    );
  }
}
