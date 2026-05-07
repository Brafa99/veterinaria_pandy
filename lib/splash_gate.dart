import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'auth_gate.dart';

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (!kIsWeb) {
      await Future.delayed(const Duration(seconds: 2));
    }

    Future.microtask(() {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthGate()),
      );
    });
  }

  @override
Widget build(BuildContext context) {
  final size = MediaQuery.of(context).size;

  return Scaffold(
    backgroundColor: const Color(0xFFF4F6FA),
    body: SizedBox.expand(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Center(
                child: Image.asset(
                  "assets/img/pandy.jpeg",
                  width: size.width * 0.85,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.only(bottom: 30),
            child: CircularProgressIndicator(),
          ),
        ],
      ),
    ),
  );
}
}