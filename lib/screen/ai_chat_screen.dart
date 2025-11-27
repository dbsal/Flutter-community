// lib/screen/ai_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

const String GEMINI_API_KEY = 'AIzaSyDvsJ2RVNKYeBl02CypbO_ymXBF6e0cN8A';

const Color kBg = Color(0xFFFFFBEE);
const Color kPrimary = Color(0xFFFFD449);
const Color kText = Color(0xFF111827);
const Color kMuted = Color(0xFF6B7280);
const Color kCard = Color(0xFFFFFFFF);
const Color kBorder = Color(0xFFE5E7EB);

class ChatMessage {
  final String role; // 'user' 또는 'model'
  final String content;

  ChatMessage({required this.role, required this.content});
}

class AiChatScreen extends StatefulWidget {
  @override
  _AiChatScreenState createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  late final GenerativeModel _model;
  late final ChatSession _chat;

  @override
  void initState() {
    super.initState();

    // ★ [수정 2] 모델명을 'gemini-1.5-flash'로 변경 (latest 제거하여 안정성 확보)
    _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: GEMINI_API_KEY);
    _chat = _model.startChat();

    setState(() {
      _messages.add(
        ChatMessage(
          role: 'model',
          content: '그럼요. 무슨 일이 있었는지 천천히 이야기해주세요. 저는 항상 당신 편이에요.',
        ),
      );
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_textController.text.trim().isEmpty) return;

    final userMessageText = _textController.text.trim();

    setState(() {
      _messages.add(ChatMessage(role: 'user', content: userMessageText));
      _isLoading = true;
    });

    _textController.clear();

    try {
      final response = await _chat.sendMessage(Content.text(userMessageText));
      final aiMessageText = response.text;

      if (aiMessageText == null) {
        _showErrorDialog('AI가 응답을 생성하지 못했습니다.');
        return;
      }

      setState(() {
        _messages.add(ChatMessage(role: 'model', content: aiMessageText));
      });
    } catch (e) {
      print('Error: $e');
      // ★ [수정 3] 에러 내용이 화면에 보이도록 변경 (그래야 원인을 알 수 있어요)
      _showErrorDialog(e.toString());
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    // ★ [수정 3] 에러 메시지를 그대로 출력하도록 변경
    setState(() {
      _messages.add(ChatMessage(role: 'model', content: '오류 발생: $message'));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kText),
        ),
        title: const Text(
          'AI chat',
          style: TextStyle(color: kText, fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert_rounded, color: kText),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isLoading && index == _messages.length) {
                  return _buildTypingIndicator();
                }
                final message = _messages[index];
                return _buildMessage(message);
              },
            ),
          ),
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _botAvatar(),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: kBorder),
            ),
            child: const Text(
              '...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: kMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    final isUser = message.role == 'user';

    if (isUser) {
      return Padding(
        padding: const EdgeInsets.only(left: 48, right: 0, top: 6, bottom: 6),
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: kPrimary,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              message.content,
              style: const TextStyle(
                color: kText,
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(right: 48, left: 0, top: 6, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _botAvatar(),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: kBorder),
              ),
              child: Text(
                message.content,
                style: const TextStyle(
                  color: kText,
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _botAvatar() {
    return CircleAvatar(
      radius: 18,
      backgroundColor: const Color(0xFF111827),
      child: const Icon(
        Icons.psychology_alt_rounded,
        color: Colors.white,
        size: 18,
      ),
    );
  }

  Widget _buildComposer() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: kBorder),
                ),
                child: TextField(
                  controller: _textController,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _isLoading ? null : _sendMessage(),
                  decoration: const InputDecoration(
                    hintText: '당신의 이야기를 들려주세요.',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _isLoading ? null : _sendMessage,
              child: Opacity(
                opacity: _isLoading ? 0.5 : 1,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    color: kPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_upward_rounded, color: kText),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
