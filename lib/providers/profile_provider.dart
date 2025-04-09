import 'package:flutter/material.dart';

class ProfileProvider with ChangeNotifier {
  String _avatarPath = 'assets/avatar_he.png'; // Default avatar

  String get avatarPath => _avatarPath;

  void updateAvatar(String newAvatar) {
    _avatarPath = newAvatar;
    notifyListeners(); // Notifies UI to update
  }
}
