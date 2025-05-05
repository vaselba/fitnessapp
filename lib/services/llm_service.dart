import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Message {
  final String role;
  final String content;
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
  
  LLMService();

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

  Future<String> sendMessage(String message, {List<Message>? previousMessages}) async {
    print('Starting sendMessage...'); // Debug log
    await _ensureApiKey();
    print('API key ensured, proceeding with request...'); // Debug log
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated');
    }

    String aiResponse;
    try {
      final List<Map<String, String>> messages = [
        {
          'role': 'system',
          'content': 'You are a fitness assistant focused on providing workout guidance and motivation. Provide me a very short answer. Reaosoning is not needed.'
        },
      ];

      if (previousMessages != null) {
        messages.addAll(
          previousMessages.map((msg) => {
            'role': msg.role,
            'content': msg.content,
          })
        );
      }

      messages.add({
        'role': 'user',
        'content': message,
      });

      print('Sending request to x.ai API...'); // Debug log
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'messages': messages,
          'model': 'grok-3-latest',
          'stream': false,
          'temperature': 0,
          // 'reasoning_effort': "low"
        }),
      );

      print('Response received. Status code: ${response.statusCode}'); // Debug log
      print('Response body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        aiResponse = responseData['choices'][0]['message']['content'] as String;
      } else {
        final errorBody = response.body.isNotEmpty ? jsonDecode(response.body) : null;
        final errorMessage = errorBody != null ? errorBody['error']?.toString() ?? 'Unknown error' : 'Empty response';
        throw Exception('API call failed with status code ${response.statusCode}: $errorMessage');
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
    } catch (e) {
      print('Error saving conversation: ${e.toString()}'); // Debug log
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

  Stream<List<Message>> getConversationStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated');
    }

    print('Starting conversation stream for user: ${user.uid}'); // Debug log

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('conversations')
        .orderBy('timestamp', descending: true)  // Changed to true to get newest first
        .limit(50)
        .snapshots()
        .map((snapshot) {
          print('Received snapshot with ${snapshot.docs.length} messages'); // Debug log
          return snapshot.docs.map((doc) {
            try {
              return Message.fromJson(doc.data());
            } catch (e) {
              print('Error parsing message: ${e.toString()}'); // Debug log
              rethrow;
            }
          }).toList();
        });
  }
}