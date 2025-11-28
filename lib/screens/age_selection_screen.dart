import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'homescreen.dart';

class AgeSelectionScreen extends StatefulWidget {
  const AgeSelectionScreen({super.key});

  @override
  State<AgeSelectionScreen> createState() => _AgeSelectionScreenState();
}

class _AgeSelectionScreenState extends State<AgeSelectionScreen> {
  // 模拟的年龄选项 (实际应用中可能需要更精确的范围)
  final List<int> ageOptions = [13, 18, 25, 35, 45, 55, 65];
  int? _selectedAge;
  bool _isLoading = false;

  // 最终提交登录/设置信息
  void _completeSetup() async {
    if (_selectedAge == null) {
      // 如果没有选择年龄，可以弹出一个提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your age to continue.')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // 使用 updateUserInfo 来更新年龄
      authProvider.updateUserInfo(age: _selectedAge!);

      // 直接导航到 HomeScreen，替换整个导航栈
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      // 处理可能的错误
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Setup failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 构建年龄选择按钮
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
            // 企鹅图标
            const Padding(
              padding: EdgeInsets.only(top: 20, bottom: 20),
              child: Icon(Icons.cake, size: 60, color: Colors.purple),
            ),

            // 标题
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

            // 年龄选择列表 (使用 Expanded 填充中间区域)
            Expanded(
              child: ListView.builder(
                itemCount: ageOptions.length,
                itemBuilder: (context, index) {
                  return _buildAgeButton(ageOptions[index]);
                },
              ),
            ),
            const SizedBox(height: 20),

            // 完成按钮
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
                    : const Text('Finish Setup'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
