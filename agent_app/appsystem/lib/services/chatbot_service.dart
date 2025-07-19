import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

/// ChatBot Service that handles voice-to-text conversion and ChatGPT API integration
///
/// Features:
/// - Voice-to-text conversion using device microphone
/// - ChatGPT API integration for intelligent responses
/// - Real-time speech recognition
/// - Audio recording and processing
/// - Permission handling for microphone access
class ChatBotService {
  // TODO: Move to environment variables or secure configuration
  static const String _apiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: '', // Empty default - will need to be configured
  );
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';

  final SpeechToText _speechToText = SpeechToText();
  final AudioRecorder _audioRecorder = AudioRecorder();

  bool _isListening = false;
  bool _isRecording = false;
  String _lastWords = '';

  /// Initialize speech recognition
  Future<bool> initializeSpeech() async {
    try {
      // Request microphone permission
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        return false;
      }

      // Initialize speech to text
      final available = await _speechToText.initialize(
        onError: (error) => print('Speech recognition error: $error'),
        onStatus: (status) => print('Speech recognition status: $status'),
      );

      return available;
    } catch (e) {
      print('Error initializing speech recognition: $e');
      return false;
    }
  }

  /// Start listening for voice input
  Future<void> startListening({
    required Function(String text) onResult,
    required Function() onListeningStarted,
    required Function() onListeningStopped,
  }) async {
    if (_isListening) return;

    try {
      _isListening = true;
      onListeningStarted();

      await _speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            _lastWords = result.recognizedWords;
            onResult(_lastWords);
            stopListening();
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: 'ar_SA', // Arabic locale
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.confirmation,
        ),
      );
    } catch (e) {
      print('Error starting speech recognition: $e');
      _isListening = false;
      onListeningStopped();
    }
  }

  /// Stop listening for voice input
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speechToText.stop();
      _isListening = false;
    } catch (e) {
      print('Error stopping speech recognition: $e');
    }
  }

  /// Start recording audio
  Future<void> startRecording({
    required Function(String path) onRecordingStarted,
    required Function(String path) onRecordingStopped,
  }) async {
    if (_isRecording) return;

    try {
      // Request microphone permission
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw Exception('Microphone permission denied');
      }

      // Get temporary directory for audio file
      final tempDir = await getTemporaryDirectory();
      final audioPath =
          '${tempDir.path}/voice_message_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // Start recording
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: audioPath,
      );

      _isRecording = true;
      onRecordingStarted(audioPath);
    } catch (e) {
      print('Error starting audio recording: $e');
      rethrow;
    }
  }

  /// Stop recording audio
  Future<String?> stopRecording() async {
    if (!_isRecording) return null;

    try {
      final path = await _audioRecorder.stop();
      _isRecording = false;
      return path;
    } catch (e) {
      print('Error stopping audio recording: $e');
      _isRecording = false;
      return null;
    }
  }

  /// Send message to ChatGPT API
  Future<String> sendMessage(String message) async {
    // Check if API key is configured
    if (_apiKey.isEmpty) {
      return 'خطأ في التكوين: لم يتم تعيين مفتاح OpenAI API.\nConfiguration Error: OpenAI API key not set.';
    }
    
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content':
                  '''You are a helpful real estate assistant for a professional real estate agent in the UAE. 
              You can communicate in both Arabic and English. 
              You help with:
              - Property inquiries and information
              - Market analysis and trends
              - Client relationship management
              - Property valuation guidance
              - Legal and regulatory information
              - Investment advice
              
              Always be professional, helpful, and provide accurate information. 
              If you don't know something, say so rather than guessing.
              Respond in the same language as the user's message.''',
            },
            {'role': 'user', 'content': message},
          ],
          'max_tokens': 500,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('API request failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending message to ChatGPT: $e');
      return 'عذراً، حدث خطأ في الاتصال. يرجى المحاولة مرة أخرى.\nSorry, there was a connection error. Please try again.';
    }
  }

  /// Process voice input and get response
  Future<String> processVoiceInput({
    required Function(String text) onTranscription,
    required Function() onListeningStarted,
    required Function() onListeningStopped,
  }) async {
    try {
      await startListening(
        onResult: (text) async {
          onTranscription(text);
          if (text.isNotEmpty) {
            final response = await sendMessage(text);
            return response;
          }
        },
        onListeningStarted: onListeningStarted,
        onListeningStopped: onListeningStopped,
      );

      return '';
    } catch (e) {
      print('Error processing voice input: $e');
      return 'عذراً، حدث خطأ في معالجة الصوت. يرجى المحاولة مرة أخرى.\nSorry, there was an error processing the voice input. Please try again.';
    }
  }

  /// Check if currently listening
  bool get isListening => _isListening;

  /// Check if currently recording
  bool get isRecording => _isRecording;

  /// Get last recognized words
  String get lastWords => _lastWords;

  /// Dispose resources
  void dispose() {
    _speechToText.cancel();
    _audioRecorder.dispose();
  }
}

/// Chat message model
class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final MessageType type;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.type = MessageType.text,
  });
}

/// Message types
enum MessageType { text, voice, image }
