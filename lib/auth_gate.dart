import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:veterinaria_pandy/dashboard/dashboard_page.dart';
import 'package:veterinaria_pandy/login/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<bool> _shouldStayLogged() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool("rememberMe") ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const LoginPage();
        }

        return FutureBuilder<bool>(
          future: _shouldStayLogged(),
          builder: (context, prefs) {
            if (!prefs.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // ✔ si no marcó "recordar", lo sacas
            if (prefs.data == false) {
              FirebaseAuth.instance.signOut();
              return const LoginPage();
            }

            return const DashboardPage();
          },
        );
      },
    );
  }
}