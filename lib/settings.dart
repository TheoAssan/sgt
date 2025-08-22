import 'package:flutter/material.dart';
import 'mqtt.dart'; // Import MQTT service
import 'dart:async'; // Import for StreamSubscription

class SettingsPage extends StatefulWidget {
  final AdafruitIOService? mqttService; // Add MQTT service parameter
  
  const SettingsPage({super.key, this.mqttService});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // State variables for toggle switches
  bool _motionDetectionEnabled = true;
  bool _automationAlertsEnabled = true;

  // State variables for sliders and dropdown
  double _sensitivity = 75.0;
  String _deactivationDelay = '5';
  bool _showDelayOptions = false;
  
  // Stream subscription for override feed
  StreamSubscription<String>? _overrideFeedSub;
  
  // Loading state for initial fetch
  bool _isLoadingOverrideState = true;

  @override
  void initState() {
    super.initState();
    // Listen to override feed changes
    _setupOverrideFeedListener();
    // Fetch current override state
    _fetchCurrentOverrideState();
  }

  void _fetchCurrentOverrideState() async {
    if (widget.mqttService != null) {
      try {
        // Fetch the latest value from the override feed
        final history = await widget.mqttService!.fetchOverrideHistory(maxResults: 1);
        if (history.isNotEmpty && mounted) {
          final latestValue = history.first['value'] as String;
          final clean = latestValue.trim().toUpperCase();
          setState(() {
            if (clean == 'ON') {
              _motionDetectionEnabled = true;
            } else if (clean == 'OFF') {
              _motionDetectionEnabled = false;
            }
            _isLoadingOverrideState = false;
          });
        } else {
          setState(() {
            _isLoadingOverrideState = false;
          });
        }
      } catch (e) {
        // If fetch fails, keep the default state
        print('Failed to fetch override state: $e');
        if (mounted) {
          setState(() {
            _isLoadingOverrideState = false;
          });
        }
      }
    } else {
      setState(() {
        _isLoadingOverrideState = false;
      });
    }
  }

  void _setupOverrideFeedListener() {
    if (widget.mqttService != null) {
      // Listen to override feed changes
      _overrideFeedSub = widget.mqttService!.overrideStream.listen((text) {
        if (mounted) {
          final clean = text.trim().toUpperCase();
          setState(() {
            if (clean == 'ON') {
              _motionDetectionEnabled = true;
            } else if (clean == 'OFF') {
              _motionDetectionEnabled = false;
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _overrideFeedSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: Color(0xFF001F54),
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      backgroundColor: Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Automation Section
            _buildSectionCard(
              title: 'Automation',
              icon: Icons.auto_awesome,
              children: [
                _buildMotionDetectionToggle(),
                SizedBox(height: 24),
                _buildSensitivitySlider(),
                SizedBox(height: 24),
                _buildDeactivationDelaySelector(),
              ],
            ),
            
            SizedBox(height: 20),
            
            // Notifications Section
            _buildSectionCard(
              title: 'Notifications',
              icon: Icons.notifications,
              children: [
                _buildAutomationAlertsToggle(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF001F54).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Color(0xFF001F54),
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF001F54),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildMotionDetectionToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: SwitchListTile(
        title: Text(
          'Enable Motion Detection',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF001F54),
          ),
        ),
        subtitle: Text(
          'Control motion-based automation',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        value: _motionDetectionEnabled,
        onChanged: _isLoadingOverrideState ? null : (value) {
          setState(() {
            _motionDetectionEnabled = value;
          });
          // Send override command to MQTT
          _sendMotionDetectionOverride(value);
        },
        activeColor: Color(0xFF001F54),
        secondary: _isLoadingOverrideState
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                ),
              )
            : Icon(
                _motionDetectionEnabled ? Icons.motion_photos_on : Icons.motion_photos_off,
                color: _motionDetectionEnabled ? Colors.green : Colors.grey,
                size: 24,
              ),
      ),
    );
  }

  Widget _buildAutomationAlertsToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: SwitchListTile(
        title: Text(
          'Automation Alerts',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF001F54),
          ),
        ),
        subtitle: Text(
          'When routines are triggered',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        value: _automationAlertsEnabled,
        onChanged: (value) {
          setState(() {
            _automationAlertsEnabled = value;
          });
        },
        activeColor: Color(0xFF001F54),
        secondary: Icon(
          Icons.autorenew,
          color: Colors.green,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildSensitivitySlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sensitivity',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF001F54),
          ),
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Color(0xFF001F54),
                  inactiveTrackColor: Colors.grey[300],
                  thumbColor: Color(0xFF001F54),
                  overlayColor: Color(0xFF001F54).withOpacity(0.2),
                  valueIndicatorColor: Color(0xFF001F54),
                  valueIndicatorTextStyle: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Slider(
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
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('25%', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    Text('50%', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    Text('75%', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    Text('100%', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeactivationDelaySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Deactivation Delay',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF001F54),
          ),
        ),
        SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text(
                  '$_deactivationDelay minutes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF001F54),
                  ),
                ),
                subtitle: Text(
                  'Time before motion detection deactivates',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                trailing: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF001F54).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _showDelayOptions ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Color(0xFF001F54),
                  ),
                ),
                onTap: () {
                  setState(() {
                    _showDelayOptions = !_showDelayOptions;
                  });
                },
              ),
              if (_showDelayOptions) ...[
                Divider(height: 1, color: Colors.grey[200]),
                ...['3', '5', '10'].map((delay) => ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(
                    '$delay minutes',
                    style: TextStyle(
                      fontSize: 16,
                      color: _deactivationDelay == delay ? Color(0xFF001F54) : Colors.grey[700],
                      fontWeight: _deactivationDelay == delay ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: _deactivationDelay == delay
                      ? Icon(Icons.check, color: Color(0xFF001F54))
                      : null,
                  tileColor: _deactivationDelay == delay ? Color(0xFF001F54).withOpacity(0.05) : null,
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
          ),
        ),
      ],
    );
  }

  // New method to send motion detection override
  void _sendMotionDetectionOverride(bool enabled) {
    if (widget.mqttService != null) {
      final topic = '${widget.mqttService!.username}/feeds/ld2410c-feeds.override';
      final payload = enabled ? 'ON' : 'OFF';
      
      try {
        widget.mqttService!.publish(topic, payload);
        
        // Show success feedback to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Motion detection ${enabled ? 'enabled' : 'disabled'}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      } catch (e) {
        // Show error feedback if MQTT publish fails
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update motion detection: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        
        // Revert the toggle if publish failed
        setState(() {
          _motionDetectionEnabled = !enabled;
        });
      }
    } else {
      // Show error if MQTT service is not available
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('MQTT service not available. Please check your connection.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      
      // Revert the toggle if MQTT service is not available
      setState(() {
        _motionDetectionEnabled = !enabled;
      });
    }
  }
}