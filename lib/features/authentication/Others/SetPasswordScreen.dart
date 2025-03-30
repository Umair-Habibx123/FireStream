import 'package:chat_app/features/chat/screens/chat_list/chat_list_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SetPasswordScreen extends StatefulWidget {
  final User user; // Pass the authenticated user

  const SetPasswordScreen({super.key, required this.user});

  @override
  _SetPasswordScreenState createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false; // Add this loading state variable

  Future<void> _setPassword() async {
    try {
      setState(() {
        _isLoading = true; // Show loading before starting the operation
      });

      String newPassword = _passwordController.text;

      // Update password for the user
      await widget.user.updatePassword(newPassword);

      final prefs = await SharedPreferences.getInstance();

      // Mark as logged in
      await prefs.setBool('isLoggedIn', true);

      // Redirect to home screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const ChatListScreen()),
      );
    } catch (e) {
      _showError(e.toString()); // Handle errors accordingly
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Hide loading when done
        });
      }
    }
  }

  void _showError(String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(errorMessage),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
 @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text("Set Password"),
            backgroundColor: Colors.deepOrange,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Create a new password for your account',
                  style: TextStyle(fontSize: 18, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _setPassword, // Disable button when loading
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 14, horizontal: 60),
                    backgroundColor: Colors.deepOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Set Password',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Loading overlay
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
    );
  }
}