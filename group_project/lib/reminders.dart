import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tasktracker/add_reminder.dart';
import 'routine.dart';
import 'timer.dart';
import 'settings.dart';

class ReminderApp extends StatelessWidget {
  const ReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const RemindersPage(),
    );
  }
}

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  List<bool> isActive = [false, true, true, false];
  bool _showDelete = false; // Add this to control delete mode

  // Function to delete a reminder by its Firestore document ID
  Future<void> _deleteReminder(String reminderId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('reminders')
        .doc(reminderId)
        .delete();
  }

  // Add this function to store a reminder for the current user
  Future<void> _addReminder({
    required String title,
    required String subtitle,
    required String time,
    required bool isActive,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not logged in");

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('reminders')
        .add({
      'title': title,
      'subtitle': subtitle,
      'time': time,
      'isActive': isActive,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Function to update the isActive field for a reminder
  Future<void> _toggleReminderActive(String reminderId, bool currentValue) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('reminders')
        .doc(reminderId)
        .update({'isActive': !currentValue});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Reminders",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddReminderPage()),
              );
            },
          ),
          IconButton(
            icon: Icon(
              _showDelete ? Icons.cancel : Icons.delete_outline,
              color: Colors.black,
            ),
            tooltip: _showDelete ? 'Hide Delete Buttons' : 'Show Delete Buttons',
            onPressed: () {
              setState(() {
                _showDelete = !_showDelete;
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseAuth.instance.currentUser == null
              ? null
              : FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .collection('reminders')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No reminders yet."));
            }
            final reminders = snapshot.data!.docs;
            return ListView.builder(
              itemCount: reminders.length,
              itemBuilder: (context, index) {
                final reminderDoc = reminders[index];
                final reminder = reminderDoc.data();
                return buildReminderCard(
                  title: reminder['title'] ?? '',
                  subtitle: reminder['subtitle'] ?? '',
                  time: reminder['time'] ?? '',
                  isActive: reminder['isActive'] ?? true,
                  reminderId: reminderDoc.id,
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.star), label: "Routine"),
          BottomNavigationBarItem(icon: Icon(Icons.timer), label: "Timer"),
          BottomNavigationBarItem(icon: Icon(Icons.alarm), label: "Reminders"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TasksPage()),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TimerPage()),
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

  Widget buildReminderCard({
    required String title,
    required String subtitle,
    required String time,
    required bool isActive,
    required String reminderId,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 14)),
            ],
          ),
          Row(
            children: [
              Text(time, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 12),
              _showDelete
                  ? IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Delete Reminder',
                      onPressed: () async {
                        await _deleteReminder(reminderId);
                      },
                    )
                  : Switch(
                      value: isActive,
                      onChanged: (val) {
                        _toggleReminderActive(reminderId, isActive);
                      },
                    ),
            ],
          ),
        ],
      ),
    );
  }
}
