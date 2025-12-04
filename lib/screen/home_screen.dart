import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:community/screen/new_post_screen.dart';
import 'package:community/screen/comment_screen.dart';

const Color kBg = Color(0xFFFFFBEE);
const Color kPrimary = Color(0xFFFFD449);
const Color kText = Color(0xFF111827);
const Color kMuted = Color(0xFF6B7280);
const Color kCard = Color(0xFFFFFFFF);
const Color kBorder = Color(0xFFE5E7EB);

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 게시글 목록
  List<DocumentSnapshot> _posts = [];

  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  final int _limit = 5;

  // true: 최신순, false: 댓글순
  bool _isLatestSort = true;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('ko', timeago.KoMessages());
    _fetchPosts(isRefresh: true);
  }

  Future<void> _fetchPosts({bool isRefresh = false}) async {
    if (_isLoading) return;

    final bool isInitialLoad = _posts.isEmpty && _lastDocument == null;

    _isLoading = true;
    if (!isRefresh || isInitialLoad) {
      if (mounted) setState(() {});
    }

    try {
      Query query = _firestore.collection('post');

      if (_isLatestSort) {
        query = query.orderBy('timestamp', descending: true);
      } else {
        query = query.orderBy('commentCount', descending: true);
      }

      if (!isRefresh && _lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      query = query.limit(_limit);
      final snapshot = await query.get();
      final newDocs = snapshot.docs;

      if (!mounted) return;
      setState(() {
        if (isRefresh) {
          _posts = List<DocumentSnapshot>.from(newDocs);
          _lastDocument = newDocs.isNotEmpty ? newDocs.last : null;
          _hasMore = newDocs.length == _limit;
        } else {
          if (newDocs.isNotEmpty) {
            _posts.addAll(newDocs);
            _lastDocument = newDocs.last;
            _hasMore = newDocs.length == _limit;
          } else {
            _hasMore = false;
          }
        }
        _isLoading = false;
      });
    } catch (e) {
      print('게시글 불러오기 오류: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onRefresh() async {
    await _fetchPosts(isRefresh: true);
  }

  Future<void> _openNewPost() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NewPostScreen()),
    );
    if (result == true) _onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,

      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  _sortPill(
                    label: '최신순',
                    selected: _isLatestSort,
                    onTap: () {
                      if (_isLatestSort) return;
                      setState(() => _isLatestSort = true);
                      _fetchPosts(isRefresh: true);
                    },
                  ),
                  const SizedBox(width: 10),
                  _sortPill(
                    label: '댓글순',
                    selected: !_isLatestSort,
                    onTap: () {
                      if (!_isLatestSort) return;
                      setState(() => _isLatestSort = false);
                      _fetchPosts(isRefresh: true);
                    },
                  ),

                  const Spacer(),

                  GestureDetector(
                    onTap: _openNewPost,
                    child: Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: kPrimary,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, size: 16, color: kText),
                          SizedBox(width: 4),
                          Text(
                            '감정 기록',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: kText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 게시글 리스트
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  itemCount: _posts.length + 1,
                  itemBuilder: (context, index) {
                    if (index < _posts.length) {
                      return _buildPostCard(_posts[index]);
                    }

                    if (_isLoading) {
                      return const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (!_hasMore) {
                      return const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Center(
                          child: Text(
                            '마지막 게시글입니다.',
                            style: TextStyle(color: kMuted),
                          ),
                        ),
                      );
                    }

                    return Center(
                      child: OutlinedButton(
                        onPressed: () => _fetchPosts(isRefresh: false),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: kBorder),
                          foregroundColor: kText,
                          shape: const StadiumBorder(),
                        ),
                        child: const Text('더보기'),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sortPill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? kPrimary : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: selected ? kText : kMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildPostCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final content = (data['content'] as String?) ?? '';
    final emotions = (data['emotions'] as List<dynamic>?) ?? [];
    final int commentCount = (data['commentCount'] as int?) ?? 0;

    String? timeAgo;
    final ts = data['timestamp'];
    DateTime? date;
    if (ts is Timestamp) {
      date = ts.toDate();
    } else if (ts is String) {
      date = DateTime.tryParse(ts);
    }
    if (date != null) {
      timeAgo = timeago.format(date, locale: 'ko');
    }

    final String heading = content.trim().isEmpty ? doc.id : content.trim();
    final parts = heading.split('\n');
    final title = parts.first;
    final snippet = (parts.length > 1) ? parts.skip(1).join('\n') : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(color: kBg, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                '사용자',
                style: const TextStyle(
                  fontSize: 13,
                  color: kMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (timeAgo != null)
                Text(
                  timeAgo,
                  style: const TextStyle(fontSize: 12, color: kMuted),
                ),
            ],
          ),
          const SizedBox(height: 10),

          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: kText,
            ),
          ),
          if (snippet.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              snippet,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: kMuted, height: 1.35),
            ),
          ],

          const SizedBox(height: 12),

          if (emotions.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: emotions
                  .take(6)
                  .map<Widget>((e) => _buildEmotionChip(e.toString()))
                  .toList(),
            ),

          const SizedBox(height: 12),

          Row(
            children: [
              GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CommentScreen(postId: doc.id),
                    ),
                  );
                  _onRefresh();
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 18,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '댓글 $commentCount',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CommentScreen(postId: doc.id),
                    ),
                  );
                  _onRefresh();
                },
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: kText,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionChip(String emotion) {
    final chipColor = _getEmotionColor(emotion);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.35),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        emotion,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: kText,
        ),
      ),
    );
  }

  Color _getEmotionColor(String emotion) {
    switch (emotion) {
      case '행복':
        return const Color(0xFFAEE571);
      case '기쁨':
        return const Color(0xFF90CAF9);
      case '사랑':
        return const Color(0xFFFFCDD2);
      case '화남':
        return const Color.fromARGB(255, 255, 0, 0);
      case '창피':
        return const Color(0xFFFFF59D);
      case '즐거움':
        return const Color.fromARGB(255, 51, 255, 160);
      case '우울':
        return const Color(0xFF78909C);
      case '스트레스':
        return const Color.fromARGB(255, 255, 131, 94);
      case '슬픔':
        return const Color.fromARGB(255, 204, 212, 216);
      default:
        return Colors.grey[300]!;
    }
  }
}
