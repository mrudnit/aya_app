import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/onboarding/onboarding_flow.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aya',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.interTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF39FF14),
          brightness: Brightness.light,
        ),
      ),
      // Outer stream
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnap) {
          // Still connecting
          if (authSnap.connectionState == ConnectionState.waiting) {
            return const _Loader();
          }

          // Not logged in - LoginScreen
          if (!authSnap.hasData || authSnap.data == null) {
            return const LoginScreen();
          }

          // Logged in - check if onboarding is done
          final uid = authSnap.data!.uid;
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .get(),
            builder: (context, profileSnap) {
              if (profileSnap.connectionState == ConnectionState.waiting) {
                return const _Loader();
              }

              final data =
              profileSnap.data?.data() as Map<String, dynamic>?;
              final onboardingDone = data?['onboarding_completed'] == true;

              if (!onboardingDone) {
                return const OnboardingFlow();
              }

              return const HomeScreen();
            },
          );
        },
      ),
    );
  }
}

class _Loader extends StatelessWidget {
  const _Loader();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFF39FF14)),
      ),
    );
  }
}
