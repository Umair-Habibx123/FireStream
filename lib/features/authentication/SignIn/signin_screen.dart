import 'package:chat_app/features/chat/screens/chat_list/chat_list_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat_app/features/authentication/Others/SetPasswordScreen.dart';
import 'package:chat_app/features/authentication/Others/reset_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _isEmailValid = false;
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _validateEmail() {
    final email = _emailController.text;
    setState(() {
      _isEmailValid = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
    });
  }

  Future<void> _signInWithEmailPassword() async {
    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      final User? user = userCredential.user;

      if (user != null) {
        final userDoc = FirebaseFirestore.instance
            .collection('users')
            .doc(email);
        final docSnapshot = await userDoc.get();

        if (docSnapshot.exists) {
          final userData = docSnapshot.data()!;
          final username = userData['username'] ?? '';
          final profilePhotoUrl = userData['profilePic'] ?? '';

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userName', username);
          await prefs.setString('userPhoto', profilePhotoUrl);
          await prefs.setString('userEmail', email);

          await prefs.setBool('isLoggedIn', true);

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const ChatListScreen()),
          );
        } else {
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Sign Up with Google'),
                  content: const Text(
                    'It seems this email is not registered. Please sign up using Google.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _signInWithGoogle();
                      },
                      child: const Text('Sign Up with Google'),
                    ),
                  ],
                ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;

      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email address.';
          break;
        case 'wrong-password':
          errorMessage = 'The password is incorrect. Please try again.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'network-request-failed':
          errorMessage =
              'Network error. Please check your internet connection.';
          break;
        default:
          errorMessage =
              'The password is incorrect. Please try logging in with google. ';
      }

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Login Error'),
              content: Text(errorMessage),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An unexpected error occurred: ${e.toString()}'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        final userDoc = FirebaseFirestore.instance
            .collection('users')
            .doc(user.email);
        final docSnapshot = await userDoc.get();

        if (docSnapshot.exists) {
          final userData = docSnapshot.data()!;
          await prefs.setString('userEmail', userData['email'] ?? '');
          await prefs.setString('userName', userData['username'] ?? '');
          await prefs.setString('userPhoto', userData['profilePic'] ?? '');

          await prefs.setBool('isLoggedIn', true);

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const ChatListScreen()),
          );
        } else {
          await userDoc.set({
            'email': user.email,
            'username': user.displayName,
            'profilePic': user.photoURL,
          });

          await prefs.setString('userEmail', user.email ?? '');
          await prefs.setString('userName', user.displayName ?? '');
          await prefs.setString('userPhoto', user.photoURL ?? '');

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => SetPasswordScreen(user: user),
            ),
          );
        }
      }
    } catch (e) {
      print('Error signing in with Google: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing in with Google: ${e.toString()}'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepOrangeAccent, Colors.orange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  height: 250,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      Text(
                        'Welcome Back',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Find your perfect stay',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Text(
                            'Sign In to Continue',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 24),

                          TextField(
                            controller: _emailController,
                            focusNode: _emailFocusNode,
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              labelStyle: const TextStyle(
                                color: Colors.deepOrange,
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: const Icon(
                                Icons.email,
                                color: Colors.deepOrange,
                              ),
                              suffixIcon:
                                  _isEmailValid
                                      ? const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                      )
                                      : (!_isEmailValid &&
                                          _emailController.text.isNotEmpty)
                                      ? const Icon(
                                        Icons.cancel,
                                        color: Colors.red,
                                      )
                                      : null,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          TextField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            focusNode: _passwordFocusNode,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: const TextStyle(
                                color: Colors.deepOrange,
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: const Icon(
                                Icons.lock,
                                color: Colors.deepOrange,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.deepOrange,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed:
                                  _isLoading
                                      ? null
                                      : () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                    const ResetPasswordScreen(),
                                          ),
                                        );
                                      },
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: Colors.deepOrange[600],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  _isLoading ? null : _signInWithEmailPassword,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                backgroundColor: Colors.deepOrange,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: const Text(
                                'Log In',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    children: [
                      Expanded(
                        child: Divider(color: Colors.grey[400], thickness: 1),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: Colors.grey[400], thickness: 1),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _signInWithGoogle,
                      icon: Image.asset('assets/google_icon.png', height: 24),
                      label: const Text(
                        'Continue with Google',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
                  strokeWidth: 4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
