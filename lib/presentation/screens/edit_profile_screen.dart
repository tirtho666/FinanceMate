import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../providers/home_provider.dart';
import '../providers/user_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>();
    final home = context.read<HomeProvider>();
    final profile = home.profile;
    _nameController = TextEditingController(
      text: user.displayNameFor(profile) ?? '',
    );
    _emailController = TextEditingController(text: user.emailOr(profile, fallback: ''));
    _phoneController = TextEditingController(text: profile.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = context.read<UserProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final success = await user.updateProfile(
      fullName: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
    );
    if (!mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            success
                ? (user.successMessage ?? 'Profile updated!')
                : (user.errorMessage ?? 'Could not update profile.'),
          ),
          backgroundColor: success ? AppPalette.income : AppPalette.expense,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    if (success) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.textTheme;
    final user = context.watch<UserProvider>();
    final home = context.watch<HomeProvider>();
    final profile = home.profile;
    final displayName = user.displayNameOr(profile);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back_ios_new, color: colors.primary),
        ),
        title: Text(
          'Edit Profile',
          style: textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const SizedBox(height: 8),
            Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.primary.withValues(alpha: 0.08),
                      ),
                      child: Icon(
                        Icons.person,
                        color: colors.primary.withValues(alpha: 0.5),
                        size: 56,
                      ),
                    ),
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.primary,
                          border: Border.all(color: Colors.white, width: 2.5),
                        ),
                        child: Icon(
                          Icons.photo_camera,
                          color: colors.onPrimary,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  displayName,
                  style: textTheme.titleLarge?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Change Photo',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.primary.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _FieldLabel('Full Name'),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              style: textTheme.titleSmall?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Enter your full name',
                prefixIcon: Icon(Icons.person_outline, color: colors.primary),
                suffixIcon: _nameController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _nameController.clear();
                          setState(() {});
                        },
                        icon: Icon(Icons.close, color: colors.primary.withValues(alpha: 0.6)),
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),
            _FieldLabel('Email Address'),
            const SizedBox(height: 8),
            AbsorbPointer(
              absorbing: true,
              child: Opacity(
                opacity: 0.55,
                child: TextField(
                  controller: _emailController,
                  enabled: false,
                  style: textTheme.titleSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Email address',
                    prefixIcon: Icon(Icons.mail_outline, color: colors.primary),
                    suffixIcon: Icon(Icons.lock_outline, color: colors.primary.withValues(alpha: 0.5)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _FieldLabel('Phone Number'),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: textTheme.titleSmall?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: '+880 1XXXXXXXXX',
                prefixIcon: Icon(Icons.phone_outlined, color: colors.primary),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: user.isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: AppPalette.expense,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppPalette.expense.withValues(alpha: 0.4),
                  disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: user.isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.textTheme.titleSmall?.copyWith(
        color: context.appColors.primary,
      ),
    );
  }
}
