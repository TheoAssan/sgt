import 'package:flutter/material.dart';
import 'dart:math';
import 'sidebar.dart';
import 'power_consumption.dart';
import 'mqtt.dart'; // Import the real service
import 'dart:async'; // Import for StreamSubscription

void main() {
  runApp(const MaterialApp(home: HomePage()));
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  bool lightIsOn = false;
  bool _isSidebarOpen = false;
  bool _isConnected = false; // <-- Add this
  bool _pendingToggle = false;
  bool _pendingTargetState = false;
  late AnimationController _controller;
  late AnimationController _sidebarController;
  late Animation<double> _sweepAnimation;
  late AdafruitIOService mqttService; // Add this
  StreamSubscription<bool>? _lightStateSub;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _sweepAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(_controller);

    _sidebarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    mqttService = AdafruitIOService(
      showNotification: (msg) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(top: 40, left: 10, right: 10),
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );

    // Auto-connect on startup
    _autoConnect();

    // Listen to light state changes from MQTT
    _lightStateSub = mqttService.lightStateStream.listen((isOn) {
      if (mounted) {
        // Only update if the device state disagrees with the optimistic state
        if (_pendingToggle && isOn == _pendingTargetState) {
          _pendingToggle = false;
          // No correction needed, UI already matches
        } else if (isOn != lightIsOn) {
          setState(() {
            lightIsOn = isOn;
            final newBegin = isOn ? 0.0 : 1.0;
            final newEnd = isOn ? 1.0 : 0.0;
            _sweepAnimation = Tween<double>(begin: newBegin, end: newEnd).animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
            )..addListener(() {
                setState(() {});
              });
            _controller.forward(from: 0);
          });
        }
      }
    });
  }

  Future<void> _autoConnect() async {
    try {
      bool connected = await mqttService.connect();
      if (mounted) {
        setState(() {
          _isConnected = connected;
        });
      }
    } catch (e) {
      // Error notification already handled in mqttService
    }
  }

  void _showDisconnectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect'),
        content: const Text('Are you sure you want to disconnect from MQTT?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              mqttService.disconnect();
              setState(() {
                _isConnected = false;
              });
              Navigator.of(context).pop();
            },
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _sidebarController.dispose();
    _lightStateSub?.cancel();
    super.dispose();
  }

  void toggleLight() {
    final wasOn = lightIsOn;
    final newBegin = wasOn ? 1.0 : 0.0;
    final newEnd = wasOn ? 0.0 : 1.0;

    _sweepAnimation = Tween<double>(begin: newBegin, end: newEnd).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    )..addListener(() {
        setState(() {});
      });

    _controller.forward(from: 0);

    setState(() {
      lightIsOn = !lightIsOn;
      _pendingToggle = true;
      _pendingTargetState = lightIsOn;
    });

    // Send MQTT command to ESP32
    if (_isConnected) {
      final cmd = lightIsOn ? "LIGHT ON(MANUAL)" : "LIGHT OFF(MANUAL)";
      mqttService.publish("TeslaOw/feeds/ld2410c-feeds.light-state", cmd);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Not connected to MQTT"),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(top: 40, left: 10, right: 10),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
      if (_isSidebarOpen) {
        _sidebarController.forward();
      } else {
        _sidebarController.reverse();
      }
    });
  }

  Widget _buildConnectButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _isConnected ? Colors.white : const Color(0xFF001F54),
          foregroundColor: _isConnected ? const Color(0xFF001F54) : Colors.white,
          side: const BorderSide(
            color: Color(0xFF001F54),
            width: 2,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () async {
          if (_isConnected) {
            _showDisconnectDialog();
          } else {
            await _autoConnect();
          }
        },
        child: Text(
          _isConnected ? 'Disconnect' : 'Connect',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _isConnected ? const Color(0xFF001F54) : Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Sidebar(mqttService: mqttService),
      backgroundColor: const Color.fromARGB(255, 231, 230, 230),
      appBar: AppBar(
        backgroundColor: const Color(0xFF001F54),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Spacer(),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'SMARTGLOW ',
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  TextSpan(
                    text: 'GT',
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.w600,
                      color: Colors.amber,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildPowerCard(),
                    _buildCircularToggle(),
                    _buildConnectButton(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPowerCard() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            transitionDuration: Duration(milliseconds: 500),
            pageBuilder: (context, animation, secondaryAnimation) => PowerConsumptionPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              final scale = Tween<double>(begin: 0.9, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
              );
              return ScaleTransition(
                scale: scale,
                child: child,
              );
            },
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 235, 235, 235),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(color: const Color.fromARGB(255, 179, 177, 177), blurRadius: 2, offset: const Offset(0, 4)),
          ],
        ),
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Room Consumption', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600, color: Color(0xFF001F54))),
            const SizedBox(height: 2),
            const Text('8‑watt smart light', style: TextStyle(fontSize: 14, color: Colors.black)),
            const SizedBox(height: 35),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPowerMetric(icon: Icons.flash_on, value: '5 kWh', label: 'This week'),
                _buildPowerMetric(icon: Icons.electrical_services, value: '120 kWh', label: 'Total'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPowerMetric({required IconData icon, required String value, required String label}) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF001F54),
            borderRadius: BorderRadius.circular(90),
          ),
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 24, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.black)),
          ],
        ),
      ],
    );
  }

  Widget _buildCircularToggle() {
    const double dialSize = 230;
    const double strokeWidth = 15;

    return GestureDetector(
      onTap: toggleLight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(dialSize, dialSize),
            painter: RingPainter(
              strokeWidth: strokeWidth,
              color: Colors.grey.shade400,
              sweepFraction: 1.0,
            ),
          ),
          CustomPaint(
            size: const Size(dialSize, dialSize),
            painter: RingPainter(
              strokeWidth: strokeWidth,
              color: const Color(0xFF001F54),
              sweepFraction: _sweepAnimation.value,
            ),
          ),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 400),
            opacity: lightIsOn ? 1.0 : 0.5,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 400),
              scale: lightIsOn ? 1.05 : 0.9,
              child: Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lightbulb,
                      size: lightIsOn ? 55 : 50,
                      color: lightIsOn ? Colors.amber : Colors.grey,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lightIsOn ? 'ON' : 'OFF',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RingPainter extends CustomPainter {
  final double strokeWidth;
  final double sweepFraction;
  final Color color;

  RingPainter({
    required this.strokeWidth,
    required this.sweepFraction,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final sweepAngle = 2 * pi * sweepFraction;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: size.center(Offset.zero), 
      radius: size.width / 2 - strokeWidth / 2),
      -pi / 2,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}