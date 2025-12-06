import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../data/avatar_data.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../widgets/glass_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
        child: SafeArea(
          child: Column(
            children: [
              // 顶部标题栏
              GlassCard(
                margin: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: AppColors.accentGradient,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('My Profile', style: AppTextStyles.headline2),
                          Text(
                            'Manage your account & settings',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.lightBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      final user = authProvider.user;
                      final userAvatar = AvatarData.avatars.firstWhere(
                        (avatar) => avatar.id == user.avatar,
                        orElse: () => AvatarData.avatars.first,
                      );

                      return Column(
                        children: [
                          // 个人资料卡片
                          GlassCard(
                            margin: const EdgeInsets.only(bottom: 20),
                            child: Column(
                              children: [
                                // 头像部分
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: AppColors.accentGradient,
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
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
                                  child: Center(
                                    child: Text(
                                      userAvatar.emoji,
                                      style: const TextStyle(fontSize: 40),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  user.nickname.isNotEmpty
                                      ? user.nickname
                                      : 'Guest',
                                  style: AppTextStyles.headline3,
                                ),
                                Text(
                                  userAvatar.name,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.lightBlue,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Container(
                                  height: 1,
                                  color: Colors.white.withAlpha(25),
                                ),
                              ],
                            ),
                          ),

                          // 设置部分
                          _buildSection(
                            title: 'Settings',
                            icon: Icons.settings_outlined,
                            children: [
                              _buildProfileTile(
                                icon: Icons.notifications_outlined,
                                title: 'Notifications',
                                subtitle: 'Manage notification preferences',
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Notification settings coming soon!',
                                        style: AppTextStyles.bodySmall,
                                      ),
                                      backgroundColor: AppColors.accentBlue,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              _buildProfileTile(
                                icon: Icons.palette_outlined,
                                title: 'Theme',
                                subtitle: 'Change app theme color',
                                onTap: () {
                                  _showThemeSelectionDialog(context);
                                },
                              ),
                              _buildProfileTile(
                                icon: Icons.visibility_outlined,
                                title: 'Appearance',
                                subtitle: 'Dark mode & theme settings',
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Appearance settings coming soon!',
                                        style: AppTextStyles.bodySmall,
                                      ),
                                      backgroundColor: AppColors.accentBlue,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),

                          // 个人信息部分
                          _buildSection(
                            title: 'Personal Information',
                            icon: Icons.person_outline,
                            children: [
                              _buildProfileTile(
                                icon: Icons.badge_outlined,
                                title: 'Nickname',
                                subtitle: user.nickname.isNotEmpty
                                    ? user.nickname
                                    : 'Not set',
                                onTap: () {
                                  _showEditNicknameDialog(context, user);
                                },
                              ),
                              _buildProfileTile(
                                icon: Icons.face_retouching_natural_outlined,
                                title: 'Cartoon Avatar',
                                subtitle: 'Choose your character',
                                onTap: () {
                                  _showAvatarSelectionDialog(context, user);
                                },
                              ),
                              _buildProfileTile(
                                icon: Icons.cake_outlined,
                                title: 'Age',
                                subtitle: user.age > 0
                                    ? '${user.age} years old'
                                    : 'Not set',
                                onTap: () {
                                  _showEditAgeDialog(context, user);
                                },
                              ),
                              _buildProfileTile(
                                icon: Icons.transgender_outlined,
                                title: 'Gender',
                                subtitle: user.gender,
                                onTap: () {
                                  _showGenderSelectionDialog(context, user);
                                },
                              ),
                            ],
                          ),

                          // 数据管理部分
                          _buildSection(
                            title: 'Data Management',
                            icon: Icons.storage_outlined,
                            children: [
                              _buildProfileTile(
                                icon: Icons.backup_outlined,
                                title: 'Export Data',
                                subtitle: 'Download your mood history',
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Export feature coming soon!',
                                        style: AppTextStyles.bodySmall,
                                      ),
                                      backgroundColor: AppColors.accentBlue,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              _buildProfileTile(
                                icon: Icons.delete_sweep_outlined,
                                title: 'Remove Personal Data',
                                subtitle: 'Delete all stored information',
                                onTap: () {
                                  _showDeleteConfirmationDialog(context);
                                },
                                isWarning: true,
                              ),
                            ],
                          ),

                          // 法律部分
                          _buildSection(
                            title: 'Legal',
                            icon: Icons.gavel_outlined,
                            children: [
                              _buildProfileTile(
                                icon: Icons.feedback_outlined,
                                title: 'Feedback',
                                subtitle: 'Share your thoughts with us',
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Feedback system coming soon!',
                                        style: AppTextStyles.bodySmall,
                                      ),
                                      backgroundColor: AppColors.accentBlue,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              _buildProfileTile(
                                icon: Icons.privacy_tip_outlined,
                                title: 'Privacy Policy',
                                subtitle: 'How we protect your data',
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Privacy policy coming soon!',
                                        style: AppTextStyles.bodySmall,
                                      ),
                                      backgroundColor: AppColors.accentBlue,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              _buildProfileTile(
                                icon: Icons.description_outlined,
                                title: 'Terms & Conditions',
                                subtitle: 'App usage terms',
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Terms & conditions coming soon!',
                                        style: AppTextStyles.bodySmall,
                                      ),
                                      backgroundColor: AppColors.accentBlue,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),

                          // 退出按钮
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 20,
                              bottom: 40,
                              left: 20,
                              right: 20,
                            ),
                            child: GlassCard(
                              padding: const EdgeInsets.all(0),
                              child: OutlinedButton(
                                onPressed: () => _handleLogout(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.drained,
                                  side: BorderSide(
                                    color: AppColors.drained.withAlpha(127),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.logout_outlined,
                                      color: AppColors.drained,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Reset App Data & Logout',
                                      style: AppTextStyles.button.copyWith(
                                        color: AppColors.drained,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 16),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.lightBlue),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: AppTextStyles.headline3.copyWith(
                    color: AppColors.lightBlue,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          GlassCard(child: Column(children: children)),
        ],
      ),
    );
  }

  Widget _buildProfileTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isWarning = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isWarning
                    ? AppColors.drained.withAlpha(25)
                    : AppColors.accentBlue.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isWarning ? AppColors.drained : AppColors.accentBlue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.subtitle2.copyWith(
                      color: isWarning ? AppColors.drained : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: isWarning
                          ? AppColors.drained.withAlpha(180)
                          : AppColors.textGray,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isWarning ? AppColors.drained : AppColors.textGray,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Text(
          "Reset App Data",
          style: AppTextStyles.headline3.copyWith(color: Colors.white),
        ),
        content: Text(
          "Are you sure you want to clear your personal data and return to the setup screen?",
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: Text(
              "Confirm Reset",
              style: TextStyle(color: AppColors.drained),
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

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Text(
          "Delete Personal Data",
          style: AppTextStyles.headline3.copyWith(color: Colors.white),
        ),
        content: Text(
          "This will permanently delete all your mood entries, check-ins, and personal information. This action cannot be undone.",
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text(
              "Delete All Data",
              style: TextStyle(color: AppColors.drained),
            ),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Personal data deletion feature coming soon!',
                    style: AppTextStyles.bodySmall,
                  ),
                  backgroundColor: AppColors.accentBlue,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showEditNicknameDialog(BuildContext context, UserModel user) {
    final nicknameController = TextEditingController(text: user.nickname);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Text(
          "Edit Nickname",
          style: AppTextStyles.headline3.copyWith(color: Colors.white),
        ),
        content: TextField(
          controller: nicknameController,
          style: AppTextStyles.input,
          decoration: InputDecoration(
            hintText: 'Enter your nickname',
            hintStyle: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textGray.withAlpha(150),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: AppColors.cardLight,
            contentPadding: const EdgeInsets.all(16),
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
                  SnackBar(
                    content: Text(
                      'Nickname updated!',
                      style: AppTextStyles.bodySmall,
                    ),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showEditAgeDialog(BuildContext context, UserModel user) {
    final ageController = TextEditingController(
      text: user.age > 0 ? user.age.toString() : '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Text(
          "Edit Age",
          style: AppTextStyles.headline3.copyWith(color: Colors.white),
        ),
        content: TextField(
          controller: ageController,
          keyboardType: TextInputType.number,
          style: AppTextStyles.input,
          decoration: InputDecoration(
            hintText: 'Enter your age',
            hintStyle: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textGray.withAlpha(150),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: AppColors.cardLight,
            contentPadding: const EdgeInsets.all(16),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Age updated!',
                        style: AppTextStyles.bodySmall,
                      ),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Please enter a valid age (1-119)',
                        style: AppTextStyles.bodySmall,
                      ),
                      backgroundColor: AppColors.drained,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
              backgroundColor: AppColors.cardDark,
              title: Text(
                "Select Gender",
                style: AppTextStyles.headline3.copyWith(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: Text('Male', style: AppTextStyles.bodyMedium),
                    value: 'Male',
                    groupValue: selectedGender,
                    onChanged: (value) {
                      setState(() {
                        selectedGender = value!;
                      });
                    },
                    activeColor: AppColors.accentBlue,
                  ),
                  RadioListTile<String>(
                    title: Text('Female', style: AppTextStyles.bodyMedium),
                    value: 'Female',
                    groupValue: selectedGender,
                    onChanged: (value) {
                      setState(() {
                        selectedGender = value!;
                      });
                    },
                    activeColor: AppColors.accentBlue,
                  ),
                  RadioListTile<String>(
                    title: Text('Non-binary', style: AppTextStyles.bodyMedium),
                    value: 'Non-binary',
                    groupValue: selectedGender,
                    onChanged: (value) {
                      setState(() {
                        selectedGender = value!;
                      });
                    },
                    activeColor: AppColors.accentBlue,
                  ),
                  RadioListTile<String>(
                    title: Text(
                      'Prefer not to say',
                      style: AppTextStyles.bodyMedium,
                    ),
                    value: 'Prefer not to say',
                    groupValue: selectedGender,
                    onChanged: (value) {
                      setState(() {
                        selectedGender = value!;
                      });
                    },
                    activeColor: AppColors.accentBlue,
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
                          content: Text(
                            'Gender updated to: $selectedGender',
                            style: AppTextStyles.bodySmall,
                          ),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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

  void _showThemeSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Text(
          "Select Theme",
          style: AppTextStyles.headline3.copyWith(color: Colors.white),
        ),
        content: Text(
          "Choose your preferred theme color",
          style: AppTextStyles.bodyMedium,
        ),
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
                SnackBar(
                  content: Text(
                    'Theme changed to Purple',
                    style: AppTextStyles.bodySmall,
                  ),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
          ),
          TextButton(
            child: const Text("Blue"),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Theme changed to Blue',
                    style: AppTextStyles.bodySmall,
                  ),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
          ),
          TextButton(
            child: const Text("Green"),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Theme changed to Green',
                    style: AppTextStyles.bodySmall,
                  ),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

void _showAvatarSelectionDialog(BuildContext context, UserModel user) {
  String selectedAvatar = user.avatar;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: GlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: AppColors.accentGradient,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.face_retouching_natural,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          "Choose Your Avatar",
                          style: AppTextStyles.headline3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  GridView.builder(
                    shrinkWrap: true,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.9,
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
                        child: GlassCard(
                          padding: const EdgeInsets.all(12),
                          color: isSelected
                              ? AppColors.accentBlue.withAlpha(25)
                              : null,
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
                                style: AppTextStyles.caption.copyWith(
                                  color: isSelected
                                      ? AppColors.accentBlue
                                      : AppColors.textGray,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: GlassCard(
                          padding: const EdgeInsets.all(0),
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
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
                            child: const Text("Cancel"),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassCard(
                          padding: const EdgeInsets.all(0),
                          child: ElevatedButton(
                            onPressed: () {
                              if (selectedAvatar.isNotEmpty) {
                                final authProvider = Provider.of<AuthProvider>(
                                  context,
                                  listen: false,
                                );
                                authProvider.updateUserInfo(
                                  avatar: selectedAvatar,
                                );
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Avatar updated!',
                                      style: AppTextStyles.bodySmall,
                                    ),
                                    backgroundColor: AppColors.success,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text("Save"),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
