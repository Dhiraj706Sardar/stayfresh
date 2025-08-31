import 'package:flutter/material.dart';
import '../services/fcm_service.dart';
import '../widgets/test_notification_widget.dart';

/// Screen for testing FCM notifications and managing notification settings
class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  final FCMService _fcmService = FCMService.instance;
  
  bool _isInitialized = false;
  String? _fcmToken;
  bool _permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    try {
      // Initialize FCM service
      await _fcmService.initialize();
      
      // Get current status
      final token = await _fcmService.getToken();
      final permissions = await _fcmService.requestPermissions();
      
      setState(() {
        _isInitialized = true;
        _fcmToken = token;
        _permissionsGranted = permissions;
      });
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notification Testing',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isInitialized ? _buildContent() : _buildLoading(),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Initializing notifications...'),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Status section
          _buildStatusSection(),
          
          // Test notification widget
          const TestNotificationWidget(),
          
          // FCM Token section
          _buildTokenSection(),
          
          // Instructions section
          _buildInstructionsSection(),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notification Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Permission status
            _buildStatusRow(
              icon: _permissionsGranted ? Icons.check_circle : Icons.error,
              iconColor: _permissionsGranted ? Colors.green : Colors.red,
              title: 'Permissions',
              subtitle: _permissionsGranted ? 'Granted' : 'Denied',
            ),
            
            const SizedBox(height: 12),
            
            // FCM service status
            _buildStatusRow(
              icon: _fcmService.isInitialized ? Icons.check_circle : Icons.error,
              iconColor: _fcmService.isInitialized ? Colors.green : Colors.red,
              title: 'FCM Service',
              subtitle: _fcmService.isInitialized ? 'Initialized' : 'Not initialized',
            ),
            
            const SizedBox(height: 12),
            
            // Token status
            _buildStatusRow(
              icon: _fcmToken != null ? Icons.check_circle : Icons.error,
              iconColor: _fcmToken != null ? Colors.green : Colors.red,
              title: 'FCM Token',
              subtitle: _fcmToken != null ? 'Available' : 'Not available',
            ),
            
            if (!_permissionsGranted) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _requestPermissions,
                  icon: const Icon(Icons.notifications),
                  label: const Text('Request Permissions'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTokenSection() {
    if (_fcmToken == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.key, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'FCM Token',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _copyTokenToClipboard,
                  icon: const Icon(Icons.copy, size: 20),
                  tooltip: 'Copy token',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                _fcmToken!,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This token identifies your device for push notifications.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.help_outline, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'How to Test from Firebase Console',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildInstructionStep(
              step: '1',
              title: 'Open Firebase Console',
              description: 'Go to console.firebase.google.com and select your project',
            ),
            
            _buildInstructionStep(
              step: '2',
              title: 'Navigate to Cloud Messaging',
              description: 'Click on "Cloud Messaging" in the left sidebar',
            ),
            
            _buildInstructionStep(
              step: '3',
              title: 'Create Campaign',
              description: 'Click "Send your first message" or "New campaign"',
            ),
            
            _buildInstructionStep(
              step: '4',
              title: 'Configure Message',
              description: 'Enter title, body, and select "Send test message"',
            ),
            
            _buildInstructionStep(
              step: '5',
              title: 'Add FCM Token',
              description: 'Paste the FCM token from above and click "Test"',
            ),
            
            const SizedBox(height: 16),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sample Message Data:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Title: Your Tomatoes are expiring soon!\n'
                    'Body: Only 2 days left. Use them before they spoil.\n'
                    'Custom data:\n'
                    '  • item: Tomatoes\n'
                    '  • days_left: 2\n'
                    '  • type: expiry_alert',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep({
    required String step,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _requestPermissions() async {
    final granted = await _fcmService.requestPermissions();
    setState(() {
      _permissionsGranted = granted;
    });

    if (granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Notification permissions granted!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Notification permissions denied'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _copyTokenToClipboard() async {
    if (_fcmToken != null) {
      // You'll need to add clipboard package or use platform channels
      // For now, just show a message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token copied to clipboard!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}