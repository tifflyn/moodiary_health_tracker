import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'age_selection_screen.dart';

class NicknameScreen extends StatefulWidget {
  final String email;
  final String password;

  const NicknameScreen({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<NicknameScreen> createState() => _NicknameScreenState();
}

class _NicknameScreenState extends State<NicknameScreen> {
  final _nicknameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _nicknameController.addListener(_updateButtonState);
  }

  @override
  void dispose() {
    _nicknameController.removeListener(_updateButtonState);
    _nicknameController.dispose();
    super.dispose();
  }

  void _updateButtonState() {
    setState(() {
      _isButtonEnabled = _nicknameController.text.trim().isNotEmpty;
    });
  }

  void _submitNickname() {
    if (_formKey.currentState!.validate()) {
      final nickname = _nicknameController.text.trim();

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.updateUserInfo(nickname: nickname);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AgeSelectionScreen(
            email: widget.email,
            password: widget.password,
            nickname: nickname,
          ),
        ),
      );
    }
  }

  Widget _buildStar(double size, double left, double top, double opacity) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [Colors.white.withOpacity(opacity), Colors.transparent],
            stops: const [0.2, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildNebula(
    double width,
    double height,
    double left,
    double top,
    Color color,
    double opacity,
  ) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withOpacity(opacity * 0.8),
              color.withOpacity(opacity * 0.4),
              Colors.transparent,
            ],
            stops: const [0.1, 0.5, 1.0],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 星空背景
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0B0B3B), // 深蓝色
                  Color(0xFF1A1A4B), // 紫色调
                  Color(0xFF2D1B69), // 星空紫
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // 大星星
                _buildStar(3, 50, 100, 0.8),
                _buildStar(2, 120, 180, 0.7),
                _buildStar(4, 280, 80, 0.9),
                _buildStar(1.5, 350, 150, 0.6),
                _buildStar(2.5, 40, 300, 0.7),
                _buildStar(3, 320, 350, 0.8),
                _buildStar(2, 150, 400, 0.6),

                // 星云效果
                _buildNebula(200, 200, -50, -50, Color(0xFF4A148C), 0.15),
                _buildNebula(150, 150, 300, 100, Color(0xFF311B92), 0.12),
                _buildNebula(180, 180, 200, 400, Color(0xFF1A237E), 0.1),

                // 流星
                Positioned(
                  right: 50,
                  top: 120,
                  child: Transform.rotate(
                    angle: -0.3,
                    child: Container(
                      width: 80,
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.9),
                            Colors.white.withOpacity(0.1),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 返回按钮
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Material(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // 星球图标
                        Center(
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                colors: [
                                  Color(0xFF9C27B0).withOpacity(0.8),
                                  Color(0xFF673AB7).withOpacity(0.6),
                                  Color(0xFF3F51B5).withOpacity(0.4),
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF9C27B0).withOpacity(0.5),
                                  blurRadius: 30,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.person_add_alt_1,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // 标题
                        Text(
                          'What should I call you?',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Space',
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'This is how I will address you in the vast universe of thoughts.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.8),
                            fontFamily: 'Space',
                          ),
                        ),
                        const SizedBox(height: 40),

                        // 输入表单
                        Material(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          child: Form(
                            key: _formKey,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: TextFormField(
                                controller: _nicknameController,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Your Nickname',
                                  labelStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                  hintText: 'e.g., Star-Gazer, Cosmo-Traveller',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                  border: InputBorder.none,
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.always,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter a nickname to begin your journey.';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // 提示文字
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.travel_explore,
                                color: Color(0xFF9C27B0),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Choose a name that resonates with your cosmic journey',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 14,
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

                // 底部按钮区域
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Color(0xFF0B0B3B).withOpacity(0.9),
                        Color(0xFF0B0B3B).withOpacity(0.1),
                      ],
                    ),
                  ),
                  child: Material(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _isButtonEnabled
                              ? [
                                  Color(0xFF9C27B0),
                                  Color(0xFF673AB7),
                                  Color(0xFF3F51B5),
                                ]
                              : [
                                  Colors.grey.withOpacity(0.3),
                                  Colors.grey.withOpacity(0.2),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _isButtonEnabled
                            ? [
                                BoxShadow(
                                  color: Color(0xFF9C27B0).withOpacity(0.4),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: InkWell(
                        onTap: _isButtonEnabled ? _submitNickname : null,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 18,
                            horizontal: 24,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Continue to the Stars',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
