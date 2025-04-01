import 'package:flutter/material.dart';
// import 'package:provider/provider.dart'; // Remove provider
import 'package:flutter_solidart/flutter_solidart.dart'; // Add solidart
import 'package:intl/intl.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';
import '../stores/auth_store.dart'; // Use AuthStore
import '../stores/message_store.dart'; // Use MessageStore
// import '../services/auth_service.dart';
// import '../services/message_service.dart';
import '../models/message_model.dart';
import '../widgets/new_message_dialog.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Fetch messages on initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.get<MessageStore>().fetchMessages();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.get<MessageStore>().fetchMessages();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshing messages...')),
              );
            },
          ),
        ],
      ),
      body: const _MessagesScreenContent(),
      floatingActionButton: FloatingActionButton(
        // Use context.get to access the store for the FAB action
        onPressed: () => _showSendMessageDialog(context),
        child: const Icon(Icons.chat),
      ),
    );
  }

  // Moved dialog showing logic here to access context easily
  void _showSendMessageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const NewMessageDialog(),
    ); // No need to manually refresh, store handles it after send
  }
}

// Extracted content into a separate widget for better organization
class _MessagesScreenContent extends StatelessWidget {
  const _MessagesScreenContent();

  Future<void> _handleRefresh(BuildContext context) async {
    // Call fetchMessages on the store
    await context.get<MessageStore>().fetchMessages();
  }

  void _openChat(BuildContext context, String partnerEmail,
      List<Message> conversationMessages) {
    // Get the actual User object for the current user if available
    final currentUser = context.get<AuthStore>().currentUser();
    if (currentUser == null) return; // Should not happen if logged in

    // Combine received messages with potentially sent messages (if backend supported it)
    // For now, conversationMessages only contains received messages from partnerEmail.
    // We need the full conversation history for the ChatScreen.

    // --- Backend Limitation Workaround --- ///
    // Since we only have received messages grouped by sender, we pass these.
    // The ChatScreen will need modification to handle this limitation or
    // ideally, the backend/MessageStore would provide the full thread.
    /// --- End Workaround --- ///

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          recipientEmail: partnerEmail,
          // Pass the messages received FROM this partner.
          // ChatScreen needs adjustment to understand this context.
          initialMessages: conversationMessages,
        ),
      ),
    );
    // No manual refresh needed here, polling or returning from chat might trigger updates.
  }

  @override
  Widget build(BuildContext context) {
    // Use SignalBuilder to react to loading state
    return SignalBuilder(
      signal: context.get<MessageStore>().isLoading,
      builder: (context, isLoading, _) {
        if (isLoading && context.get<MessageStore>().messages().isEmpty) {
          // Show loading only if messages are empty initially
          return Center(
            child: SleekCircularSlider(
              appearance: CircularSliderAppearance(
                size: 50,
                spinnerMode: true,
                animationEnabled: true,
                customColors: CustomSliderColors(
                  dotColor: Theme.of(context).colorScheme.primary,
                  progressBarColor: Theme.of(context).colorScheme.primary,
                  trackColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
            ),
          );
        }

        // Use SignalBuilder to react to message list changes
        return SignalBuilder(
          signal: context.get<MessageStore>().messagesByConversation,
          builder: (context, messagesBySender, _) {
            if (messagesBySender.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('No messages yet'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      // FAB handles this now
                      onPressed: () => const MessagesScreen()
                          ._showSendMessageDialog(context),
                      icon: const Icon(Icons.message),
                      label: const Text('Start a new conversation'),
                    ),
                  ],
                ),
              );
            }

            final senders = messagesBySender.keys.toList();

            // Use RefreshIndicator to allow manual refresh
            return RefreshIndicator(
              onRefresh: () => _handleRefresh(context),
              child: ListView.builder(
                itemCount: senders.length,
                itemBuilder: (ctx, index) {
                  final sender = senders[index];
                  final messages = messagesBySender[sender]!;
                  // Messages are sorted oldest first by store, get latest
                  final latestMessage = messages.last;

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(
                            sender.isNotEmpty ? sender[0].toUpperCase() : '?'),
                      ),
                      title: Text(sender),
                      subtitle: Text(
                        latestMessage.content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            DateFormat('HH:mm').format(latestMessage.createdAt),
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          // Displaying message count might be less useful now
                          // depending on how conversations are handled.
                          // Container(
                          //   padding: const EdgeInsets.all(8),
                          //   decoration: BoxDecoration(
                          //     color: Theme.of(context).primaryColor,
                          //     shape: BoxShape.circle,
                          //   ),
                          //   child: Text(
                          //     messages.length.toString(),
                          //     style: const TextStyle(
                          //       color: Colors.white,
                          //       fontSize: 12,
                          //     ),
                          //   ),
                          // ),
                        ],
                      ),
                      onTap: () => _openChat(context, sender, messages),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
