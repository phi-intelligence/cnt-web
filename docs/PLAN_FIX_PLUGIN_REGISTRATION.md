# Plan: Fix Plugin Registration Issues in Mobile App

## Problem Summary

After fixing Firebase initialization, the app now launches successfully but has plugin channel registration issues:

1. **PathProvider/Google Fonts Error** (Non-blocking but causes exceptions)
2. **Google Sign-In Error** (Blocking - feature completely non-functional)
3. **GeneratedPluginRegistrant Warning** (Root cause of both issues)

## Root Cause Analysis

The `GeneratedPluginRegistrant.java` file exists and contains all plugin registrations (PathProvider, Google Sign-In, etc.), but:

1. `MainActivity.kt` doesn't override `configureFlutterEngine()` to call `GeneratedPluginRegistrant.registerWith()`
2. Flutter's automatic plugin registration may not be working in release builds with minification enabled
3. ProGuard rules may be missing for plugin classes

## Solution Overview

1. **Override `configureFlutterEngine()` in MainActivity** to explicitly register plugins
2. **Add ProGuard rules** for PathProvider and Google Sign-In plugin classes
3. **Add error handling** for Google Fonts to gracefully handle PathProvider failures
4. **Add error handling** for Google Sign-In with user-friendly messages

## Implementation Steps

### 1. Fix MainActivity to Explicitly Register Plugins

**File:** [`mobile/frontend/android/app/src/main/kotlin/com/christtabernacle/cntmedia/MainActivity.kt`](mobile/frontend/android/app/src/main/kotlin/com/christtabernacle/cntmedia/MainActivity.kt)

**Changes:**
- Override `configureFlutterEngine()` method
- Explicitly call `GeneratedPluginRegistrant.registerWith()`
- Add error handling for plugin registration

**Code:**
```kotlin
package com.christtabernacle.cntmedia

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Explicitly register all plugins
        GeneratedPluginRegistrant.registerWith(flutterEngine)
    }
}
```

### 2. Add ProGuard Rules for Plugin Classes

**File:** [`mobile/frontend/android/app/proguard-rules.pro`](mobile/frontend/android/app/proguard-rules.pro)

**Changes:**
- Add PathProvider-specific ProGuard rules
- Add Google Sign-In specific ProGuard rules
- Ensure plugin classes and methods are not obfuscated

**Code to add:**
```proguard
# ============================================
# PathProvider Plugin - Keep necessary classes
# ============================================
-keep class io.flutter.plugins.pathprovider.** { *; }
-keep class androidx.core.content.** { *; }
-dontwarn io.flutter.plugins.pathprovider.**

# Keep PathProvider API classes (Pigeon generated)
-keep class io.flutter.plugins.pathprovider.Messages$** { *; }
-keep class io.flutter.plugins.pathprovider.PathProviderApi** { *; }

# ============================================
# Google Sign-In Plugin - Keep necessary classes
# ============================================
-keep class io.flutter.plugins.googlesignin.** { *; }
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }
-dontwarn io.flutter.plugins.googlesignin.**
-dontwarn com.google.android.gms.**

# Keep Google Sign-In API classes (Pigeon generated)
-keep class io.flutter.plugins.googlesignin.Messages$** { *; }
-keep class io.flutter.plugins.googlesignin.GoogleSignInApi** { *; }

# Keep Google Sign-In configuration
-keep class com.google.android.gms.auth.api.signin.** { *; }

# ============================================
# Google Fonts - PathProvider dependency
# ============================================
-keep class dev.dart_lang.pigeon.** { *; }
-keep class io.flutter.plugins.pigeon.** { *; }
```

### 3. Add Error Handling for Google Fonts

**File:** [`mobile/frontend/lib/theme/app_typography.dart`](mobile/frontend/lib/theme/app_typography.dart)

**Changes:**
- Wrap `GoogleFonts.inter()` calls in try-catch blocks
- Provide fallback to system font if Google Fonts fails
- Cache font loading failures to avoid repeated attempts

**Approach:**
Create a helper method that safely loads fonts with fallback:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';

/// Typography system matching the React Native mobile app exactly
/// Based on Inter font family and website typography
class AppTypography {
  AppTypography._();

  // Cache for font loading failures
  static bool _fontLoadFailed = false;

