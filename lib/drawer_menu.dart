// lib/drawer_menu.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Import other necessary screens here

class DrawerMenu extends StatelessWidget {
  const DrawerMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              'Rehan School',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.dashboard),
            title: Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
              // If not already on dashboard, navigate to it
              // Navigator.pushReplacementNamed(context, '/dashboard');
            },
          ),
          ListTile(
            leading: Icon(Icons.people),
            title: Text('Users'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to Users screen
              // Navigator.pushNamed(context, '/users');
            },
          ),
          ListTile(
            leading: Icon(Icons.assignment),
            title: Text('Assignments'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to Assignments screen
              // Navigator.pushNamed(context, '/assignments');
            },
          ),
          ListTile(
            leading: Icon(Icons.school),
            title: Text('Students'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to Students screen
              // Navigator.pushNamed(context, '/students');
            },
          ),
          ListTile(
            leading: Icon(Icons.attach_money),
            title: Text('Student Fees'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to Student Fees screen
              // Navigator.pushNamed(context, '/student_fees');
            },
          ),
          ListTile(
            leading: Icon(Icons.exit_to_app),
            title: Text('Logout'),
            onTap: () async {
              bool? confirm = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text("Logout"),
                    content: Text("Are you sure you want to logout?"),
                    actions: [
                      TextButton(
                        child: Text("Cancel"),
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                      TextButton(
                        child: Text("Logout"),
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                    ],
                  );
                },
              );

              if (confirm == true) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
    );
  }
}