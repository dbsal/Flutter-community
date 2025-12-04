import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const String GEMINI_API_KEY = 'AIzaSyDVjH_4If-URMTbc1OH08bt90YrvfMHKE8';

const Color kBg = Color(0xFFFFFBEE);
const Color kPrimary = Color(0xFFFFD449);
const Color kText = Color(0xFF111827);
const Color kMuted = Color(0xFF6B7280);
const Color kCard = Color(0xFFFFFFFF);
const Color kBorder = Color(0xFFE5E7EB);

class ChatMessage {
  final String role;
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
  int _userMessageCount = 0;

  late final GenerativeModel _model;
  late ChatSession _chat;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: GEMINI_API_KEY);
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    final user = _auth.currentUser;
    if (user == null) {
      _chat = _model.startChat();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('ai_chats')
          .orderBy('timestamp')
          .get();

      final history = <Content>[];
      int userMsgCount = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final role = data['role'] as String;
        final content = data['content'] as String;

        _messages.add(ChatMessage(role: role, content: content));

        if (role == 'user') {
          history.add(Content.text(content));
          userMsgCount++;
        } else {
          history.add(Content.model([TextPart(content)]));
        }
      }

      _userMessageCount = userMsgCount;
      _chat = _model.startChat(history: history);
    } catch (e) {
      print('대화 기록 불러오기 실패: $e');
      _chat = _model.startChat();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _saveMessage(String role, String content) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('ai_chats')
          .add({
            'role': role,
            'content': content,
            'timestamp': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print('메시지 저장 실패: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_textController.text.trim().isEmpty) return;

    // ★ 10회 제한 체크
    if (_userMessageCount >= 10) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('무료 사용량 초과'),
          content: const Text('이 이상은 유료결제입니다! 결제를 하시겠어요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // 결제 로직 연결 가능
              },
              child: const Text('결제하기'),
            ),
          ],
        ),
      );
      return;
    }

    final userMessageText = _textController.text.trim();
    _textController.clear();

    setState(() {
      _messages.add(ChatMessage(role: 'user', content: userMessageText));
      _isLoading = true;
      _userMessageCount++;
    });

    _saveMessage('user', userMessageText);

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

      // AI 응답 저장
      _saveMessage('model', aiMessageText);
    } catch (e) {
      print('Error: $e');
      _showErrorDialog(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resetChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('대화 초기화'),
        content: const Text('모든 대화 기록이 삭제되고 카운트가 초기화됩니다.\n계속하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('초기화', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user != null) {
        final snapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('ai_chats')
            .get();

        for (var doc in snapshot.docs) {
          await doc.reference.delete();
        }
      }

      setState(() {
        _messages.clear();
        _userMessageCount = 0;
        _chat = _model.startChat();
        _isLoading = false;
      });
    } catch (e) {
      print('초기화 실패: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
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
            onPressed: _resetChat,
            icon: const Icon(Icons.refresh_rounded, color: kText),
            tooltip: '대화 초기화',
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
