import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tasktracker/main.dart';
import 'about_me.dart';
import 'contact_us.dart';
import 'routine.dart';
import 'timer.dart';
import 'reminders.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        currentIndex: 3, // Profile tab selected
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
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RemindersPage()),
            );
          }
        },
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 32),
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey.shade300,
                    child: const Icon(Icons.person, size: 40, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'John Doe',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              _buildMenuItem(context: context, title: 'About Me'),
              _buildMenuItem(context: context, title: 'Contact Us'),
              _buildMenuItem(context: context, title: 'Log Out'), 
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({required BuildContext context, required String title}) {
    return Column(
      children: [
        ListTile(
          title: Text(title),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () async {
            if (title == 'About Me') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutMeScreen()),
              );
            } else if (title == 'Contact Us') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ContactUsScreen()),
              );
            } else if (title == 'Log Out') {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => TaskTrackerHomePage()),
                (route) => false,
              );
            }
          },
        ),
        const Divider(height: 1),
      ],
    );
  }
}
