import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'auth_screen.dart';

class AgeSelectionScreen extends StatefulWidget {
  final String email;
  final String password;
  final String nickname;

  const AgeSelectionScreen({
    super.key,
    required this.email,
    required this.password,
    required this.nickname,
  });

  @override
  State<AgeSelectionScreen> createState() => _AgeSelectionScreenState();
}

class _AgeSelectionScreenState extends State<AgeSelectionScreen> {
  final List<Map<String, dynamic>> ageOptions = [
    {'age': 13, 'label': '13 - 17', 'emoji': '🌱', 'color': Color(0xFF4CAF50)},
    {'age': 18, 'label': '18 - 24', 'emoji': '🚀', 'color': Color(0xFF2196F3)},
    {'age': 25, 'label': '25 - 34', 'emoji': '🌟', 'color': Color(0xFF9C27B0)},
    {'age': 35, 'label': '35 - 44', 'emoji': '🌠', 'color': Color(0xFF673AB7)},
    {'age': 45, 'label': '45 - 54', 'emoji': '🪐', 'color': Color(0xFF3F51B5)},
    {'age': 55, 'label': '55 - 64', 'emoji': '💫', 'color': Color(0xFF009688)},
    {'age': 65, 'label': '65+', 'emoji': '🌌', 'color': Color(0xFF795548)},
  ];

  final List<String> genderOptions = [
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say',
  ];

  int? _selectedAge;
  bool _isLoading = false;
  String _selectedGender = 'Prefer not to say';

  void _completeSetup() async {
    if (_selectedAge == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select your age to begin your journey.'),
          backgroundColor: Color(0xFF9C27B0),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      await authProvider.signUpWithEmail(
        email: widget.email,
        password: widget.password,
        nickname: widget.nickname,
        age: _selectedAge!,
        gender: _selectedGender,
        avatar: 'default',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Check your email for verification. Welcome to the cosmos!',
            ),
            backgroundColor: Color(0xFF4CAF50),
            duration: const Duration(seconds: 6),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cosmic connection failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

  Widget _buildAgeButton(Map<String, dynamic> option) {
    final isSelected = _selectedAge == option['age'];
    final color = option['color'] as Color;
    final emoji = option['emoji'] as String;
    final label = option['label'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedAge = option['age'];
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color.withOpacity(0.8), color.withAlpha(100)],
                    )
                  : null,
              color: isSelected ? null : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? color.withOpacity(0.5)
                    : Colors.white.withOpacity(0.1),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.white,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
              ],
            ),
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
                  Color(0xFF0B0B3B),
                  Color(0xFF1A1A4B),
                  Color(0xFF2D1B69),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // 星星
                _buildStar(3, 80, 120, 0.8),
                _buildStar(2, 200, 250, 0.7),
                _buildStar(4, 300, 100, 0.9),
                _buildStar(1.5, 150, 350, 0.6),
                _buildStar(2.5, 20, 200, 0.7),
                _buildStar(3, 280, 380, 0.8),

                // 星云
                _buildNebula(180, 180, -60, -60, Color(0xFF4A148C), 0.15),
                _buildNebula(200, 200, 250, 50, Color(0xFF311B92), 0.12),
                _buildNebula(150, 150, 50, 450, Color(0xFF1A237E), 0.1),
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
                      const SizedBox(width: 16),
                      Text(
                        'Step 2 of 2',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // 星球图标
                        Center(
                          child: Container(
                            width: 120,
                            height: 120,
                            margin: const EdgeInsets.only(top: 20, bottom: 30),
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                colors: [
                                  Color(0xFF2196F3).withOpacity(0.8),
                                  Color(0xFF03A9F4).withOpacity(0.6),
                                  Color(0xFF00BCD4).withOpacity(0.4),
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF2196F3).withOpacity(0.5),
                                  blurRadius: 30,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.timeline,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        // 标题
                        Text(
                          'Where are you in the cosmic timeline?',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Select your age to personalize your journey through the stars',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // 性别选择
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gender (Optional)',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Material(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                child: DropdownButtonFormField<String>(
                                  value: _selectedGender,
                                  dropdownColor: Color(0xFF1A1A4B),
                                  icon: Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                  items: genderOptions.map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Row(
                                        children: [
                                          Icon(
                                            value == 'Male'
                                                ? Icons.male
                                                : value == 'Female'
                                                ? Icons.female
                                                : Icons.transgender,
                                            color: Colors.white.withOpacity(
                                              0.7,
                                            ),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(value),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedGender = value!;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // 年龄选择标题
                        Text(
                          'Select Your Age Group',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 年龄选择按钮
                        ...ageOptions.map((option) => _buildAgeButton(option)),

                        const SizedBox(height: 40),

                        // 提示卡片
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
                                Icons.info_outline_rounded,
                                color: Color(0xFF2196F3),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Your age helps us tailor cosmic insights to your life stage',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),
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
                        Color(0xFF0B0B3B).withOpacity(0.95),
                        Color(0xFF0B0B3B).withOpacity(0.1),
                      ],
                    ),
                  ),
                  child: Material(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: _selectedAge != null && !_isLoading
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF2196F3),
                                  Color(0xFF03A9F4),
                                  Color(0xFF00BCD4),
                                ],
                              )
                            : LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.grey.withOpacity(0.3),
                                  Colors.grey.withOpacity(0.2),
                                ],
                              ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _selectedAge != null && !_isLoading
                            ? [
                                BoxShadow(
                                  color: Color(0xFF2196F3).withOpacity(0.4),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: InkWell(
                        onTap: _selectedAge != null && !_isLoading
                            ? _completeSetup
                            : null,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 18,
                            horizontal: 24,
                          ),
                          child: _isLoading
                              ? Center(
                                  child: SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.rocket_launch,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Launch into the Cosmos',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
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
