import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _errorMessage = '';

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'Login failed! Please try again.';
      });
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Expense Tracker",
                style: TextStyle(color: Colors.greenAccent, fontSize: 30, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                "Track your spending effortlessly",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              SizedBox(height: 30),

              _buildTextField("Email", Icons.email, _emailController, false),
              SizedBox(height: 20),
              _buildTextField("Password", Icons.lock, _passwordController, true),

              if (_errorMessage.isNotEmpty) ...[
                SizedBox(height: 10),
                Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.redAccent, fontSize: 14),
                ),
              ],

              SizedBox(height: 30),
              _isLoading
                  ? CircularProgressIndicator(color: Colors.greenAccent)
                  : ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text("Login", style: TextStyle(color: Colors.black, fontSize: 18)),
              ),

              SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SignUpScreen())),
                child: Text("Don't have an account? Sign Up", style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, IconData icon, TextEditingController controller, bool isPassword) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.greenAccent),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.greenAccent),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        )
            : null,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.greenAccent)),
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }
}
