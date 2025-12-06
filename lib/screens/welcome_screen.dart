import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../widgets/glass_card.dart';
import 'auth_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 设置状态栏颜色
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.bgGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // 顶部留空
                const Expanded(flex: 1, child: SizedBox()),

                // 应用图标和标题
                Column(
                  children: [
                    GlassCard(
                      padding: const EdgeInsets.all(30),
                      child: Icon(
                        Icons.psychology_alt_outlined,
                        size: 80,
                        color: AppColors.accentBlue,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Welcome to MindWell',
                      style: AppTextStyles.headline1.copyWith(
                        fontSize: 36,
                        shadows: [
                          Shadow(
                            color: AppColors.accentBlue.withAlpha(76),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your personal mental wellness companion',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.lightBlue,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),

                // 中间留空
                const Expanded(flex: 2, child: SizedBox()),

                // 按钮区域
                Column(
                  children: [
                    // 注册按钮
                    SizedBox(
                      width: double.infinity,
                      child: GlassCard(
                        padding: const EdgeInsets.all(0),
                        color: AppColors.accentBlue.withAlpha(30),
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AuthScreen(initialIsLogin: false),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 20,
                              horizontal: 32,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_add_alt_1,
                                color: AppColors.accentBlue,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Create Account',
                                style: AppTextStyles.button.copyWith(
                                  color: AppColors.accentBlue,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 登录按钮
                    SizedBox(
                      width: double.infinity,
                      child: GlassCard(
                        padding: const EdgeInsets.all(0),
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AuthScreen(initialIsLogin: true),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 20,
                              horizontal: 32,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.login, color: AppColors.lightBlue),
                              const SizedBox(width: 12),
                              Text(
                                'Sign In',
                                style: AppTextStyles.button.copyWith(
                                  color: AppColors.lightBlue,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // 隐私条款提示
                    Text(
                      'By continuing, you agree to our Terms of Service and Privacy Policy',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textGray.withAlpha(150),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),

                // 底部留空
                const Expanded(flex: 1, child: SizedBox()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
