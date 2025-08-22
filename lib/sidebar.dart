import 'package:flutter/material.dart';
import 'package:sgt/settings.dart';
import 'package:sgt/data_log.dart';
import 'package:sgt/power_consumption.dart';
import 'package:sgt/motiontracker.dart';
import 'package:sgt/mqtt.dart';

// ignore: use_key_in_widget_constructors
class Sidebar extends StatelessWidget {
  final AdafruitIOService? mqttService; // Add MQTT service parameter
  
  const Sidebar({super.key, this.mqttService});

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
                        pageBuilder: (context, animation, secondaryAnimation) => SettingsPage(mqttService: mqttService),
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
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        transitionDuration: Duration(milliseconds: 450),
                        pageBuilder: (context, animation, secondaryAnimation) => DataLogPage(),
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
                  leading: Icon(Icons.bolt, color: Color(0xFF001F54)),
                  title: Text('Power Consumption', style: TextStyle(color: Colors.black)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        transitionDuration: Duration(milliseconds: 450),
                        pageBuilder: (context, animation, secondaryAnimation) => PowerConsumptionPage(),
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
                  leading: Icon(Icons.motion_photos_on, color: Color(0xFF001F54)),
                  title: Text('Motion Tracker', style: TextStyle(color: Colors.black)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        transitionDuration: Duration(milliseconds: 450),
                        pageBuilder: (context, animation, secondaryAnimation) => MotionTrackerPage(),
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
              ],
            ),
          ),
          const Divider(
            height: 1,
            thickness: 1,
            indent: 16,
            endIndent: 16,
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 48.0),
            child: ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text('Log Out', style: TextStyle(color: Colors.red)),
              onTap: () async {
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Log Out'),
                    content: Text('Are you sure you want to log out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text('Log Out', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (shouldLogout == true) {
                  Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
                    '/login',
                    (Route<dynamic> route) => false,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}