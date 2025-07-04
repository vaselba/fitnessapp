import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';

import '../models/user_profile.dart';

part 'llm_service.g.dart';

@HiveType(typeId: 0)
class Message {
  @HiveField(0)
  final String role;
  @HiveField(1)
  final String content;
  @HiveField(2)
  final DateTime? timestamp;

  Message({
    required this.role, 
    required this.content,
    this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
    'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : null,
  };

  factory Message.fromJson(Map<String, dynamic> json) {
    DateTime? timestamp;
    final timestampData = json['timestamp'];
    
    if (timestampData is Timestamp) {
      timestamp = timestampData.toDate();
    } else if (timestampData is String) {
      timestamp = DateTime.tryParse(timestampData);
    }

    return Message(
      role: json['role'] as String,
      content: json['content'] as String,
      timestamp: timestamp,
    );
  }
}

class LLMService {
  static const String baseUrl = 'https://api.x.ai/v1/chat/completions';
  String? _apiKey;
  UserProfile? _userProfile;
  
  LLMService();

  String _createSystemPrompt() {
    if (_userProfile == null) {
      return 'Please respond only in Bulgarian. You are a fitness assistant focused on providing workout guidance and motivation. Provide me a very short answer. Reasoning is not needed.';
    }

    final profile = _userProfile!;
    final preferredWorkouts = profile.preferredWorkouts?.join(', ') ?? 'any type of workout';
    
    return '''You are a fitness assistant focused on providing personalized workout guidance and motivation. 
You are talking to ${profile.name}, a ${profile.age} year old person who:
- Has a fitness goal of: ${profile.fitnessGoal ?? 'general fitness'}
- Works out ${profile.workoutsPerWeek ?? 3} times per week
- Is at a ${profile.experienceLevel ?? 'beginner'} fitness level
- Prefers: $preferredWorkouts
${profile.healthConditions?.isNotEmpty == true ? '- Has the following health considerations: ${profile.healthConditions}' : ''}

Provide short, personalized answers considering their profile. Reasoning is not needed.
Use their name occasionally to make it more personal.
All responses should be in \\${profile.preferredLanguage}.''';
  }

  Future<void> _ensureUserProfile() async {
    if (_userProfile != null) return;
    _userProfile = await UserProfile.getCurrentUserProfile();
  }

  Future<void> _ensureApiKey() async {
    print('Starting API key retrieval...'); // Debug log
    if (_apiKey != null) {
      print('API key already cached'); // Debug log
      return;
    }
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated');
    }
    print('User authenticated: ${user.uid}'); // Debug log

    try {
      print('Attempting to fetch secret document...'); // Debug log
      final doc = await FirebaseFirestore.instance
          .collection('secrets')
          .doc('llm')
          .get();

      print('Document exists: ${doc.exists}'); // Debug log
      if (!doc.exists) {
        throw Exception('API configuration not found. Please ensure the API key is configured in Firestore.');
      }

      final apiKey = doc.data()?['apiKey'];
      print('API key retrieved: ${apiKey != null ? '[PRESENT]' : 'null'}'); // Debug log - don't print actual key
      if (apiKey == null || (apiKey is String && apiKey.isEmpty)) {
        throw Exception('Invalid API key configuration. Please check the API key in Firestore.');
      }

      _apiKey = apiKey as String;
    } catch (e) {
      print('Error during API key retrieval: ${e.toString()}'); // Debug log
      if (e is FirebaseException) {
        throw Exception('Failed to fetch API key: ${e.message}');
      }
      rethrow;
    }
  }

  // Returns all cached messages from Hive, newest first
  Future<List<Message>> getCachedMessages() async {
    final box = Hive.box<Message>('messages');
    final messages = box.values.toList();
    messages.sort((a, b) => (b.timestamp ?? DateTime(0)).compareTo(a.timestamp ?? DateTime(0)));
    return messages;
  }

  // Save a message to Hive
  Future<void> cacheMessage(Message message) async {
    final box = Hive.box<Message>('messages');
    await box.add(message);
  }

  // Save multiple messages to Hive (replace all)
  Future<void> cacheMessages(List<Message> messages) async {
    final box = Hive.box<Message>('messages');
    await box.clear();
    await box.addAll(messages);
  }

