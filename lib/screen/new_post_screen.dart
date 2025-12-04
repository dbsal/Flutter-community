import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

const Color kBg = Color(0xFFFFFBEE);
const Color kPrimary = Color(0xFFFFD449);

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
        if (!await _pickedImage!.exists()) {
          print('파일이 존재하지 않습니다.');
          throw Exception('Selected file does not exist');
        }
        final length = await _pickedImage!.length();
        print('업로드 파일 크기: $length bytes');

        final fileName = DateTime.now().millisecondsSinceEpoch.toString();
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('post_images')
            .child(uid)
            .child('$fileName.jpg');

        print('업로드 경로: ${storageRef.fullPath}');

        final uploadTask = storageRef.putData(
          await _pickedImage!.readAsBytes(),
        );

        // 업로드 완료 대기
        final snapshot = await uploadTask;

        print(
          '업로드 상태: ${snapshot.state}, 전송된 바이트: ${snapshot.bytesTransferred}/${snapshot.totalBytes}',
        );

        if (snapshot.state == TaskState.success) {
          // snapshot.ref를 사용하여 URL 가져오기 (경로 불일치 방지)
          imageUrl = await snapshot.ref.getDownloadURL();
          print('다운로드 URL 획득 성공: $imageUrl');
        } else {
          print('이미지 업로드 실패 상태: ${snapshot.state}');
          throw FirebaseException(
            plugin: 'firebase_storage',
            code: 'upload-failed',
            message: 'Image upload failed with state: ${snapshot.state}',
          );
        }
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
      backgroundColor: kBg,
      appBar: AppBar(
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

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _selectedEmotions.map((emotion) {
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedEmotions.remove(emotion);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: _getEmotionColor(
                                    emotion,
                                  ).withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  emotion,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 이미지 추가 버튼
                      GestureDetector(
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
                    ],
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

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
