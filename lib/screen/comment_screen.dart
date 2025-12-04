import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommentScreen extends StatefulWidget {
  final String postId;

  const CommentScreen({Key? key, required this.postId}) : super(key: key);

  @override
  _CommentScreenState createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _commentController = TextEditingController();

  String? _lastStreamErrorLog;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('ko', timeago.KoMessages());
    debugPrint('댓글 화면 진입 postId: ${widget.postId}');
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _logStreamErrorOnce(Object? error) {
    final msg = error?.toString() ?? 'unknown error';
    if (_lastStreamErrorLog == msg) return;
    _lastStreamErrorLog = msg;
    debugPrint('댓글 스트림 에러: $msg');
  }

  bool _isNetworkLikeError(Object? error) {
    final s = (error?.toString() ?? '').toLowerCase();
    return s.contains('unable to resolve host') ||
        s.contains('unknownhostexception') ||
        s.contains('unavailable');
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    final user = _auth.currentUser;

    if (text.isEmpty || user == null) return;

    _commentController.clear();

    try {
      await _firestore.collection('comment').add({
        'postId': widget.postId,
        'content': text,
        'authorId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('댓글 문서 저장 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('댓글 저장에 실패했습니다. 네트워크 상태를 확인해주세요.')),
        );
      }
      return;
    }

    try {
      await _firestore.collection('post').doc(widget.postId).update({
        'commentCount': FieldValue.increment(1),
      });

      await _firestore.collection('users').doc(user.uid).set({
        'commentCount': FieldValue.increment(1),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('commentCount 업데이트 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('댓글')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('comment')
                  .where('postId', isEqualTo: widget.postId)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  _logStreamErrorOnce(snapshot.error);

                  final isNetErr = _isNetworkLikeError(snapshot.error);
                  return Center(
                    child: Text(
                      isNetErr
                          ? '네트워크 연결이 불안정해요.\n와이파이/핫스팟 또는 에뮬레이터 인터넷을 확인해주세요.'
                          : '댓글을 불러오는 중 오류가 발생했습니다.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      '첫 번째 댓글을 남겨보세요 😊',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;

                    final content = data['content'] as String? ?? '';
                    final ts = data['timestamp'];

                    DateTime date;
                    if (ts is Timestamp) {
                      date = ts.toDate();
                    } else {
                      date = DateTime.now();
                    }

                    final timeAgo = timeago.format(date, locale: 'ko');

                    return ListTile(
                      title: Text(
                        content,
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        timeAgo,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      maxLines: null,
                      decoration: const InputDecoration(
                        hintText: '댓글을 입력하세요',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _commentController,
                    builder: (context, value, _) {
                      final isComposing = value.text.trim().isNotEmpty;

                      return GestureDetector(
                        onTap: isComposing ? _submitComment : null,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isComposing ? Colors.black : Colors.grey,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.send,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
