import 'package:chat_app/features/authentication/SignIn/signin_screen.dart';
import 'package:chat_app/features/chat/screens/chat_list/chat_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  bool _showProgressIndicator = false;
  late AnimationController _logoController;
  late Animation<double> _logoAnimation;
  late AnimationController _textController;
  late Animation<double> _textAnimation;

  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _initializeSplashScreen();
  }

  void _initializeSplashScreen() async {
    _logoController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _logoAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOutBack,
    );

    _textController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _textAnimation = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    );

    _logoController.forward();

    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _showProgressIndicator = true;
    });
    _textController.forward();

    isLoggedIn = await _checkLoginStatus();

    await Future.delayed(const Duration(seconds: 2));
    Navigator.pushReplacement(
      context,
      PageTransition(
        type: PageTransitionType.fade,
        child: isLoggedIn ? const ChatListScreen() : const LoginScreen(),
      ),
    );
  }

  Future<bool> _checkLoginStatus() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFA8B02),
              Color(0xFFF97400),
              Color(0xFFD14D00),
              Color(0xFF4A154B),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _logoAnimation,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  width: width * 0.35,
                  height: height * 0.18,
                ),
              ),
            ),
            const SizedBox(height: 20),
            FadeTransition(
              opacity: _textAnimation,
              child: Text(
                "Connecting Lives, Instantly",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 50),
            if (_showProgressIndicator)
              const SpinKitPulse(
                color: Colors.white,
                size: 60,
              ),
          ],
        ),
      ),
    );
  }
}
