import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/message_notifier.dart';

class MessageCenterScreen extends StatefulWidget {
  const MessageCenterScreen({super.key});

  @override
  State<MessageCenterScreen> createState() => _MessageCenterScreenState();
}

class _MessageCenterScreenState extends State<MessageCenterScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MessageNotifier>().loadMessages();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nachrichtenzentrum'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        toolbarHeight: 50,
        actions: [
          Consumer<MessageNotifier>(
            builder: (context, messageNotifier, child) {
              if (messageNotifier.messages.isEmpty) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.delete_sweep),
                tooltip: 'Alle Nachrichten löschen',
                onPressed: () {
                  _showClearAllDialog(context);
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<MessageNotifier>(
        builder: (context, messageNotifier, child) {
          if (!messageNotifier.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final messages = messageNotifier.messages;

          return messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.mail_outline,
                        size: 64,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      const Text('Keine Nachrichten vorhanden'),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return Card(
                      margin:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: Icon(
                          _getIconForType(message.type),
                          color: _getColorForType(message.type),
                        ),
                        title: Text(
                          message.title,
                          style: TextStyle(
                            fontWeight: message.isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              message.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${message.timestamp.day}.${message.timestamp.month}.${message.timestamp.year} ${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'mark') {
                              if (message.isRead) {
                                context
                                    .read<MessageNotifier>()
                                    .markAsUnread(message.id);
                              } else {
                                context
                                    .read<MessageNotifier>()
                                    .markAsRead(message.id);
                              }
                            } else if (value == 'delete') {
                              _deleteMessage(context, message.id);
                            }
                          },
                          itemBuilder: (BuildContext context) =>
                              <PopupMenuEntry<String>>[
                            PopupMenuItem<String>(
                              value: 'mark',
                              child: Text(message.isRead
                                  ? 'Als ungelesen markieren'
                                  : 'Als gelesen markieren'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Text('Löschen'),
                            ),
                          ],
                        ),
                        onTap: () {
                          if (!message.isRead) {
                            context
                                .read<MessageNotifier>()
                                .markAsRead(message.id);
                          }
                          _showMessageDetails(context, message);
                        },
                      ),
                    );
                  },
                );
        },
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'warning':
        return Icons.warning;
      case 'error':
        return Icons.error;
      case 'info':
      default:
        return Icons.info;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'warning':
        return Colors.orange;
      case 'error':
        return Colors.red;
      case 'info':
      default:
        return Colors.blue;
    }
  }

  void _showMessageDetails(BuildContext context, Message message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(message.title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message.content),
                const SizedBox(height: 16),
                Text(
                  'Typ: ${message.type}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  '${message.timestamp.day}.${message.timestamp.month}.${message.timestamp.year} ${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Schließen'),
            ),
          ],
        );
      },
    );
  }

  void _deleteMessage(BuildContext context, String messageId) {
    context.read<MessageNotifier>().deleteMessage(messageId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nachricht gelöscht'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showClearAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Alle Nachrichten löschen'),
          content:
              const Text('Sind Sie sicher, dass Sie alle Nachrichten löschen möchten?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () {
                context.read<MessageNotifier>().clearAll();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Alle Nachrichten gelöscht'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Löschen'),
            ),
          ],
        );
      },
    );
  }
}
