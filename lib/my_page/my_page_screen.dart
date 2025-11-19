import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class MyPageScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // 1. 프로필 섹션
          _buildProfileSection(),
          SizedBox(height: 24),
          // 2. 활동 카운트 섹션
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
            items: ['📝 게시글 작성\n감정을 선택하고 마음을 나눠주세요', '💬 댓글 작성\n따뜻한 위로를 남겨주세요'],
            isIconList: true,
          ),
          SizedBox(height: 24),
          // 5. 버전 정보 버튼
          _buildVersionButton(),
        ],
      ),
    );
  }

  // 1. 프로필 위젯
  Widget _buildProfileSection() {
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.grey[300],
          child: Icon(Icons.person, size: 50, color: Colors.white),
        ),
        SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.center, // 수평 중앙 정렬
          crossAxisAlignment: CrossAxisAlignment.center, // 수직 중앙 정렬
          children: [
            // '익명 사용자' 텍스트
            Text(
              '익명 사용자',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            // 공백
            SizedBox(width: 4),

            // 로그아웃 아이콘 버튼
            IconButton(
              // visualDensity를 compact로 설정해 여백을 줄입니다.
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.logout, size: 20.0, color: Colors.grey[600]),
              onPressed: () {
                // Google과 Firebase 양쪽 모두 로그아웃을 실행합니다.
                GoogleSignIn().signOut();
                FirebaseAuth.instance.signOut();
              },
            ),
          ],
        ),
      ],
    );
  }

  // 2. 활동 카운트 위젯
  Widget _buildActivityCounters() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCountCard('작성한 글', '0개', Icons.edit_note),
        _buildCountCard('보낸 댓글', '0개', Icons.chat_bubble_outline),
      ],
    );
  }

  Widget _buildCountCard(String title, String count, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 150,
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: Colors.grey[600]),
            SizedBox(height: 6),
            Text(
              count,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  // 3 & 4. 정보 카드 위젯 (재사용)
  Widget _buildInfoCard({
    required String title,
    required List<String> items,
    bool isIconList = false,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildInfoItem(item, isIconList),
            ),
          ),
        ],
      ),
    );
  }

  // 정보 카드 내 아이템
  Widget _buildInfoItem(String text, bool isIconList) {
    IconData iconData;
    String mainText;
    String? subText;

    if (isIconList) {
      if (text.contains('\n')) {
        var parts = text.split('\n');
        mainText = parts[0];
        subText = parts[1];
      } else {
        mainText = text;
        subText = null;
      }

      if (mainText.startsWith('📝'))
        iconData = Icons.edit_note;
      else if (mainText.startsWith('💬'))
        iconData = Icons.chat_bubble_outline;
      else
        iconData = Icons.error; // default

      mainText = mainText.substring(2).trim(); // 이모지 제거
    } else {
      // '마음 놓고' 섹션
      if (text.startsWith('❤️'))
        iconData = Icons.favorite_border;
      else if (text.startsWith('🤝'))
        iconData = Icons.group_outlined;
      else if (text.startsWith('✨'))
        iconData = Icons.star_border;
      else
        iconData = Icons.error;

      mainText = text.substring(2).trim(); // 이모지 제거
      subText = null;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(iconData, size: 20, color: Colors.grey[700]),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mainText,
                style: TextStyle(fontSize: 15, color: Colors.black87),
              ),
              if (subText != null) ...[
                SizedBox(height: 4),
                Text(
                  subText,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // 5. 버전 버튼 위젯
  Widget _buildVersionButton() {
    return OutlinedButton(
      onPressed: () {},
      child: Text('버전 1.0.0 (MVP)', style: TextStyle(color: Colors.grey[600])),
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(color: Colors.grey[300]!),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }
}
