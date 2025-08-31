import 'package:flutter/material.dart';
import '../services/fcm_service.dart';

/// Widget for testing FCM notifications
/// 
/// This widget provides a UI for sending test notifications
/// with customizable item names and expiry days.
class TestNotificationWidget extends StatefulWidget {
  const TestNotificationWidget({super.key});

  @override
  State<TestNotificationWidget> createState() => _TestNotificationWidgetState();
}

class _TestNotificationWidgetState extends State<TestNotificationWidget> {
  final FCMService _fcmService = FCMService.instance;
  final TextEditingController _itemController = TextEditingController(text: 'Tomatoes');
  final TextEditingController _daysController = TextEditingController(text: '2');
  
  bool _isSending = false;
  String? _lastResult;

  @override
  void dispose() {
    _itemController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.notifications_active,
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Test Notifications',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Description
            Text(
              'Send a test expiry notification to your device',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Item name input
            TextField(
              controller: _itemController,
              decoration: InputDecoration(
                labelText: 'Item Name',
                hintText: 'e.g., Tomatoes, Milk, Bread',
                prefixIcon: const Icon(Icons.shopping_basket),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Days left input
            TextField(
              controller: _daysController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Days Left',
                hintText: 'e.g., 1, 2, 3',
                prefixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Preview section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notification Preview:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Title: "Your ${_itemController.text.isEmpty ? 'Item' : _itemController.text} is expiring soon!"',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Body: "Only ${_daysController.text.isEmpty ? '0' : _daysController.text} days left. Use it before it spoils."',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Data: { "item": "${_itemController.text}", "days_left": "${_daysController.text}" }',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Send button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSending ? null : _sendTestNotification,
                icon: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(_isSending ? 'Sending...' : 'Send Test Alert'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            
            // Result display
            if (_lastResult != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _lastResult!.startsWith('✅') ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _lastResult!.startsWith('✅') ? Colors.green[200]! : Colors.red[200]!,
                  ),
                ),
                child: Text(
                  _lastResult!,
                  style: TextStyle(
                    color: _lastResult!.startsWith('✅') ? Colors.green[800] : Colors.red[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Info section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber[800], size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Testing Tips:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.amber[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Make sure notifications are enabled in device settings\n'
                    '• Test on a physical device (not simulator)\n'
                    '• Check Firebase Console for delivery status\n'
                    '• Notification may take a few seconds to appear',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber[800],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendTestNotification() async {
    if (_itemController.text.isEmpty || _daysController.text.isEmpty) {
      _showResult('❌ Please fill in both item name and days left');
      return;
    }

    setState(() {
      _isSending = true;
      _lastResult = null;
    });

    try {
      final success = await _fcmService.sendTestNotification(
        item: _itemController.text.trim(),
        daysLeft: _daysController.text.trim(),
      );

      if (success) {
        _showResult('✅ Test notification sent successfully! Check your device.');
      } else {
        _showResult('❌ Failed to send notification. Check console for details.');
      }
    } catch (e) {
      _showResult('❌ Error: $e');
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _showResult(String message) {
    setState(() {
      _lastResult = message;
    });

    // Also show a snackbar for immediate feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: message.startsWith('✅') ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}