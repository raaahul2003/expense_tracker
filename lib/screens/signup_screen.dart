import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _signUp() async {
    if (_passwordController.text.trim() != _confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Passwords do not match!')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sign up failed! Try again.')));
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Create Account",
                style: TextStyle(color: Colors.greenAccent, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 30),
              _buildTextField("Email", Icons.email, _emailController, false),
              SizedBox(height: 20),
              _buildTextField("Password", Icons.lock, _passwordController, true),
              SizedBox(height: 20),
              _buildTextField("Confirm Password", Icons.lock, _confirmPasswordController, true, confirm: true),
              SizedBox(height: 30),
              _isLoading
                  ? CircularProgressIndicator(color: Colors.greenAccent)
                  : ElevatedButton(
                onPressed: _signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text("Sign Up", style: TextStyle(color: Colors.black, fontSize: 18)),
              ),
              SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LoginScreen())),
                child: Text("Already have an account? Login", style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, IconData icon, TextEditingController controller, bool isPassword, {bool confirm = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? (confirm ? _obscureConfirmPassword : _obscurePassword) : false,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.greenAccent),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            confirm ? (_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility) : (_obscurePassword ? Icons.visibility_off : Icons.visibility),
            color: Colors.greenAccent,
          ),
          onPressed: () => setState(() {
            if (confirm) {
              _obscureConfirmPassword = !_obscureConfirmPassword;
            } else {
              _obscurePassword = !_obscurePassword;
            }
          }),
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
