import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'age_selection_screen.dart'; // 导入下一个屏幕

class NicknameScreen extends StatefulWidget {
  const NicknameScreen({super.key});

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

  // 处理昵称提交
  void _submitNickname() {
    if (_formKey.currentState!.validate()) {
      final nickname = _nicknameController.text.trim();

      // 1. 在 AuthProvider 中保存昵称，年龄暂时设为0
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.setUserInfo(
        nickname,
        0,
      ); // 使用 setUserInfo 而不是 setTemporaryNickname

      // 2. 导航到年龄选择屏幕
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AgeSelectionScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 返回按钮回到 WelcomeScreen
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
            // 企鹅图标 (Wysa 风格)
            const Padding(
              padding: EdgeInsets.only(top: 20, bottom: 20),
              child: Icon(Icons.adb, size: 60, color: Colors.purple),
            ),

            // 标题
            const Text(
              'What should I call you?',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'This is how I will address you, so feel free to use a nickname!',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),

            // 输入表单
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _nicknameController,
                decoration: InputDecoration(
                  labelText: 'Your Nickname',
                  hintText: 'e.g., Star-Gazer, Traveller',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.purple,
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a nickname.';
                  }
                  return null;
                },
              ),
            ),

            const Spacer(), // 将按钮推到底部
            // 继续按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isButtonEnabled ? _submitNickname : null,
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
                child: const Text('Continue'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
