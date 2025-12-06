import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as my_provider; // 添加别名

import 'homescreenview.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  bool _showForgotPasswordDialog = false; // 新增：控制对话框显示

  @override
  void initState() {
    super.initState();
    _isLogin = widget.initialIsLogin;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Sign In' : 'Sign Up'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    const Icon(Icons.favorite, size: 80, color: Colors.purple),
                    const SizedBox(height: 20),
                    Text(
                      _isLogin ? 'Welcome Back!' : 'Create Account',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _isLogin
                          ? 'Sign in to continue your wellness journey'
                          : 'Join us to start your wellness journey',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 30),

                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
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

                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
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

                    // 忘记密码链接 (仅在登录页面显示)
                    if (_isLogin) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _showForgotPasswordDialog = true;
                            });
                          },
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(color: Colors.purple),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    if (_isLoading)
                      const CircularProgressIndicator()
                    else
                      ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: Text(_isLogin ? 'Sign In' : 'Sign Up'),
                      ),

                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isLogin = !_isLogin;
                        });
                      },
                      child: Text(
                        _isLogin
                            ? 'Need an account? Sign up'
                            : 'Have an account? Sign in',
                        style: const TextStyle(color: Colors.purple),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 忘记密码对话框
          if (_showForgotPasswordDialog) _buildForgotPasswordDialog(),
        ],
      ),
    );
  }

  // 忘记密码对话框
  Widget _buildForgotPasswordDialog() {
    final resetEmailController = TextEditingController();
    bool isResetting = false;

    return Container(
      color: Colors.black.withValues(alpha:0.5),
      child: Center(
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 图标
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_reset,
                        size: 40,
                        color: Colors.purple,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 标题
                    const Text(
                      'Reset Password',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 说明文字
                    const Text(
                      'Enter your email address and we\'ll send you a link to reset your password.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 24),

                    // 邮箱输入框
                    TextFormField(
                      controller: resetEmailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
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

                    const SizedBox(height: 32),

                    // 按钮
                    Row(
                      children: [
                        // 取消按钮
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isResetting
                                ? null
                                : () {
                                    setState(() {
                                      _showForgotPasswordDialog = false;
                                    });
                                  },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.purple,
                              side: const BorderSide(color: Colors.purple),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),

                        const SizedBox(width: 16),

                        // 发送按钮
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isResetting
                                ? null
                                : () async {
                                    if (resetEmailController.text.isEmpty ||
                                        !resetEmailController.text.contains(
                                          '@',
                                        )) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Please enter a valid email',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    setState(() {
                                      isResetting = true;
                                    });

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
                                        const SnackBar(
                                          content: Text(
                                            'Password reset email sent! Check your inbox.',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );

                                      setState(() {
                                        _showForgotPasswordDialog = false;
                                      });
                                    } on FirebaseAuthException catch (e) {
                                      String errorMessage;
                                      switch (e.code) {
                                        case 'user-not-found':
                                          errorMessage =
                                              'No account found with this email';
                                          break;
                                        case 'invalid-email':
                                          errorMessage =
                                              'Invalid email address';
                                          break;
                                        default:
                                          errorMessage =
                                              'Failed to send reset email: ${e.message}';
                                      }

                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(errorMessage),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    } catch (e) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Error: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    } finally {
                                      if (mounted) {
                                        setState(() {
                                          isResetting = false;
                                        });
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
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
                                : const Text(
                                    'Send Reset Link',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<my_provider.AuthProvider>(
        context,
        listen: false,
      ); // 使用别名

      if (_isLogin) {
        await authProvider.signInWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
        );

        if (authProvider.isLoggedIn) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreenView()),
          );
          return;
        }
      } else {
        // 使用新的方法来检查邮箱是否存在
        try {
          // 替代过时的 fetchSignInMethodsForEmail 方法
          final userCredential = await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
                email: _emailController.text,
                password: _passwordController.text,
              );

          // 如果创建成功，说明邮箱不存在，立即删除这个测试用户
          await userCredential.user?.delete();

          // 现在真正注册用户
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

          // 注册成功后自动切换到登录界面
          setState(() {
            _isLogin = true;
            _emailController.clear();
            _passwordController.clear();
          });
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            // 邮箱已存在，切换到登录界面
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

            setState(() {
              _isLogin = true;
            });
            return;
          } else {
            rethrow;
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      if (e.code == 'email-already-in-use') {
        // 邮箱已存在，显示提示并切换到登录界面
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.message ?? 'This email is already registered. Please sign in.',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );

        // 自动切换到登录界面
        setState(() {
          _isLogin = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
