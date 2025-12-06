import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/welcome_screen.dart';
import 'screens/homescreenview.dart';
import 'screens/email_screen.dart';
import 'screens/nickname_screen.dart';
import 'screens/age_selection_screen.dart';
import 'services/ai_service.dart';
import 'models/user_model.dart';

void main() async {
  // Ensure Flutter widgets are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    debugPrint('✅ Firebase initialized successfully');
  } catch (e) {
    debugPrint('❌ Firebase initialization failed: $e');
  }
  
  // Initialize AI Service
  AIService.instance.clearApiKeys();
  AIService.instance.setChatbotMode();
  
  final geminiApiKey =
      dotenv.env['GEMINI_API_KEY'] ??
      'AIzaSyDCD6kBoBUxVvq0sigKWF2IOmebvdDXYXQ';
  
  AIService.instance.setGeminiApiKey(geminiApiKey);
  
  debugPrint(
    '🎯 Using new Gemini Chatbot with key: ${geminiApiKey.substring(0, 10)}...',
  );
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mental Health Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

// Wrapper widget to handle authentication logic
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show loading screen while checking auth state
        if (authProvider.isLoading) {
          debugPrint('🔄 AuthProvider is loading...');
          return _buildLoadingScreen();
        }
        
        // Debug information
        _logAuthState(authProvider);
        
        // 1. User is NOT logged in
        if (!authProvider.isLoggedIn) {
          debugPrint('👋 No user logged in, showing welcome screen');
          return const WelcomeScreen();
        }
        
        // 2. User IS logged in
        final user = authProvider.user;
        
        // Debug user profile
        _logUserProfile(user);
        
        // 2.1 Check email verification
        if (!authProvider.isEmailVerified) {
          debugPrint('📧 Email not verified, showing verification screen');
          return const EmailScreen();
        }
        
        // 2.2 Check if profile setup is complete
        if (!authProvider.hasCompletedSetup || !authProvider.isProfileComplete) {
          debugPrint('👤 Profile incomplete, showing setup flow');
          return _determineSetupScreen(authProvider, user, context);
        }
        
        // 2.3 Everything is complete - show home screen
        debugPrint('✅ All checks passed, showing home screen');
        return const HomeScreen();
      },
    );
  }
  
  // Helper method to determine which setup screen to show
  Widget _determineSetupScreen(AuthProvider authProvider, UserModel user, BuildContext context) {
    // Determine what step needs to be completed
    if (user.nickname.isEmpty || user.nickname == 'User') {
      debugPrint('📝 Showing nickname screen (first step)');
      return NicknameScreen(
        email: user.email,
        password: authProvider.tempPassword ?? '',
      );
    }
    
    // If nickname is set but age is not set
    if (user.age <= 0) {
      debugPrint('🎂 Showing age selection screen');
      return AgeSelectionScreen(
        email: user.email,
        password: authProvider.tempPassword ?? '',
        nickname: user.nickname,
      );
    }
    
    // If nickname and age are set but gender is not set
    if (user.gender.isEmpty) {
      debugPrint('🚻 Showing age selection screen for gender selection');
      return AgeSelectionScreen(
        email: user.email,
        password: authProvider.tempPassword ?? '',
        nickname: user.nickname,
      );
    }
    
    // Default fallback - shouldn't reach here if logic is correct
    debugPrint('⚠️ Profile incomplete but could not determine missing field');
    return _buildProfileIncompleteScreen(user, authProvider, context);
  }
  
  // Loading screen
  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.purple.shade300),
            ),
            const SizedBox(height: 20),
            const Text(
              'Loading your cosmic journey...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Profile incomplete screen (fallback)
  Widget _buildProfileIncompleteScreen(UserModel user, AuthProvider authProvider, BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated planet icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.shade300,
                      Colors.purple.shade300,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_add_alt_1,
                  color: Colors.white,
                  size: 50,
                ),
              ),
              
              const SizedBox(height: 30),
              
              const Text(
                'Complete Your Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'Email: ${user.email}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              
              const SizedBox(height: 8),
              
              const Text(
                'Please complete your profile setup to personalize your experience.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 20),
              
              // Show what's missing
              _buildMissingFieldsList(user),
              
              const SizedBox(height: 40),
              
              // Continue setup button - dynamically determine which screen to show
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    _navigateToAppropriateSetupScreen(user, authProvider, context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: Colors.purple.withOpacity(0.4),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_outline, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Continue Setup',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Logout button
              TextButton(
                onPressed: () async {
                  debugPrint('🚪 User requested logout');
                  await authProvider.logout();
                },
                child: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Helper method to navigate to the correct setup screen
  void _navigateToAppropriateSetupScreen(
    UserModel user, 
    AuthProvider authProvider, 
    BuildContext context
  ) {
    if (user.nickname.isEmpty || user.nickname == 'User') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NicknameScreen(
            email: user.email,
            password: authProvider.tempPassword ?? '',
          ),
        ),
      );
    } else if (user.age <= 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AgeSelectionScreen(
            email: user.email,
            password: authProvider.tempPassword ?? '',
            nickname: user.nickname,
          ),
        ),
      );
    } else if (user.gender.isEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AgeSelectionScreen(
            email: user.email,
            password: authProvider.tempPassword ?? '',
            nickname: user.nickname,
          ),
        ),
      );
    }
  }
  
  // Widget to show missing fields
  Widget _buildMissingFieldsList(UserModel user) {
    final missingFields = <String>[];
    
    if (user.nickname.isEmpty || user.nickname == 'User') {
      missingFields.add('Nickname');
    }
    if (user.age <= 0) {
      missingFields.add('Age');
    }
    if (user.gender.isEmpty) {
      missingFields.add('Gender');
    }
    
    if (missingFields.isEmpty) return const SizedBox();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Missing Information:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...missingFields.map((field) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  color: Colors.orange.shade300,
                  size: 8,
                ),
                const SizedBox(width: 8),
                Text(
                  field,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }
  
  // Log auth state for debugging
  void _logAuthState(AuthProvider authProvider) {
    debugPrint('=== AUTH STATE ===');
    debugPrint('isLoggedIn: ${authProvider.isLoggedIn}');
    debugPrint('isEmailVerified: ${authProvider.isEmailVerified}');
    debugPrint('hasCompletedSetup: ${authProvider.hasCompletedSetup}');
    debugPrint('isProfileComplete: ${authProvider.isProfileComplete}');
    debugPrint('tempPassword: ${authProvider.tempPassword != null ? "Set" : "Not set"}');
    debugPrint('========================');
  }
  
  // Log user profile for debugging
  void _logUserProfile(UserModel user) {
    debugPrint('=== USER PROFILE ===');
    debugPrint('User ID: ${user.id}');
    debugPrint('Email: ${user.email}');
    debugPrint('Nickname: "${user.nickname}" (isEmpty: ${user.nickname.isEmpty})');
    debugPrint('Age: ${user.age} (valid: ${user.age > 0})');
    debugPrint('Gender: "${user.gender}" (isEmpty: ${user.gender.isEmpty})');
    debugPrint('Avatar: ${user.avatar}');
    debugPrint('====================');
  }
}