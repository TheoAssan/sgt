import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'mqtt.dart';

class PowerConsumptionPage extends StatefulWidget {
  const PowerConsumptionPage({super.key});

  @override
  State<PowerConsumptionPage> createState() => _PowerConsumptionPageState();
}

class _PowerConsumptionPageState extends State<PowerConsumptionPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isDataLoading = true;
  
  // Power consumption data
  Map<String, double> _powerData = {
    'today': 0.0,
    'thisWeek': 0.0,
    'thisMonth': 0.0,
    'total': 0.0,
  };
  
  late AdafruitIOService mqttService;

  @override
  void initState() {
    super.initState();
    
    // Initialize MQTT service
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
    
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            // Inject CSS to reduce spacing without hiding content
            _controller.runJavaScript('''
              var style = document.createElement('style');
              style.innerHTML = `
                body { 
                  margin: 0 !important; 
                  padding: 0 !important; 
                }
                .container-fluid { 
                  padding: 5px !important; 
                }
                .row { 
                  margin: 0 !important; 
                }
                .col, .col-md-6, .col-lg-4 { 
                  padding: 5px !important; 
                }
                .card { 
                  margin: 5px !important; 
                  border-radius: 8px !important; 
                }
                .card-body { 
                  padding: 10px !important; 
                }
              `;
              document.head.appendChild(style);
            ''');
          },
        ),
      )
      ..loadRequest(Uri.parse('https://io.adafruit.com/TeslaOw/dashboards/power-consumption?kiosk=true'));
      
    // Load power data
    _loadPowerData();
  }

  Future<void> _loadPowerData() async {
    setState(() {
      _isDataLoading = true;
    });
    
    try {
      final powerStats = await mqttService.calculatePowerStats();
      setState(() {
        _powerData = powerStats;
        _isDataLoading = false;
      });
    } catch (e) {
      setState(() {
        _isDataLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load power data: $e'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(top: 40, left: 10, right: 10),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildModernPowerCard(String title, String value, IconData icon, List<Color> gradientColors) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.45,
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned(
            top: -10,
            right: -10,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                _isDataLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        value,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                const SizedBox(height: 4),
                Container(
                  width: 30,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalPowerCard(String title, String value, Color accentColor) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.45,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const Spacer(),
            _isDataLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                    ),
                  )
                : Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                      letterSpacing: 0.3,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  String _formatPowerValue(double value) {
    if (value < 1.0) {
      return '${(value * 1000).toStringAsFixed(0)} mWh';
    } else if (value < 1000) {
      return '${value.toStringAsFixed(1)} Wh';
    } else {
      return '${(value / 1000).toStringAsFixed(2)} kWh';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Power Consumption', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF001F54),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPowerData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: Column(
        children: [
          // Dashboard takes 45% of the space
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.45,
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
          // Spacing between WebView and power cards
          const SizedBox(height: 20),
          // Power cards section
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Top row - Today and This Week
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildModernPowerCard(
                        'Today',
                        _formatPowerValue(_powerData['today']!),
                        Icons.today,
                        [const Color(0xFF001F54), const Color(0xFF001F54).withOpacity(0.8)],
                      ),
                      _buildModernPowerCard(
                        'This Week',
                        _formatPowerValue(_powerData['thisWeek']!),
                        Icons.calendar_view_week,
                        [const Color(0xFF001F54), const Color(0xFF001F54).withOpacity(0.8)],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Bottom row - This Month and Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildModernPowerCard(
                        'This Month',
                        _formatPowerValue(_powerData['thisMonth']!),
                        Icons.calendar_month,
                        [const Color(0xFF001F54), const Color(0xFF001F54).withOpacity(0.8)],
                      ),
                      _buildModernPowerCard(
                        'Total',
                        _formatPowerValue(_powerData['total']!),
                        Icons.analytics,
                        [const Color(0xFF001F54), const Color(0xFF001F54).withOpacity(0.8)],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}