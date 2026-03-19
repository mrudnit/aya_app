import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_shell.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/onboarding/onboarding_flow.dart';

final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (_, mode, __) => MaterialApp(
          title: 'Aya',
          debugShowCheckedModeBanner: false,
          themeMode: mode,

      // Light theme
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.interTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF39FF14),
          brightness: Brightness.light,
        ),
      ),

      // Dark theme
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF39FF14),
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          surfaceTintColor: Colors.transparent,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1E1E1E),
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
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .snapshots(),
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

              return const MainShell();
            },
          );
        },
      ),
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