  // Sync all messages from Firestore to Hive (call on app start/login)
  Future<void> syncMessagesFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('conversations')
        .orderBy('timestamp', descending: false)
        .get();
    final messages = snapshot.docs.map((doc) => Message.fromJson(doc.data())).toList();
    await cacheMessages(messages);
  }

  Future<String> sendMessage(String message, {List<Message>? previousMessages}) async {
    await Future.wait([
      _ensureApiKey(),
      _ensureUserProfile(),
    ]);
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated');
    }

    String aiResponse;
    try {
      final List<Map<String, String>> messages = [
        {
          'role': 'system',
          'content': _createSystemPrompt()
        },
      ];

      print('Processing previous messages. Count: ${previousMessages?.length ?? 0}'); // Debug log

      // Handle previous conversation context if available
      if (previousMessages != null && previousMessages.isNotEmpty) {
        // Reverse the messages since they come in descending order from Firestore
        final sortedMessages = List<Message>.from(previousMessages.reversed);
        
        // Create pairs of messages (user + assistant responses)
        List<List<Message>> messagePairs = [];
        for (int i = 0; i < sortedMessages.length - 1; i += 2) {
          if (i + 1 < sortedMessages.length &&
              sortedMessages[i].role == 'user' && 
              sortedMessages[i + 1].role == 'assistant') {
            messagePairs.add([sortedMessages[i], sortedMessages[i + 1]]);
          }
        }

        // Take last 5 pairs if available
        if (messagePairs.isNotEmpty) {
          final recentPairs = messagePairs.length > 5 
              ? messagePairs.sublist(messagePairs.length - 5) 
              : messagePairs;
          
          print('Adding ${recentPairs.length} message pairs to context'); // Debug log
          
          // Add message pairs in chronological order
          for (final pair in recentPairs) {
            messages.add({
              'role': 'user',
              'content': pair[0].content,
            });
            messages.add({
              'role': 'assistant',
              'content': pair[1].content,
            });
            print('Added pair - User: ${pair[0].content.substring(0, min(20, pair[0].content.length))}...');
          }
        }
      }

      // Add the current user message
      messages.add({
        'role': 'user',
        'content': message,
      });

      print('Final messages in request: ${messages.length}'); // Debug log

      // Debug print of the complete API request body
      final requestBody = {
        'messages': messages,
        'model': 'grok-3-mini',
        'stream': false,
        'temperature': 0.23,
        'reasoning_effort': "low"
      };
      print('API Request Body: ${jsonEncode(requestBody)}'); // Debug log
      
      print('Sending request to x.ai API with ${messages.length} messages...'); // Debug log
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode(requestBody),
      );

      print('Response received. Status code: \\${response.statusCode}'); // Debug log
      // Decode response body as UTF-8 to handle Cyrillic properly
      final decodedBody = utf8.decode(response.bodyBytes);
      print('Response body: \\${decodedBody}'); // Debug log

      if (response.statusCode == 200) {
        final responseData = jsonDecode(decodedBody);
        aiResponse = responseData['choices'][0]['message']['content'] as String;
      } else {
        final errorBody = decodedBody.isNotEmpty ? jsonDecode(decodedBody) : null;
        final errorMessage = errorBody != null ? errorBody['error']?.toString() ?? 'Unknown error' : 'Empty response';
        throw Exception('API call failed with status code \\${response.statusCode}: \\${errorMessage}');
      }
    } catch (e) {
      print('Error during message send: ${e.toString()}'); // Debug log
      if (e is FormatException) {
        throw Exception('Invalid response format from AI service');
      } else if (e is http.ClientException) {
        throw Exception('Network error while connecting to AI service');
      }
      rethrow;
    }

    // Try to save the conversation but don't fail if it doesn't work
    try {
      print('Attempting to save conversation...'); // Debug log
      await _saveConversation(message, aiResponse);
      print('Conversation saved successfully'); // Debug log
      // Cache both user and AI messages locally
      await cacheMessage(Message(role: 'user', content: message, timestamp: DateTime.now()));
      await cacheMessage(Message(role: 'assistant', content: aiResponse, timestamp: DateTime.now()));
    } catch (e) {
      print('Error saving conversation: \\${e.toString()}'); // Debug log
      // Don't rethrow - we still want to return the AI response even if saving fails
    }

    return aiResponse;
  }

  Future<void> _saveConversation(String userMessage, String aiResponse) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No authenticated user found when saving conversation'); // Debug log
      return;
    }

    try {
      final conversationsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('conversations');

      // Add user message
      await conversationsRef.add(Message(
        role: 'user',
        content: userMessage,
        timestamp: DateTime.now(),
      ).toJson());

      // Add AI response
      await conversationsRef.add(Message(
        role: 'assistant',
        content: aiResponse,
        timestamp: DateTime.now(),
      ).toJson());
    } catch (e) {
      print('Error in _saveConversation: ${e.toString()}'); // Debug log
      rethrow;
    }
  }

  // Use local cache for conversation stream
  Stream<List<Message>> getConversationStream() async* {
    final box = Hive.box<Message>('messages');
    yield box.values.toList().reversed.toList();
    // Optionally, listen to box changes for live updates
    await for (final _ in box.watch()) {
      yield box.values.toList().reversed.toList();
    }
  }
}