  // Helper method to safely load Google Fonts with fallback
  static TextStyle _safeGoogleFont(TextStyle Function() fontLoader) {
    if (_fontLoadFailed) {
      // Use fallback if fonts failed to load previously
      return _fallbackFont();
    }
    
    try {
      return fontLoader();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Google Fonts loading failed: $e');
        debugPrint('   Using fallback system font');
      }
      _fontLoadFailed = true;
      return _fallbackFont();
    }
  }

  // Fallback font using system defaults
  static TextStyle _fallbackFont({
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: 'Inter', // Try Inter first, falls back to system default
      fontSize: fontSize ?? fontSizeBase,
      fontWeight: fontWeight ?? fontWeightNormal,
      height: height ?? lineHeightNormal,
      letterSpacing: letterSpacing,
    );
  }

  // Update all getters to use _safeGoogleFont
  static TextStyle get heroTitle => _safeGoogleFont(() => GoogleFonts.inter(
        fontSize: fontSize4XL,
        fontWeight: fontWeightBold,
        height: lineHeightTight,
      ));

  // ... (update all other getters similarly)
}
```

### 4. Improve Google Sign-In Error Handling

**File:** [`mobile/frontend/lib/services/google_auth_service.dart`](mobile/frontend/lib/services/google_auth_service.dart)

**Changes:**
- Add better error handling in `_getGoogleSignIn()` method
- Check plugin availability before attempting initialization
- Provide user-friendly error messages

**Code updates:**
```dart
Future<GoogleSignIn> _getGoogleSignIn() async {
  if (_googleSignInInstance != null) {
    return _googleSignInInstance!;
  }
  
  if (_isInitializing) {
    await Future.delayed(const Duration(milliseconds: 100));
    if (_googleSignInInstance != null) {
      return _googleSignInInstance!;
    }
  }
  
  _isInitializing = true;
  
  try {
    // Check if plugin is available (might fail if not registered)
    try {
      // Attempt to create instance to check plugin availability
      final testInstance = GoogleSignIn(scopes: ['email']);
      // If we get here, plugin is available
    } catch (e) {
      throw Exception(
        'Google Sign-In plugin not available. '
        'This may be a build configuration issue. '
        'Please try reinstalling the app or contact support.'
      );
    }

    String? clientId = _getClientIdFromEnv();
    
    if (clientId == null || clientId.isEmpty) {
      try {
        clientId = await _apiService.getGoogleClientId();
        _cachedClientId = clientId;
      } catch (e) {
        print('⚠️  Could not fetch Google Client ID from backend: $e');
      }
    }
    
    if (clientId != null && clientId.isNotEmpty) {
      _googleSignInInstance = GoogleSignIn(
        scopes: ['email', 'profile'],
        clientId: clientId,
      );
      print('✅ Google Sign-In initialized with Client ID');
    } else {
      _googleSignInInstance = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
      print('⚠️  Google Sign-In initialized without Client ID');
    }
  } catch (e) {
    _isInitializing = false;
    rethrow; // Re-throw to let caller handle it
  } finally {
    _isInitializing = false;
  }
  
  return _googleSignInInstance!;
}
```

### 5. Update User Login Screen Error Display

**File:** [`mobile/frontend/lib/screens/user_login_screen.dart`](mobile/frontend/lib/screens/user_login_screen.dart)

**Changes:**
- Improve error message display for Google Sign-In failures
- Show user-friendly message instead of raw PlatformException

**Find the `_handleGoogleSignIn()` method and update error handling:**
```dart
Future<void> _handleGoogleSignIn() async {
  // ... existing code ...
  
  try {
    // ... existing sign-in code ...
  } catch (e) {
    setState(() {
      _isGoogleLoading = false;
    });
    
    String errorMessage = 'Failed to sign in with Google';
    if (e.toString().contains('plugin not available')) {
      errorMessage = 'Google Sign-In is not available. Please try reinstalling the app.';
    } else if (e.toString().contains('channel-error')) {
      errorMessage = 'Google Sign-In service is temporarily unavailable. Please try again later.';
    } else if (e.toString().contains('Client ID')) {
      errorMessage = 'Google Sign-In is not configured. Please contact support.';
    }
    
    // Show error to user
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
    
    print('❌ Error signing in with Google: $e');
  }
}
```

## Testing Steps

1. **Clean and rebuild:**
   ```bash
   cd mobile/frontend
   flutter clean
   flutter pub get
   flutter build apk --release
   ```

2. **Install and test:**
   - Install APK on physical device
   - Verify app launches without errors
   - Check logs for plugin registration success
   - Test Google Sign-In button (should work or show friendly error)
   - Verify fonts load correctly (check UI appearance)

3. **Verify fixes:**
   - No PathProvider errors in logs
   - No Google Sign-In channel errors
   - GeneratedPluginRegistrant warning should be resolved
   - Fonts display correctly (Google Fonts or fallback)
   - Google Sign-In works or shows user-friendly error

## Expected Outcomes

- Plugin channels properly registered in release builds
- No more GeneratedPluginRegistrant warnings
- PathProvider errors resolved (or gracefully handled)
- Google Sign-In works correctly
- Better error messages for users
- Fonts load reliably with graceful fallback

## Files to Modify

1. [`mobile/frontend/android/app/src/main/kotlin/com/christtabernacle/cntmedia/MainActivity.kt`](mobile/frontend/android/app/src/main/kotlin/com/christtabernacle/cntmedia/MainActivity.kt) - Add explicit plugin registration
2. [`mobile/frontend/android/app/proguard-rules.pro`](mobile/frontend/android/app/proguard-rules.pro) - Add plugin ProGuard rules
3. [`mobile/frontend/lib/theme/app_typography.dart`](mobile/frontend/lib/theme/app_typography.dart) - Add error handling for fonts
4. [`mobile/frontend/lib/services/google_auth_service.dart`](mobile/frontend/lib/services/google_auth_service.dart) - Improve error handling
5. [`mobile/frontend/lib/screens/user_login_screen.dart`](mobile/frontend/lib/screens/user_login_screen.dart) - Better error messages

## Priority Order

1. **High Priority:** MainActivity plugin registration (fixes root cause)
2. **High Priority:** ProGuard rules (prevents obfuscation issues)
3. **Medium Priority:** Google Sign-In error handling (improves UX)
4. **Low Priority:** Google Fonts error handling (non-blocking but improves stability)

## Additional Notes

- The explicit plugin registration in MainActivity should resolve the GeneratedPluginRegistrant warning
- ProGuard rules ensure plugin classes aren't obfuscated in release builds
- Error handling provides graceful degradation if plugins still fail
- Font fallback ensures UI remains functional even if Google Fonts fails
- User-friendly error messages improve app quality and user experience

