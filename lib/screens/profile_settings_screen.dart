import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileSettingsScreen extends StatefulWidget {
  @override
  _ProfileSettingsScreenState createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  String selectedAvatar = "he"; // Default avatar
  bool isLoading = true; // Loading state

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  /// **Fetch user profile data from Firebase**
  Future<void> _fetchProfileData() async {
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists) {
        setState(() {
          _nameController.text = userDoc['name'] ?? "";
          selectedAvatar = userDoc['avatar'] ?? "he";
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  /// **Save profile data to Firebase Firestore**
  Future<void> _saveProfile() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'name': _nameController.text.trim(),
      'avatar': selectedAvatar,
    }, SetOptions(merge: true));

    Navigator.pop(context); // Close the settings screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // ✅ Dark theme
      appBar: AppBar(
        title: Text("Edit Profile", style: TextStyle(color: Colors.greenAccent)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.greenAccent),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(), // ✅ Dismiss keyboard on tap
        child: Padding(
          padding: EdgeInsets.all(16),
          child: isLoading
              ? Center(child: CircularProgressIndicator(color: Colors.greenAccent))
              : Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              /// **Name Input Field**
              TextField(
                controller: _nameController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Enter your name",
                  labelStyle: TextStyle(color: Colors.greenAccent),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.greenAccent),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: Icon(Icons.person, color: Colors.greenAccent),
                ),
              ),
              SizedBox(height: 20),

              /// **Avatar Selection Title**
              Text(
                "Select Avatar",
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: Colors.greenAccent),
              ),
              SizedBox(height: 15),

              /// **Avatar Selection Row**
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildAvatarSelection("he", "assets/avatar_he.png"),
                  SizedBox(width: 30),
                  _buildAvatarSelection("she", "assets/avatar_she.png"),
                ],
              ),
              SizedBox(height: 40),

              /// **Save Button**
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    "Save Profile",
                    style:
                    TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// **Reusable Avatar Selection Widget**
  Widget _buildAvatarSelection(String avatarKey, String assetPath) {
    bool isSelected = selectedAvatar == avatarKey;
    return GestureDetector(
      onTap: () => setState(() => selectedAvatar = avatarKey),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedOpacity(
            duration: Duration(milliseconds: 200),
            opacity: isSelected ? 1.0 : 0.6, // ✅ Slight fade effect when not selected
            child: CircleAvatar(
              radius: 38,
              backgroundColor: isSelected ? Colors.greenAccent.withOpacity(0.2) : Colors.transparent,
              child: CircleAvatar(
                radius: 35,
                backgroundImage: AssetImage(assetPath),
              ),
            ),
          ),
          if (isSelected)
            Positioned(
              bottom: 0,
              right: 0,
              child: Icon(Icons.check_circle, color: Colors.greenAccent, size: 22),
            ),
        ],
      ),
    );
  }
}
