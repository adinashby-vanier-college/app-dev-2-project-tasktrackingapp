import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'add_task.dart';
import 'settings.dart';
import 'timer.dart';
import 'reminders.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  String selectedFilter = 'All Tasks';
  int _selectedIndex = 0;
  bool _showDelete = false; 
  String _quote = "Loading motivation...";

  Stream<QuerySnapshot<Map<String, dynamic>>>? _tasksStream;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _tasksStream = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('tasks')
          .orderBy('createdAt', descending: true)
          .snapshots();
    }
    _fetchMotivationalQuote();
  }

  Future<void> _fetchMotivationalQuote() async {
    try {
      final response = await http.get(Uri.parse('https://api.quotable.io/random'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _quote = "${data['content']} — ${data['author']}";
        });
      } else {
        setState(() {
          _quote = "Stay motivated and keep going!";
        });
      }
    } catch (e) {
      setState(() {
        _quote = "Stay motivated and keep going!";
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const TimerPage()),
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
  }

  Future<void> _toggleTaskComplete(String taskId, bool currentValue) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .doc(taskId)
        .update({'isComplete': !currentValue});
  }

  Future<void> _deleteTask(String taskId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .doc(taskId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: PopupMenuButton<String>(
          icon: const Icon(Icons.menu, color: Colors.black),
          onSelected: (value) {
            setState(() {
              selectedFilter = value;
            });
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem(value: 'All Tasks', child: Text('All Tasks')),
            const PopupMenuItem(value: 'Completed', child: Text('Completed')),
            const PopupMenuItem(value: 'Not done', child: Text('Not done')),
          ],
        ),
        title: Text(
          selectedFilter,
          style: const TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        actions: [
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
      body: Column(
        children: [
          // Motivational messages
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.format_quote, color: Colors.blue, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _quote,
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddTaskPage()),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text("Add Task"),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(150, 40),
              side: const BorderSide(color: Colors.black),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _tasksStream == null
                ? const Center(child: Text("No user logged in"))
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _tasksStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image,
                              size: 80,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              "Your journey starts\nwith a single step",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        );
                      }
                      List<QueryDocumentSnapshot<Map<String, dynamic>>> tasks = snapshot.data!.docs;
                      if (selectedFilter == 'Completed') {
                        tasks = tasks.where((doc) => doc['isComplete'] == true).toList();
                      } else if (selectedFilter == 'Not done') {
                        tasks = tasks.where((doc) => doc['isComplete'] != true).toList();
                      }
                      tasks.sort((a, b) {
                        final aComplete = a['isComplete'] == true ? 1 : 0;
                        final bComplete = b['isComplete'] == true ? 1 : 0;
                        return aComplete.compareTo(bComplete);
                      });
                      return ListView.builder(
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final taskDoc = tasks[index];
                          final task = taskDoc.data();
                          final isComplete = task['isComplete'] ?? false;
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              leading: IconButton(
                                icon: Icon(
                                  isComplete
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: isComplete ? Colors.green : Colors.grey,
                                ),
                                onPressed: () {
                                  _toggleTaskComplete(taskDoc.id, isComplete);
                                },
                              ),
                              title: Text(
                                task['title'] ?? '',
                                style: TextStyle(
                                  decoration: isComplete
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(task['description'] ?? ''),
                                  if (task['days'] != null)
                                    Text(
                                      (task['days'] as List).join(', '),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                ],
                              ),
                              trailing: _showDelete
                                  ? IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      tooltip: 'Delete Task',
                                      onPressed: () async {
                                        await _deleteTask(taskDoc.id);
                                      },
                                    )
                                  : null,
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.star_outline),
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
            icon: Icon(Icons.person_outline),
            label: "Profile",
          ),
        ],
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}



