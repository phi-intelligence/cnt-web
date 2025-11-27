import 'package:flutter/foundation.dart';

class AppState extends ChangeNotifier {
  // User state
  String? currentUserId;
  
  // Player state
  bool isPlayingAudio = false;
  bool isPlayingVideo = false;
  String? currentMediaId;
  
  // Navigation state
  int currentTabIndex = 0;
  
  // Theme state
  bool isDarkMode = false;
  
  void setCurrentTab(int index) {
    currentTabIndex = index;
    notifyListeners();
  }
  
  void toggleDarkMode() {
    isDarkMode = !isDarkMode;
    notifyListeners();
  }
  
  void updatePlayerState(bool playing) {
    isPlayingAudio = playing;
    notifyListeners();
  }
}

