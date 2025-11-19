import 'package:flutter/material.dart';
import 'package:community/auth/service.dart';

class LoginScreen extends StatelessWidget {
  final AuthService authService;

  LoginScreen({required this.authService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          child: Text('Google로 로그인하기'),
          onPressed: () async {
            await authService.signInWithGoogle();
          },
        ),
      ),
    );
  }
}
