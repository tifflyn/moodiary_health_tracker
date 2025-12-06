import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart' as my_provider;
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../widgets/glass_card.dart';

import 'homescreenview.dart';

class AuthScreen extends StatefulWidget {
  final bool initialIsLogin;

  const AuthScreen({super.key, this.initialIsLogin = true});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late bool _isLogin;
  bool _isLoading = false;
  bool _showForgotPasswordDialog = false;

  @override
  void initState() {
    super.initState();
    _isLogin = widget.initialIsLogin;
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  Widget _buildDecoratedInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(0),
      color: AppColors.cardDark,
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        style: AppTextStyles.input,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textGray.withAlpha(180),
          ),
          prefixIcon: Icon(icon, color: AppColors.lightBlue, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 20,
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildForgotPasswordDialog() {
    final resetEmailController = TextEditingController();
    bool isResetting = false;

    return Container(
      color: Colors.black.withAlpha(127),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: AppColors.accentGradient,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_reset_outlined,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Reset Password', style: AppTextStyles.headline3),
                  const SizedBox(height: 12),
                  Text(
                    'Enter your email to receive a password reset link',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.lightBlue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  GlassCard(
                    padding: const EdgeInsets.all(0),
                    color: AppColors.cardDark,
                    child: TextFormField(
                      controller: resetEmailController,
                      style: AppTextStyles.input,
                      decoration: InputDecoration(
                        hintText: 'your@email.com',
                        hintStyle: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textGray.withAlpha(100),
                        ),
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: AppColors.lightBlue,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: GlassCard(
                          padding: const EdgeInsets.all(0),
                          child: OutlinedButton(
                            onPressed: isResetting
                                ? null
                                : () {
                                    setState(() {
                                      _showForgotPasswordDialog = false;
                                    });
                                  },
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
                            child: Text(
                              'Cancel',
                              style: AppTextStyles.buttonSmall,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassCard(
                          padding: const EdgeInsets.all(0),
                          child: ElevatedButton(
                            onPressed: isResetting
                                ? null
                                : () async {
                                    if (resetEmailController.text.isEmpty ||
                                        !resetEmailController.text.contains(
                                          '@',
                                        )) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Please enter a valid email',
                                              style: AppTextStyles.bodySmall,
                                            ),
                                            backgroundColor: AppColors.drained,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        );
                                      }
                                      return;
                                    }
                                    setState(() => isResetting = true);
                                    try {
                                      final authProviderInstance =
                                          Provider.of<my_provider.AuthProvider>(
                                            context,
                                            listen: false,
                                          );
                                      await authProviderInstance
                                          .sendPasswordResetEmail(
                                            resetEmailController.text,
                                          );
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Reset email sent! Check your inbox.',
                                            style: AppTextStyles.bodySmall,
                                          ),
                                          backgroundColor: AppColors.success,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      );
                                      if (mounted) {
                                        setState(() {
                                          _showForgotPasswordDialog = false;
                                        });
                                      }
                                    } catch (e) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error: $e',
                                            style: AppTextStyles.bodySmall,
                                          ),
                                          backgroundColor: AppColors.drained,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      );
                                    } finally {
                                      if (mounted) {
                                        setState(() => isResetting = false);
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: isResetting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Send Link',
                                    style: AppTextStyles.buttonSmall,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<my_provider.AuthProvider>(
        context,
        listen: false,
      );
      if (_isLogin) {
        await authProvider.signInWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
        );
        if (authProvider.isLoggedIn && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        try {
          final userCredential = await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
                email: _emailController.text,
                password: _passwordController.text,
              );
          await userCredential.user?.delete();
          await authProvider.signUpWithEmail(
            email: _emailController.text,
            password: _passwordController.text,
            nickname: 'User',
            age: 0,
            gender: 'Prefer not to say',
            avatar: 'default',
          );
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please check your email for verification link'),
            ),
          );
          if (mounted) {
            setState(() {
              _isLogin = true;
              _emailController.clear();
              _passwordController.clear();
            });
          }
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'This email is already registered. Please sign in instead.',
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
            if (mounted) {
              setState(() {
                _isLogin = true;
              });
            }
            return;
          } else {
            rethrow;
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found with this email';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password';
          break;
        case 'email-already-in-use':
          errorMessage = 'Email already in use. Please sign in.';
          if (mounted) {
            setState(() => _isLogin = true);
          }
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        case 'weak-password':
          errorMessage = 'Password is too weak';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many attempts. Please try again later';
          break;
        default:
          errorMessage = e.message ?? 'Authentication failed';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage, style: AppTextStyles.bodySmall),
          backgroundColor: AppColors.drained,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e', style: AppTextStyles.bodySmall),
          backgroundColor: AppColors.drained,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
        child: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      GlassCard(
                        margin: const EdgeInsets.only(bottom: 32),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: AppColors.accentGradient,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.accentBlue.withAlpha(
                                          76,
                                        ),
                                        blurRadius: 15,
                                        spreadRadius: 3,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.psychology_alt_outlined,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _isLogin
                                            ? 'Welcome Back'
                                            : 'Join MindWell',
                                        style: AppTextStyles.headline2,
                                      ),
                                      Text(
                                        _isLogin
                                            ? 'Continue your wellness journey'
                                            : 'Start your wellness journey',
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
                      GlassCard(
                        margin: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          children: [
                            Text(
                              'Account Details',
                              style: AppTextStyles.headline3.copyWith(
                                color: AppColors.lightBlue,
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildDecoratedInputField(
                              controller: _emailController,
                              label: 'Email Address',
                              icon: Icons.email_outlined,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!value.contains('@')) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildDecoratedInputField(
                              controller: _passwordController,
                              label: 'Password',
                              icon: Icons.lock_outline,
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            // 忘记密码链接 - 放在密码框下面，右侧对齐
                            if (_isLogin) ...[
                              const SizedBox(height: 12),
                              Container(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(
                                      () => _showForgotPasswordDialog = true,
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                      horizontal: 8,
                                    ),
                                    child: Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        color: AppColors.accentBlue,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        decoration: TextDecoration.underline,
                                        decorationColor: AppColors.accentBlue
                                            .withAlpha(127),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ],
                        ),
                      ),
                      GlassCard(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(0),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
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
                                      _isLogin
                                          ? Icons.login
                                          : Icons.person_add_alt_1,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      _isLogin ? 'Sign In' : 'Sign Up',
                                      style: AppTextStyles.button,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      GlassCard(
                        padding: const EdgeInsets.all(0),
                        child: TextButton(
                          onPressed: () {
                            setState(() => _isLogin = !_isLogin);
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isLogin
                                    ? Icons.person_add_outlined
                                    : Icons.login_outlined,
                                color: AppColors.lightBlue,
                                size: 18,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _isLogin
                                    ? 'Need an account? Sign up'
                                    : 'Have an account? Sign in',
                                style: TextStyle(
                                  color: AppColors.lightBlue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        color: AppColors.cardDark.withAlpha(150),
                        child: Row(
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              color: AppColors.success,
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Your data is encrypted and secure',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.success,
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
            if (_showForgotPasswordDialog) _buildForgotPasswordDialog(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
