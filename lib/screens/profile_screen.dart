import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../data/avatar_data.dart'; // 导入头像数据

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset App Data"),
        content: const Text(
          "Are you sure you want to clear your personal data and return to the setup screen?",
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text(
              "Confirm Reset",
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      authProvider.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.purple,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // User Profile Header
            _buildProfileHeader(user),

            const SizedBox(height: 32),

            // Settings Section
            _buildSettingsSection(context),

            const SizedBox(height: 24),

            // Personal Information Section
            _buildPersonalInfoSection(context, user),

            const SizedBox(height: 24),

            // Data Management Section
            _buildDataManagementSection(context),

            const SizedBox(height: 24),

            // Legal Section
            _buildLegalSection(context),

            const SizedBox(height: 40),

            // Logout Button
            _buildLogoutButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          _buildListTile(
            icon: Icons.notifications,
            title: 'Notifications',
            subtitle: 'Manage your notification preferences',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notification settings coming soon!'),
                ),
              );
            },
          ),
          _buildListTile(
            icon: Icons.color_lens,
            title: 'Theme',
            subtitle: 'Change app theme color',
            onTap: () {
              _showThemeSelectionDialog(context);
            },
          ),
          _buildListTile(
            icon: Icons.visibility,
            title: 'Appearance',
            subtitle: 'Dark mode and theme settings',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Appearance settings coming soon!'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection(BuildContext context, UserModel user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Personal Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          _buildListTile(
            icon: Icons.person,
            title: 'Nickname',
            subtitle: user.nickname.isNotEmpty ? user.nickname : 'Not set',
            onTap: () {
              _showEditNicknameDialog(context, user);
            },
          ),
          _buildListTile(
            icon: Icons.face,
            title: 'Cartoon Avatar',
            subtitle: 'Choose your character',
            onTap: () {
              _showAvatarSelectionDialog(context, user);
            },
          ),
          _buildListTile(
            icon: Icons.cake,
            title: 'Age',
            subtitle: user.age > 0 ? '${user.age} years old' : 'Not set',
            onTap: () {
              _showEditAgeDialog(context, user);
            },
          ),
          _buildListTile(
            icon: Icons.transgender,
            title: 'Gender',
            subtitle: user.gender,
            onTap: () {
              _showGenderSelectionDialog(context, user);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDataManagementSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Data Management',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          _buildListTile(
            icon: Icons.backup,
            title: 'Export Data',
            subtitle: 'Download your mood history',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export feature coming soon!')),
              );
            },
          ),
          _buildListTile(
            icon: Icons.delete_sweep,
            title: 'Remove Personal Data',
            subtitle: 'Delete all your stored information',
            onTap: () => _showDeleteConfirmationDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Legal',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          _buildListTile(
            icon: Icons.feedback,
            title: 'Feedback',
            subtitle: 'Share your thoughts with us',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feedback system coming soon!')),
              );
            },
          ),
          _buildListTile(
            icon: Icons.privacy_tip,
            title: 'Privacy Policy',
            subtitle: 'How we protect your data',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Privacy policy coming soon!')),
              );
            },
          ),
          _buildListTile(
            icon: Icons.description,
            title: 'Terms & Conditions',
            subtitle: 'App usage terms',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Terms & conditions coming soon!'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    // 根据用户选择的头像显示对应的emoji，如果没有选择则显示默认头像
    final userAvatar = AvatarData.avatars.firstWhere(
      (avatar) => avatar.id == user.avatar,
      orElse: () => AvatarData.avatars.first,
    );

    return Center(
      child: Column(
        children: [
          // 头像显示
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.purple.shade100,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.purple, width: 3),
            ),
            child: Center(
              child: Text(
                userAvatar.emoji,
                style: const TextStyle(fontSize: 40),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user.nickname.isNotEmpty ? user.nickname : 'Guest',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            userAvatar.name, // 显示头像名称
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => _handleLogout(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          "Reset App Data & Logout",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.purple),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Personal Data"),
        content: const Text(
          "This will permanently delete all your mood entries, check-ins, and personal information. This action cannot be undone.",
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text(
              "Delete All Data",
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Personal data deletion feature coming soon!'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 编辑昵称对话框
  void _showEditNicknameDialog(BuildContext context, UserModel user) {
    final nicknameController = TextEditingController(text: user.nickname);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Nickname"),
        content: TextField(
          controller: nicknameController,
          decoration: const InputDecoration(
            labelText: 'Nickname',
            hintText: 'Enter your nickname',
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("Save"),
            onPressed: () {
              final newNickname = nicknameController.text.trim();
              if (newNickname.isNotEmpty) {
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                authProvider.updateUserInfo(nickname: newNickname);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nickname updated!')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // 编辑年龄对话框
  void _showEditAgeDialog(BuildContext context, UserModel user) {
    final ageController = TextEditingController(
      text: user.age > 0 ? user.age.toString() : '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Age"),
        content: TextField(
          controller: ageController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Age',
            hintText: 'Enter your age',
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("Save"),
            onPressed: () {
              final ageText = ageController.text.trim();
              if (ageText.isNotEmpty) {
                final age = int.tryParse(ageText);
                if (age != null && age > 0 && age < 120) {
                  final authProvider = Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  );
                  authProvider.updateUserInfo(age: age);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Age updated!')));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid age (1-119)'),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showGenderSelectionDialog(BuildContext context, UserModel user) {
    String selectedGender = user.gender;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Select Gender"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 使用新的 Radio 语法
                  RadioListTile(
                    title: const Text('Male'),
                    value: 'Male',
                    // ignore: deprecated_member_use
                    groupValue: selectedGender,
                    // ignore: deprecated_member_use
                    onChanged: (value) {
                      setState(() {
                        selectedGender = value!;
                      });
                    },
                  ),
                  RadioListTile(
                    title: const Text('Female'),
                    value: 'Female',
                    // ignore: deprecated_member_use
                    groupValue: selectedGender,
                    // ignore: deprecated_member_use
                    onChanged: (value) {
                      setState(() {
                        selectedGender = value!;
                      });
                    },
                  ),
                  RadioListTile(
                    title: const Text('Non-binary'),
                    value: 'Non-binary',
                    // ignore: deprecated_member_use
                    groupValue: selectedGender,
                    // ignore: deprecated_member_use
                    onChanged: (value) {
                      setState(() {
                        selectedGender = value!;
                      });
                    },
                  ),
                  RadioListTile(
                    title: const Text('Prefer not to say'),
                    value: 'Prefer not to say',
                    // ignore: deprecated_member_use
                    groupValue: selectedGender,
                    // ignore: deprecated_member_use
                    onChanged: (value) {
                      setState(() {
                        selectedGender = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.pop(context),
                ),
                TextButton(
                  child: const Text("Save"),
                  onPressed: () {
                    if (selectedGender.isNotEmpty) {
                      final authProvider = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );
                      authProvider.updateUserInfo(gender: selectedGender);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Gender updated to: $selectedGender'),
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 新增主题选择对话框
  void _showThemeSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Theme"),
        content: const Text("Choose your preferred theme color"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("Purple (Default)"),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Theme changed to Purple')),
              );
            },
          ),
          TextButton(
            child: const Text("Blue"),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Theme changed to Blue')),
              );
            },
          ),
          TextButton(
            child: const Text("Green"),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Theme changed to Green')),
              );
            },
          ),
        ],
      ),
    );
  }
}

// 添加头像选择对话框
void _showAvatarSelectionDialog(BuildContext context, UserModel user) {
  String selectedAvatar = user.avatar;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Choose Your Avatar"),
            content: SizedBox(
              width: double.maxFinite,
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // 每行3个头像
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.8,
                ),
                itemCount: AvatarData.avatars.length,
                itemBuilder: (context, index) {
                  final avatar = AvatarData.avatars[index];
                  final isSelected = selectedAvatar == avatar.id;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedAvatar = avatar.id;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.purple.shade100
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Colors.purple
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            avatar.emoji,
                            style: const TextStyle(fontSize: 30),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            avatar.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: const Text("Save"),
                onPressed: () {
                  if (selectedAvatar.isNotEmpty) {
                    final authProvider = Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    );
                    authProvider.updateUserInfo(avatar: selectedAvatar);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Avatar updated!')),
                    );
                  }
                },
              ),
            ],
          );
        },
      );
    },
  );
}
