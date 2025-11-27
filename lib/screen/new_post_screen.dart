// lib/screen/new_post_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

const Color kBg = Color(0xFFFFFBEE); // 크림 배경
const Color kPrimary = Color(0xFFFFD449); // 포인트 노랑

class NewPostScreen extends StatefulWidget {
  @override
  _NewPostScreenState createState() => _NewPostScreenState();
}

class _NewPostScreenState extends State<NewPostScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<String> _selectedEmotions = [];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isUploading = false;

  File? _pickedImage;

  // 감정 리스트
  final List<String> emotions = [
    '기쁨',
    '사랑',
    '우울',
    '행복',
    '화남',
    '슬픔',
    '창피',
    '즐거움',
    '스트레스',
    '불안',
  ];

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
      case '불안':
        return const Color(0xFFB39DDB);
      default:
        return Colors.grey[300]!;
    }
  }

  // 이미지 선택
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(source: ImageSource.gallery);

      if (picked != null) {
        setState(() {
          _pickedImage = File(picked.path);
        });
      }
    } catch (e) {
      print('이미지 선택 실패: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이미지를 불러오지 못했습니다.')));
    }
  }

  // 게시글 저장
  Future<void> _savePost() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('내용을 입력해주세요.')));
      return;
    }

    if (_selectedEmotions.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('감정을 1개 이상 선택해주세요.')));
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final user = _auth.currentUser;
      final String uid = user?.uid ?? 'anonymous';

      String? imageUrl;

      // 이미지 업로드
      if (_pickedImage != null) {
        final fileName = DateTime.now().millisecondsSinceEpoch.toString();
        final ref = FirebaseStorage.instance
            .ref()
            .child('post_images')
            .child('$uid/$fileName.jpg');

        await ref.putFile(_pickedImage!);
        imageUrl = await ref.getDownloadURL();
      }

      // Firestore 저장
      await _firestore.collection('post').add({
        'content': _textController.text.trim(),
        'emotions': _selectedEmotions,
        'timestamp': FieldValue.serverTimestamp(),
        'uid': uid,
        'imageUrl': imageUrl,
        'commentCount': 0,
        'likeCount': 0,
      });

      Navigator.pop(context, true);
    } catch (e) {
      print('게시글 저장 실패: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('게시글 저장에 실패했습니다.')));
    } finally {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
      });
    }
  }

  Widget _buildEmotionChip(String emotion, bool isSelected) {
    final Color baseColor = _getEmotionColor(emotion);
    final Color bgColor = isSelected ? baseColor : baseColor.withOpacity(0.7);

    return FilterChip(
      label: Text(emotion),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          if (selected) {
            _selectedEmotions.add(emotion);
          } else {
            _selectedEmotions.remove(emotion);
          }
        });
      },
      backgroundColor: bgColor,
      selectedColor: baseColor,
      labelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      showCheckmark: false,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      side: BorderSide.none,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ 게시글 작성 화면 전체 배경을 크림으로
      backgroundColor: kBg,
      appBar: AppBar(
        // ✅ 상단바도 크림으로
        backgroundColor: kBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal: 16.0,
            ),
            child: ElevatedButton(
              onPressed: _isUploading ? null : _savePost,
              style: ElevatedButton.styleFrom(
                // ✅ 등록 버튼 노랑으로
                backgroundColor: kPrimary,
                disabledBackgroundColor: Colors.grey[300],
                foregroundColor: Colors.black,
                disabledForegroundColor: Colors.black54,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: _isUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      '등록',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔲 회색 박스 : 글쓰기 + (아래) 선택된 감정 + + 버튼
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  // 위쪽: 글 입력
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      maxLines: null,
                      decoration: const InputDecoration(
                        hintText: '오늘 느낀 감정을 편하게 나눠보세요...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  // 이미지 미리보기
                  if (_pickedImage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          _pickedImage!,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                  // 오른쪽 아래 + 버튼 (이미지 추가)
                  Align(
                    alignment: Alignment.bottomRight,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 24,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // 감정 칩 선택 영역
          Container(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: emotions.map((emotion) {
                final isSelected = _selectedEmotions.contains(emotion);
                return _buildEmotionChip(emotion, isSelected);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
