import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:community/auth/service.dart';
import 'package:community/screen/main_app_screen.dart';
import 'package:community/screen/login_screen..dart';

void main() async {
  // Flutter 엔진 초기화 보장
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 앱 실행
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '마음 놓고',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Color(0xFFF8F8F8),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
        ),
      ),
      home: StreamBuilder<User?>(
        // 로그인 상태 실시간 감지
        stream: _authService.authStateChanges,
        builder: (context, snapshot) {
          // 연결 중이면 로딩 표시
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          // 로그인 데이터(User)가 있으면 메인 화면으로
          if (snapshot.hasData) {
            return MainAppScreen();
          }

          // 데이터가 없으면(로그아웃 상태) 로그인 화면으로
          return LoginScreen(authService: _authService);
        },
      ),
    );
  }
}
