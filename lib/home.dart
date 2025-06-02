import 'package:flutter/material.dart';
import 'dart:math';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  bool lightIsOn = true;
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  double _currentAngle = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _rotationAnimation = AlwaysStoppedAnimation(_currentAngle);
  }

void toggleLight() {
  final targetAngle = lightIsOn ? _currentAngle : _currentAngle + (2 * pi); // full spin when turning ON

  _rotationAnimation = Tween<double>(
    begin: _currentAngle,
    end: targetAngle,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut))
    ..addListener(() {
      setState(() {});
    })
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _currentAngle = targetAngle;
      }
    });

  _controller.forward(from: 0);
  setState(() {
    lightIsOn = !lightIsOn;
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 231, 230, 230),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreeting(),
              const SizedBox(height: 24.0),
              _buildPowerCard(),
              const SizedBox(height: 45.0),
              Center(child: _buildCircularToggle()),
              const SizedBox(height: 32.0),
              _buildRoomStatusRow(),
              const SizedBox(height: 32.0),
              _buildDataLogButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting() {
    return Container(
      child: const Text(
        'Hello, Tim',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
      )
    );
  }

  Widget _buildPowerCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 235, 235, 235),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: const Color.fromARGB(255, 179, 177, 177), blurRadius: 2, offset: const Offset(0, 4)),
        ]
      ),
      margin: const EdgeInsets.symmetric(vertical: 25),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Room Consumption',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const SizedBox(height: 2),
          const Text(
            '8‑watt smart light',
            style: TextStyle(fontSize: 14, color: Colors.black),
          ),
          const SizedBox(height: 35),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPowerMetric(icon: Icons.flash_on, value: '5 kWh', label: 'This month'),
              _buildPowerMetric(icon: Icons.electrical_services, value: '120 kWh', label: 'Total'),
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
            color: const Color.fromARGB(255, 37, 37, 37),
            borderRadius: BorderRadius.circular(90),
            // boxShadow: [
            //   BoxShadow(color: const Color.fromARGB(255, 28, 28, 28), blurRadius: 4, offset: const Offset(0, 2)),
            // ],
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
  const double dialSize = 250;
  const double strokeWidth = 20;

  return GestureDetector(
    onTap: toggleLight,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Transform.rotate(
          angle: _rotationAnimation.value,
          child: CustomPaint(
            size: const Size(dialSize, dialSize),
            painter: RingPainter(
              strokeWidth: strokeWidth,
              color: lightIsOn ? Colors.amber : Colors.grey,
              gapAngle: lightIsOn ? 0 : 40, // full circle if ON, gap if OFF
            ),
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
                color: Colors.transparent, // NO background glow
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lightbulb,
                    size: lightIsOn ? 48 : 40,
                    color: lightIsOn ? Colors.amber : Colors.grey,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lightIsOn ? 'ON' : 'OFF',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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


  Widget _buildRoomStatusRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Room Status',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(3, (index) {
            return Container(
              width: 100,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Center(
                child: Icon(
                  Icons.circle,
                  size: 32,
                  color: Colors.grey,
                ),
              ),
            );
          }),
        ),
      ],
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
        child: const Text(
          'Data Log',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// 🎨 Painter for the rotating ring with a gap
class RingPainter extends CustomPainter {
  final double strokeWidth;
  final double gapAngle; // in degrees
  final Color color;

  RingPainter({
    required this.strokeWidth,
    required this.gapAngle,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final startAngle = gapAngle * pi / 180;
    final sweepAngle = (360 - gapAngle) * pi / 180;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: size.center(Offset.zero), radius: size.width / 2 - strokeWidth / 2),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
