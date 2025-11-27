// lib/my_page/my_page_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

const Color kBg = Color(0xFFFFFBEE);
const Color kPrimary = Color(0xFFFFD449);
const Color kText = Color(0xFF111827);
const Color kMuted = Color(0xFF6B7280);
const Color kCard = Color(0xFFFFFFFF);
const Color kBorder = Color(0xFFE5E7EB);

class MyPageScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1. 프로필 섹션
            _buildProfileSection(context),
            SizedBox(height: 24),

            // 2. 활동 카운트 섹션 (✅ 공감 삭제)
            _buildActivityCounters(),
            SizedBox(height: 24),

            // 3. 마음 놓고 섹션
            _buildInfoCard(
              title: '마음 놓고',
              items: [
                '❤️ 익명으로 감정을 나누는 안전한 공간입니다',
                '🤝 서로를 판단하지 않고 위로하는 커뮤니티입니다',
                '✨ 계정이나 팔로우 없이 자유롭게 소통할 수 있어요',
              ],
            ),
            SizedBox(height: 24),

            // 4. 이용 안내 섹션
            _buildInfoCard(
              title: '이용 안내',
              items: [
                '📝 게시글 작성\n감정을 선택하고 마음을 나눠주세요',
                '💬 댓글 작성\n따뜻한 위로를 남겨주세요',
              ],
              isIconList: true,
            ),
            SizedBox(height: 24),

            // 5. 버전 버튼
            _buildVersionButton(),
          ],
        ),
      ),
    );
  }

  Future<void> _showLogoutConfirmSheet(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: kBorder),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '로그아웃 하시겠어요?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kText,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('취소', style: TextStyle(color: kText)),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          side: BorderSide(color: kBorder),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _logout();
                        },
                        child: Text(
                          '로그아웃',
                          style: TextStyle(color: Colors.black87),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _logout() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await FirebaseAuth.instance.signOut();
  }

  Widget _buildProfileSection(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: kPrimary.withOpacity(0.3),
          child: Icon(Icons.person, size: 50, color: Colors.black87),
        ),
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '익명 사용자',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kText,
              ),
            ),
            SizedBox(width: 4),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.logout, size: 20.0, color: Colors.grey[700]),
              onPressed: () => _showLogoutConfirmSheet(context),
            ),
          ],
        ),
      ],
    );
  }

  // ✅ 공감 박스 제거: 작성/댓글 2개만
  Widget _buildActivityCounters() {
    return Row(
      children: [
        Expanded(child: _buildCounterBox(Icons.edit_note, '작성', '3')),
        SizedBox(width: 12),
        Expanded(
          child: _buildCounterBox(Icons.chat_bubble_outline, '댓글', '12'),
        ),
      ],
    );
  }

  Widget _buildCounterBox(IconData icon, String label, String count) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 30, color: Colors.grey[700]),
          SizedBox(height: 6),
          Text(
            count,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kText,
            ),
          ),
          SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<String> items,
    bool isIconList = false,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kText,
            ),
          ),
          SizedBox(height: 12),
          ...items.map(
            (text) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 14,
                        color: kMuted,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionButton() {
    return OutlinedButton(
      onPressed: () {},
      child: Text('버전 1.0.0 (MVP)', style: TextStyle(color: Colors.grey[700])),
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(color: kBorder),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }
}
