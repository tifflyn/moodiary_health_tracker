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
  final List<int> ageOptions = [13, 18, 25, 35, 45, 55, 65];
  int? _selectedAge;
  bool _isLoading = false;
  String _selectedGender = 'Prefer not to say';

  void _completeSetup() async {
    if (_selectedAge == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your age to continue.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // 使用 Firebase 注册用户
      await authProvider.signUpWithEmail(
        email: widget.email,
        password: widget.password,
        nickname: widget.nickname,
        age: _selectedAge!,
        gender: _selectedGender,
        avatar: 'default',
      );

      // 显示邮箱验证提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please check your email for verification link. You can sign in after verification.',
            ),
            duration: Duration(seconds: 6),
          ),
        );

        // 导航到登录界面
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Registration failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildAgeButton(int age) {
    final isSelected = _selectedAge == age;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            _selectedAge = age;
          });
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: isSelected ? Colors.white : Colors.purple,
          backgroundColor: isSelected ? Colors.purple : Colors.white,
          side: BorderSide(
            color: isSelected ? Colors.purple : Colors.grey.shade300,
            width: 2,
          ),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          age == 13
              ? '13 - 17'
              : age == 65
              ? '65+'
              : '$age - ${age + 9}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.purple),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.only(top: 20, bottom: 20),
              child: Icon(Icons.cake, size: 60, color: Colors.purple),
            ),

            const Text(
              'And how old are you?',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'This helps me tailor the content and support to your life stage.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),

            // 性别选择
            const Text(
              'Gender (Optional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedGender,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Select your gender',
              ),
              items: ['Male', 'Female', 'Non-binary', 'Prefer not to say'].map((
                String value,
              ) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedGender = value!;
                });
              },
            ),

            const SizedBox(height: 24),
            const Text(
              'Age Group',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: ListView.builder(
                itemCount: ageOptions.length,
                itemBuilder: (context, index) {
                  return _buildAgeButton(ageOptions[index]);
                },
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedAge != null && !_isLoading
                    ? _completeSetup
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text('Create Account'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
