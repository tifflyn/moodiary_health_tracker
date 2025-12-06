import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart' as my_provider;
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../widgets/glass_card.dart';
import 'auth_screen.dart';

class EmailScreen extends StatefulWidget {
  const EmailScreen({super.key});

  @override
  State<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends State<EmailScreen> {
  bool _isLoading = false;
  bool _isChecking = false;
  bool _isEmailSent = false;
  bool _isVerified = false;
  bool _isAutoLoggingIn = false;
  Timer? _verificationTimer;
  
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    
    // Start checking verification status
    _startVerificationCheck();
  }
  
  @override
  void dispose() {
    _verificationTimer?.cancel();
    super.dispose();
  }
  
  void _startVerificationCheck() {
    // Check every 3 seconds if email is verified
    _verificationTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_isVerified) {
        timer.cancel();
        return;
      }
      
      await _checkEmailVerification();
    });
  }
  
  Future<void> _checkEmailVerification() async {
    if (_isChecking) return;
    
    setState(() => _isChecking = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Force reload to get latest verification status
        await user.reload();
        final updatedUser = FirebaseAuth.instance.currentUser;
        
        if (updatedUser?.emailVerified ?? false) {
          setState(() => _isVerified = true);
          
          // Stop the timer
          _verificationTimer?.cancel();
          
          // AUTO-LOGIN after verification
          await _autoLoginAfterVerification();
          
          if (mounted) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Email verified successfully! Auto-logging in...'),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking verification: $e');
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }
  
  // Auto-login after verification
  Future<void> _autoLoginAfterVerification() async {
    try {
      setState(() => _isAutoLoggingIn = true);
      
      final authProvider = Provider.of<my_provider.AuthProvider>(
        context,
        listen: false,
      );
      
      // Try auto-login with stored credentials
      final success = await authProvider.autoLoginWithStoredCredentials();
      
      if (success) {
        debugPrint('✅ Auto-login successful after verification');
        
        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Logged in successfully!'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 2),
            ),
          );
          
          // Navigation will be handled by main.dart AuthWrapper
          // No need to navigate manually
        }
      } else {
        // If auto-login fails, show manual login button
        debugPrint('⚠️ Auto-login failed, showing manual option');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Please sign in manually to continue'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error during auto-login: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.drained,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAutoLoggingIn = false);
      }
    }
  }
  
  Future<void> _resendVerificationEmail() async {
    setState(() => _isLoading = true);
    
    try {
      final authProvider = Provider.of<my_provider.AuthProvider>(
        context,
        listen: false,
      );
      
      await authProvider.resendVerificationEmail();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Verification email sent! Check your inbox.'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
        
        setState(() => _isEmailSent = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.drained,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  // Manual sign in button
  void _goToSignIn() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const AuthScreen(initialIsLogin: true),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<my_provider.AuthProvider>(context);
    final userEmail = authProvider.user.email;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.bgGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Header
                GlassCard(
                  margin: const EdgeInsets.only(bottom: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.cardDark,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_back_ios_new,
                                color: AppColors.lightBlue,
                                size: 18,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentBlue.withAlpha(25),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.accentBlue.withAlpha(76),
                              ),
                            ),
                            child: Text(
                              'Email Verification',
                              style: TextStyle(
                                color: AppColors.accentBlue,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: AppColors.accentGradient,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accentBlue.withAlpha(76),
                                  blurRadius: 15,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: Icon(
                              _isVerified ? Icons.verified : Icons.mail_outline,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isVerified ? 'Email Verified!' : 'Verify Your Email',
                                  style: AppTextStyles.headline2,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _isVerified 
                                    ? 'Your email has been verified successfully'
                                    : 'Check your inbox for verification link',
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    color: AppColors.lightBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.accentBlue,
                              AppColors.accentBlue.withAlpha(100),
                              Colors.transparent,
                            ],
                            stops: const [0.5, 0.51, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Content
                GlassCard(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    children: [
                      if (_isVerified)
                        Column(
                          children: [
                            _isAutoLoggingIn
                                ? Column(
                                    children: [
                                      SizedBox(
                                        height: 60,
                                        width: 60,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 4,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            AppColors.success,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        'Auto-logging in...',
                                        style: AppTextStyles.headline3.copyWith(
                                          color: AppColors.success,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Please wait while we sign you in automatically',
                                        style: AppTextStyles.bodyLarge.copyWith(
                                          color: AppColors.lightBlue,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: AppColors.success,
                                        size: 60,
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        '✓ Email Verified',
                                        style: AppTextStyles.headline3.copyWith(
                                          color: AppColors.success,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Your email has been verified successfully!',
                                        style: AppTextStyles.bodyLarge.copyWith(
                                          color: AppColors.lightBlue,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 32),
                                      
                                      // Manual Sign In Button (in case auto-login fails)
                                      SizedBox(
                                        width: double.infinity,
                                        child: GlassCard(
                                          padding: const EdgeInsets.all(0),
                                          child: ElevatedButton(
                                            onPressed: _goToSignIn,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.accentBlue,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 16),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              elevation: 0,
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.login,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 12),
                                                const Text(
                                                  'Sign In to Continue',
                                                  style: AppTextStyles.buttonSmall,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            Text(
                              'Verification Required',
                              style: AppTextStyles.headline3.copyWith(
                                color: AppColors.lightBlue,
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Email display
                            GlassCard(
                              color: AppColors.cardDark,
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.email_outlined,
                                    color: AppColors.accentBlue,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Email Address',
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.textGray,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          userEmail,
                                          style: AppTextStyles.bodyMedium,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Instructions
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInstructionStep(
                                  number: 1,
                                  text: 'Check your email inbox (and spam folder)',
                                ),
                                _buildInstructionStep(
                                  number: 2,
                                  text: 'Click the verification link in the email',
                                ),
                                _buildInstructionStep(
                                  number: 3,
                                  text: 'Return to this screen after verification',
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Check verification button
                            SizedBox(
                              width: double.infinity,
                              child: GlassCard(
                                padding: const EdgeInsets.all(0),
                                child: ElevatedButton(
                                  onPressed: _isChecking ? null : _checkEmailVerification,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.accentBlue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isChecking
                                      ? SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 3,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.refresh,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            const Text(
                                              'Check Verification Status',
                                              style: AppTextStyles.buttonSmall,
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Resend email button
                            SizedBox(
                              width: double.infinity,
                              child: GlassCard(
                                padding: const EdgeInsets.all(0),
                                child: OutlinedButton(
                                  onPressed: _isLoading ? null : _resendVerificationEmail,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.accentBlue,
                                    side: BorderSide(
                                      color: AppColors.accentBlue.withAlpha(76),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 3,
                                            color: AppColors.accentBlue,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.send_outlined,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              _isEmailSent ? 'Email Sent Again' : 'Resend Verification Email',
                                              style: AppTextStyles.buttonSmall.copyWith(
                                                color: AppColors.accentBlue,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                // Info card
                GlassCard(
                  color: AppColors.accentBlue.withAlpha(20),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.accentBlue,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isVerified
                            ? 'After signing in, you\'ll complete your profile setup.'
                            : 'Verification is required to secure your account and access all features.',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.lightBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildInstructionStep({required int number, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.accentBlue.withAlpha(50),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.accentBlue,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                '$number',
                style: TextStyle(
                  color: AppColors.accentBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.lightBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}