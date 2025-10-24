import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../../domain/entities/user.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  bool _isEditing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _saveProfile() {
    // TODO: Implement profile update
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    setState(() {
      _isEditing = false;
    });
  }

  void _signOut() {
    context.read<AuthBloc>().add(SignOutRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Color(0xFF1A3A5C),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A3A5C)),
        actions: [
          IconButton(
            onPressed: _toggleEdit,
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            tooltip: _isEditing ? 'Cancel' : 'Edit Profile',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Profile Header
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  User? user;
                  if (state is AuthAuthenticated) {
                    user = state.user;
                    if (!_isEditing) {
                      _nameController.text = user.fullName ?? '';
                      _emailController.text = user.email;
                      _phoneController.text = user.phone ?? '';
                      _addressController.text =
                          '123 Main Street, City, State'; // TODO: Add address to user entity
                    }
                  }
                  return _buildProfileHeader(user);
                },
              ),
              const SizedBox(height: 20),

              // Profile Information
              _buildProfileInfoSection(),
              const SizedBox(height: 20),

              // Account Settings
              _buildAccountSettingsSection(),
              const SizedBox(height: 20),

              // App Settings
              _buildAppSettingsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(User? user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Picture
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF4A90E2),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 16),

          // User Name
          Text(
            user?.fullName ?? 'User',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A3A5C),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),

          // User Email
          Text(
            user?.email ?? 'No email',
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Member Since
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF4A90E2).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Member since ${user?.createdAt?.year ?? DateTime.now().year}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A90E2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.person_outline,
                color: Color(0xFF4A90E2),
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A3A5C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Name Field
          _buildInfoField(
            label: 'Full Name',
            controller: _nameController,
            icon: Icons.person,
            enabled: _isEditing,
          ),
          const SizedBox(height: 16),

          // Email Field
          _buildInfoField(
            label: 'Email',
            controller: _emailController,
            icon: Icons.email,
            enabled: false, // Email usually can't be changed
          ),
          const SizedBox(height: 16),

          // Phone Field
          _buildInfoField(
            label: 'Phone Number',
            controller: _phoneController,
            icon: Icons.phone,
            enabled: _isEditing,
          ),
          const SizedBox(height: 16),

          // Address Field
          _buildInfoField(
            label: 'Address',
            controller: _addressController,
            icon: Icons.location_on,
            enabled: _isEditing,
          ),

          if (_isEditing) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90E2),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool enabled,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A3A5C),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF6B7280), size: 20),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4A90E2)),
            ),
            filled: !enabled,
            fillColor: enabled ? null : Colors.grey.withOpacity(0.1),
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSettingsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.settings_outlined,
                color: Color(0xFF4A90E2),
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text(
                'Account Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A3A5C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildSettingItem(
            icon: Icons.lock_outline,
            title: 'Change Password',
            subtitle: 'Update your password',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Change password feature coming soon!'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
          ),
          const Divider(height: 24),

          _buildSettingItem(
            icon: Icons.notifications_outlined,
            title: 'Notification Settings',
            subtitle: 'Manage your notifications',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notification settings coming soon!'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
          ),
          const Divider(height: 24),

          _buildSettingItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Settings',
            subtitle: 'Manage your privacy preferences',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Privacy settings coming soon!'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppSettingsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: Color(0xFF4A90E2),
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text(
                'App Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A3A5C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildSettingItem(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get help and contact support',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Help & Support coming soon!'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
          ),
          const Divider(height: 24),

          _buildSettingItem(
            icon: Icons.info,
            title: 'About',
            subtitle: 'App version and information',
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('About BAWASA'),
                  content: const Text(
                    'BAWASA Management System\nVersion 1.0.0\n\nBuilt with Flutter',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(height: 24),

          _buildSettingItem(
            icon: Icons.logout,
            title: 'Sign Out',
            subtitle: 'Sign out of your account',
            onTap: _signOut,
            textColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: textColor ?? const Color(0xFF6B7280), size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor ?? const Color(0xFF1A3A5C),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: textColor ?? const Color(0xFF6B7280),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
