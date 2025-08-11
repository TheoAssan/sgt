import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // State variables for toggle switches
  bool _motionDetectionEnabled = true;
  bool _deviceAlertsEnabled = true;
  bool _automationAlertsEnabled = true;

  // State variables for sliders and dropdown
  double _sensitivity = 75.0;
  String _deactivationDelay = '5';
  bool _showDelayOptions = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF001F54),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Sensitivity and Automation Section
          _buildSectionHeader('Sensitivity and Automation'),
          SwitchListTile(
            title: Text('Enable Motion Detection'),
            value: _motionDetectionEnabled,
            onChanged: (value) {
              setState(() {
                _motionDetectionEnabled = value;
              });
            },
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildSensitivitySlider(),
                SizedBox(height: 16),
                _buildDeactivationDelaySelector(),
                SizedBox(height: 16),
                _buildListTile(
                  icon: Icons.schedule,
                  title: 'Schedules',
                  subtitle: 'Set time-based rules',
                  onTap: () {},
                ),
              ],
            ),
          ),

          // Notifications Section
          _buildSectionHeader('Notifications'),
          SwitchListTile(
            title: Text('Device Alerts'),
            subtitle: Text('Bulb disconnections, low battery'),
            value: _deviceAlertsEnabled,
            onChanged: (value) {
              setState(() {
                _deviceAlertsEnabled = value;
              });
            },
            secondary: Icon(Icons.notifications_active, color: Colors.red),
          ),
          SwitchListTile(
            title: Text('Automation Alerts'),
            subtitle: Text('When routines are triggered'),
            value: _automationAlertsEnabled,
            onChanged: (value) {
              setState(() {
                _automationAlertsEnabled = value;
              });
            },
            secondary: Icon(Icons.autorenew, color: Colors.green),
          ),
          _buildListTile(
            icon: Icons.notification_add,
            title: 'Notification Sounds',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSensitivitySlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sensitivity', style: TextStyle(fontSize: 18)),
        Slider(
          value: _sensitivity,
          min: 25,
          max: 100,
          divisions: 3,
          label: '${_sensitivity.toInt()}%',
          onChanged: (newValue) async {
            setState(() {
              _sensitivity = newValue;
            });
            // You can add your own logic here to handle sensitivity changes
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('25%', style: TextStyle(fontSize: 16)),
              Text('50%', style: TextStyle(fontSize: 16)),
              Text('75%', style: TextStyle(fontSize: 16)),
              Text('100%', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeactivationDelaySelector() {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Deactivation Delay',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$_deactivationDelay minutes',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(
                _showDelayOptions ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                color: Colors.grey,
              ),
            ],
          ),
          onTap: () {
            setState(() {
              _showDelayOptions = !_showDelayOptions;
            });
          },
        ),
        if (_showDelayOptions) ...[
          ...['3', '5', '10'].map((delay) => ListTile(
            contentPadding: EdgeInsets.only(left: 16, right: 16),
            title: Text('$delay minutes'),
            tileColor: _deactivationDelay == delay ? Colors.blue.withOpacity(0.1) : null,
            onTap: () async {
              setState(() {
                _deactivationDelay = delay;
                _showDelayOptions = false;
              });
              // You can add your own logic here to handle delay changes
            },
          )),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF001F54),
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Color(0xFF001F54)),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}