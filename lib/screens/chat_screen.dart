import 'package:flutter/material.dart';
import '../services/llm_service.dart';

class ChatScreen extends StatefulWidget {
  final String language;
  final LLMService llmService;

  const ChatScreen({
    super.key,
    required this.language,
    required this.llmService,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_updateSendButton);
  }

  @override
  void dispose() {
    _messageController.removeListener(_updateSendButton);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _updateSendButton() {
    setState(() {
      _canSend = _messageController.text.trim().isNotEmpty;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (!_canSend) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.llmService.sendMessage(_messageController.text);
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.language == 'Български'
                  ? 'Грешка при изпращане на съобщението: ${e.toString()}'
                  : 'Error sending message: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inDays > 0) {
      return widget.language == 'Български'
          ? 'преди ${difference.inDays} ${difference.inDays == 1 ? 'ден' : 'дни'}'
          : '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return widget.language == 'Български'
          ? 'преди ${difference.inHours} ${difference.inHours == 1 ? 'час' : 'часа'}'
          : '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return widget.language == 'Български'
          ? 'преди ${difference.inMinutes} ${difference.inMinutes == 1 ? 'минута' : 'минути'}'
          : '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    }
    return widget.language == 'Български' ? 'току-що' : 'just now';
  }

  Widget _buildMessageBubble(Message message) {
    final isUser = message.role == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Card(
          color: isUser 
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surface,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(isUser ? 12 : 4),
              topRight: Radius.circular(isUser ? 4 : 12),
              bottomLeft: const Radius.circular(12),
              bottomRight: const Radius.circular(12),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.content,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isUser
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (message.timestamp != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(message.timestamp!),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isUser
                          ? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7)
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          widget.language == 'Български'
              ? 'Как беше тренировката ти днес?'
              : 'How was your workout today?',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder<List<Message>>(
            stream: widget.llmService.getConversationStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    widget.language == 'Български'
                        ? 'Грешка при зареждане на съобщенията'
                        : 'Error loading messages',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final messages = snapshot.data!;
              if (messages.isEmpty) {
                return Center(
                  child: Text(
                    widget.language == 'Български'
                        ? 'Няма съобщения. Започнете разговор!'
                        : 'No messages. Start a conversation!',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                );
              }

              // Messages are already in reverse order from Firestore
              return ListView.separated(
                controller: _scrollController,
                itemCount: messages.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                itemBuilder: (context, index) => _buildMessageBubble(messages[index]),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: TextField(
            controller: _messageController,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: widget.language == 'Български'
                  ? 'Отговори тук...'
                  : 'Answer here...',
              suffixIcon: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(),
                    )
                  : IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _canSend ? _sendMessage : null,
                    ),
            ),
            maxLines: 3,
            onSubmitted: (_) => _canSend ? _sendMessage() : null,
          ),
        ),
      ],
    );
  }
}