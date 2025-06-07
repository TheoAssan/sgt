import 'package:flutter/material.dart';
import 'dart:math';
import 'sidebar.dart';

void main() {
  runApp(const MaterialApp(home: HomePage()));
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  bool lightIsOn = true;
  bool _isSidebarOpen = false;
  late AnimationController _controller;
  late AnimationController _sidebarController;
  late Animation<double> _sweepAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _sweepAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(_controller);

    _sidebarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _sidebarController.dispose();
    super.dispose();
  }

  void toggleLight() {
    final newBegin = lightIsOn ? 1.0 : 0.0;
    final newEnd = lightIsOn ? 0.0 : 1.0;

    _sweepAnimation = Tween<double>(begin: newBegin, end: newEnd).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    )..addListener(() {
        setState(() {});
      });

    _controller.forward(from: 0);

    setState(() {
      lightIsOn = !lightIsOn;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Sidebar(),
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
                    _buildDataLogButton(context),
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
    return Container(
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
              _buildPowerMetric(icon: Icons.flash_on, value: '5 kWh', label: 'This month'),
              _buildPowerMetric(icon: Icons.electrical_services, value: '120 kWh', label: 'Total'),
            ],
          ),
        ],
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

  Widget _buildDataLogButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data Log pressed')),
          );
        },
        child: const Text('Data Log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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