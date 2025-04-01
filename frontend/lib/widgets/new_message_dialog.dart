import 'package:flutter/material.dart';
// import 'package:provider/provider.dart'; // Remove provider
import 'package:flutter_solidart/flutter_solidart.dart'; // Add solidart
import 'package:sleek_circular_slider/sleek_circular_slider.dart';
// import '../services/auth_service.dart'; // Use stores
// import '../services/message_service.dart';
import '../stores/message_store.dart'; // Use MessageStore
import '../stores/auth_store.dart'; // Use AuthStore
import '../screens/chat_screen.dart'; // Use ChatScreen
// Add Message model import

class NewMessageDialog extends StatefulWidget {
  const NewMessageDialog({super.key});

  @override
  State<NewMessageDialog> createState() => _NewMessageDialogState();
}

class _NewMessageDialogState extends State<NewMessageDialog> {
  final _formKey = GlobalKey<FormState>();
  final _recipientController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isLoading = false; // Keep local loading state for the dialog itself
  String? _error; // Keep local error state for the dialog
  bool _isSubmitting = false; // Flag to prevent double submissions

  @override
  void dispose() {
    _recipientController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _isSubmitting = true; // Set flag to prevent double submissions
    });

    try {
      // Get MessageStore
      final messageStore = context.get<MessageStore>();
      context.get<AuthStore>();

      // Debug logs (keep if useful)
      debugPrint('Sending message to: ${_recipientController.text}');
      debugPrint('Message content: ${_contentController.text}');

      // Create an optimistic message for immediate display

      // Call store action
      final success = await messageStore.sendMessage(
        _contentController.text,
        _recipientController.text,
      );

      if (success && mounted) {
        debugPrint('Message sent successfully via dialog');
        Navigator.of(context).pop(); // Close dialog

        // Navigate to chat screen without the optimistic message as it's already in the store
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              recipientEmail: _recipientController.text,
              initialMessages: const [], // Don't pass optimistic message, let store handle it
            ),
          ),
        );
      } else if (mounted) {
        setState(() {
          // Get error from the store
          _error = messageStore.error() ?? 'Failed to send message';
          _isLoading = false;
          _isSubmitting = false; // Reset submission flag on error
        });
        debugPrint('Error sending message (dialog): $_error');
      }
    } catch (e) {
      if (mounted) {
        // Check mounted before setState
        setState(() {
          _error = 'An unexpected error occurred: $e';
          _isLoading = false;
          _isSubmitting = false; // Reset submission flag on exception
        });
      }
      debugPrint('Exception while sending message (dialog): $e');
    } finally {
      // Ensure loading is false even if mounted check fails mid-try block
      if (_isLoading && mounted) {
        setState(() {
          _isLoading = false;
          // Note: we don't reset _isSubmitting here since we're either navigating away or have already reset it
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // No need to get store here unless reading initial state
    return AlertDialog(
      title: const Text('Start New Conversation'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _recipientController,
              decoration: const InputDecoration(
                labelText: 'Recipient Email',
                hintText: 'user@example.com',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofocus: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter recipient email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Message',
                hintText: 'Type your message here...',
                prefixIcon: Icon(Icons.message),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _isLoading
                  ? null
                  : _sendMessage(), // Prevent submit while loading
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a message';
                }
                return null;
              },
            ),
            // Use local _error state for dialog feedback
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: Theme.of(context).colorScheme.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!, // Use local error
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _sendMessage,
          icon: _isLoading // Use local loading state
              ? SleekCircularSlider(
                  appearance: CircularSliderAppearance(
                    size: 20,
                    spinnerMode: true,
                    animationEnabled: true,
                    customColors: CustomSliderColors(
                      dotColor: Colors.white,
                      progressBarColor: Colors.white,
                      trackColor: Colors.white.withAlpha(77),
                    ),
                  ),
                )
              : const Icon(Icons.send),
          label: const Text('Send'),
        ),
      ],
    );
  }
}
