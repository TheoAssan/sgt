import 'package:flutter/material.dart';
import 'package:sgt/settings.dart'; 

// ignore: use_key_in_widget_constructors
class Sidebar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  accountName: Text('Tim'),
                  accountEmail: Text('User 1'),
                  currentAccountPicture: Center(
                    child: ClipOval(
                      child: Image.asset(
                        'assets/user.jpg',
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFF001F54),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.home, color: Color(0xFF001F54)),
                  title: Text('Home', style: TextStyle(color: Colors.black)),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.settings, color: Color(0xFF001F54)),
                  title: Text('Settings', style: TextStyle(color: Colors.black)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        transitionDuration: Duration(milliseconds: 450),
                        pageBuilder: (context, animation, secondaryAnimation) => SettingsPage(),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          const begin = Offset(1.0, 0.0); // Slide from right
                          const end = Offset.zero;
                          const curve = Curves.ease;
                          final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                          return SlideTransition(
                            position: animation.drive(tween),
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.list_alt, color: Color(0xFF001F54)),
                  title: Text('Data Log', style: TextStyle(color: Colors.black)),
                  onTap: () {
                    // TODO: Add navigation to Data Log page
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.notifications, color: Color(0xFF001F54)),
                  title: Text('Notifications', style: TextStyle(color: Colors.black)),
                  onTap: () {
                    // TODO: Add navigation to Notifications page
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text('Log Out', style: TextStyle(color: Colors.red)),
            onTap: () {
              // TODO: Add log out functionality
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}