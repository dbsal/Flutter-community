// lib/screens/ai_chat_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// API 키 (보안을 위해 실제 앱에서는 이렇게 코드에 직접 넣으면 안 됩니다)
const String OPENAI_API_KEY = 'YOUR_API_KEY_HERE';

// OpenAI API로 보낼 메시지 형식
class ChatMessage {
  final String role; // 'user' 또는 'assistant'
  final String content;

  ChatMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() {
    return {'role': role, 'content': content};
  }
}

class AiChatScreen extends StatefulWidget {
  @override
  _AiChatScreenState createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = []; // 대화 내역 저장
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // AI가 먼저 인사하도록 초기 메시지 추가
    setState(() {
      _messages.add(
        ChatMessage(
          role: 'assistant',
          content: '안녕하세요. 오늘 어떤 감정을 느끼셨나요? 편하게 이야기해주세요.',
        ),
      );
    });
  }

  // 메시지 전송 및 AI 응답 받기
  Future<void> _sendMessage() async {
    if (_textController.text.isEmpty) return;

    final userMessage = ChatMessage(
      role: 'user',
      content: _textController.text,
    );

    setState(() {
      _messages.add(userMessage); // 사용자가 보낸 메시지 추가
      _isLoading = true;
    });

    _textController.clear(); // 입력창 비우기

    try {
      // (1) API 요청 준비
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $OPENAI_API_KEY',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo', // (2) 선택하신 모델
          // (3) 대화 내역 전체를 API에 전송
          'messages': _messages.map((msg) => msg.toJson()).toList(),
        }),
      );

      // (4) 응답 처리
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final aiMessageContent = data['choices'][0]['message']['content'];

        final aiMessage = ChatMessage(
          role: 'assistant',
          content: aiMessageContent,
        );
        setState(() {
          _messages.add(aiMessage); // AI 응답 메시지 추가
        });
      } else {
        // 에러 처리
        print('API Error: ${response.statusCode}');
        print('API Body: ${response.body}');
        _showErrorDialog('API 오류가 발생했습니다. (코드: ${response.statusCode})');
      }
    } catch (e) {
      // 네트워크 오류 등
      print('Error: $e');
      _showErrorDialog('오류가 발생했습니다: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    setState(() {
      _messages.add(
        ChatMessage(role: 'assistant', content: '죄송합니다. 오류가 발생했어요.'),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('AI 채팅')),
      body: Column(
        children: [
          // (5) 채팅 내역 (ListView)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              reverse: false, // 아래부터 쌓이도록 (false가 위부터 쌓임)
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                bool isUser = message.role == 'user';
                return _buildChatBubble(message.content, isUser);
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          // (6) 메시지 입력창
          _buildTextInput(),
        ],
      ),
    );
  }

  // 채팅 말풍선 UI
  Widget _buildChatBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: Text(text),
      ),
    );
  }

  // 메시지 입력창 UI
  Widget _buildTextInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: '메시지 입력...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
              onSubmitted: (value) => _sendMessage(),
            ),
          ),
          SizedBox(width: 8.0),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: _isLoading ? null : _sendMessage, // 로딩 중이면 비활성화
          ),
        ],
      ),
    );
  }
}
