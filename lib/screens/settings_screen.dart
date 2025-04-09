import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  bool _isDarkMode = false; // Toggle for dark/light theme
  String _selectedCurrency = 'INR'; // Default currency
  List<String> _currencies = ['INR', 'USD', 'EUR', 'GBP', 'JPY'];

  User? get _user => _auth.currentUser;

  /// Change Password Function
  Future<void> _changePassword() async {
    if (_user == null) {
      Fluttertoast.showToast(msg: "User not logged in.");
      return;
    }

    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: _user!.email!,
        password: _currentPasswordController.text,
      );
      await _user!.reauthenticateWithCredential(credential);
      await _user!.updatePassword(_newPasswordController.text);

      Fluttertoast.showToast(msg: "Password changed successfully.");
      _currentPasswordController.clear();
      _newPasswordController.clear();
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: ${e.toString()}");
    }
  }

  /// Show Password Change Dialog
  void _showPasswordChangeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Change Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _currentPasswordController,
              obscureText: true,
              decoration: InputDecoration(labelText: "Current Password"),
            ),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: InputDecoration(labelText: "New Password"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              _changePassword();
              Navigator.pop(context);
            },
            child: Text("Change"),
          ),
        ],
      ),
    );
  }

  /// Logout User
  Future<void> _logout() async {
    await _auth.signOut();
    Navigator.of(context).pushReplacementNamed('/login'); // Navigate to login screen
  }

  /// Show Currency Selection Dialog
  void _showCurrencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Select Currency"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _currencies.map((currency) {
            return ListTile(
              title: Text(currency),
              trailing: _selectedCurrency == currency ? Icon(Icons.check, color: Colors.green) : null,
              onTap: () {
                setState(() => _selectedCurrency = currency);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Toggle Dark/Light Mode
  void _toggleDarkMode(bool value) {
    setState(() => _isDarkMode = value);
    // Implement theme change logic (you can use a theme provider)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text("Settings"),
        backgroundColor: _isDarkMode ? Colors.black : Colors.blue,
        iconTheme: IconThemeData(color: _isDarkMode ? Colors.white : Colors.black),
      ),
      body: ListView(
        children: [
          // Profile Info
          ListTile(
            leading: Icon(Icons.person, color: _isDarkMode ? Colors.white : Colors.black),
            title: Text(_user?.email ?? "Not logged in", style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
            subtitle: Text("Your Email", style: TextStyle(color: _isDarkMode ? Colors.white54 : Colors.black54)),
          ),
          Divider(color: Colors.grey),

          // Change Password
          ListTile(
            leading: Icon(Icons.lock, color: Colors.blue),
            title: Text("Change Password", style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
            onTap: _showPasswordChangeDialog,
          ),

          // Currency Selection
          ListTile(
            leading: Icon(Icons.currency_exchange, color: Colors.green),
            title: Text("Currency: $_selectedCurrency", style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
            onTap: _showCurrencyDialog,
          ),

          // Dark Mode Toggle
          SwitchListTile(
            title: Text("Dark Mode", style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
            secondary: Icon(_isDarkMode ? Icons.dark_mode : Icons.light_mode, color: Colors.amber),
            value: _isDarkMode,
            onChanged: _toggleDarkMode,
          ),

          // Logout Button
          ListTile(
            leading: Icon(Icons.logout, color: Colors.redAccent),
            title: Text("Logout", style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}
